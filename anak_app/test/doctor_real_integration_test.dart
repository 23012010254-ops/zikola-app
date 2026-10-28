import 'package:flutter_test/flutter_test.dart';
import 'package:zikola/models/clinical_note.dart';
import 'package:zikola/models/patient.dart';
import 'package:zikola/models/doctor_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doctor Real Data & Serialization Tests', () {
    test('Patient model parses assessments and serializes correctly', () {
      final patientJson = {
        'id': 'patient-001',
        'name': 'Aisya Putri',
        'avatar': '👧',
        'age': 4,
        'gender': 'Perempuan',
        'parentName': 'Ibu Nurul',
        'lastVisit': '08 Sep 2026',
        'status': 'active',
        'latestAssessment': {
          'cognitive': 92,
          'linguistic': 88,
          'motor': 90,
          'completedTests': 3,
        },
      };

      final patient = Patient.fromJson(patientJson);
      expect(patient.id, 'patient-001');
      expect(patient.name, 'Aisya Putri');
      expect(patient.age, 4);
      expect(patient.gender, 'Perempuan');
      expect(patient.latestAssessment?['cognitive'], 92);
      expect(patient.latestAssessment?['completedTests'], 3);

      final backToJson = patient.toJson();
      expect(backToJson['id'], 'patient-001');
      expect(backToJson['name'], 'Aisya Putri');
      expect(backToJson['latestAssessment']['motor'], 90);
    });

    test('DoctorSchedule model fromJson, toJson and helpers work accurately', () {
      final now = DateTime.now();
      final schedule = DoctorSchedule(
        id: 'sched-101',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        patientAvatar: '👧',
        dateTime: now.add(const Duration(days: 2)),
        sessionType: 'video',
        topic: 'Evaluasi Tumbuh Kembang 4 Tahun',
        status: 'upcoming',
        notes: 'Orang tua ingin konsultasi speech delay ringan',
      );

      expect(schedule.isUpcoming, isTrue);
      expect(schedule.isCompleted, isFalse);

      final json = schedule.toJson();
      expect(json['id'], 'sched-101');
      expect(json['topic'], 'Evaluasi Tumbuh Kembang 4 Tahun');

      final completedSched = schedule.copyWith(status: 'completed');
      expect(completedSched.isCompleted, isTrue);
      expect(completedSched.isUpcoming, isFalse);
    });

    test('ClinicalNote model with Action Plan flag initializes properly', () {
      final note = ClinicalNote(
        id: 'note-001',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        doctorName: 'Dr. Sarah Amelia, Sp.A',
        category: 'Sensori & Motorik Halus',
        observation: 'Respon motorik jari tangan aktif dan fleksibel.',
        recommendation: 'Latihan menyusun balok 15 menit setiap sore.',
        isActionPlan: true,
      );

      expect(note.isActionPlan, isTrue);
      expect(note.doctorName, 'Dr. Sarah Amelia, Sp.A');
      expect(note.category, 'Sensori & Motorik Halus');

      final json = note.toJson();
      expect(json['isActionPlan'], isTrue);
      expect(json['recommendation'], 'Latihan menyusun balok 15 menit setiap sore.');
    });

    test('Doctor Action Plan matches ProgressScreen regex pattern', () {
      final note = ClinicalNote(
        id: 'note-plan-test',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        category: 'Sensori & Motorik Halus',
        observation: 'Kemampuan genggaman jemari stabil.',
        recommendation: 'Bermain puzzle 15 menit/hari dan kurangi gawai.',
        isActionPlan: true,
      );

      final actionPlanText =
          '📋 *ACTION PLAN DOKTER ZIKOLA*\n'
          '*Target Fokus*: ${note.category}\n'
          '*Batas Waktu Layar*: Maks. 30-45 Menit/Hari\n'
          '*Instruksi Khusus*: ${note.recommendation}\n\n'
          'Observasi Klinis:\n${note.observation}';

      // Test against the exact regex used in ProgressScreen._buildDoctorActionPlanSection
      expect(actionPlanText.contains('ACTION PLAN') || actionPlanText.contains('Target Fokus'), isTrue);

      final targetMatch = RegExp(r'Target Fokus\*?:\s*([^\n]+)').firstMatch(actionPlanText);
      expect(targetMatch, isNotNull);
      expect(targetMatch!.group(1)?.trim(), 'Sensori & Motorik Halus');

      final screenMatch = RegExp(r'Batas Waktu Layar\*?:\s*([^\n]+)').firstMatch(actionPlanText);
      expect(screenMatch, isNotNull);
      expect(screenMatch!.group(1)?.trim(), 'Maks. 30-45 Menit/Hari');

      final notesMatch = RegExp(r'Instruksi Khusus\*?:\s*([\s\S]+?)(?=\n\n|Silakan|$)').firstMatch(actionPlanText);
      expect(notesMatch, isNotNull);
      expect(notesMatch!.group(1)?.trim(), 'Bermain puzzle 15 menit/hari dan kurangi gawai.');
    });

    test('E-Resep Digital formatting contains required prescription metadata', () {
      const category = 'Nutrisi Otak & Perkembangan';
      const itemName = 'Minyak Ikan Omega-3 DHA Anak';
      const dosage = '1x sehari 5ml sesudah sarapan';
      const instructions = 'Diberikan rutin setiap pagi.';
      const docName = 'Dr. Sarah Amelia, Sp.A';

      final prescriptionText =
          '💊 *RESEP & REKOMENDASI TERAPI DOKTER*\n'
          '*Kategori*: $category\n'
          '*Item/Suplemen*: $itemName\n'
          '*Aturan Pakai*: $dosage\n'
          '*Instruksi Khusus*: $instructions\n\n'
          'Dokter Pemeriksa: $docName\n'
          'Resep digital ini telah tersimpan resmi pada EMR Zikola.';

      expect(prescriptionText.contains('RESEP & REKOMENDASI TERAPI DOKTER'), isTrue);
      expect(prescriptionText.contains(itemName), isTrue);
      expect(prescriptionText.contains(dosage), isTrue);
      expect(prescriptionText.contains(docName), isTrue);
      expect(prescriptionText.contains(instructions), isTrue);
    });
  });
}
