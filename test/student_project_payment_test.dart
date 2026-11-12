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
  String status = 'In Progress',
  bool paymentSent = false,
  String? confirmationStatus,
}) {
  return {
    'id': _applicationId,
    'applicationId': _applicationId,
    'projectId': _projectId,
    'title': 'Assigned project',
    'company': 'Partner company',
    'status': status,
    'deadline': 'Flexible',
    'isAssignedProject': true,
    'paymentStatusAvailable': true,
    'paymentSent': paymentSent,
    'paymentConfirmationStatus': confirmationStatus,
  };
}

Future<void> _loadApplication(Map<String, dynamic> application) async {
  SharedPreferences.setMockInitialValues({
    'cc_is_logged_in_v1': true,
    'cc_user_role_v1': 'Student',
    'cc_user_id_v1': '00000000-0000-4000-8000-000000000003',
    'cc_applications_v1': jsonEncode([application]),
  });
  await AppDataService.instance.init();
}

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

    expect(find.text('Payment Pending'), findsOneWidget);
    expect(find.text('Yes, Payment Received'), findsNothing);
    expect(find.text('No, Payment Not Received'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
