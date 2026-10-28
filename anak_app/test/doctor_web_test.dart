import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zikola/models/patient.dart';
import 'package:zikola/screens/doctor_web_screen.dart';
import 'package:zikola/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doctor Web Stage 1 - Unit Tests', () {
    test('Patient.fromJson parses correctly', () {
      final json = {
        'id': 'patient-test',
        'name': 'Budi Santoso',
        'avatar': '👦',
        'age': 6,
        'gender': 'Laki-laki',
        'parentName': 'Ibu Dewi',
        'lastVisit': '10 Sep 2026',
        'status': 'active',
        'latestAssessment': {
          'cognitive': 85,
          'linguistic': 80,
          'motor': 90,
          'completedTests': 5,
        },
      };

      final patient = Patient.fromJson(json);

      expect(patient.id, 'patient-test');
      expect(patient.name, 'Budi Santoso');
      expect(patient.age, 6);
      expect(patient.gender, 'Laki-laki');
      expect(patient.parentName, 'Ibu Dewi');
      expect(patient.status, 'active');
      expect(patient.latestAssessment?['completedTests'], 5);

      final backToJson = patient.toJson();
      expect(backToJson['name'], 'Budi Santoso');
    });

    test('AppState.getDoctorPatients returns list of patients', () async {
      final appState = AppState();
      final patients = await appState.getDoctorPatients();

      expect(patients, isNotEmpty);
      expect(patients.length, greaterThanOrEqualTo(3));
      expect(patients.first.name, isNotEmpty);
      expect(patients.any((p) => p.status == 'active'), isTrue);
    });

    test('AppState doctor mode toggle works', () {
      final appState = AppState();
      expect(appState.isDoctor, isFalse);

      appState.setDoctorMode(true);
      expect(appState.isDoctor, isTrue);

      appState.setDoctorMode(false);
      expect(appState.isDoctor, isFalse);
    });
  });

  group('Doctor Web Stage 1 - Widget Tests', () {
    testWidgets('DoctorWebScreen renders portal header and loads patient data', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: DoctorWebScreen(),
          ),
        ),
      );

      // Verify portal header
      expect(find.text('Portal Dokter Zikola'), findsOneWidget);

      // Pump to finish FutureBuilder loading
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verify stats and patient cards appear
      expect(find.text('Total Pasien'), findsOneWidget);
      expect(find.text('Aisya Putri'), findsOneWidget);
      expect(find.text('Bima Arya'), findsOneWidget);
    });
  });
}
