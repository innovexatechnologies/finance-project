import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/platform_payment_method_model.dart';

/// Service managing Admin-controlled custodial escrow payment accounts.
class AdminPaymentService {
  static final AdminPaymentService _instance = AdminPaymentService._internal();
  factory AdminPaymentService() => _instance;
  AdminPaymentService._internal();

  final ValueNotifier<List<PlatformPaymentMethodModel>> paymentMethodsNotifier =
      ValueNotifier<List<PlatformPaymentMethodModel>>([]);

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  String? _lastError;
  String? get lastError => _lastError;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  List<PlatformPaymentMethodModel> get allMethods =>
      paymentMethodsNotifier.value;

  List<PlatformPaymentMethodModel> get activeMethods =>
      allMethods.where((m) => m.isActive).toList();

  int get totalCount => allMethods.length;
  int get activeCount => activeMethods.length;

  /// Default fallback accounts if the database table is not yet seeded or offline.
  static final List<PlatformPaymentMethodModel> defaultFallbackMethods = [
    const PlatformPaymentMethodModel(
      id: 'default-meezan-1',
      methodType: PlatformPaymentMethodType.bankAccount,
      bankOrWalletName: 'Meezan Bank Ltd',
      accountTitle: 'SkillBridge Escrow Services Pvt Ltd',
      accountNumber: '01020304050607',
      iban: 'PK36MEZN0001020304050607',
      instructions: 'Please transfer the exact project amount. In the transfer purpose or memo, include your Project ID.',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
    const PlatformPaymentMethodModel(
      id: 'default-jazzcash-1',
      methodType: PlatformPaymentMethodType.jazzCash,
      bankOrWalletName: 'JazzCash Merchant',
      accountTitle: 'SkillBridge Admin Escrow',
      accountNumber: '03001234567',
      iban: null,
      instructions: 'Send project funding via JazzCash Till / Mobile Account. Save the 12-digit TID and screenshot.',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
    const PlatformPaymentMethodModel(
      id: 'default-easypaisa-1',
      methodType: PlatformPaymentMethodType.easyPaisa,
      bankOrWalletName: 'EasyPaisa Wallet',
      accountTitle: 'SkillBridge Admin Escrow',
      accountNumber: '03451234567',
      iban: null,
      instructions: 'Send project funding via EasyPaisa. Retain the Transaction ID (TRX ID) and payment confirmation slip.',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
    const PlatformPaymentMethodModel(
      id: 'default-nayapay-1',
      methodType: PlatformPaymentMethodType.nayapay,
      bankOrWalletName: 'NayaPay Wallet',
      accountTitle: 'SkillBridge Admin Escrow',
      accountNumber: '03331234567',
      iban: null,
      instructions: 'Pay via NayaPay to NayaPay ID @skillbridge or account number. Upload receipt screenshot after transfer.',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
    ),
  ];

  /// Loads platform payment methods from Supabase.
  Future<bool> loadPaymentMethods({bool forceRefresh = false}) async {
    if (_hasLoaded &&
        !forceRefresh &&
        paymentMethodsNotifier.value.isNotEmpty) {
      return true;
    }

    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      if (paymentMethodsNotifier.value.isEmpty) {
        paymentMethodsNotifier.value = List.from(defaultFallbackMethods);
      }
      _hasLoaded = true;
      isLoadingNotifier.value = false;
      return true;
    }

    try {
      final rows = await supabase
          .from('platform_payment_methods')
          .select()
          .order('created_at', ascending: true);

      final list = (rows as List<dynamic>)
          .map(
            (r) =>
                PlatformPaymentMethodModel.fromJson(r as Map<String, dynamic>),
          )
          .toList();

      if (list.isEmpty) {
        // If table exists but is empty, seed with fallback defaults in memory
        paymentMethodsNotifier.value = List.from(defaultFallbackMethods);
      } else {
        paymentMethodsNotifier.value = list;
      }

      _hasLoaded = true;
      return true;
    } catch (e) {
      debugPrint('AdminPaymentService loadPaymentMethods warning: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      // Fallback gracefully so the UI never breaks
      if (paymentMethodsNotifier.value.isEmpty) {
        paymentMethodsNotifier.value = List.from(defaultFallbackMethods);
      }
      _hasLoaded = true;
      return false;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Adds a new platform payment method to Supabase and local state.
  Future<bool> addPaymentMethod(PlatformPaymentMethodModel method) async {
    _lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    final cleanId = SupabaseHelper.isUuid(method.id)
        ? method.id
        : supabase == null
        ? method.id
        : SupabaseHelper.generateUuid();

    final nowIso = DateTime.now().toIso8601String();
    final newMethod = method.copyWith(
      id: cleanId,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    if (supabase != null) {
      try {
        await supabase.from('platform_payment_methods').insert({
          'id': cleanId,
          'method_type': newMethod.methodType,
          'bank_or_wallet_name': newMethod.bankOrWalletName,
          'account_title': newMethod.accountTitle,
          'account_number': newMethod.accountNumber,
          'iban': newMethod.iban?.trim().isEmpty == true
              ? null
              : newMethod.iban?.trim(),
          'instructions': newMethod.instructions?.trim().isEmpty == true
              ? null
              : newMethod.instructions?.trim(),
          'is_active': newMethod.isActive,
          'created_at': nowIso,
          'updated_at': nowIso,
        });
      } catch (e) {
        debugPrint('AdminPaymentService addPaymentMethod error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        // Continue to add locally so the Admin UI updates reliably
      }
    }

    final updated = List<PlatformPaymentMethodModel>.from(
      paymentMethodsNotifier.value,
    );
    updated.add(newMethod);
    paymentMethodsNotifier.value = updated;
    return _lastError == null;
  }

  /// Updates an existing platform payment method in Supabase and local state.
  Future<bool> updatePaymentMethod(PlatformPaymentMethodModel method) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final updatedMethod = method.copyWith(updatedAt: nowIso);

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && SupabaseHelper.isUuid(method.id)) {
      try {
        await supabase
            .from('platform_payment_methods')
            .update({
              'method_type': updatedMethod.methodType,
              'bank_or_wallet_name': updatedMethod.bankOrWalletName,
              'account_title': updatedMethod.accountTitle,
              'account_number': updatedMethod.accountNumber,
              'iban': updatedMethod.iban?.trim().isEmpty == true
                  ? null
                  : updatedMethod.iban?.trim(),
              'instructions': updatedMethod.instructions?.trim().isEmpty == true
                  ? null
                  : updatedMethod.instructions?.trim(),
              'is_active': updatedMethod.isActive,
              'updated_at': nowIso,
            })
            .eq('id', method.id);
      } catch (e) {
        debugPrint('AdminPaymentService updatePaymentMethod error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    final list = List<PlatformPaymentMethodModel>.from(
      paymentMethodsNotifier.value,
    );
    final idx = list.indexWhere((m) => m.id == method.id);
    if (idx != -1) {
      list[idx] = updatedMethod;
      paymentMethodsNotifier.value = list;
    }
    return _lastError == null;
  }

  /// Toggles active/inactive state of a payment method.
  Future<bool> toggleMethodStatus(String id, bool isActive) async {
    _lastError = null;
    final list = List<PlatformPaymentMethodModel>.from(
      paymentMethodsNotifier.value,
    );
    final idx = list.indexWhere((m) => m.id == id);
    if (idx == -1) return false;

    final updated = list[idx].copyWith(isActive: isActive);
    list[idx] = updated;
    paymentMethodsNotifier.value = list;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && SupabaseHelper.isUuid(id)) {
      try {
        await supabase
            .from('platform_payment_methods')
            .update({
              'is_active': isActive,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
      } catch (e) {
        debugPrint('AdminPaymentService toggleMethodStatus error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }
    return true;
  }

  /// Deletes a payment method permanently.
  Future<bool> deletePaymentMethod(String id) async {
    _lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && SupabaseHelper.isUuid(id)) {
      try {
        await supabase.from('platform_payment_methods').delete().eq('id', id);
      } catch (e) {
        debugPrint('AdminPaymentService deletePaymentMethod error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    final list = List<PlatformPaymentMethodModel>.from(
      paymentMethodsNotifier.value,
    );
    list.removeWhere((m) => m.id == id);
    paymentMethodsNotifier.value = list;
    return _lastError == null;
  }
}
