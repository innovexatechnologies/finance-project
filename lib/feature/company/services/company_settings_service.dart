import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/company_settings_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

class CompanySettingsService {
  static final CompanySettingsService _instance =
      CompanySettingsService._internal();

  factory CompanySettingsService() => _instance;

  CompanySettingsService._internal();

  final ValueNotifier<CompanySettingsModel> settingsNotifier =
      ValueNotifier<CompanySettingsModel>(const CompanySettingsModel());

  String? lastError;

  CompanySettingsModel get currentSettings => settingsNotifier.value;

  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final row = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (row != null) {
        final ps = row['privacy_settings'] is Map
            ? Map<String, dynamic>.from(row['privacy_settings'] as Map)
            : <String, dynamic>{};

        settingsNotifier.value = CompanySettingsModel(
          privacyDirectoryVisible: ps['privacy_directory_visible'] ?? true,
          privacyShowContactPerson: ps['privacy_show_contact_person'] ?? true,
          privacyShareAnalytics: ps['privacy_share_analytics'] ?? true,
        );
      }
    } catch (e) {
      debugPrint('CompanySettingsService loadFromSupabase error: $e');
    }
  }

  Future<void> updateSettings(CompanySettingsModel updated) async {
    settingsNotifier.value = updated;

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        await supabase.from('user_settings').upsert({
          'user_id': user.id,
          'privacy_settings': {
            'privacy_directory_visible': updated.privacyDirectoryVisible,
            'privacy_show_contact_person': updated.privacyShowContactPerson,
            'privacy_share_analytics': updated.privacyShareAnalytics,
          },
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('CompanySettingsService updateSettings error: $e');
      }
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastError = null;
    final trimmedNew = newPassword.trim();
    if (currentPassword.isEmpty || trimmedNew.isEmpty) {
      lastError = 'Please enter your current and new password.';
      return false;
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        final email = user.email;
        if (email != null && email.isNotEmpty) {
          SupabaseHelper.beginInteractiveAuth();
          try {
            await supabase.auth.signInWithPassword(
              email: email,
              password: currentPassword,
            );
          } finally {
            SupabaseHelper.endInteractiveAuth();
          }
        }
        await supabase.auth.updateUser(UserAttributes(password: trimmedNew));
        return true;
      } on AuthException catch (e) {
        lastError = e.message;
        return false;
      } catch (e) {
        lastError = e.toString();
        return false;
      }
    }
    return true;
  }

  Future<bool> deleteAccount() async {
    lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    final accountEmail =
        (user?.email ??
                CompanyProfileService().currentProfile.officialEmail)
            .trim()
            .toLowerCase();

    if (supabase != null && user != null) {
      try {
        try {
          final projRows = await supabase
              .from('projects')
              .select('id')
              .or('posted_by.eq.${user.id},user_id.eq.${user.id}');
          final projectIds = List<Map<String, dynamic>>.from(projRows)
              .map((row) => row['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          if (projectIds.isNotEmpty) {
            await supabase
                .from('applications')
                .delete()
                .inFilter('project_id', projectIds);
          }
        } catch (e) {
          debugPrint('Delete applications cleanup skipped: $e');
        }

        try {
          await supabase
              .from('projects')
              .delete()
              .or('posted_by.eq.${user.id},user_id.eq.${user.id}');
        } catch (e) {
          debugPrint('Delete projects cleanup skipped: $e');
        }

        try {
          await supabase.from('companies').delete().eq('user_id', user.id);
        } catch (e) {
          debugPrint('Delete companies cleanup skipped: $e');
        }

        try {
          await supabase
              .from('support_tickets')
              .delete()
              .eq('user_id', user.id);
        } catch (e) {
          debugPrint('Delete support_tickets cleanup skipped: $e');
        }

        try {
          await supabase.from('user_settings').delete().eq('user_id', user.id);
        } catch (e) {
          debugPrint('Delete user_settings cleanup skipped: $e');
        }

        var rpcDeleted = false;
        try {
          await supabase.rpc('delete_user_account');
          rpcDeleted = true;
        } catch (_) {}

        if (!rpcDeleted) {
          try {
            await supabase
                .from('profiles')
                .update({'name': 'Deleted Account', 'bio': '', 'phone': ''})
                .eq('id', user.id);
          } catch (e) {
            debugPrint('Anonymize profile skipped: $e');
          }
        }
      } catch (e) {
        lastError = e.toString();
        return false;
      }
    }

    if (accountEmail.isNotEmpty) {
      await AppDataService.instance.removeUserAccount(accountEmail);
    }
    if (AppDataService.instance.userEmail.isNotEmpty) {
      await AppDataService.instance.removeUserAccount(
        AppDataService.instance.userEmail,
      );
    }

    await logout();
    return true;
  }

  Future<void> logout() async {
    final supabase = SupabaseHelper.clientOrNull;
    try {
      await supabase?.auth.signOut().timeout(const Duration(seconds: 3));
    } catch (_) {}

    SupabaseHelper.clearAuthFlags();
    await AppDataService.instance.clearAuthSession();
    CompanyProfileService().reset();
    CompanyProjectService().reset();
    CompanyApplicantService().reset();
    CompanyAssignmentService().reset();
    CompanyVerificationService().reset();
    reset();
  }

  void reset() {
    lastError = null;
    settingsNotifier.value = const CompanySettingsModel();
  }
}
