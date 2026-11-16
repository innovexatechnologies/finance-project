import 'package:shared_preferences/shared_preferences.dart';
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

    if (supabase != null && user != null) {
      try {
        final row = await supabase
            .from('student_payment_methods')
            .select('provider, account_number')
            .eq('user_id', user.id)
            .maybeSingle();

        if (row != null) {
          final method = StudentPaymentMethod.fromJson(row);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_payment_provider', method.provider);
          await prefs.setString('student_payment_account', method.accountNumber);
          return method;
        }
      } catch (e) {
        // Fallback to local cache below
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final localProvider = prefs.getString('student_payment_provider');
    final localAccount = prefs.getString('student_payment_account');
    if (localAccount != null && localAccount.isNotEmpty) {
      return StudentPaymentMethod(
        provider: localProvider ?? providers.first,
        accountNumber: localAccount,
      );
    }

    if (user == null) {
      throw StateError('Sign in to load your payment details.');
    }
    return null;
  }

  Future<void> saveForCurrentUser({
    required String provider,
    required String accountNumber,
  }) async {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_payment_provider', provider);
    await prefs.setString('student_payment_account', normalizedAccountNumber);

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
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
}
