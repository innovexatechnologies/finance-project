import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/app_data_service.dart';
import 'core/services/supabase_helper.dart';
import 'core/theme/app_theme.dart';
import 'feature/auth/presentation/screens/email_verification_screen.dart';
import 'feature/auth/presentation/screens/reset_password_screen.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';

StreamSubscription<AuthState>? _bootAuthSub;

Map<String, String> _extractUriParams(Uri uri) {
  final params = <String, String>{...uri.queryParameters};
  if (uri.fragment.isNotEmpty) {
    final frag = uri.fragment.contains('?')
        ? uri.fragment.split('?').last
        : uri.fragment;
    try {
      params.addAll(Uri.splitQueryString(frag));
    } catch (_) {}
  }
  return params;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture initial Web URL params BEFORE Supabase.initialize() clears them.
  final initialWebParams =
      kIsWeb ? _extractUriParams(Uri.base) : const <String, String>{};

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
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
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

  // Keep boot listener alive immediately after Supabase.initialize() until
  // _MyAppState.initState() takes over so deep links arriving during init are
  // never dropped.
  final bootSupabase = SupabaseHelper.clientOrNull;
  if (bootSupabase != null) {
    _bootAuthSub = bootSupabase.auth.onAuthStateChange.listen(
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

  await AppDataService.instance.init();

  if (initialWebParams.isNotEmpty) {
    final errDesc = initialWebParams['error_description'] ??
        initialWebParams['error'];
    final redirectType = initialWebParams['type']?.toLowerCase();
    if (errDesc != null && errDesc.isNotEmpty) {
      SupabaseHelper.pendingAuthCallbackError ??=
          SupabaseHelper.friendlyError(AuthException(errDesc));
    } else if (redirectType == 'recovery') {
      SupabaseHelper.pendingPasswordRecovery = true;
    } else if (initialWebParams.containsKey('access_token') ||
        initialWebParams.containsKey('code')) {
      SupabaseHelper.pendingEmailVerification = true;
    }
  }

  // Recover sessions established inside Supabase.initialize() on cold start
  // (e.g. Web _handleInitialUri or immediate mobile deep link) before listeners ran.
  if (!AppDataService.instance.isLoggedIn &&
      SupabaseHelper.currentUser != null &&
      !SupabaseHelper.pendingPasswordRecovery &&
      SupabaseHelper.pendingAuthCallbackError == null) {
    SupabaseHelper.pendingEmailVerification = true;
  }

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
    _bootAuthSub?.cancel();
    _bootAuthSub = null;

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
        _routeAuthCallbackError(err);
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
    _routeAuthCallbackError(msg);
  }

  void _routeAuthCallbackError(String msg) {
    final isSignupFlow = SupabaseHelper.pendingAuthFlow == 'signup' ||
        (SupabaseHelper.pendingAuthFlow == null &&
            SupabaseHelper.pendingAuthEmail != null &&
            SupabaseHelper.pendingAuthEmail!.isNotEmpty);

    if (isSignupFlow) {
      _openVerificationErrorScreen(msg);
      return;
    }

    _openResetPasswordScreen(
      hasRecoverySession: SupabaseHelper.currentUser != null,
      initialError: msg,
    );
  }

  void _openVerificationErrorScreen(String err) {
    final nav = MyApp.navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openVerificationErrorScreen(err);
      });
      return;
    }

    final email = SupabaseHelper.pendingAuthEmail ??
        SupabaseHelper.currentUser?.email ??
        '';
    final role = SupabaseHelper.pendingAuthRole ?? 'Student';

    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(
          email: email,
          role: role,
          isVerified: false,
          initialError: err,
        ),
      ),
      (route) => false,
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
        !SupabaseHelper.shouldIgnoreSignedInEvent &&
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

    Map<String, dynamic>? profileRow;
    try {
      profileRow = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('Deep link profile lookup warning: $e');
    }

    final status = (profileRow?['account_status']?.toString() ?? 'active')
        .trim()
        .toLowerCase();
    if (status == 'suspended') {
      try {
        await supabase.auth.signOut();
      } catch (_) {}
      return;
    }

    String role = 'Student';
    try {
      role = await SupabaseHelper.resolveAccountRole(
        supabase,
        user,
        profileRow: profileRow,
      );
    } catch (e) {
      final metaType =
          user.userMetadata?['user_type']?.toString().trim().toLowerCase() ??
              '';
      if (metaType == 'company' ||
          SupabaseHelper.pendingAuthRole == 'Company') {
        role = 'Company';
      } else if (metaType == 'admin') {
        role = 'Admin';
      }
      debugPrint('Deep link role resolution warning: $e');
    }

    if (role == 'Company') {
      try {
        await supabase
            .from('companies')
            .update({'is_email_verified': true})
            .eq('user_id', user.id);
      } catch (_) {}
    }

    await AppDataService.instance.clearPendingAuthContext();

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
          email: user.email ?? SupabaseHelper.pendingAuthEmail ?? '',
          role: role,
          isVerified: true,
        ),
      ),
      (route) => false,
    );
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
      title: 'SkillBridge — Student-Corporate Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
