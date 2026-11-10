import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/services/app_data_service.dart';
import 'core/services/supabase_helper.dart';
import 'core/theme/app_theme.dart';
import 'feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'feature/admin/services/admin_auth_service.dart';
import 'feature/company/presentation/screens/company_dashboard.dart';
import 'feature/company/services/company_profile_service.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';
import 'feature/student/presentation/screens/student_main_nav.dart';

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
    bootSub = bootSupabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        SupabaseHelper.pendingPasswordRecovery = true;
      }
    });
  }

  if (SupabaseHelper.currentUser != null) {
    await AppDataService.instance.syncFromSupabase();
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
  bool _recoveryDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      _authSub = supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
    }
    if (SupabaseHelper.pendingPasswordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPasswordRecoveryDialog();
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(AuthState data) async {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _showPasswordRecoveryDialog();
      return;
    }

    if (data.event == AuthChangeEvent.signedIn &&
        !SupabaseHelper.isInteractiveAuthInProgress &&
        !AppDataService.instance.isLoggedIn &&
        data.session?.user != null &&
        !_handlingAuthCallback) {
      _handlingAuthCallback = true;
      try {
        await _completeDeepLinkSignIn(data.session!.user);
      } finally {
        _handlingAuthCallback = false;
      }
    }
  }

  Future<void> _completeDeepLinkSignIn(User user) async {
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

      final resolvedName =
          (profileRow?['name']?.toString().trim().isNotEmpty == true)
              ? profileRow!['name'].toString().trim()
              : (user.userMetadata?['name']?.toString().trim().isNotEmpty ==
                      true
                  ? user.userMetadata!['name'].toString().trim()
                  : (user.email?.split('@').first ?? 'User'));
      final resolvedUni =
          (profileRow?['university']?.toString().trim().isNotEmpty == true)
              ? profileRow!['university'].toString().trim()
              : user.userMetadata?['university']?.toString();

      await AppDataService.instance.saveAuthSession(
        role: role,
        email: user.email ?? '',
        name: resolvedName,
        university: resolvedUni,
        userId: user.id,
      );

      Widget destination;
      if (role == 'Admin') {
        final admin = await AdminAuthService().restoreFromCurrentUser();
        if (admin == null) return;
        destination = const AdminDashboardScreen();
      } else if (role == 'Company') {
        await CompanyProfileService.loadAllCompanyPanelData();
        destination = const CompanyDashboardScreen();
      } else {
        await AppDataService.instance.syncFromSupabase(forceRefresh: true);
        destination = const StudentMainNav();
      }

      final nav = MyApp.navigatorKey.currentState;
      final ctx = MyApp.navigatorKey.currentContext;
      if (nav != null) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      }
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Email verified! Welcome, $resolvedName.'),
            backgroundColor: AppColors.statusOpen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Deep link auth completion warning: $e');
    }
  }

  void _showPasswordRecoveryDialog() {
    if (_recoveryDialogOpen) return;
    final ctx = MyApp.navigatorKey.currentContext;
    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPasswordRecoveryDialog();
      });
      return;
    }

    SupabaseHelper.pendingPasswordRecovery = false;
    _recoveryDialogOpen = true;
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Set New Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your new password below to complete account recovery.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMsg!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final p1 = passCtrl.text.trim();
                      final p2 = confirmCtrl.text.trim();
                      if (p1.length < 6) {
                        setDialogState(
                          () => errorMsg = 'Minimum 6 characters required.',
                        );
                        return;
                      }
                      if (p1 != p2) {
                        setDialogState(
                          () => errorMsg = 'Passwords do not match.',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        errorMsg = null;
                      });
                      try {
                        final supabase = SupabaseHelper.clientOrNull;
                        if (supabase == null) {
                          throw Exception('Supabase client unavailable.');
                        }
                        await supabase.auth.updateUser(
                          UserAttributes(password: p1),
                        );
                        if (!AppDataService.instance.isLoggedIn) {
                          await supabase.auth.signOut();
                        }
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password updated successfully! Please sign in with your new password.',
                              ),
                              backgroundColor: AppColors.statusOpen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          errorMsg = SupabaseHelper.friendlyError(e);
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      _recoveryDialogOpen = false;
      passCtrl.dispose();
      confirmCtrl.dispose();
    });
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
