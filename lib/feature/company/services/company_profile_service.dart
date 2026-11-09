import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';

class CompanyProfileService {
  static final CompanyProfileService _instance =
      CompanyProfileService._internal();

  factory CompanyProfileService() => _instance;

  CompanyProfileService._internal();

  // ValueNotifier for reactive updates across company screens
  final ValueNotifier<CompanyProfileModel> currentProfileNotifier =
      ValueNotifier<CompanyProfileModel>(
    const CompanyProfileModel(
      id: 'comp_01',
      companyName: 'TechVista Innovations',
      industry: 'Software & Cloud Services',
      description:
          'TechVista Innovations is an enterprise software and cloud engineering firm partnering with leading universities to sponsor real-world technical projects and hire top-tier student engineers.',
      officialEmail: 'partnerships@techvistainnovations.com',
      websiteUrl: 'https://techvistainnovations.com',
      contactPersonName: 'Danish Ali Rajpoot',
      phoneNumber: '+92 300 1234567',
      city: 'Islamabad',
      completeAddress:
          'Executive Tech Park, Sector I-9/3, Islamabad, Pakistan',
      logoInitial: 'TV',
      isVerified: true,
      lastUpdated: 'Today at 08:00 PM',
    ),
  );

  CompanyProfileModel get currentProfile => currentProfileNotifier.value;

  Future<void> updateProfile(CompanyProfileModel updated) async {
    // Simulating structured local persistence or backend save
    await Future.delayed(const Duration(milliseconds: 350));
    currentProfileNotifier.value = updated.copyWith(
      lastUpdated: 'Just now',
    );
  }
}

