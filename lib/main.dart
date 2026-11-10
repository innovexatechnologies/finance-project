import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/app_data_service.dart';
import 'core/services/supabase_helper.dart';
import 'core/theme/app_theme.dart';
import 'feature/auth/presentation/screens/email_verification_screen.dart';
import 'feature/auth/presentation/screens/reset_password_screen.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely load .env and initialize Supabase if credentials are configured
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Notice: .env asset load fallback ($e).');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseKey = (dotenv.env['SUPABASE_ANON_KEY'] ??
          dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
          '')
      .trim();

  if (supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty &&
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('your-project-id')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Notice: Supabase initialization error: $e');
    }
  } else {
    debugPrint(
      'Notice: Supabase credentials not configured in .env. Running with local storage fallback.',
    );
  }

  await AppDataService.instance.init();
  final bootSupabase = SupabaseHelper.clientOrNull;
  StreamSubscription<AuthState>? bootSub;
  if (bootSupabase != null) {
    bootSub = bootSupabase.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          SupabaseHelper.pendingPasswordRecovery = true;
        } else if (data.event == AuthChangeEvent.signedIn &&
            !AppDataService.instance.isLoggedIn) {
          SupabaseHelper.pendingEmailVerification = true;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        SupabaseHelper.pendingAuthCallbackError =
            SupabaseHelper.friendlyError(error);
      },
    );
  }

  await bootSub?.cancel();
  runApp(const MyApp());
}

SupabaseClient? get supabaseOrNull => SupabaseHelper.clientOrNull;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSub;
  bool _handlingAuthCallback = false;

  @override
  void initState() {
    super.initState();
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      _authSub = supabase.auth.onAuthStateChange.listen(
        _onAuthStateChanged,
        onError: _onAuthError,
      );
    }

    if (SupabaseHelper.pendingPasswordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openResetPasswordScreen(hasRecoverySession: true);
      });
    } else if (SupabaseHelper.pendingEmailVerification &&
        SupabaseHelper.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeDeepLinkVerification(SupabaseHelper.currentUser!);
      });
    } else if (SupabaseHelper.pendingAuthCallbackError != null) {
      final err = SupabaseHelper.pendingAuthCallbackError!;
      SupabaseHelper.pendingAuthCallbackError = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openResetPasswordScreen(
          hasRecoverySession: false,
          initialError: err,
        );
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _onAuthError(Object error, StackTrace stackTrace) {
    final msg = SupabaseHelper.friendlyError(error);
    _openResetPasswordScreen(
      hasRecoverySession: SupabaseHelper.currentUser != null,
      initialError: msg,
    );
  }

  Future<void> _onAuthStateChanged(AuthState data) async {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _openResetPasswordScreen(
        hasRecoverySession: true,
        initialEmail: data.session?.user.email ?? '',
      );
      return;
    }

    if (data.event == AuthChangeEvent.signedIn &&
        !SupabaseHelper.isInteractiveAuthInProgress &&
        !AppDataService.instance.isLoggedIn &&
        data.session?.user != null &&
        !_handlingAuthCallback) {
      _handlingAuthCallback = true;
      try {
        await _completeDeepLinkVerification(data.session!.user);
      } finally {
        _handlingAuthCallback = false;
      }
    }
  }

  Future<void> _completeDeepLinkVerification(User user) async {
    SupabaseHelper.pendingEmailVerification = false;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final profileRow = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final status = (profileRow?['account_status']?.toString() ?? 'active')
          .trim()
          .toLowerCase();
      if (status == 'suspended') {
        await supabase.auth.signOut();
        return;
      }

      final role = await SupabaseHelper.resolveAccountRole(
        supabase,
        user,
        profileRow: profileRow,
      );

      final nav = MyApp.navigatorKey.currentState;
      if (nav == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _completeDeepLinkVerification(user);
        });
        return;
      }

      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: user.email ?? '',
            role: role,
            isVerified: true,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Deep link verification navigation warning: $e');
    }
  }

  void _openResetPasswordScreen({
    String initialEmail = '',
    required bool hasRecoverySession,
    String? initialError,
  }) {
    SupabaseHelper.pendingPasswordRecovery = false;
    final nav = MyApp.navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openResetPasswordScreen(
            initialEmail: initialEmail,
            hasRecoverySession: hasRecoverySession,
            initialError: initialError,
          );
        }
      });
      return;
    }

    final email = initialEmail.isNotEmpty
        ? initialEmail
        : (SupabaseHelper.currentUser?.email ?? '');

    if (AppDataService.instance.isLoggedIn) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            initialEmail: email,
            hasRecoverySession: hasRecoverySession,
            initialError: initialError,
          ),
        ),
      );
    } else {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            initialEmail: email,
            hasRecoverySession: hasRecoverySession,
            initialError: initialError,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: 'CAMPUSCONNECT — Student-Corporate Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
