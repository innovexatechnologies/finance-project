import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/student/my_projects/presentation/screens/my_projects_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _projectId = '00000000-0000-4000-8000-000000000001';
const _applicationId = '00000000-0000-4000-8000-000000000002';

Map<String, dynamic> _application({
  String projectId = _projectId,
  String applicationId = _applicationId,
  String title = 'Assigned project',
  String status = 'In Progress',
  bool isAssignedProject = true,
  bool paymentSent = false,
  String? confirmationStatus,
}) {
  return {
    'id': applicationId,
    'applicationId': applicationId,
    'projectId': projectId,
    'title': title,
    'company': 'Partner company',
    'status': status,
    'deadline': 'Flexible',
    'isAssignedProject': isAssignedProject,
    'paymentStatusAvailable': true,
    'paymentSent': paymentSent,
    'paymentConfirmationStatus': confirmationStatus,
  };
}

Future<void> _loadApplications(List<Map<String, dynamic>> applications) async {
  SharedPreferences.setMockInitialValues({
    'cc_is_logged_in_v1': true,
    'cc_user_role_v1': 'Student',
    'cc_user_id_v1': '00000000-0000-4000-8000-000000000003',
    'cc_applications_v1': jsonEncode(applications),
  });
  await AppDataService.instance.init();
}

Future<void> _loadApplication(Map<String, dynamic> application) =>
    _loadApplications([application]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('My Projects shows assigned payment status without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadApplication(_application(status: 'Pending'));

    await tester.pumpWidget(const MaterialApp(home: MyProjectsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Awaiting Confirmation'), findsNWidgets(2));
    expect(find.text('Yes, Payment Received'), findsNothing);
    expect(find.text('No, Payment Not Received'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'payment tabs classify each project and keep unassigned visible',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _loadApplications([
        _application(
          projectId: '00000000-0000-4000-8000-000000000004',
          applicationId: '00000000-0000-4000-8000-000000000005',
          title: 'Awaiting project',
          paymentSent: true,
        ),
        _application(
          projectId: '00000000-0000-4000-8000-000000000006',
          applicationId: '00000000-0000-4000-8000-000000000007',
          title: 'Received project',
          paymentSent: true,
          confirmationStatus: 'Received',
        ),
        _application(
          projectId: '00000000-0000-4000-8000-000000000008',
          applicationId: '00000000-0000-4000-8000-000000000009',
          title: 'Not received project',
          paymentSent: true,
          confirmationStatus: 'Not Received',
        ),
        _application(
          projectId: '00000000-0000-4000-8000-000000000010',
          applicationId: '00000000-0000-4000-8000-000000000011',
          title: 'Unassigned project',
          isAssignedProject: false,
        ),
      ]);

      await tester.pumpWidget(const MaterialApp(home: MyProjectsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Awaiting project'), findsOneWidget);
      expect(find.text('Unassigned project'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('Received project'), findsNothing);
      expect(find.text('Not received project'), findsNothing);

      await tester.ensureVisible(find.text('Received').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Received').first);
      await tester.pumpAndSettle();
      expect(find.text('Received project'), findsOneWidget);
      expect(find.text('Awaiting project'), findsNothing);

      await tester.ensureVisible(find.text('Not Received').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not Received').first);
      await tester.pumpAndSettle();
      expect(find.text('Not received project'), findsOneWidget);
      expect(find.text('Received project'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirmation choices appear only after payment is sent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final application = _application(paymentSent: true);
    await _loadApplication(application);

    await tester.pumpWidget(
      MaterialApp(home: StudentProjectDetailsScreen(project: application)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Yes, Payment Received'), 200);

    expect(find.text('Payment Sent'), findsOneWidget);
    expect(find.text('Yes, Payment Received'), findsOneWidget);
    expect(find.text('No, Payment Not Received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unassigned projects do not show payment confirmation controls', (
    tester,
  ) async {
    final application = _application(isAssignedProject: false);
    await _loadApplication(application);

    await tester.pumpWidget(
      MaterialApp(home: StudentProjectDetailsScreen(project: application)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment Confirmation'), findsNothing);
    expect(find.text('Yes, Payment Received'), findsNothing);
    expect(find.text('No, Payment Not Received'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final response in ['Received', 'Not Received']) {
    testWidgets('$response confirmation is shown without repeat choices', (
      tester,
    ) async {
      final application = _application(
        paymentSent: true,
        confirmationStatus: response,
      );
      await _loadApplication(application);

      await tester.pumpWidget(
        MaterialApp(home: StudentProjectDetailsScreen(project: application)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(response), 200);

      expect(find.text(response), findsOneWidget);
      expect(find.text('Yes, Payment Received'), findsNothing);
      expect(find.text('No, Payment Not Received'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
