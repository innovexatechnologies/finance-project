import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/theme/app_theme.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/core/widgets/student_avatar.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/email_verification_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/reset_password_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/signup_screen.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_dashboard.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_main_nav.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/splash/presentation/screens/splash_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/home/presentation/screens/student_home_screen.dart';
import 'package:link_vibe/feature/student/my_projects/presentation/screens/my_projects_screen.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';
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

    testWidgets('ChatListScreen renders empty state cleanly ($tag)', (
      tester,
    ) async {
      await pumpAndVerifyScreen(
        tester,
        screen: const ChatListScreen(),
        size: size,
      );
    });

    testWidgets(
      'ResetPasswordScreen & EmailVerificationScreen render cleanly ($tag)',
      (tester) async {
        await pumpAndVerifyScreen(
          tester,
          screen: const ResetPasswordScreen(
            initialEmail: 'student@university.edu',
            hasRecoverySession: true,
          ),
          size: size,
        );
        await pumpAndVerifyScreen(
          tester,
          screen: const ResetPasswordScreen(
            initialEmail: 'student@university.edu',
            hasRecoverySession: false,
          ),
          size: size,
        );
        await pumpAndVerifyScreen(
          tester,
          screen: const EmailVerificationScreen(
            email: 'student@university.edu',
            role: 'Student',
            isVerified: true,
          ),
          size: size,
        );
        await pumpAndVerifyScreen(
          tester,
          screen: const EmailVerificationScreen(
            email: 'company@partner.io',
            role: 'Company',
            isVerified: false,
          ),
          size: size,
        );
      },
    );
  }

  group('Portal Role & Strict Auth Routing', () {
    test(
      'SupabaseHelper.friendlyError translates DNS & SocketException errors',
      () {
        final msg = SupabaseHelper.friendlyError(
          Exception(
            "ClientException with SocketException: Failed host lookup: 'example.supabase.co' (OS Error: No address associated with hostname, errno = 7)",
          ),
        );
        expect(msg, contains('internet connection'));
        expect(
          SupabaseHelper.authRedirectUri,
          'io.supabase.campusconnect://login-callback/',
        );
        expect(SupabaseHelper.isInteractiveAuthInProgress, isFalse);

        SupabaseHelper.beginInteractiveAuth();
        expect(SupabaseHelper.shouldIgnoreSignedInEvent, isTrue);
        SupabaseHelper.endInteractiveAuth();
        expect(SupabaseHelper.isInteractiveAuthInProgress, isFalse);
        expect(SupabaseHelper.shouldIgnoreSignedInEvent, isTrue);
        SupabaseHelper.clearAuthFlags();
        expect(SupabaseHelper.shouldIgnoreSignedInEvent, isFalse);

        const rateLimitErr = AuthApiException(
          'email rate limit exceeded',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        );
        expect(SupabaseHelper.isEmailRateLimitError(rateLimitErr), isTrue);
        expect(
          SupabaseHelper.friendlyError(rateLimitErr),
          contains('2 emails per hour'),
        );
        const cooldownErr = AuthApiException(
          'For security purposes, you can only request this after 45 seconds.',
          statusCode: '429',
          code: 'over_request_rate_limit',
        );
        expect(SupabaseHelper.isEmailRateLimitError(cooldownErr), isFalse);
        expect(
          SupabaseHelper.friendlyError(cooldownErr),
          contains('wait 60 seconds'),
        );

        final cooldown = ResendCooldown();
        int ticks = 0;
        cooldown.start(() => ticks++, seconds: 5);
        expect(cooldown.isActive, isTrue);
        expect(cooldown.remainingSeconds, 5);
        expect(ticks, 1);
        cooldown.dispose();
        expect(cooldown.isActive, isFalse);
        expect(cooldown.remainingSeconds, 0);

        const unconfirmedErr = AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        );
        expect(SupabaseHelper.isEmailNotConfirmedError(unconfirmedErr), isTrue);
        expect(
          SupabaseHelper.extractRateLimitCooldownSeconds(cooldownErr),
          45,
        );
        const alreadyErr = AuthApiException(
          'User already registered',
          statusCode: '422',
          code: 'user_already_exists',
        );
        expect(SupabaseHelper.isAlreadyRegisteredError(alreadyErr), isTrue);
      },
    );

    test(
      'AppDataService persists and clears pending email verification context cleanly',
      () async {
        await AppDataService.instance.savePendingAuthContext(
          flow: 'signup',
          email: 'hr@acme.io',
          role: 'Company',
        );
        expect(SupabaseHelper.pendingAuthFlow, 'signup');
        expect(SupabaseHelper.pendingAuthEmail, 'hr@acme.io');
        expect(SupabaseHelper.pendingAuthRole, 'Company');

        SupabaseHelper.clearAuthFlags();
        await AppDataService.instance.init();
        expect(SupabaseHelper.pendingAuthFlow, 'signup');
        expect(SupabaseHelper.pendingAuthEmail, 'hr@acme.io');
        expect(SupabaseHelper.pendingAuthRole, 'Company');

        await AppDataService.instance.clearPendingAuthContext();
        expect(SupabaseHelper.pendingAuthFlow, isNull);
        expect(SupabaseHelper.pendingAuthEmail, isNull);
        expect(SupabaseHelper.pendingAuthRole, isNull);
      },
    );

    testWidgets(
      'Company EmailVerificationScreen renders verified & unverified states cleanly under AppTheme transitions',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('company_verify_unverified'),
            theme: AppTheme.lightTheme,
            home: const EmailVerificationScreen(
              email: 'founder@acme.io',
              role: 'Company',
              isVerified: false,
              initialInfo: 'Verification email resent to founder@acme.io.',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.text('Verify & Activate Account'), findsOneWidget);
        expect(find.text('Resend Email'), findsOneWidget);
        expect(
          find.text('Verification email resent to founder@acme.io.'),
          findsOneWidget,
        );

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('company_verify_unverified'),
            theme: AppTheme.lightTheme,
            home: const EmailVerificationScreen(
              email: 'founder@acme.io',
              role: 'Company',
              isVerified: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Email Verified Successfully'), findsOneWidget);
        expect(find.text('Continue to Company Portal'), findsOneWidget);
        await tester.tap(find.text('Continue to Company Portal'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Sign In as Company'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('company_signup_screen'),
            theme: AppTheme.lightTheme,
            home: const SignupScreen(initialRole: 'Company'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Create Company Account'), findsOneWidget);
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
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
        expect(find.byIcon(Icons.notifications_outlined), findsNothing);
        expect(find.byIcon(Icons.notifications_rounded), findsNothing);
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
      'ShareService includes clickable links alongside details for projects, certificates, and student profiles',
      () {
        final projectMsg = ShareService.buildProjectShareText({
          'id': 'proj-101',
          'title': 'Flutter Mobile App',
          'company': 'Acme Labs',
          'workMode': 'Remote',
          'duration': '4 Weeks',
        });
        expect(projectMsg, contains('Flutter Mobile App'));
        expect(projectMsg, contains('Acme Labs'));
        expect(
          projectMsg,
          contains('https://skillbridge.app/projects/proj-101'),
        );

        final certMsg = ShareService.buildCertificateShareText({
          'id': 'CERT-999',
          'title': 'Excellence Certificate',
          'project': 'Cloud API',
          'issuer': 'Acme Labs',
          'verificationUrl': 'https://verify.acme.io/cert/999',
        });
        expect(certMsg, contains('Excellence Certificate'));
        expect(certMsg, contains('https://verify.acme.io/cert/999'));

        final fallbackCertLink = ShareService.buildCertificateShareLink({
          'id': 'SB-2026-1',
        });
        expect(
          fallbackCertLink,
          'https://skillbridge.app/verify/certificate/SB-2026-1',
        );

        final profileMsg = ShareService.buildStudentProfileShareText({
          'userId': 'stu-42',
          'name': 'Ali Raza',
          'university': 'NUST',
          'portfolioUrl': 'github.com/aliraza',
        }, skills: ['Flutter', 'Dart']);
        expect(profileMsg, contains('Ali Raza'));
        expect(profileMsg, contains('https://github.com/aliraza'));
        expect(profileMsg, contains('https://skillbridge.app/students/stu-42'));
      },
    );

    test(
      'CompanyProfileService caches workspace snapshot cleanly and markConversationRead persists read IDs',
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

        // Verify unread message markConversationRead zeroes unread & persists read IDs across init
        SharedPreferences.setMockInitialValues({
          'cc_is_logged_in_v1': true,
          'cc_user_id_v1': 'comp-user-1',
          'cc_chat_conversations_v1':
              '[{"id":"conv_1","peerUserId":"stu-1","company":"Ali Student","supervisor":"Ali Student","projectTitle":"AI Analytics","lastMessage":"Hello!","time":"1m ago","unread":2,"messages":[{"id":"m1","isMe":false,"sender":"Ali Student","text":"Hi","time":"2m ago"},{"id":"m2","isMe":false,"sender":"Ali Student","text":"Hello!","time":"1m ago"}]}]',
        });
        await AppDataService.instance.init();
        expect(
          AppDataService.instance.getConversation('conv_1')?['unread'],
          2,
        );
        await AppDataService.instance.markConversationRead('conv_1');
        expect(
          AppDataService.instance.getConversation('conv_1')?['unread'],
          0,
        );

        await AppDataService.instance.init();
        expect(
          AppDataService.instance.getConversation('conv_1')?['unread'],
          0,
        );
      },
    );

    testWidgets(
      'CompanyDashboardScreen renders immediately without blocking sync spinner across tab navigation, and Student executive UI renders cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: CompanyMainNav()));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CompanyDashboardScreen), findsOneWidget);
        expect(
          find.text('Synchronizing Corporate Workspace...'),
          findsNothing,
        );

        await tester.tap(find.text('Projects'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();

        expect(
          find.text('Synchronizing Corporate Workspace...'),
          findsNothing,
        );
        expect(find.text('Workspace Overview'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          const MaterialApp(
            key: ValueKey('student_exec_nav'),
            home: StudentMainNav(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ExecutiveHeroBanner), findsOneWidget);
        expect(find.byType(ExecutiveStatCard), findsNWidgets(4));
        expect(find.text('Workspace Overview'), findsOneWidget);
        expect(find.byTooltip('Messages'), findsOneWidget);
        expect(find.byTooltip('Open Workspace Menu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
