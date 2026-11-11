import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_certificate_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_dashboard_service.dart';
import 'package:link_vibe/feature/admin/services/admin_hash_util.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/company/services/company_settings_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Result envelope for administrative authentication attempts.
class AdminAuthResult {
  final bool success;
  final String? message;
  final AdminUserModel? admin;
  final bool isLockedOut;
  final int? lockoutSecondsRemaining;

  const AdminAuthResult({
    required this.success,
    this.message,
    this.admin,
    this.isLockedOut = false,
    this.lockoutSecondsRemaining,
  });

  factory AdminAuthResult.successful(AdminUserModel admin) {
    return AdminAuthResult(
      success: true,
      admin: admin,
      message: 'Authentication successful. Welcome, ${admin.fullName}.',
    );
  }

  factory AdminAuthResult.failed(String errorMessage) {
    return AdminAuthResult(
      success: false,
      message: errorMessage,
    );
  }

  factory AdminAuthResult.lockedOut(int remainingSeconds) {
    return AdminAuthResult(
      success: false,
      isLockedOut: true,
      lockoutSecondsRemaining: remainingSeconds,
      message:
          'Security Lockout: Too many failed login attempts. Please wait $remainingSeconds seconds before trying again.',
    );
  }
}

/// Enterprise Admin Authentication Service backed by Supabase Auth & Profiles.
/// Enforces role verification (`user_type == 'Admin'`), suspension checks,
/// brute-force throttling, and full administrative audit logging.
class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;

  AdminAuthService._internal();

  // Offline/test-only fallback hash for default provisioned admin when Supabase is uninitialized
  static const String _defaultAdminEmail = 'admin@campusconnect.edu.pk';
  static const String _defaultSalt = '7f9a8b2c4d1e3f5a';
  static final String _defaultPassHash = AdminHashUtil.hashPassword(
    'Admin@CampusConnect2026!',
    _defaultSalt,
  );

  // Brute-force mitigation tracking
  static const int _maxConsecutiveFailures = 5;
  static const Duration _lockoutDuration = Duration(seconds: 60);
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  final ValueNotifier<AdminUserModel?> currentAdminNotifier =
      ValueNotifier<AdminUserModel?>(null);

  bool _rememberMeEnabled = false;
  bool get isRememberMeEnabled => _rememberMeEnabled;

  AdminUserModel? get currentAdmin => currentAdminNotifier.value;
  bool get isAuthenticated => currentAdminNotifier.value != null;

  int getRemainingLockoutSeconds(String normalizedEmail) {
    final lockoutTime = _lockoutUntil[normalizedEmail];
    if (lockoutTime == null) return 0;

    final now = DateTime.now();
    if (now.isBefore(lockoutTime)) {
      return lockoutTime.difference(now).inSeconds + 1;
    } else {
      _lockoutUntil.remove(normalizedEmail);
      _failedAttempts[normalizedEmail] = 0;
      return 0;
    }
  }

  /// Secure Login backed by Supabase Auth + `public.profiles` Admin role verification.
  Future<AdminAuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final remainingSeconds = getRemainingLockoutSeconds(normalizedEmail);
    if (remainingSeconds > 0) {
      return AdminAuthResult.lockedOut(remainingSeconds);
    }

    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      SupabaseHelper.beginInteractiveAuth();
      try {
        final response = await supabase.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );

        final user = response.user;
        if (user == null) {
          _registerFailedAttempt(normalizedEmail);
          return AdminAuthResult.failed(
            'Authentication failed. Please check your credentials.',
          );
        }

        // Verify Admin role from profiles table (or metadata fallback if row pending)
        final profileRow = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        final rawRole = (profileRow?['user_type']?.toString() ??
                user.userMetadata?['user_type']?.toString() ??
                '')
            .trim()
            .toLowerCase();

        if (rawRole != 'admin') {
          await supabase.auth.signOut();
          _registerFailedAttempt(normalizedEmail);
          return AdminAuthResult.failed(
            'Access denied. This account does not have Administrator privileges.',
          );
        }

        final accountStatus =
            (profileRow?['account_status']?.toString() ?? 'active')
                .trim()
                .toLowerCase();
        if (accountStatus == 'suspended') {
          await supabase.auth.signOut();
          return AdminAuthResult.failed(
            'This administrator account is currently suspended. Contact root governance.',
          );
        }

        final fullName = (profileRow?['name']?.toString().trim().isNotEmpty == true)
            ? profileRow!['name'].toString().trim()
            : (user.userMetadata?['name']?.toString().trim().isNotEmpty == true
                ? user.userMetadata!['name'].toString().trim()
                : 'Executive Administrator');
        final department =
            (profileRow?['university']?.toString().trim().isNotEmpty == true)
                ? profileRow!['university'].toString().trim()
                : 'CampusConnect Governance Council';

        final authenticatedAdmin = AdminUserModel(
          id: user.id,
          fullName: fullName,
          email: user.email ?? normalizedEmail,
          role: 'SUPER_ADMIN',
          roleDisplayName: 'Executive Super Administrator',
          department: department,
          avatarInitial: SupabaseHelper.initialsFor(fullName, fallback: 'EA'),
          permissions: const [
            'all',
            'manage_companies',
            'verify_students',
            'audit_projects',
            'manage_settings',
          ],
          lastLoginAt: 'Just now',
          sessionToken: response.session?.accessToken,
          isActive: true,
        );

        _failedAttempts.remove(normalizedEmail);
        _lockoutUntil.remove(normalizedEmail);
        _rememberMeEnabled = rememberMe;
        currentAdminNotifier.value = authenticatedAdmin;

        await AppDataService.instance.saveAuthSession(
          userId: user.id,
          role: 'Admin',
          email: authenticatedAdmin.email,
          name: authenticatedAdmin.fullName,
        );

        // Log sign-in event in immutable admin_audit_logs
        try {
          await supabase.from('admin_audit_logs').insert({
            'admin_email': authenticatedAdmin.email,
            'action': 'ADMIN_LOGIN',
            'target': authenticatedAdmin.email,
            'details': 'Administrative session authenticated via Supabase Auth.',
          });
        } catch (e) {
          debugPrint('AdminAuthService audit insert warning: $e');
        }

        await AdminDashboardService().loadAllAdminData();

        return AdminAuthResult.successful(authenticatedAdmin);
      } on AuthException catch (e) {
        final failures = _registerFailedAttempt(normalizedEmail);
        final remainingAttempts = _maxConsecutiveFailures - failures;
        if (remainingAttempts <= 0) {
          return AdminAuthResult.lockedOut(60);
        }
        return AdminAuthResult.failed(
          '${SupabaseHelper.friendlyError(e)} ($remainingAttempts attempt${remainingAttempts == 1 ? '' : 's'} remaining)',
        );
      } catch (e) {
        debugPrint('AdminAuthService login error: $e');
        return AdminAuthResult.failed(
          SupabaseHelper.friendlyError(e),
        );
      } finally {
        SupabaseHelper.endInteractiveAuth();
      }
    }

    // Offline unit-test fallback only when Supabase client is uninitialized
    if (normalizedEmail != _defaultAdminEmail) {
      _registerFailedAttempt(normalizedEmail);
      return AdminAuthResult.failed(
        'Invalid administrative credentials. Access restricted to authorized personnel.',
      );
    }

    final computedHash = AdminHashUtil.hashPassword(password, _defaultSalt);
    if (!AdminHashUtil.secureCompare(computedHash, _defaultPassHash)) {
      final failures = _registerFailedAttempt(normalizedEmail);
      final remainingAttempts = _maxConsecutiveFailures - failures;
      if (remainingAttempts <= 0) {
        return AdminAuthResult.lockedOut(60);
      }
      return AdminAuthResult.failed(
        'Invalid administrator password. $remainingAttempts attempt${remainingAttempts == 1 ? '' : 's'} remaining before security lockout.',
      );
    }

    _failedAttempts.remove(normalizedEmail);
    _lockoutUntil.remove(normalizedEmail);
    _rememberMeEnabled = rememberMe;

    final sessionNonce = Random().nextInt(9999999).toString().padLeft(7, '0');
    final offlineAdmin = AdminUserModel(
      id: 'a0000000-0000-0000-0000-000000000001',
      fullName: 'Executive Administrator',
      email: _defaultAdminEmail,
      role: 'SUPER_ADMIN',
      roleDisplayName: 'Executive Super Administrator',
      department: 'CampusConnect Governance Council',
      avatarInitial: 'EA',
      permissions: const [
        'all',
        'manage_companies',
        'verify_students',
        'audit_projects',
        'manage_settings',
      ],
      lastLoginAt: 'Just now',
      sessionToken: 'cc_adm_sess_${DateTime.now().millisecondsSinceEpoch}_$sessionNonce',
      isActive: true,
    );

    currentAdminNotifier.value = offlineAdmin;
    return AdminAuthResult.successful(offlineAdmin);
  }

  /// Restores active admin session cleanly (e.g. from SplashScreen on cold start).
  Future<AdminUserModel?> restoreFromCurrentUser() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return null;

    try {
      final profileRow = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final rawRole = (profileRow?['user_type']?.toString() ??
              user.userMetadata?['user_type']?.toString() ??
              '')
          .trim()
          .toLowerCase();
      if (rawRole != 'admin') return null;

      final fullName = (profileRow?['name']?.toString().trim().isNotEmpty == true)
          ? profileRow!['name'].toString().trim()
          : 'Executive Administrator';
      final department =
          (profileRow?['university']?.toString().trim().isNotEmpty == true)
              ? profileRow!['university'].toString().trim()
              : 'CampusConnect Governance Council';

      final admin = AdminUserModel(
        id: user.id,
        fullName: fullName,
        email: user.email ?? '',
        role: 'SUPER_ADMIN',
        roleDisplayName: 'Executive Super Administrator',
        department: department,
        avatarInitial: SupabaseHelper.initialsFor(fullName, fallback: 'EA'),
        permissions: const [
          'all',
          'manage_companies',
          'verify_students',
          'audit_projects',
          'manage_settings',
        ],
        lastLoginAt: 'Active Session',
        isActive: true,
      );

      currentAdminNotifier.value = admin;
      await AdminDashboardService().loadAllAdminData();
      return admin;
    } catch (e) {
      debugPrint('AdminAuthService restoreFromCurrentUser error: $e');
      return null;
    }
  }

  int _registerFailedAttempt(String email) {
    final current = (_failedAttempts[email] ?? 0) + 1;
    _failedAttempts[email] = current;

    if (current >= _maxConsecutiveFailures) {
      _lockoutUntil[email] = DateTime.now().add(_lockoutDuration);
    }
    return current;
  }

  /// Dispatches real password reset email via Supabase Auth.
  Future<bool> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) return false;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      return normalized == _defaultAdminEmail;
    }

    try {
      await supabase.auth.resetPasswordForEmail(
        normalized,
        redirectTo: SupabaseHelper.emailRedirectUrl,
      );
      return true;
    } catch (e) {
      debugPrint('AdminAuthService requestPasswordReset error: $e');
      return false;
    }
  }

  /// Invalidates Supabase auth session and resets all Admin/Company/Shared caches.
  Future<void> logout() async {
    final supabase = SupabaseHelper.clientOrNull;
    try {
      await supabase?.auth.signOut().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('AdminAuthService signOut error: $e');
    }

    SupabaseHelper.clearAuthFlags();
    await AppDataService.instance.clearAuthSession();
    currentAdminNotifier.value = null;
    _rememberMeEnabled = false;

    // Reset all Admin caches
    AdminCompanyService().reset();
    AdminVerificationService().reset();
    AdminStudentService().reset();
    AdminProjectService().reset();
    AdminApplicationMonitoringService().reset();
    AdminCertificateService().reset();
    AdminSettingsService().reset();
    AdminDashboardService().reset();

    // Reset Company singleton caches too
    CompanyProfileService().reset();
    CompanyVerificationService().reset();
    CompanyProjectService().reset();
    CompanyApplicantService().reset();
    CompanyAssignmentService().reset();
    CompanySettingsService().reset();
  }
}
