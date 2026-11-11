import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';

class CompanyVerificationService {
  static final CompanyVerificationService _instance =
      CompanyVerificationService._internal();

  factory CompanyVerificationService() => _instance;

  CompanyVerificationService._internal();

  static const CompanyVerificationModel _emptyVerification =
      CompanyVerificationModel(
    companyId: '',
    officialEmail: '',
    isEmailVerified: false,
    status: VerificationStatus.notSubmitted,
  );

  final ValueNotifier<CompanyVerificationModel> verificationNotifier =
      ValueNotifier<CompanyVerificationModel>(_emptyVerification);

  CompanyVerificationModel get currentVerification =>
      verificationNotifier.value;

  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final profile = CompanyProfileService().currentProfile;
      final row = await supabase
          .from('companies')
          .select()
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        verificationNotifier.value = CompanyVerificationModel(
          companyId: profile.id,
          officialEmail: profile.officialEmail.isNotEmpty
              ? profile.officialEmail
              : (user.email ?? ''),
          isEmailVerified: user.emailConfirmedAt != null,
          websiteUrl: profile.websiteUrl,
          status: VerificationStatus.notSubmitted,
        );
        return;
      }

      final rawStatus =
          row['verification_status']?.toString().toLowerCase() ?? 'not_submitted';
      VerificationStatus parsedStatus;
      switch (rawStatus) {
        case 'pending':
          parsedStatus = VerificationStatus.pending;
          break;
        case 'verified':
          parsedStatus = VerificationStatus.verified;
          break;
        case 'rejected':
          parsedStatus = VerificationStatus.rejected;
          break;
        default:
          parsedStatus = VerificationStatus.notSubmitted;
      }

      final dbEmail = row['email']?.toString() ?? user.email ?? '';
      final isConfirmed = (row['is_email_verified'] == true) ||
          (user.email != null &&
              dbEmail.toLowerCase() == user.email!.toLowerCase());

      verificationNotifier.value = CompanyVerificationModel(
        companyId: row['id']?.toString() ?? profile.id,
        officialEmail: dbEmail,
        isEmailVerified: isConfirmed,
        businessEvidenceFileName: row['evidence_file_name']?.toString(),
        businessEvidenceType: row['evidence_file_type']?.toString() ??
            'SECP / Company Registration',
        businessEvidenceFileSize: row['evidence_file_size']?.toString(),
        businessEvidenceUrl: row['evidence_url']?.toString(),
        websiteUrl: row['website']?.toString() ?? profile.websiteUrl,
        status: parsedStatus,
        submittedAt: row['submitted_at'] != null
            ? SupabaseHelper.formatRelativeTime(row['submitted_at'])
            : null,
        reviewedAt: row['reviewed_at'] != null
            ? SupabaseHelper.formatRelativeTime(row['reviewed_at'])
            : null,
        adminFeedback: row['admin_feedback']?.toString(),
        reviewerName: row['reviewer_name']?.toString(),
      );
    } catch (e) {
      debugPrint('CompanyVerificationService loadFromSupabase error: $e');
    }
  }

  /// Confirms official domain email against authenticated corporate account or updates contact email.
  Future<bool> confirmOfficialEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return false;

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        await supabase.from('companies').update({
          'email': cleanEmail,
          'is_email_verified': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', user.id);
      } catch (e) {
        debugPrint('CompanyVerificationService confirmOfficialEmail error: $e');
        return false;
      }
    }

    verificationNotifier.value = currentVerification.copyWith(
      officialEmail: cleanEmail,
      isEmailVerified: true,
    );
    return true;
  }

  Future<void> submitVerificationRequest({
    required String? businessEvidenceFileName,
    required String? businessEvidenceType,
    String? businessEvidenceFileSize,
    String? businessEvidenceUrl,
    required String? websiteUrl,
    String? officialEmail,
  }) async {
    final cleanEmail = (officialEmail != null && officialEmail.trim().isNotEmpty)
        ? officialEmail.trim()
        : currentVerification.officialEmail;
    final cleanWebsite = websiteUrl?.trim() ?? '';
    final cleanFile = businessEvidenceFileName?.trim() ?? '';
    final cleanUrl = businessEvidenceUrl?.trim() ?? '';
    final nowIso = DateTime.now().toIso8601String();

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      await supabase.from('companies').update({
        'email': cleanEmail,
        'is_email_verified': true,
        'evidence_file_name': cleanFile.isNotEmpty ? cleanFile : null,
        'evidence_file_type': businessEvidenceType,
        'evidence_file_size': businessEvidenceFileSize,
        'evidence_url': cleanUrl.isNotEmpty ? cleanUrl : null,
        'website': cleanWebsite,
        'verification_status': 'pending',
        'submitted_at': nowIso,
        'admin_feedback': null,
        'reviewed_at': null,
        'updated_at': nowIso,
      }).eq('user_id', user.id);
    }

    verificationNotifier.value = CompanyVerificationModel(
      companyId: currentVerification.companyId,
      officialEmail: cleanEmail,
      isEmailVerified: true,
      businessEvidenceFileName: cleanFile.isNotEmpty ? cleanFile : null,
      businessEvidenceType: businessEvidenceType,
      businessEvidenceFileSize: businessEvidenceFileSize,
      businessEvidenceUrl: cleanUrl.isNotEmpty ? cleanUrl : null,
      websiteUrl: cleanWebsite.isNotEmpty ? cleanWebsite : null,
      status: VerificationStatus.pending,
      submittedAt: 'Just now',
      adminFeedback: null,
      reviewedAt: null,
    );
  }

  Future<void> resubmitVerificationRequest({
    required String? businessEvidenceFileName,
    required String? businessEvidenceType,
    String? businessEvidenceFileSize,
    String? businessEvidenceUrl,
    required String? websiteUrl,
    String? officialEmail,
  }) async {
    await submitVerificationRequest(
      businessEvidenceFileName: businessEvidenceFileName,
      businessEvidenceType: businessEvidenceType,
      businessEvidenceFileSize: businessEvidenceFileSize,
      businessEvidenceUrl: businessEvidenceUrl,
      websiteUrl: websiteUrl,
      officialEmail: officialEmail,
    );
  }

  void applyAdminDecision({
    required VerificationStatus status,
    String? feedback,
    String? reviewerName,
  }) {
    verificationNotifier.value = currentVerification.copyWith(
      status: status,
      reviewedAt: 'Just now',
      adminFeedback: feedback,
      reviewerName: reviewerName ?? 'SkillBridge Governance Admin',
    );
  }

  void reset() {
    verificationNotifier.value = _emptyVerification;
  }
}
