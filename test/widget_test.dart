import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_dashboard.dart';
import 'package:link_vibe/feature/splash/presentation/screens/splash_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/home/presentation/screens/student_home_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/change_password_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/contact_support_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/settings_screen.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';
import 'package:link_vibe/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDataService.instance.init();
  });

  testWidgets('App launches with SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    // Drain SplashScreen navigation timer safely
    await tester.pump(const Duration(seconds: 4));
  });

  Future<void> pumpAndVerifyScreen(
    WidgetTester tester, {
    required Widget screen,
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  }

  final viewports = [
    const Size(320, 568), // Narrow mobile
    const Size(1280, 800), // Desktop / web
  ];

  for (final size in viewports) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('AdminDashboardScreen renders cleanly ($tag)', (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const AdminDashboardScreen(),
        size: size,
      );
    });

    testWidgets('CompanyDashboardScreen renders cleanly ($tag)',
        (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const CompanyDashboardScreen(),
        size: size,
      );
    });

    testWidgets('StudentHomeScreen renders cleanly on empty DB ($tag)',
        (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const StudentHomeScreen(),
        size: size,
      );
    });

    testWidgets('SubmitWorkScreen renders cleanly ($tag)', (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const SubmitWorkScreen(
          project: {
            'projectId': 'proj_test_1',
            'title': 'Cloud API Integration',
            'company': 'Partner Labs',
            'deadline': 'Dec 20, 2026',
            'status': 'In Progress',
          },
        ),
        size: size,
      );
    });

    testWidgets('FeedbackScreen renders cleanly ($tag)', (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const FeedbackScreen(
          project: {
            'projectId': 'proj_test_2',
            'title': 'UI Architecture Audit',
            'company': 'Studio Alpha',
            'companyFeedback': 'Please include responsive tablet breakpoints.',
            'deadline': 'Dec 22, 2026',
            'status': 'Revision Requested',
          },
        ),
        size: size,
      );
    });

    testWidgets('CertificatesScreen renders empty state cleanly ($tag)',
        (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const CertificatesScreen(),
        size: size,
      );
    });

    testWidgets('SettingsScreen & Security screens render cleanly ($tag)',
        (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const SettingsScreen(),
        size: size,
      );
      await pumpAndVerifyScreen(
        tester,
        screen: const ChangePasswordScreen(),
        size: size,
      );
      await pumpAndVerifyScreen(
        tester,
        screen: const ContactSupportScreen(),
        size: size,
      );
    });

    testWidgets('ChatListScreen renders empty state cleanly ($tag)',
        (tester) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const ChatListScreen(),
        size: size,
      );
    });
  }
}
