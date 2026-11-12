import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_project_detail_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_projects_list_screen.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

void main() {
  ProjectModel makeProject({
    String id = 'project-id',
    String title = 'Test project',
    String? assignedStudent,
    bool paymentSent = false,
  }) {
    return ProjectModel(
      id: id,
      title: title,
      category: 'Development',
      description: '',
      deadline: 'Flexible',
      companyName: 'Test company',
      status: 'In Progress',
      assignedStudent: assignedStudent,
      paymentSent: paymentSent,
    );
  }

  test('payment status defaults to pending for existing project data', () {
    final project = ProjectModel.fromJson({
      'id': 'project-id',
      'title': 'Test project',
      'deadline': 'Flexible',
      'company_name': 'Test company',
      'status': 'Open',
    });

    expect(project.paymentSent, isFalse);
    expect(project.toJson()['payment_sent'], isFalse);
  });

  test('payment status survives serialization and project updates', () {
    final paid = makeProject(
      assignedStudent: 'Selected student',
      paymentSent: true,
    );
    final restored = ProjectModel.fromJson(paid.toJson());
    final updated = restored.copyWith(status: 'Completed');

    expect(restored.paymentSent, isTrue);
    expect(updated.paymentSent, isTrue);
  });

  testWidgets('payment controls fit on a narrow project details screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = makeProject(assignedStudent: 'Selected student');
    final projectService = CompanyProjectService();
    projectService.projectsNotifier.value = [project];
    addTearDown(() => projectService.projectsNotifier.value = []);

    await tester.pumpWidget(
      MaterialApp(home: CompanyProjectDetailScreen(project: project)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Payment Sent'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Payment Pending'), findsOneWidget);
    expect(find.text('Payment Sent'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Payment Sent'),
          )
          .onPressed,
      isNotNull,
    );

    projectService.projectsNotifier.value = [
      project.copyWith(paymentSent: true),
    ];
    await tester.pumpAndSettle();
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Payment Pending'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Payment Sent'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Payment Sent stays disabled until a student is assigned', (
    tester,
  ) async {
    final project = makeProject();
    final projectService = CompanyProjectService();
    projectService.projectsNotifier.value = [project];
    addTearDown(() => projectService.projectsNotifier.value = []);

    await tester.pumpWidget(
      MaterialApp(home: CompanyProjectDetailScreen(project: project)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Payment Sent'), 200);

    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Payment Sent'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'My Projects shows pending status without narrow-screen overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final projectService = CompanyProjectService();
      final project = makeProject(assignedStudent: 'Selected student');
      projectService.projectsNotifier.value = [project];
      addTearDown(() => projectService.projectsNotifier.value = []);

      await tester.pumpWidget(
        const MaterialApp(home: CompanyProjectsListScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Payment Pending').last,
        200,
        scrollable: find.descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Pending'), findsNWidgets(2));
      projectService.projectsNotifier.value = [
        project.copyWith(paymentSent: true),
      ];
      await tester.pumpAndSettle();
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Payment Pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('company payment filters update when project is paid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final projectService = CompanyProjectService();
    final pending = makeProject(
      id: 'pending-id',
      title: 'Pending project',
      assignedStudent: 'Selected student',
    );
    final unassigned = makeProject(
      id: 'unassigned-id',
      title: 'Unassigned project',
    );
    final paid = makeProject(
      id: 'paid-id',
      title: 'Paid project',
      assignedStudent: 'Another student',
      paymentSent: true,
    );
    projectService.projectsNotifier.value = [pending, unassigned, paid];
    addTearDown(() => projectService.projectsNotifier.value = []);

    await tester.pumpWidget(
      const MaterialApp(home: CompanyProjectsListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending project'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Unassigned project'),
      200,
      scrollable: find.descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unassigned project'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);
    expect(find.text('Paid project'), findsNothing);

    projectService.projectsNotifier.value = [
      pending.copyWith(paymentSent: true),
      unassigned,
      paid,
    ];
    await tester.pumpAndSettle();
    expect(find.text('Pending project'), findsNothing);

    await tester.tap(find.byKey(const Key('company-payment-filter-paid')));
    await tester.pumpAndSettle();
    expect(find.text('Pending project'), findsOneWidget);
    expect(find.text('Paid project'), findsOneWidget);
    expect(find.text('Unassigned project'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
