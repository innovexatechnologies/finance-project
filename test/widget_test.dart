import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/deep_link_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/theme/app_theme.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/core/widgets/student_avatar.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/reset_password_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/signup_screen.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_dashboard.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_main_nav.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_profile_screen.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/splash/presentation/screens/splash_screen.dart';
import 'package:link_vibe/feature/student/applications/presentation/screens/my_applications_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/home/presentation/screens/student_home_screen.dart';
import 'package:link_vibe/feature/student/my_projects/presentation/screens/my_projects_screen.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';
import 'package:link_vibe/feature/student/profile/presentation/screens/student_profile_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/change_password_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/contact_support_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/settings_screen.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';
import 'package:link_vibe/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DeepLinkService.instance.resetForTest();
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

    testWidgets('CompanyDashboardScreen renders cleanly ($tag)', (
      tester,
    ) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const CompanyDashboardScreen(),
        size: size,
      );
    });

    testWidgets('StudentHomeScreen renders cleanly on empty DB ($tag)', (
      tester,
    ) async {
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

    testWidgets('CertificatesScreen renders empty state cleanly ($tag)', (
      tester,
    ) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const CertificatesScreen(),
        size: size,
      );
    });

    testWidgets('SettingsScreen & Security screens render cleanly ($tag)', (
      tester,
    ) async {
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

    testWidgets(
      'ResetPasswordScreen renders in-app reset view cleanly ($tag)',
      (tester) async {
        await pumpAndVerifyScreen(
          tester,
          screen: const ResetPasswordScreen(
            initialEmail: 'student@university.edu',
          ),
          size: size,
        );
      },
    );
  }

  group('Portal Role & Direct Auth Flows', () {
    test(
      'SupabaseHelper error helpers classify auth states without credential limits',
      () {
        final msg = SupabaseHelper.friendlyError(
          Exception(
            "ClientException with SocketException: Failed host lookup: 'example.supabase.co' (OS Error: No address associated with hostname, errno = 7)",
          ),
        );
        expect(msg, contains('internet connection'));
        expect(SupabaseHelper.isInteractiveAuthInProgress, isFalse);

        SupabaseHelper.beginInteractiveAuth();
        expect(SupabaseHelper.isInteractiveAuthInProgress, isTrue);
        SupabaseHelper.endInteractiveAuth();
        expect(SupabaseHelper.isInteractiveAuthInProgress, isFalse);
        SupabaseHelper.clearAuthFlags();

        const weakPassErr = AuthApiException(
          'Password should be at least 6 characters',
          statusCode: '422',
          code: 'weak_password',
        );
        expect(SupabaseHelper.isWeakPasswordError(weakPassErr), isTrue);

        const rateLimitErr = AuthApiException(
          'email rate limit exceeded',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        );
        expect(SupabaseHelper.isEmailRateLimitError(rateLimitErr), isTrue);

        const unconfirmedErr = AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        );
        expect(SupabaseHelper.isEmailNotConfirmedError(unconfirmedErr), isTrue);

        const alreadyErr = AuthApiException(
          'User already registered',
          statusCode: '422',
          code: 'user_already_exists',
        );
        expect(SupabaseHelper.isAlreadyRegisteredError(alreadyErr), isTrue);
      },
    );

    testWidgets(
      'Signup logs directly into portal with zero verification and zero password length limit; Forgot Password resets in-app',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SignupScreen(initialRole: 'Student'),
          ),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'A');
        await tester.enterText(fields.at(1), 'a@b');
        await tester.enterText(fields.at(2), 'U');
        await tester.enterText(fields.at(3), '12'); // < 6 chars allowed!

        await tester.ensureVisible(find.text('Create Student Account'));
        await tester.tap(find.text('Create Student Account'));
        await tester.pumpAndSettle();

        // Direct login into StudentMainNav (zero email verification gate)
        expect(find.byType(StudentMainNav), findsOneWidget);
        expect(AppDataService.instance.isLoggedIn, isTrue);
        expect(
          AppDataService.instance.verifyLocalCredentials('a@b', '12'),
          isTrue,
        );
        expect(tester.takeException(), isNull);

        // Log out and test direct in-app Forgot Password -> ResetPasswordScreen
        await AppDataService.instance.clearAuthSession();
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('login_reset_flow'),
            theme: AppTheme.lightTheme,
            home: const LoginScreen(initialRole: 'Student'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), 'a@b');
        await tester.ensureVisible(find.text('Forgot Password?'));
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();

        expect(find.byType(ResetPasswordScreen), findsOneWidget);
        expect(find.text('Set a new password directly in the app'), findsOneWidget);
        expect(find.text('Resend Reset Email'), findsNothing);

        final resetFields = find.byType(TextFormField);
        await tester.enterText(resetFields.at(1), '9');
        await tester.enterText(resetFields.at(2), '9');
        await tester.ensureVisible(find.text('Reset Password').last);
        await tester.tap(find.text('Reset Password').last);
        await tester.pumpAndSettle();

        expect(find.text('Password Updated'), findsOneWidget);
        expect(
          AppDataService.instance.verifyLocalCredentials('a@b', '9'),
          isTrue,
        );

        await tester.tap(find.text('Continue to Sign In'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LoginScreen Portal Role only shows Student & Company and opens Admin via Governance Console',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Portal Role'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget);
        expect(find.text('Company'), findsOneWidget);
        expect(find.text('Admin'), findsNothing);
        expect(find.text('Governance Admin Console'), findsOneWidget);

        await tester.ensureVisible(find.text('Governance Admin Console'));
        await tester.tap(find.text('Governance Admin Console'));
        await tester.pumpAndSettle();
        expect(find.byType(AdminLoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen rejects cross-role login and routes Student vs Company exclusively',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await AppDataService.instance.registerUserAccount(
          email: 'student.only@university.edu',
          password: 'Password123',
          name: 'Student Tester',
          university: 'NUST',
          role: 'Student',
        );
        await AppDataService.instance.registerUserAccount(
          email: 'company.only@partner.io',
          password: 'Password123',
          name: 'Partner Co',
          university: 'Software',
          role: 'Company',
        );

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        // Try logging into Company portal with a Student account -> blocked
        await tester.tap(find.text('Company'));
        await tester.pump();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'student.only@university.edu',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
        await tester.ensureVisible(find.text('Sign In as Company'));
        await tester.tap(find.text('Sign In as Company'));
        await tester.pumpAndSettle();

        expect(find.byType(CompanyDashboardScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.textContaining('registered as a Student'), findsOneWidget);

        // Try logging into Student portal with a Company account -> blocked
        await tester.tap(find.text('Student'));
        await tester.pump();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'company.only@partner.io',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
        await tester.ensureVisible(find.text('Sign In as Student'));
        await tester.tap(find.text('Sign In as Student'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentMainNav), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.textContaining('registered as a Company'), findsOneWidget);

        // Valid Student login opens StudentMainNav
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'student.only@university.edu',
        );
        await tester.ensureVisible(find.text('Sign In as Student'));
        await tester.tap(find.text('Sign In as Student'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentMainNav), findsOneWidget);
      },
    );

    testWidgets(
      'StudentProfileScreen Add New Skill dialog adds skill without assertion/lifecycle errors',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetViewInsets();
        });

        await AppDataService.instance.addSkill('cc');
        await AppDataService.instance.addSkill('i');

        await tester.pumpWidget(
          const MaterialApp(home: StudentMainNav(initialIndex: 3)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Simulate soft keyboard opening while dialog is focused
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump(const Duration(milliseconds: 50));

        await tester.enterText(find.byType(TextField).last, 'yuu');
        await tester.pump();

        await tester.tap(find.text('Add'));
        // Simulate keyboard dismissing right as dialog closes
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('yuu'), findsOneWidget);
      },
    );

    testWidgets(
      'StudentProfileScreen Edit Academic Profile dialog saves without controller lifecycle errors',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetViewInsets();
        });

        await tester.pumpWidget(
          const MaterialApp(home: StudentMainNav(initialIndex: 3)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Edit Profile'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump(const Duration(milliseconds: 50));

        await tester.enterText(find.byType(TextField).first, 'Ayesha Noor');
        await tester.pump();

        await tester.ensureVisible(find.text('Save Changes'));
        await tester.tap(find.text('Save Changes'));
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Ayesha Noor'), findsOneWidget);
      },
    );

    testWidgets(
      'StudentProfileScreen Edit Academic Profile works cleanly at 320x568 with keyboard insets',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetViewInsets();
        });

        await tester.pumpWidget(
          const MaterialApp(home: StudentMainNav(initialIndex: 3)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Edit Profile'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pump(const Duration(milliseconds: 50));

        await tester.enterText(find.byType(TextField).first, 'Zara Khan');
        await tester.pump();

        await tester.ensureVisible(find.text('Save Changes'));
        await tester.tap(find.text('Save Changes'));
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Zara Khan'), findsOneWidget);
      },
    );

    testWidgets(
      'Notifications are completely removed from StudentMainNav and StudentHomeScreen',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: StudentMainNav()));
        await tester.pumpAndSettle();

        final nav = find.byType(BottomNavigationBar);
        expect(
          find.descendant(of: nav, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('Explore')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('My Projects')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('Profile')),
          findsOneWidget,
        );
        expect(find.text('Alerts'), findsNothing);
        expect(find.byTooltip('Messages'), findsNothing);
        expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
        expect(find.byIcon(Icons.notifications_outlined), findsNothing);
        expect(find.byIcon(Icons.notifications_rounded), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          const MaterialApp(
            key: ValueKey('change_password_no_email_reset'),
            home: ChangePasswordScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Reset via Email'), findsNothing);
        expect(find.text('Send Password Reset Email'), findsNothing);
        expect(find.text('Update Password Now'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MyProjectsScreen Refresh button refreshes projects with feedback',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: MyProjectsScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Refreshed local projects.'), findsOneWidget);
      },
    );

    testWidgets(
      'StudentProfileScreen displays StudentAvatar and opens photo options sheet',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final samplePng = Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
          73,
          72,
          68,
          82,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          1,
          8,
          6,
          0,
          0,
          0,
          31,
          21,
          196,
          137,
          0,
          0,
          0,
          10,
          73,
          68,
          65,
          84,
          120,
          156,
          99,
          0,
          1,
          0,
          0,
          5,
          0,
          1,
          13,
          10,
          45,
          180,
          0,
          0,
          0,
          0,
          73,
          69,
          78,
          68,
          174,
          66,
          96,
          130,
        ]);
        await AppDataService.instance.updateStudentAvatar(
          samplePng,
          fileExtension: 'png',
        );

        await tester.pumpWidget(
          const MaterialApp(home: StudentMainNav(initialIndex: 3)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StudentAvatar), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Change Profile Photo'));
        await tester.pumpAndSettle();

        expect(find.text('Profile Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
        expect(find.text('Remove Current Photo'), findsOneWidget);
        expect(find.text('Edit Academic Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'Student can log out via Settings and re-login with the same Gmail',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await AppDataService.instance.registerUserAccount(
          email: 'student.relogin@gmail.com',
          password: 'Password123',
          name: 'Student Relogin',
          university: 'FAST',
          role: 'Student',
        );

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'student.relogin@gmail.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
        await tester.ensureVisible(find.text('Sign In as Student'));
        await tester.tap(find.text('Sign In as Student'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentMainNav), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text('Profile'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Log Out'));
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out').last);
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Sign In as Student'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'student.relogin@gmail.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
        await tester.ensureVisible(find.text('Sign In as Student'));
        await tester.tap(find.text('Sign In as Student'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentMainNav), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Company can log out via CompanySettings and re-login with the same Gmail without wrong-role block',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await AppDataService.instance.registerUserAccount(
          email: 'company.relogin@gmail.com',
          password: 'Password123',
          name: 'Company Relogin',
          university: 'Cloud Tech',
          role: 'Company',
        );

        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen(initialRole: 'Company')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'company.relogin@gmail.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
        await tester.ensureVisible(find.text('Sign In as Company'));
        await tester.tap(find.text('Sign In as Company'));
        await tester.pumpAndSettle();
        expect(find.byType(CompanyDashboardScreen), findsOneWidget);

        await tester.tap(find.byTooltip('Open Workspace Menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Sign Out'));
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign Out').last);
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Sign In as Company'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'company.relogin@gmail.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
        await tester.ensureVisible(find.text('Sign In as Company'));
        await tester.tap(find.text('Sign In as Company'));
        await tester.pumpAndSettle();

        expect(find.byType(CompanyDashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('SplashScreen and LoginScreen show SkillBridge brand & logo',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SkillBridgeLogo), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'SkillBridge',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('CampusConnect'), findsNothing);
      await tester.pump(const Duration(seconds: 4));

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(SkillBridgeLogo), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'SkillBridge',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('SkillBridge'), findsAtLeastNWidgets(1));
      expect(find.textContaining('CampusConnect'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test(
      'ShareService generates in-app SkillBridge deep links for projects, applications, and certificates without external GoDaddy domains',
      () {
        final projectMsg = ShareService.buildProjectShareText({
          'id': 'proj-101',
          'title': 'Flutter Mobile App',
          'company': 'Acme Labs',
          'workMode': 'Remote',
          'duration': '4 Weeks',
          'websiteUrl': 'https://skillbridge.app/external',
        });
        expect(projectMsg, contains('Flutter Mobile App'));
        expect(projectMsg, contains('Acme Labs'));
        expect(projectMsg, contains('skillbridge://project/proj-101'));
        expect(projectMsg, isNot(contains('skillbridge.app')));

        final appMsg = ShareService.buildApplicationShareText({
          'id': 'app-77',
          'projectId': 'proj-101',
          'title': 'Flutter Mobile App',
          'company': 'Acme Labs',
          'status': 'Pending',
          'timelineStep': 1,
        });
        expect(appMsg, contains('Flutter Mobile App'));
        expect(appMsg, contains('Pending'));
        expect(
          appMsg,
          contains('skillbridge://application/app-77?projectId=proj-101'),
        );
        expect(appMsg, isNot(contains('skillbridge.app')));

        final certMsg = ShareService.buildCertificateShareText({
          'id': 'CERT-999',
          'title': 'Excellence Certificate',
          'project': 'Cloud API',
          'issuer': 'Acme Labs',
          'verificationUrl': 'https://skillbridge.app/cert/999',
        });
        expect(certMsg, contains('Excellence Certificate'));
        expect(certMsg, contains('skillbridge://certificate/CERT-999'));
        expect(certMsg, isNot(contains('skillbridge.app')));

        final fallbackCertLink = ShareService.buildCertificateShareLink({
          'id': 'SB-2026-1',
        });
        expect(
          fallbackCertLink,
          'skillbridge://certificate/SB-2026-1',
        );

        final parsedProj = DeepLinkService.parseUri(
          Uri.parse('skillbridge://project/proj-101'),
        );
        expect(parsedProj?.type, AppLinkType.project);
        expect(parsedProj?.id, 'proj-101');

        final parsedApp = DeepLinkService.parseUri(
          Uri.parse('skillbridge://application/app-77?projectId=proj-101'),
        );
        expect(parsedApp?.type, AppLinkType.application);
        expect(parsedApp?.id, 'app-77');
        expect(parsedApp?.projectId, 'proj-101');

        final parsedCert = DeepLinkService.parseUri(
          Uri.parse('skillbridge://certificate/CERT-999'),
        );
        expect(parsedCert?.type, AppLinkType.certificate);
        expect(parsedCert?.id, 'CERT-999');

        expect(
          DeepLinkService.parseUri(
            Uri.parse('io.supabase.campusconnect://login-callback?code=abc'),
          ),
          isNull,
        );
      },
    );

    test(
      'CompanyProfileService caches workspace snapshot cleanly',
      () async {
        await AppDataService.instance.saveAuthSession(
          role: 'Company',
          email: 'hr@fastcloud.io',
          name: 'FastCloud Labs',
          userId: 'comp-user-1',
        );

        CompanyProfileService().currentProfileNotifier.value =
            const CompanyProfileModel(
          id: 'comp-row-1',
          companyName: 'FastCloud Labs',
          industry: 'Cloud Services',
          description: 'Building fast platforms',
          officialEmail: 'hr@fastcloud.io',
          websiteUrl: 'https://fastcloud.io',
          contactPersonName: 'Sara',
          phoneNumber: '03001234567',
          city: 'Lahore',
          completeAddress: 'Gulberg',
          logoInitial: 'FL',
          isVerified: true,
          lastUpdated: 'Just now',
        );
        CompanyProjectService().projectsNotifier.value = [
          ProjectModel(
            id: 'p-1',
            title: 'AI Analytics Dashboard',
            category: 'Development',
            description: 'Metrics',
            requirements: 'Dart',
            skillsRequired: ['Flutter'],
            deliverables: 'App',
            deadline: 'Dec 2026',
            projectType: 'Remote',
            openings: 2,
            additionalInstructions: '',
            companyName: 'FastCloud Labs',
            companyId: 'comp-row-1',
            status: 'Open',
            duration: '4 weeks',
            budget: 'Paid',
          ),
        ];

        await CompanyProfileService.persistLocalCache();
        CompanyProfileService().reset();
        CompanyProjectService().reset();
        expect(CompanyProfileService().currentProfile.companyName, isEmpty);
        expect(CompanyProjectService().allProjects, isEmpty);

        CompanyProfileService.hydrateFromLocalCache();
        expect(
          CompanyProfileService().currentProfile.companyName,
          'FastCloud Labs',
        );
        expect(CompanyProjectService().allProjects.length, 1);
        expect(CompanyProfileService.hasLoadedWorkspace, isTrue);
      },
    );

    testWidgets(
      'CompanyPanel navbar, quick actions, and drawer work without freezing under AppTheme; StudentPanel uses crisp IndexedStack without rolling animation or navbar duplicates in drawer',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        CompanyProfileService().currentProfileNotifier.value =
            const CompanyProfileModel(
          id: 'comp-nav-1',
          companyName: 'FastCloud Labs',
          industry: 'Cloud Services',
          description: 'Cloud Systems',
          officialEmail: 'hr@fastcloud.io',
          websiteUrl: 'https://fastcloud.io',
          contactPersonName: 'Sara',
          phoneNumber: '03001234567',
          city: 'Lahore',
          completeAddress: 'Gulberg',
          logoInitial: 'FL',
          isVerified: true,
          lastUpdated: 'Just now',
        );
        CompanyProjectService().projectsNotifier.value = [
          ProjectModel(
            id: 'proj-nav-1',
            title: 'AI Analytics Platform',
            category: 'Web Development',
            description: 'Metrics platform',
            requirements: 'Flutter',
            skillsRequired: ['Flutter', 'REST API'],
            deliverables: 'Dashboard App',
            deadline: '2026-12-30',
            projectType: 'Remote',
            openings: 2,
            additionalInstructions: '',
            companyName: 'FastCloud Labs',
            companyId: 'comp-nav-1',
            status: 'Open',
            duration: '4 weeks',
            budget: 'Paid',
          ),
        ];
        CompanyApplicantService().applicantsNotifier.value = [
          ApplicantModel(
            id: 'app-nav-1',
            studentId: 'stu-nav-1',
            projectId: 'proj-nav-1',
            projectTitle: 'AI Analytics Platform',
            name: 'Zara Khan',
            email: 'zara@nust.edu.pk',
            university: 'NUST',
            degree: 'BSCS',
            cgpa: 3.8,
            skills: ['Flutter'],
            appliedDate: 'Today',
            proposalSummary: 'Experienced developer',
            status: 'Pending',
          ),
        ];
        CompanyAssignmentService().assignmentsNotifier.value = [
          const AssignmentModel(
            id: 'assign-nav-1',
            companyId: 'comp-nav-1',
            projectId: 'proj-nav-1',
            projectTitle: 'AI Analytics Platform',
            projectCategory: 'Web Development',
            projectStatus: 'In Progress',
            startDate: 'Today',
            deadline: '2026-12-30',
            studentId: 'stu-nav-1',
            applicantId: 'app-nav-1',
            studentName: 'Zara Khan',
            studentUniversity: 'NUST',
            studentDegree: 'BSCS',
            studentAvatarInitial: 'ZK',
            progress: 0.4,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CompanyMainNav(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CompanyDashboardScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('company_nav_stack')), findsOneWidget);
        expect(
          find.text('Synchronizing Corporate Workspace...'),
          findsNothing,
        );

        // Verify ALL 5 BottomNavigationBar tabs respond and switch IndexedStack index
        final companyNav = find.byType(BottomNavigationBar);
        await tester.tap(
          find.descendant(of: companyNav, matching: find.text('Projects')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('company_nav_stack')))
              .index,
          1,
        );
        expect(find.text('Company Projects'), findsOneWidget);

        await tester.tap(
          find.descendant(of: companyNav, matching: find.text('Post')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('company_nav_stack')))
              .index,
          2,
        );
        expect(find.text('Create Industry Project Challenge'), findsOneWidget);

        await tester.tap(
          find.descendant(of: companyNav, matching: find.text('Applicants')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('company_nav_stack')))
              .index,
          3,
        );
        expect(find.text('Student Applicants'), findsOneWidget);

        await tester.tap(
          find.descendant(of: companyNav, matching: find.text('Deliverables')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('company_nav_stack')))
              .index,
          4,
        );
        expect(find.text('Assigned Projects'), findsOneWidget);

        await tester.tap(
          find.descendant(of: companyNav, matching: find.text('Home')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('company_nav_stack')))
              .index,
          0,
        );
        expect(find.text('Workspace Overview'), findsOneWidget);

        // Verify Dashboard Quick Action buttons also work cleanly
        await tester.ensureVisible(find.text('Post Challenge'));
        await tester.tap(find.text('Post Challenge'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('company_nav_stack')))
              .index,
          2,
        );
        await tester.tap(
          find.descendant(of: companyNav, matching: find.text('Home')),
        );
        await tester.pumpAndSettle();

        // Verify Company Drawer opens & does not duplicate navbar 'Home' item
        await tester.tap(find.byTooltip('Open Workspace Menu'));
        await tester.pumpAndSettle();
        final companyDrawer = find.byType(Drawer);
        expect(companyDrawer, findsOneWidget);
        expect(
          find.descendant(of: companyDrawer, matching: find.text('Home')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: companyDrawer,
            matching: find.text('Company Profile'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: companyDrawer,
            matching: find.text('Company Profile'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CompanyProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Verify Student Panel: no cube transition & drawer removes navbar duplicates
        expect(
          AppTheme.lightTheme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<FadeUpwardsPageTransitionsBuilder>(),
        );
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('student_exec_nav'),
            theme: AppTheme.lightTheme,
            home: const StudentMainNav(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('student_nav_stack')), findsOneWidget);
        expect(find.byType(ExecutiveHeroBanner), findsOneWidget);
        expect(find.byType(ExecutiveStatCard), findsNWidgets(4));
        expect(find.byTooltip('Open Workspace Menu'), findsOneWidget);

        final studentNav = find.byType(BottomNavigationBar);
        for (final tab in ['Explore', 'My Projects', 'Profile', 'Home']) {
          await tester.tap(
            find.descendant(of: studentNav, matching: find.text(tab)),
          );
          await tester.pumpAndSettle();
        }
        expect(
          tester
              .widget<IndexedStack>(find.byKey(const ValueKey('student_nav_stack')))
              .index,
          0,
        );

        await tester.tap(find.byTooltip('Open Workspace Menu'));
        await tester.pumpAndSettle();
        final studentDrawer = find.byType(Drawer);
        expect(studentDrawer, findsOneWidget);
        for (final navDup in ['Home', 'Explore', 'My Projects', 'Profile']) {
          expect(
            find.descendant(of: studentDrawer, matching: find.text(navDup)),
            findsNothing,
          );
        }
        expect(
          find.descendant(
            of: studentDrawer,
            matching: find.text('My Applications'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: studentDrawer,
            matching: find.text('Saved Projects'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: studentDrawer,
            matching: find.text('Certificates'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: studentDrawer,
            matching: find.text('Settings & Help'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Share buttons are removed from StudentHomeScreen & StudentProfileScreen, present on Projects/Applications/Certificates, and deep links open directly in-app',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        SharedPreferences.setMockInitialValues({
          'cc_is_logged_in_v1': true,
          'cc_user_role_v1': 'Student',
          'cc_user_id_v1': 'stu-dl-1',
          'cc_user_name_v1': 'Hina Khan',
          'cc_custom_projects_v1':
              '[{"id":"proj-dl-1","title":"Deep Link Mobile App","company":"Acme Labs","category":"Development","duration":"4 Weeks","workMode":"Remote","status":"Open","stipend":"PKR 25,000"}]',
          'cc_applications_v1':
              '[{"id":"app-dl-1","projectId":"proj-dl-1","title":"Deep Link Mobile App","company":"Acme Labs","status":"Pending","appliedDate":"Today","timelineStep":1}]',
          'cc_certificates_v1':
              '[{"id":"CERT-DL-1","title":"Completion Certificate","project":"Deep Link Mobile App","issuer":"Acme Labs","date":"2026","status":"valid","verificationUrl":"https://skillbridge.edu.pk/verify/CERT-DL-1"}]',
        });
        await AppDataService.instance.init();

        // 1. StudentHomeScreen must NOT have Share button even with open projects
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dl_home'),
            theme: AppTheme.lightTheme,
            home: const StudentHomeScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Deep Link Mobile App'), findsOneWidget);
        expect(find.byTooltip('Share Project'), findsNothing);
        expect(find.byIcon(Icons.share_outlined), findsNothing);

        // 2. StudentProfileScreen must NOT have Share Profile button
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dl_profile'),
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Share Profile'), findsNothing);
        expect(find.byIcon(Icons.share_outlined), findsNothing);

        // 3. ExploreProjectsScreen has Share button
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dl_explore'),
            theme: AppTheme.lightTheme,
            home: const ExploreProjectsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Share Project'), findsOneWidget);

        // 4. MyApplicationsScreen has Share button
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dl_apps'),
            theme: AppTheme.lightTheme,
            home: const MyApplicationsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Share Application'), findsOneWidget);

        // 5. CertificatesScreen has Share button
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dl_certs'),
            theme: AppTheme.lightTheme,
            home: const CertificatesScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.share_outlined), findsOneWidget);

        // 6. Opening shared deep links navigates cleanly inside the app
        DeepLinkService.instance.attachNavigatorKey(MyApp.navigatorKey);
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dl_main_nav'),
            navigatorKey: MyApp.navigatorKey,
            theme: AppTheme.lightTheme,
            home: const StudentMainNav(),
          ),
        );
        await tester.pumpAndSettle();
        await DeepLinkService.instance.markWorkspaceReadyAndConsume();

        // Project link opens StudentProjectDetailsScreen in-app
        final projOpened = await DeepLinkService.instance.openUri(
          Uri.parse('skillbridge://project/proj-dl-1'),
        );
        expect(projOpened, isTrue);
        await tester.pumpAndSettle();
        final detailsFinder = find.byType(StudentProjectDetailsScreen);
        expect(detailsFinder, findsOneWidget);
        expect(
          find.descendant(
            of: detailsFinder,
            matching: find.text('Deep Link Mobile App'),
          ),
          findsOneWidget,
        );
        Navigator.of(MyApp.navigatorKey.currentContext!).pop();
        await tester.pumpAndSettle();

        // Application link opens Application Detail Sheet in-app
        final appOpened = await DeepLinkService.instance.openUri(
          Uri.parse('skillbridge://application/app-dl-1?projectId=proj-dl-1'),
        );
        expect(appOpened, isTrue);
        await tester.pumpAndSettle();
        expect(find.text('View Project'), findsOneWidget);
        Navigator.of(MyApp.navigatorKey.currentContext!).pop();
        await tester.pumpAndSettle();

        // Certificate link opens Verified Certificate Dialog in-app
        final certOpened = await DeepLinkService.instance.openUri(
          Uri.parse('skillbridge://certificate/CERT-DL-1'),
        );
        expect(certOpened, isTrue);
        await tester.pumpAndSettle();
        expect(find.text('Completion Certificate'), findsOneWidget);
        expect(find.textContaining('CERT-DL-1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
