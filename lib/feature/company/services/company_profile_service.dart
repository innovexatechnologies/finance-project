import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/company/services/company_settings_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

class CompanyProfileService {
  static final CompanyProfileService _instance =
      CompanyProfileService._internal();

  factory CompanyProfileService() => _instance;

  CompanyProfileService._internal();

  static const CompanyProfileModel _emptyProfile = CompanyProfileModel(
    id: '',
    companyName: '',
    industry: 'Software & Cloud Services',
    description: '',
    officialEmail: '',
    websiteUrl: '',
    contactPersonName: '',
    phoneNumber: '',
    city: '',
    completeAddress: '',
    logoInitial: 'CO',
    isVerified: false,
    lastUpdated: 'Recently',
  );

  final ValueNotifier<CompanyProfileModel> currentProfileNotifier =
      ValueNotifier<CompanyProfileModel>(_emptyProfile);

  bool isSuspended = false;
  String? suspensionReason;

  CompanyProfileModel get currentProfile => currentProfileNotifier.value;

  /// Loads the full Company Panel dataset from Supabase cleanly.
  static Future<void> loadAllCompanyPanelData() async {
    await CompanyProfileService().loadFromSupabase();
    await CompanyProjectService().loadFromSupabase();
    await CompanyApplicantService().loadFromSupabase();
    await CompanyAssignmentService().loadFromSupabase();
    await CompanyVerificationService().loadFromSupabase();
    await CompanySettingsService().loadFromSupabase();
    await AppDataService.instance.syncFromSupabase(forceRefresh: true);
  }

  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final profileRow = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .limit(1)
          .maybeSingle();

      var companyRow = await supabase
          .from('companies')
          .select()
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (companyRow == null) {
        final fallbackName = (profileRow?['name']?.toString().trim().isNotEmpty == true)
            ? profileRow!['name'].toString().trim()
            : (user.userMetadata?['name']?.toString().trim() ??
                (user.email?.split('@').first ?? 'Company Partner'));
        final fallbackIndustry =
            (profileRow?['university']?.toString().trim().isNotEmpty == true)
                ? profileRow!['university'].toString().trim()
                : 'Software & Cloud Services';

        final inserted = await supabase
            .from('companies')
            .insert({
              'user_id': user.id,
              'company_name': fallbackName,
              'email': user.email ?? '',
              'industry': fallbackIndustry,
              'verification_status': 'not_submitted',
              'logo_initial': SupabaseHelper.initialsFor(fallbackName, fallback: 'CO'),
            })
            .select()
            .maybeSingle();
        companyRow = inserted;
      }

      if (companyRow != null) {
        final name = (companyRow['company_name']?.toString().trim().isNotEmpty == true)
            ? companyRow['company_name'].toString().trim()
            : (profileRow?['name']?.toString().trim() ?? 'Company Partner');
        final email = (companyRow['email']?.toString().trim().isNotEmpty == true)
            ? companyRow['email'].toString().trim()
            : (user.email ?? '');
        final industry = (companyRow['industry']?.toString().trim().isNotEmpty == true)
            ? companyRow['industry'].toString().trim()
            : 'Software & Cloud Services';
        final city = (companyRow['city']?.toString().trim().isNotEmpty == true)
            ? companyRow['city'].toString().trim()
            : (companyRow['location']?.toString().trim() ?? '');
        final verifStatus =
            (companyRow['verification_status']?.toString().toLowerCase() ?? '');
        isSuspended =
            (companyRow['account_status']?.toString().toLowerCase() ?? '') ==
                    'suspended' ||
                (profileRow?['account_status']?.toString().toLowerCase() ?? '') ==
                    'suspended';
        suspensionReason = companyRow['suspension_reason']?.toString();

        currentProfileNotifier.value = CompanyProfileModel(
          id: companyRow['id']?.toString() ?? '',
          companyName: name,
          industry: industry,
          description: (companyRow['description']?.toString().isNotEmpty == true)
              ? companyRow['description'].toString()
              : (profileRow?['bio']?.toString() ?? ''),
          officialEmail: email,
          websiteUrl: companyRow['website']?.toString() ?? '',
          contactPersonName: companyRow['contact_person']?.toString() ?? '',
          phoneNumber: (companyRow['phone']?.toString().isNotEmpty == true)
              ? companyRow['phone'].toString()
              : (profileRow?['phone']?.toString() ?? ''),
          city: city,
          completeAddress: companyRow['address']?.toString() ?? '',
          logoUrl: companyRow['logo_url']?.toString(),
          logoInitial: (companyRow['logo_initial']?.toString().trim().isNotEmpty == true)
              ? companyRow['logo_initial'].toString().trim()
              : SupabaseHelper.initialsFor(name, fallback: 'CO'),
          isVerified: verifStatus == 'verified',
          lastUpdated: SupabaseHelper.formatRelativeTime(
            companyRow['updated_at'] ?? companyRow['created_at'],
          ),
        );
      }
    } catch (e) {
      debugPrint('CompanyProfileService loadFromSupabase error: $e');
    }
  }

  Future<void> updateProfile(CompanyProfileModel updated) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    final nowIso = DateTime.now().toIso8601String();

    if (supabase != null && user != null) {
      final payload = {
        'user_id': user.id,
        'company_name': updated.companyName.trim(),
        'industry': updated.industry.trim(),
        'description': updated.description.trim(),
        'email': updated.officialEmail.trim(),
        'website': updated.websiteUrl.trim(),
        'contact_person': updated.contactPersonName.trim(),
        'phone': updated.phoneNumber.trim(),
        'city': updated.city.trim(),
        'location': updated.city.trim(),
        'address': updated.completeAddress.trim(),
        'logo_initial': updated.logoInitial.trim(),
        'logo_url': updated.logoUrl,
        'updated_at': nowIso,
      };

      if (SupabaseHelper.isUuid(updated.id)) {
        await supabase.from('companies').update(payload).eq('id', updated.id);
      } else {
        final existing = await supabase
            .from('companies')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (existing != null) {
          await supabase
              .from('companies')
              .update(payload)
              .eq('id', existing['id']);
        } else {
          final created = await supabase
              .from('companies')
              .insert(payload)
              .select('id')
              .maybeSingle();
          if (created != null) {
            updated = updated.copyWith(id: created['id'].toString());
          }
        }
      }

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': updated.companyName.trim(),
        'email': updated.officialEmail.trim(),
        'user_type': 'Company',
        'university': updated.industry.trim(),
        'phone': updated.phoneNumber.trim(),
        'bio': updated.description.trim(),
        'updated_at': nowIso,
      });

      await AppDataService.instance.saveAuthSession(
        role: 'Company',
        email: updated.officialEmail.trim(),
        name: updated.companyName.trim(),
        university: updated.industry.trim(),
        userId: user.id,
      );
    }

    currentProfileNotifier.value = updated.copyWith(
      lastUpdated: 'Just now',
    );
  }

  void reset() {
    isSuspended = false;
    suspensionReason = null;
    currentProfileNotifier.value = _emptyProfile;
  }
}
