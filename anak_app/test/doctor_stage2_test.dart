import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zikola/models/doctor_schedule.dart';
import 'package:zikola/models/clinical_note.dart';
import 'package:zikola/screens/doctor_web_screen.dart';
import 'package:zikola/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doctor Web Stage 2 - Model Tests', () {
    test('DoctorSchedule fromJson, toJson and helpers work correctly', () {
      final now = DateTime.now();
      final schedule = DoctorSchedule(
        id: 'test-sched-1',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        patientAvatar: '👧',
        dateTime: now,
        sessionType: 'video',
        topic: 'Evaluasi Wicara',
        status: 'upcoming',
        notes: 'Bawa mainan favorit anak',
      );

      expect(schedule.isUpcoming, isTrue);
      expect(schedule.isCompleted, isFalse);

      final json = schedule.toJson();
      expect(json['id'], 'test-sched-1');
      expect(json['sessionType'], 'video');
      expect(json['notes'], 'Bawa mainan favorit anak');

      final fromJson = DoctorSchedule.fromJson(json);
      expect(fromJson.patientName, 'Aisya Putri');
      expect(fromJson.topic, 'Evaluasi Wicara');

      final updated = schedule.copyWith(status: 'completed');
      expect(updated.isCompleted, isTrue);
      expect(updated.isUpcoming, isFalse);
    });

    test('ClinicalNote fromJson and toJson work correctly', () {
      final note = ClinicalNote(
        id: 'test-note-1',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        doctorName: 'Dr. Sarah Amelia, Sp.A',
        category: 'Sensori & Motorik',
        observation: 'Koordinasi genggaman pensil sangat baik.',
        recommendation: 'Latih tracing garis zigzag 10 menit/hari.',
        isActionPlan: true,
      );

      expect(note.isActionPlan, isTrue);
      expect(note.category, 'Sensori & Motorik');

      final json = note.toJson();
      expect(json['isActionPlan'], isTrue);

      final fromJson = ClinicalNote.fromJson(json);
      expect(fromJson.observation, 'Koordinasi genggaman pensil sangat baik.');
      expect(fromJson.doctorName, 'Dr. Sarah Amelia, Sp.A');
    });
  });

  group('Doctor Web Stage 2 - AppState Scheduling & Clinical Notes Tests', () {
    test('AppState schedules operations work properly', () async {
      final appState = AppState();

      final schedules = await appState.getDoctorSchedules();
      expect(schedules, isNotEmpty);
      expect(schedules.length, greaterThanOrEqualTo(2));

      final initialCount = schedules.length;
      final newSchedule = DoctorSchedule(
        id: 'new-test-sched',
        patientId: 'patient-002',
        patientName: 'Bima Arya',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        topic: 'Tes Sensori Baru',
      );

      await appState.addDoctorSchedule(newSchedule);
      final afterAdd = await appState.getDoctorSchedules();
      expect(afterAdd.length, initialCount + 1);
      expect(afterAdd.first.id, 'new-test-sched');

      await appState.updateScheduleStatus('new-test-sched', 'completed');
      final afterUpdate = await appState.getDoctorSchedules();
      expect(afterUpdate.first.status, 'completed');
    });

    test('AppState clinical notes operations work properly', () async {
      final appState = AppState();

      final notes = await appState.getPatientClinicalNotes('patient-001');
      expect(notes, isNotEmpty);

      final newNote = ClinicalNote(
        id: 'new-note-test',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        category: 'Wicara & Bahasa',
        observation: 'Penguasaan 50 kosakata baru.',
        recommendation: 'Bacakan dongeng interaktif setiap malam.',
      );

      await appState.addClinicalNote(newNote);
      final updatedNotes = await appState.getPatientClinicalNotes('patient-001');
      expect(updatedNotes.any((n) => n.id == 'new-note-test'), isTrue);
    });
  });

  group('Doctor Web Stage 2 - Widget & Tab Navigation Tests', () {
    testWidgets('DoctorWebScreen renders tabs and can switch between Pasien and Jadwal', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: DoctorWebScreen(),
          ),
        ),
      );

      // Verify top tab switcher exists
      expect(find.text('Daftar Pasien'), findsOneWidget);
      expect(find.text('Jadwal Konsultasi'), findsOneWidget);

      // Tap on Jadwal Konsultasi tab
      await tester.tap(find.text('Jadwal Konsultasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify schedules tab filter chips appear
      expect(find.text('Jadwal Baru'), findsOneWidget); // Floating action button
    });
  });
}
