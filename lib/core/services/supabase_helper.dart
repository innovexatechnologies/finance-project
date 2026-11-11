import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe wrapper & utilities for Supabase client access across runtime & tests.
class SupabaseHelper {
  SupabaseHelper._();

  static bool isInteractiveAuthInProgress = false;

  static void beginInteractiveAuth() {
    isInteractiveAuthInProgress = true;
  }

  static void endInteractiveAuth() {
    isInteractiveAuthInProgress = false;
  }

  static void clearAuthFlags() {
    isInteractiveAuthInProgress = false;
  }

  static final Random _random = Random();
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Returns `Supabase.instance.client` when initialized, or `null` cleanly
  /// during offline unit/widget tests where `Supabase.initialize()` was skipped.
  static SupabaseClient? get clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static User? get currentUser {
    try {
      return clientOrNull?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? get currentUserId => currentUser?.id;

  static bool isUuid(String? value) {
    if (value == null) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  /// Pure-Dart RFC-4122 version 4 UUID generator.
  static String generateUuid() {
    Random rng;
    try {
      rng = Random.secure();
    } catch (_) {
      rng = _random;
    }

    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122

    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(hex(bytes[i]));
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        buffer.write('-');
      }
    }
    return buffer.toString();
  }

  static String formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = dt.toLocal();
    final m = months[local.month - 1];
    final d = local.day.toString().padLeft(2, '0');
    return '$m $d, ${local.year}';
  }

  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str)?.toLocal();
  }

  static String formatRelativeTime(dynamic raw) {
    final dt = parseDate(raw);
    if (dt == null) return raw?.toString() ?? 'Recently';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  static List<String> parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static String initialsFor(String name, {String fallback = 'CC'}) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return fallback;
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleaned
        .substring(0, cleaned.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  /// Resolves the authoritative portal role ('Admin', 'Company', or 'Student')
  /// from `public.profiles`, auth metadata, or role-specific tables.
  static Future<String> resolveAccountRole(
    SupabaseClient supabase,
    User user, {
    Map<String, dynamic>? profileRow,
  }) async {
    final profileType =
        profileRow?['user_type']?.toString().trim().toLowerCase() ?? '';
    final metaType =
        user.userMetadata?['user_type']?.toString().trim().toLowerCase() ?? '';
    String raw = profileType.isNotEmpty ? profileType : metaType;

    if (raw.isEmpty) {
      try {
        final comp = await supabase
            .from('companies')
            .select('id')
            .eq('user_id', user.id)
            .limit(1)
            .maybeSingle();
        if (comp != null) raw = 'company';
      } catch (_) {}
    }

    if (raw == 'admin') return 'Admin';
    if (raw == 'company') return 'Company';
    return 'Student';
  }

  static bool isWeakPasswordError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();
    final code = error is AuthException ? (error.code?.toLowerCase() ?? '') : '';
    return code == 'weak_password' ||
        lower.contains('password should be at least') ||
        lower.contains('weak_password');
  }

  static bool isEmailRateLimitError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();
    final code = error is AuthException ? (error.code?.toLowerCase() ?? '') : '';
    return code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('over_request_rate_limit') ||
        lower.contains('email rate limit exceeded');
  }

  static bool isEmailNotConfirmedError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();
    final code = error is AuthException ? (error.code?.toLowerCase() ?? '') : '';
    return code == 'email_not_confirmed' ||
        lower.contains('email_not_confirmed') ||
        lower.contains('email not confirmed');
  }

  static bool isAlreadyRegisteredError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();
    final code = error is AuthException ? (error.code?.toLowerCase() ?? '') : '';
    return code == 'user_already_exists' ||
        lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('already exists');
  }

  /// Best-effort SQL RPC call to auto-confirm an unconfirmed Supabase Auth user.
  static Future<void> confirmUserEmailInApp(String email) async {
    final supabase = clientOrNull;
    final cleanEmail = email.trim().toLowerCase();
    if (supabase == null || cleanEmail.isEmpty) return;
    try {
      await supabase.rpc(
        'confirm_user_email_in_app',
        params: {'target_email': cleanEmail},
      );
    } catch (_) {}
  }

  /// Creates an immediately confirmed Supabase Auth account directly in DB
  /// (used when server SMTP or signup constraints block direct signup).
  static Future<void> registerUserInApp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String organization,
  }) async {
    final supabase = clientOrNull;
    if (supabase == null) {
      throw const AuthException('Supabase client unavailable.');
    }
    await supabase.rpc(
      'register_user_in_app',
      params: {
        'target_email': email.trim().toLowerCase(),
        'target_password': password.trim(),
        'full_name': name.trim(),
        'user_type': role.trim(),
        'organization': organization.trim(),
      },
    );
  }

  /// Resets any registered user's password directly in Supabase via RPC.
  static Future<void> resetPasswordInApp({
    required String email,
    required String newPassword,
  }) async {
    final supabase = clientOrNull;
    if (supabase == null) {
      throw const AuthException('Supabase client unavailable.');
    }
    await supabase.rpc(
      'reset_user_password_in_app',
      params: {
        'target_email': email.trim().toLowerCase(),
        'new_password': newPassword.trim(),
      },
    );
  }

  /// Provisions a confirmed administrator account in Supabase Auth + `profiles`.
  static Future<String> provisionAdminInApp({
    required String email,
    required String password,
    required String fullName,
    required String department,
  }) async {
    final supabase = clientOrNull;
    if (supabase == null) {
      throw const AuthException('Supabase client unavailable.');
    }
    final res = await supabase.rpc(
      'provision_admin_in_app',
      params: {
        'target_email': email.trim().toLowerCase(),
        'target_password': password.trim(),
        'full_name': fullName.trim(),
        'department': department.trim(),
      },
    );
    return res?.toString() ?? '';
  }

  /// Converts raw network/auth/platform exceptions into readable UI messages.
  static String friendlyError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();

    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('clientexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('timed out')) {
      return 'Unable to reach the server. Please check your internet connection (Wi-Fi / Mobile Data) and try again.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please verify and try again.';
    }
    if (lower.contains('no account found')) {
      return 'No account found for this email address.';
    }
    if (lower.contains('invalid api key')) {
      return 'Invalid API key. Check SUPABASE_URL and SUPABASE_ANON_KEY in .env against your Supabase project API Keys, then restart the app.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    var cleaned = msg.trim();
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length).trim();
    }
    return cleaned.isEmpty ? 'Something went wrong. Please try again.' : cleaned;
  }
}
