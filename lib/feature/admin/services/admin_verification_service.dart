import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_company_verification_model.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Enterprise Verification Desk Service
/// Bridges administrative verification actions with corporate panel state.
class AdminVerificationService {
  static final AdminVerificationService _instance =
      AdminVerificationService._internal();
  factory AdminVerificationService() => _instance;

  AdminVerificationService._internal() {
    _initQueue();
    _listenToCompanyVerificationChanges();
  }

  late final ValueNotifier<List<AdminCompanyVerificationItem>>
      verificationsNotifier;

  List<AdminCompanyVerificationItem> get allVerifications =>
      verificationsNotifier.value;

  void _initQueue() {
    final companyProfile = CompanyProfileService().currentProfile;
    final companyVerif = CompanyVerificationService().currentVerification;

    verificationsNotifier =
        ValueNotifier<List<AdminCompanyVerificationItem>>([
      // Primary Logged-in Company (TechVista Innovations)
      AdminCompanyVerificationItem(
        id: 'verif_tv_01',
        companyId: companyProfile.id,
        companyName: companyProfile.companyName,
        logoInitial: companyProfile.logoInitial,
        industry: companyProfile.industry,
        city: companyProfile.city,
        registrationNumber: 'SECP-ISB-2019-9481',
        officialEmail: companyProfile.officialEmail,
        isEmailVerified: companyVerif.isEmailVerified,
        websiteUrl: companyProfile.websiteUrl,
        documentName: companyVerif.businessEvidenceFileName ??
            'SECP_Registration_TechVista_2026.pdf',
        documentType: companyVerif.businessEvidenceType ??
            'SECP / Corporate Certificate',
        documentSize: companyVerif.businessEvidenceFileSize ?? '2.4 MB',
        status: companyVerif.status == VerificationStatus.notSubmitted
            ? VerificationStatus.pending
            : companyVerif.status,
        submittedAt: 'Today at 08:20 PM',
        reviewedAt: companyVerif.reviewedAt,
        reviewerName: companyVerif.reviewerName,
        adminFeedback: companyVerif.adminFeedback,
      ),

      // Additional realistic companies for rich data table testing
      const AdminCompanyVerificationItem(
        id: 'verif_inno_02',
        companyId: 'comp_02',
        companyName: 'Innovexa Cloud Technologies',
        logoInitial: 'IN',
        industry: 'Cloud Infrastructure & DevOps',
        city: 'Lahore',
        registrationNumber: 'SECP-LHR-2021-3829',
        officialEmail: 'compliance@innovexacloud.io',
        isEmailVerified: true,
        websiteUrl: 'https://innovexacloud.io',
        documentName: 'SECP_Form29_Innovexa.pdf',
        documentType: 'SECP Certificate of Incorporation',
        documentSize: '3.1 MB',
        status: VerificationStatus.verified,
        submittedAt: '3 days ago',
        reviewedAt: '2 days ago',
        reviewerName: 'Dr. Tariq Mahmood (SuperAdmin)',
        adminFeedback: null,
      ),

      const AdminCompanyVerificationItem(
        id: 'verif_code_03',
        companyId: 'comp_03',
        companyName: 'CodeCraft Mobile Systems',
        logoInitial: 'CC',
        industry: 'Mobile App Development',
        city: 'Karachi',
        registrationNumber: 'NTN-FBR-7749201-9',
        officialEmail: 'partners@codecraft.com.pk',
        isEmailVerified: true,
        websiteUrl: 'https://codecraft.com.pk',
        documentName: 'FBR_ActiveTaxpayer_NTN.pdf',
        documentType: 'FBR NTN Tax Certificate',
        documentSize: '1.8 MB',
        status: VerificationStatus.pending,
        submittedAt: 'Yesterday at 02:15 PM',
        reviewedAt: null,
        reviewerName: null,
        adminFeedback: null,
      ),

      const AdminCompanyVerificationItem(
        id: 'verif_byte_04',
        companyId: 'comp_04',
        companyName: 'ByteWorks Automation Labs',
        logoInitial: 'BW',
        industry: 'Robotics & Embedded Systems',
        city: 'Peshawar',
        registrationNumber: 'SECP-PEW-2022-1104',
        officialEmail: 'admin@byteworks.org',
        isEmailVerified: false,
        websiteUrl: 'https://byteworks.org',
        documentName: 'Registration_Scan_LowRes.png',
        documentType: 'Business Registration Document',
        documentSize: '840 KB',
        status: VerificationStatus.rejected,
        submittedAt: '5 days ago',
        reviewedAt: '4 days ago',
        reviewerName: 'Syeda Fatima Noor (OpsAdmin)',
        adminFeedback:
            'The uploaded image was illegible and missing the official SECP seal. Please re-upload a high-resolution PDF scan.',
      ),
    ]);
  }

  void _listenToCompanyVerificationChanges() {
    CompanyVerificationService().verificationNotifier.addListener(() {
      final updatedVerif =
          CompanyVerificationService().currentVerification;
      final currentList = List<AdminCompanyVerificationItem>.from(
          verificationsNotifier.value);

      final index =
          currentList.indexWhere((item) => item.companyId == updatedVerif.companyId);
      if (index != -1) {
        currentList[index] = currentList[index].copyWith(
          status: updatedVerif.status,
          reviewedAt: updatedVerif.reviewedAt,
          reviewerName: updatedVerif.reviewerName,
          adminFeedback: updatedVerif.adminFeedback,
          isEmailVerified: updatedVerif.isEmailVerified,
        );
        verificationsNotifier.value = currentList;
      }
    });
  }

  /// Approve a company verification
  Future<bool> approveCompany({
    required String verificationId,
    required String reviewerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final currentList =
        List<AdminCompanyVerificationItem>.from(verificationsNotifier.value);
    final index = currentList.indexWhere((i) => i.id == verificationId);
    if (index == -1) return false;

    final target = currentList[index];
    final updated = target.copyWith(
      status: VerificationStatus.verified,
      reviewedAt: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      reviewerName: reviewerName,
      adminFeedback: null,
    );
    currentList[index] = updated;
    verificationsNotifier.value = currentList;

    // Cross-Panel Synchronization: If comp_01, update company panel service
    if (target.companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().simulateAdminApproval();
      CompanyProfileService().updateProfile(
        CompanyProfileService().currentProfile.copyWith(isVerified: true),
      );
    }

    return true;
  }

  /// Reject a company verification with feedback
  Future<bool> rejectCompany({
    required String verificationId,
    required String feedback,
    required String reviewerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final currentList =
        List<AdminCompanyVerificationItem>.from(verificationsNotifier.value);
    final index = currentList.indexWhere((i) => i.id == verificationId);
    if (index == -1) return false;

    final target = currentList[index];
    final updated = target.copyWith(
      status: VerificationStatus.rejected,
      reviewedAt: 'Today',
      reviewerName: reviewerName,
      adminFeedback: feedback,
    );
    currentList[index] = updated;
    verificationsNotifier.value = currentList;

    // Cross-Panel Synchronization: If comp_01, update company panel service
    if (target.companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().simulateAdminRejection(feedback);
    }

    return true;
  }
}

