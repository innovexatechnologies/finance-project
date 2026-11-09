import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/company_settings_model.dart';

class CompanySettingsService {
  static final CompanySettingsService _instance =
      CompanySettingsService._internal();

  factory CompanySettingsService() => _instance;

  CompanySettingsService._internal();

  final ValueNotifier<CompanySettingsModel> settingsNotifier =
      ValueNotifier<CompanySettingsModel>(const CompanySettingsModel());

  CompanySettingsModel get currentSettings => settingsNotifier.value;

  Future<void> updateSettings(CompanySettingsModel updated) async {
    await Future.delayed(const Duration(milliseconds: 150));
    settingsNotifier.value = updated;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    // Verify current password simulation
    if (currentPassword.isEmpty || newPassword.length < 6) {
      return false;
    }
    return true;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Securely clear session tokens / user cache simulation
  }
}

