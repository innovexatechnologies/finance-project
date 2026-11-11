import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe wrapper & utilities for Supabase client access across runtime & tests.
class SupabaseHelper {
  SupabaseHelper._();

  static const String authRedirectUri =
      'io.supabase.campusconnect://login-callback/';

  /// Returns mobile deep-link callback URI on Android/iOS/desktop, or `null`
  /// on Flutter Web so Supabase falls back to the current web origin.
  static String? get emailRedirectUrl => kIsWeb ? null : authRedirectUri;

  /// Guard set while LoginScreen / SignupScreen / AdminAuthService perform an
  /// interactive auth call so the global deep-link listener only handles
  /// external verification/recovery redirects.
  static bool isInteractiveAuthInProgress = false;
  static DateTime? _lastInteractiveAuthAt;

  static void beginInteractiveAuth() {
    isInteractiveAuthInProgress = true;
    _lastInteractiveAuthAt = DateTime.now();
  }

  static void endInteractiveAuth() {
    isInteractiveAuthInProgress = false;
    _lastInteractiveAuthAt = DateTime.now();
  }

  static bool get shouldIgnoreSignedInEvent {
    if (isInteractiveAuthInProgress) return true;
    final last = _lastInteractiveAuthAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 2)) {
      return true;
    }
    return false;
  }

  static void clearAuthFlags() {
    isInteractiveAuthInProgress = false;
    _lastInteractiveAuthAt = null;
    pendingPasswordRecovery = false;
    pendingEmailVerification = false;
    pendingAuthCallbackError = null;
  }

  /// Set if a password recovery deep link arrives during app cold boot before
  /// the widget tree mounts.
  static bool pendingPasswordRecovery = false;

  /// Set if a signup/verification deep link completes during cold boot before
  /// the widget tree mounts.
  static bool pendingEmailVerification = false;

  /// Captures an auth callback error (e.g. expired link or PKCE mismatch)
  /// arriving during cold boot so the UI can show a dedicated recovery screen.
  static String? pendingAuthCallbackError;

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
    if (raw is DateTime) return raw;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str);
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

  static bool isEmailRateLimitError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();
    final code = error is AuthException ? (error.code?.toLowerCase() ?? '') : '';
    return code == 'over_email_send_rate_limit' ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('email rate limit exceeded');
  }

  /// Converts raw network/auth/platform exceptions into readable UI messages.
  static String friendlyError(Object error) {
    final msg = error is AuthException ? error.message : error.toString();
    final lower = msg.toLowerCase();
    final code = error is AuthException ? (error.code?.toLowerCase() ?? '') : '';

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
    if (isEmailRateLimitError(error)) {
      return 'Email sending limit reached (Supabase free SMTP allows only 2 emails per hour). Please wait before requesting another email, use your 6-digit code in "Verify via code", or sign in with a verified account (or disable Confirm Email / configure Custom SMTP in Supabase Dashboard).';
    }
    if (code == 'over_request_rate_limit' ||
        lower.contains('over_request_rate_limit') ||
        lower.contains('for security purposes, you can only request this')) {
      return 'Too many requests in a short time. Please wait 60 seconds and try again.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please verify and try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email is not verified yet. Please confirm the link in your inbox before signing in.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }

    var cleaned = msg.trim();
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length).trim();
    }
    return cleaned.isEmpty ? 'Something went wrong. Please try again.' : cleaned;
  }
}

/// Shared countdown timer preventing repeated email sends that exhaust
/// Supabase's strict built-in SMTP hourly quota.
class ResendCooldown {
  Timer? _timer;
  int _remainingSeconds = 0;

  int get remainingSeconds => _remainingSeconds;
  bool get isActive => _remainingSeconds > 0;

  void start(VoidCallback onTick, {int seconds = 60}) {
    _timer?.cancel();
    _remainingSeconds = seconds;
    onTick();
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _remainingSeconds = 0;
        timer.cancel();
        _timer = null;
      } else {
        _remainingSeconds--;
      }
      onTick();
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;
  }
}
