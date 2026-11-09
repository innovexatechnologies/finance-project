import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_hash_util.dart';

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

/// Internal credential record with cryptographic salt and SHA-256 hash
class _AdminCredentialRecord {
  final String salt;
  final String passwordHash;
  final AdminUserModel userModel;

  const _AdminCredentialRecord({
    required this.salt,
    required this.passwordHash,
    required this.userModel,
  });
}

/// Enterprise Admin Authentication Service
/// Manages trusted setup, brute-force throttling, cryptographic verification, and session state.
class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;

  AdminAuthService._internal() {
    _initTrustedAdmins();
  }

  // Pre-provisioned administrative accounts (Never publicly registrable)
  final Map<String, _AdminCredentialRecord> _trustedDirectory = {};

  // Brute-force mitigation tracking
  static const int _maxConsecutiveFailures = 5;
  static const Duration _lockoutDuration = Duration(seconds: 60);
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  // Active Session State
  final ValueNotifier<AdminUserModel?> currentAdminNotifier =
      ValueNotifier<AdminUserModel?>(null);

  bool _rememberMeEnabled = false;
  bool get isRememberMeEnabled => _rememberMeEnabled;

  AdminUserModel? get currentAdmin => currentAdminNotifier.value;
  bool get isAuthenticated => currentAdminNotifier.value != null;

  void _initTrustedAdmins() {
    // 1. Super Administrator (Root Platform Council)
    const superSalt = '7f9a8b2c4d1e3f5a';
    final superHash = AdminHashUtil.hashPassword('Admin@CampusConnect2026!', superSalt);

    _trustedDirectory['admin@campusconnect.edu.pk'] = _AdminCredentialRecord(
      salt: superSalt,
      passwordHash: superHash,
      userModel: const AdminUserModel(
        id: 'adm_root_001',
        fullName: 'Dr. Tariq Mahmood',
        email: 'admin@campusconnect.edu.pk',
        role: 'SUPER_ADMIN',
        roleDisplayName: 'Executive Super Administrator',
        department: 'CampusConnect Governance Council',
        avatarInitial: 'TM',
        permissions: ['all', 'manage_companies', 'verify_students', 'audit_projects', 'manage_settings'],
        lastLoginAt: 'Today at 09:15 AM',
      ),
    );

    // 2. Operations & Compliance Administrator
    const opsSalt = '3b8e1d5c9a7f2e4b';
    final opsHash = AdminHashUtil.hashPassword('CampusOps2026!', opsSalt);

    _trustedDirectory['ops@campusconnect.edu.pk'] = _AdminCredentialRecord(
      salt: opsSalt,
      passwordHash: opsHash,
      userModel: const AdminUserModel(
        id: 'adm_ops_002',
        fullName: 'Syeda Fatima Noor',
        email: 'ops@campusconnect.edu.pk',
        role: 'OPERATIONS_ADMIN',
        roleDisplayName: 'Verification & Operations Director',
        department: 'Corporate & University Partnerships',
        avatarInitial: 'FN',
        permissions: ['verify_companies', 'verify_students', 'audit_projects'],
        lastLoginAt: 'Yesterday at 04:30 PM',
      ),
    );
  }

  /// Check if the target email is currently under brute-force security lockout
  int getRemainingLockoutSeconds(String normalizedEmail) {
    final lockoutTime = _lockoutUntil[normalizedEmail];
    if (lockoutTime == null) return 0;

    final now = DateTime.now();
    if (now.isBefore(lockoutTime)) {
      return lockoutTime.difference(now).inSeconds + 1;
    } else {
      // Lockout expired
      _lockoutUntil.remove(normalizedEmail);
      _failedAttempts[normalizedEmail] = 0;
      return 0;
    }
  }

  /// Secure Login with cryptographic verification and brute-force mitigation
  Future<AdminAuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // Artificial latency emulating backend TLS round-trip
    await Future.delayed(const Duration(milliseconds: 650));

    final normalizedEmail = email.trim().toLowerCase();

    // 1. Check Brute-Force Lockout
    final remainingSeconds = getRemainingLockoutSeconds(normalizedEmail);
    if (remainingSeconds > 0) {
      return AdminAuthResult.lockedOut(remainingSeconds);
    }

    // 2. Validate against trusted administrative directory
    final record = _trustedDirectory[normalizedEmail];
    if (record == null) {
      _registerFailedAttempt(normalizedEmail);
      return AdminAuthResult.failed(
        'Invalid administrative credentials. Access restricted to authorized personnel.',
      );
    }

    // 3. Hash input password with pre-stored salt and compare
    final computedHash = AdminHashUtil.hashPassword(password, record.salt);
    final isPasswordValid = AdminHashUtil.secureCompare(computedHash, record.passwordHash);

    if (!isPasswordValid) {
      final failures = _registerFailedAttempt(normalizedEmail);
      final remainingAttempts = _maxConsecutiveFailures - failures;

      if (remainingAttempts <= 0) {
        return AdminAuthResult.lockedOut(60);
      }

      return AdminAuthResult.failed(
        'Invalid administrator password. $remainingAttempts attempt${remainingAttempts == 1 ? '' : 's'} remaining before security lockout.',
      );
    }

    // 4. Successful Authentication: Reset failures, generate secure session token
    _failedAttempts.remove(normalizedEmail);
    _lockoutUntil.remove(normalizedEmail);
    _rememberMeEnabled = rememberMe;

    final sessionNonce = Random().nextInt(9999999).toString().padLeft(7, '0');
    final sessionToken = 'cc_adm_sess_${DateTime.now().millisecondsSinceEpoch}_$sessionNonce';

    final authenticatedAdmin = record.userModel.copyWith(
      sessionToken: sessionToken,
      lastLoginAt: 'Just now',
    );

    currentAdminNotifier.value = authenticatedAdmin;
    return AdminAuthResult.successful(authenticatedAdmin);
  }

  int _registerFailedAttempt(String email) {
    final current = (_failedAttempts[email] ?? 0) + 1;
    _failedAttempts[email] = current;

    if (current >= _maxConsecutiveFailures) {
      _lockoutUntil[email] = DateTime.now().add(_lockoutDuration);
    }
    return current;
  }

  /// Forgot Password administrative dispatch
  Future<bool> requestPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final normalized = email.trim().toLowerCase();
    return _trustedDirectory.containsKey(normalized);
  }

  /// Secure Session Invalidation
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 250));
    currentAdminNotifier.value = null;
    _rememberMeEnabled = false;
  }
}

