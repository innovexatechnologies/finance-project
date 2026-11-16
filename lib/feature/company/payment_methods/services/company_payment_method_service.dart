import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';

class CompanyPaymentMethod {
  final String provider;
  final String accountNumber;
  final String accountTitle;

  const CompanyPaymentMethod({
    required this.provider,
    required this.accountNumber,
    required this.accountTitle,
  });

  factory CompanyPaymentMethod.fromJson(Map<String, dynamic> json) {
    return CompanyPaymentMethod(
      provider: json['provider']?.toString() ?? 'Bank Account',
      accountNumber: json['account_number']?.toString() ?? '',
      accountTitle: json['account_title']?.toString() ?? '',
    );
  }
}

class CompanyPaymentMethodService {
  static const providers = ['Bank Account', 'JazzCash', 'Easypaisa'];

  Future<CompanyPaymentMethod?> loadForCurrentCompany() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;

    if (supabase != null && user != null) {
      try {
        final row = await supabase
            .from('company_payment_methods')
            .select('provider, account_number, account_title')
            .or('user_id.eq.${user.id},company_id.eq.${user.id}')
            .maybeSingle();

        if (row != null) {
          final method = CompanyPaymentMethod.fromJson(row);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('company_payment_provider', method.provider);
          await prefs.setString('company_payment_account', method.accountNumber);
          await prefs.setString('company_payment_title', method.accountTitle);
          return method;
        }
      } catch (e) {
        debugPrint('CompanyPaymentMethodService load warning: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final localAccount = prefs.getString('company_payment_account');
    if (localAccount != null && localAccount.isNotEmpty) {
      return CompanyPaymentMethod(
        provider: prefs.getString('company_payment_provider') ?? providers.first,
        accountNumber: localAccount,
        accountTitle: prefs.getString('company_payment_title') ?? 'Corporate Escrow Refund Account',
      );
    }

    return null;
  }

  Future<void> saveForCurrentCompany({
    required String provider,
    required String accountNumber,
    required String accountTitle,
  }) async {
    if (!providers.contains(provider)) {
      throw ArgumentError.value(provider, 'provider', 'Unsupported provider.');
    }

    final normalizedAccountNumber = accountNumber.trim();
    if (normalizedAccountNumber.isEmpty || normalizedAccountNumber.length > 50) {
      throw ArgumentError.value(
        accountNumber,
        'accountNumber',
        'Account number must contain 1 to 50 characters.',
      );
    }

    final normalizedTitle = accountTitle.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        accountTitle,
        'accountTitle',
        'Account title is required.',
      );
    }

    // Always persist to local SharedPreferences first for instant offline/test availability
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_payment_provider', provider);
    await prefs.setString('company_payment_account', normalizedAccountNumber);
    await prefs.setString('company_payment_title', normalizedTitle);

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;

    if (supabase != null && user != null) {
      try {
        await supabase.from('company_payment_methods').upsert({
          'user_id': user.id,
          'company_id': user.id,
          'provider': provider,
          'account_number': normalizedAccountNumber,
          'account_title': normalizedTitle,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('CompanyPaymentMethodService remote save error (cached locally): $e');
      }
    }
  }
}

