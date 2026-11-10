import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe wrapper & utilities for Supabase client access across runtime & tests.
class SupabaseHelper {
  SupabaseHelper._();

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
}
