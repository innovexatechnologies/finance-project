import 'package:link_vibe/core/services/supabase_helper.dart';

class StudentPaymentMethod {
  final String provider;
  final String accountNumber;

  const StudentPaymentMethod({
    required this.provider,
    required this.accountNumber,
  });

  factory StudentPaymentMethod.fromJson(Map<String, dynamic> json) {
    return StudentPaymentMethod(
      provider: json['provider']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
    );
  }
}

class StudentPaymentMethodService {
  static const providers = ['Bank Account', 'JazzCash', 'Easypaisa'];

  Future<StudentPaymentMethod?> loadForCurrentUser() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw StateError('Sign in to load your payment details.');
    }

    final row = await supabase
        .from('student_payment_methods')
        .select('provider, account_number')
        .eq('user_id', user.id)
        .maybeSingle();

    return row == null ? null : StudentPaymentMethod.fromJson(row);
  }

  Future<void> saveForCurrentUser({
    required String provider,
    required String accountNumber,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw StateError('Sign in to save your payment details.');
    }
    if (!providers.contains(provider)) {
      throw ArgumentError.value(provider, 'provider', 'Unsupported provider.');
    }

    final normalizedAccountNumber = accountNumber.trim();
    if (normalizedAccountNumber.isEmpty ||
        normalizedAccountNumber.length > 50) {
      throw ArgumentError.value(
        accountNumber,
        'accountNumber',
        'Account number must contain 1 to 50 characters.',
      );
    }

    await supabase.from('student_payment_methods').upsert(
      {
        'user_id': user.id,
        'provider': provider,
        'account_number': normalizedAccountNumber,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
