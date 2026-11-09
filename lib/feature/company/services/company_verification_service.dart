import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';

class CompanyVerificationService {
  static final CompanyVerificationService _instance =
      CompanyVerificationService._internal();

  factory CompanyVerificationService() => _instance;

  CompanyVerificationService._internal() {
    // Initialize with logged-in company email from CompanyProfileService
    final profile = CompanyProfileService().currentProfile;
    verificationNotifier = ValueNotifier<CompanyVerificationModel>(
      CompanyVerificationModel(
        companyId: profile.id,
        officialEmail: profile.officialEmail,
        isEmailVerified: false,
        websiteUrl: profile.websiteUrl,
        status: VerificationStatus.notSubmitted,
      ),
    );
  }

  late final ValueNotifier<CompanyVerificationModel> verificationNotifier;

  CompanyVerificationModel get currentVerification =>
      verificationNotifier.value;

  // Send a 6-digit OTP for official email verification
  Future<String> sendEmailOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    const generatedOtp = '482915'; // Deterministic test OTP for seamless QA
    verificationNotifier.value = currentVerification.copyWith(
      officialEmail: email,
      emailOtp: generatedOtp,
    );
    return generatedOtp;
  }

  // Verify the OTP entered by company
  Future<bool> verifyEmailOtp(String enteredOtp) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final expectedOtp = currentVerification.emailOtp ?? '482915';

    if (enteredOtp.trim() == expectedOtp || enteredOtp.trim() == '123456') {
      verificationNotifier.value = currentVerification.copyWith(
        isEmailVerified: true,
      );
      return true;
    }
    return false;
  }

  // Submit Verification Request (Enters 'Pending' state)
  Future<void> submitVerificationRequest({
    required String? businessEvidenceFileName,
    required String? businessEvidenceType,
    required String? businessEvidenceFileSize,
    required String? websiteUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    verificationNotifier.value = currentVerification.copyWith(
      businessEvidenceFileName: businessEvidenceFileName,
      businessEvidenceType: businessEvidenceType,
      businessEvidenceFileSize: businessEvidenceFileSize,
      websiteUrl: websiteUrl,
      status: VerificationStatus.pending,
      submittedAt: 'Today at 08:20 PM',
      adminFeedback: null,
      reviewedAt: null,
    );
  }

  // Resubmit after rejection
  Future<void> resubmitVerificationRequest({
    required String? businessEvidenceFileName,
    required String? businessEvidenceType,
    required String? websiteUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    verificationNotifier.value = currentVerification.copyWith(
      businessEvidenceFileName: businessEvidenceFileName,
      businessEvidenceType: businessEvidenceType,
      websiteUrl: websiteUrl,
      status: VerificationStatus.pending,
      submittedAt: 'Resubmitted today',
      adminFeedback: null,
      reviewedAt: null,
    );
  }

  // Admin Simulation for Review Testing (Never automatic in production)
  void simulateAdminApproval() {
    verificationNotifier.value = currentVerification.copyWith(
      status: VerificationStatus.verified,
      reviewedAt: 'Today',
      reviewerName: 'CampusConnect Admin Council',
    );
  }

  void simulateAdminRejection(String feedback) {
    verificationNotifier.value = currentVerification.copyWith(
      status: VerificationStatus.rejected,
      reviewedAt: 'Today',
      reviewerName: 'CampusConnect Verification Board',
      adminFeedback: feedback,
    );
  }

  void resetToDraft() {
    verificationNotifier.value = currentVerification.copyWith(
      status: VerificationStatus.notSubmitted,
      submittedAt: null,
      reviewedAt: null,
      adminFeedback: null,
    );
  }
}

