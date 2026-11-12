import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';

void main() {
  testWidgets(
    'admin drawer navigation returns to overview and leaves it as the root',
    (tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            body: Builder(
              builder: (context) => Column(
                children: [
                  const Text('Platform Overview'),
                  ElevatedButton(
                    onPressed: () => AdminSidebar.navigateToRoute(
                      context,
                      scaffoldKey: scaffoldKey,
                      currentRouteId: 'dashboard',
                      targetRouteId: 'student_verifications',
                    ),
                    child: const Text('Open Students'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Students'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentManagementScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Platform Overview'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.text('Platform Overview'))).canPop(),
        isFalse,
      );
    },
  );
}
