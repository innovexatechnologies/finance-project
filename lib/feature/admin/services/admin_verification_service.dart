import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_company_model.dart';
import 'package:link_vibe/feature/admin/models/admin_company_verification_model.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Enterprise Verification Desk Service backed by Supabase `companies` table.
/// Bridges administrative verification actions cleanly with database persistence.
class AdminVerificationService {
  static final AdminVerificationService _instance =
      AdminVerificationService._internal();
  factory AdminVerificationService() => _instance;

  AdminVerificationService._internal();

  final ValueNotifier<List<AdminCompanyVerificationItem>> verificationsNotifier =
      ValueNotifier<List<AdminCompanyVerificationItem>>([]);

  List<AdminCompanyVerificationItem> get allVerifications =>
      verificationsNotifier.value;

  /// Fetches verification requests from Supabase `companies` table.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final rows = await supabase
          .from('companies')
          .select()
          .order('submitted_at', ascending: false);

      final List<AdminCompanyVerificationItem> loaded = [];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final rawStatus =
            (row['verification_status']?.toString().toLowerCase() ?? 'not_submitted');
        VerificationStatus status;
        switch (rawStatus) {
          case 'verified':
            status = VerificationStatus.verified;
            break;
          case 'rejected':
            status = VerificationStatus.rejected;
            break;
          case 'pending':
            status = VerificationStatus.pending;
            break;
          default:
            status = VerificationStatus.notSubmitted;
        }

        // Show companies that have submitted evidence or undergone review (plus any pending)
        final hasEvidence =
            (row['evidence_file_name']?.toString().trim().isNotEmpty == true) ||
                (row['evidence_url']?.toString().trim().isNotEmpty == true);
        if (status == VerificationStatus.notSubmitted && !hasEvidence) {
          continue;
        }

        final compId = row['id']?.toString() ?? '';
        final name = (row['company_name']?.toString().trim().isNotEmpty == true)
            ? row['company_name'].toString().trim()
            : 'Corporate Partner';

        loaded.add(
          AdminCompanyVerificationItem(
            id: 'verif_$compId',
            companyId: compId,
            userId: row['user_id']?.toString(),
            companyName: name,
            logoInitial: (row['logo_initial']?.toString().trim().isNotEmpty == true)
                ? row['logo_initial'].toString().trim()
                : SupabaseHelper.initialsFor(name, fallback: 'CO'),
            industry: (row['industry']?.toString().trim().isNotEmpty == true)
                ? row['industry'].toString().trim()
                : 'General Technology',
            city: (row['city']?.toString().trim().isNotEmpty == true)
                ? row['city'].toString().trim()
                : (row['location']?.toString().trim() ?? ''),
            registrationNumber: row['registration_number']?.toString() ?? '',
            officialEmail: row['email']?.toString() ?? '',
            isEmailVerified: row['is_email_verified'] == true,
            websiteUrl: row['website']?.toString() ?? '',
            documentName: row['evidence_file_name']?.toString() ?? '',
            documentType: row['evidence_file_type']?.toString() ??
                'SECP / Company Registration',
            documentSize: row['evidence_file_size']?.toString() ?? '',
            documentUrl: row['evidence_url']?.toString(),
            status: status == VerificationStatus.notSubmitted
                ? VerificationStatus.pending
                : status,
            submittedAt: row['submitted_at'] != null
                ? SupabaseHelper.formatRelativeTime(row['submitted_at'])
                : SupabaseHelper.formatRelativeTime(row['created_at']),
            reviewedAt: row['reviewed_at'] != null
                ? SupabaseHelper.formatRelativeTime(row['reviewed_at'])
                : null,
            reviewerName: row['reviewer_name']?.toString(),
            adminFeedback: row['admin_feedback']?.toString(),
          ),
        );
      }

      verificationsNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminVerificationService loadFromSupabase error: $e');
    }
  }

  Future<bool> _applyDecision({
    required String verificationId,
    required VerificationStatus nextStatus,
    required String reviewerName,
    String? feedback,
  }) async {
    final currentList =
        List<AdminCompanyVerificationItem>.from(verificationsNotifier.value);
    final index = currentList.indexWhere(
      (i) => i.id == verificationId || i.companyId == verificationId,
    );
    if (index == -1) return false;

    final target = currentList[index];
    final nowIso = DateTime.now().toIso8601String();
    final isApprove = nextStatus == VerificationStatus.verified;
    final cleanFeedback = feedback?.trim();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      if (!SupabaseHelper.isUuid(target.companyId) &&
          !SupabaseHelper.isUuid(target.userId)) {
        return false;
      }
      try {
        final fields = {
          'verification_status': isApprove ? 'verified' : 'rejected',
          'reviewer_name': reviewerName,
          'reviewed_at': nowIso,
          'admin_feedback': isApprove ? null : cleanFeedback,
          'updated_at': nowIso,
        };

        List<dynamic> updated = const [];
        if (SupabaseHelper.isUuid(target.companyId)) {
          updated = await supabase
              .from('companies')
              .update(fields)
              .eq('id', target.companyId)
              .select('id');
        }
        if (updated.isEmpty && SupabaseHelper.isUuid(target.userId)) {
          updated = await supabase
              .from('companies')
              .update(fields)
              .eq('user_id', target.userId!)
              .select('id');
        }
        if (updated.isEmpty) {
          return false;
        }

        if (SupabaseHelper.isUuid(target.userId)) {
          await supabase.from('profiles').update({
            'is_verified': isApprove,
            'updated_at': nowIso,
          }).eq('id', target.userId!);
        }

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@skillbridge.edu.pk',
          'action': isApprove
              ? 'COMPANY_VERIFICATION_APPROVED'
              : 'COMPANY_VERIFICATION_REJECTED',
          'target': target.companyName,
          'details': isApprove
              ? 'Approved corporate verification by $reviewerName.'
              : (cleanFeedback ?? ''),
        });
      } catch (e) {
        debugPrint('AdminVerificationService _applyDecision error: $e');
        return false;
      }
    }

    currentList[index] = target.copyWith(
      status: nextStatus,
      reviewedAt: 'Just now',
      reviewerName: reviewerName,
      adminFeedback: isApprove ? null : cleanFeedback,
      clearAdminFeedback: isApprove,
    );
    verificationsNotifier.value = currentList;

    AdminCompanyService().syncLocalVerificationStatus(
      companyId: target.companyId,
      state: isApprove
          ? CompanyVerificationState.verified
          : CompanyVerificationState.rejected,
      feedback: cleanFeedback,
    );

    if (target.companyId.isNotEmpty &&
        (target.companyId == CompanyProfileService().currentProfile.id ||
            (target.userId != null &&
                target.userId == SupabaseHelper.currentUserId))) {
      CompanyVerificationService().applyAdminDecision(
        status: nextStatus,
        feedback: isApprove ? null : cleanFeedback,
        reviewerName: reviewerName,
      );
      CompanyProfileService().currentProfileNotifier.value =
          CompanyProfileService().currentProfile.copyWith(isVerified: isApprove);
    }

    return true;
  }

  /// Approve a company verification in Supabase & sync in-memory company registry.
  Future<bool> approveCompany({
    required String verificationId,
    required String reviewerName,
  }) =>
      _applyDecision(
        verificationId: verificationId,
        nextStatus: VerificationStatus.verified,
        reviewerName: reviewerName,
      );

  /// Reject a company verification with mandatory feedback in Supabase.
  Future<bool> rejectCompany({
    required String verificationId,
    required String feedback,
    required String reviewerName,
  }) =>
      _applyDecision(
        verificationId: verificationId,
        nextStatus: VerificationStatus.rejected,
        reviewerName: reviewerName,
        feedback: feedback,
      );

  void syncVerificationStateLocal({
    required String companyId,
    required VerificationStatus status,
    String? reviewerName,
    String? adminFeedback,
  }) {
    final currentList =
        List<AdminCompanyVerificationItem>.from(verificationsNotifier.value);
    final idx = currentList.indexWhere((i) => i.companyId == companyId);
    if (idx == -1) return;
    currentList[idx] = currentList[idx].copyWith(
      status: status,
      reviewedAt: 'Just now',
      reviewerName: reviewerName,
      adminFeedback: adminFeedback,
      clearAdminFeedback: adminFeedback == null,
    );
    verificationsNotifier.value = currentList;
  }

  void reset() {
    verificationsNotifier.value = [];
  }
}
