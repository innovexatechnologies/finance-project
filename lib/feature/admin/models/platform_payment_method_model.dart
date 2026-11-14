import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Supported types for platform payment methods.
class PlatformPaymentMethodType {
  static const String bankAccount = 'Bank Account';
  static const String jazzCash = 'JazzCash';
  static const String easyPaisa = 'EasyPaisa';
  static const String nayapay = 'NayaPay';

  static const List<String> all = [
    bankAccount,
    jazzCash,
    easyPaisa,
    nayapay,
  ];
}

/// Model representing an admin-managed custodial escrow payment account.
class PlatformPaymentMethodModel {
  final String id;
  final String methodType;
  final String bankOrWalletName;
  final String accountTitle;
  final String accountNumber;
  final String? iban;
  final String? instructions;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const PlatformPaymentMethodModel({
    required this.id,
    required this.methodType,
    required this.bankOrWalletName,
    required this.accountTitle,
    required this.accountNumber,
    this.iban,
    this.instructions,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  PlatformPaymentMethodModel copyWith({
    String? id,
    String? methodType,
    String? bankOrWalletName,
    String? accountTitle,
    String? accountNumber,
    String? iban,
    String? instructions,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return PlatformPaymentMethodModel(
      id: id ?? this.id,
      methodType: methodType ?? this.methodType,
      bankOrWalletName: bankOrWalletName ?? this.bankOrWalletName,
      accountTitle: accountTitle ?? this.accountTitle,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PlatformPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PlatformPaymentMethodModel(
      id: (json['id'] ?? '').toString(),
      methodType: (json['method_type'] ?? PlatformPaymentMethodType.bankAccount).toString(),
      bankOrWalletName: (json['bank_or_wallet_name'] ?? '').toString(),
      accountTitle: (json['account_title'] ?? '').toString(),
      accountNumber: (json['account_number'] ?? '').toString(),
      iban: json['iban']?.toString(),
      instructions: json['instructions']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method_type': methodType,
      'bank_or_wallet_name': bankOrWalletName,
      'account_title': accountTitle,
      'account_number': accountNumber,
      'iban': iban,
      'instructions': instructions,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  /// Returns appropriate icon for payment method type.
  IconData get icon {
    switch (methodType) {
      case PlatformPaymentMethodType.bankAccount:
        return Icons.account_balance_rounded;
      case PlatformPaymentMethodType.jazzCash:
        return Icons.phone_android_rounded;
      case PlatformPaymentMethodType.easyPaisa:
        return Icons.payments_rounded;
      case PlatformPaymentMethodType.nayapay:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  /// Returns brand/theme color for the payment method.
  Color get brandColor {
    switch (methodType) {
      case PlatformPaymentMethodType.bankAccount:
        return AppColors.primary;
      case PlatformPaymentMethodType.jazzCash:
        return const Color(0xFFD32F2F); // JazzCash Red
      case PlatformPaymentMethodType.easyPaisa:
        return const Color(0xFF00897B); // EasyPaisa Teal/Green
      case PlatformPaymentMethodType.nayapay:
        return const Color(0xFFFF6D00); // NayaPay Orange
      default:
        return AppColors.primary;
    }
  }
}

