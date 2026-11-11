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

  /// Approve a company verification in Supabase & sync in-memory company registry.
  Future<bool> approveCompany({
    required String verificationId,
    required String reviewerName,
  }) async {
    final currentList =
        List<AdminCompanyVerificationItem>.from(verificationsNotifier.value);
    final index = currentList.indexWhere(
      (i) => i.id == verificationId || i.companyId == verificationId,
    );
    if (index == -1) return false;

    final target = currentList[index];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(target.companyId)) {
      try {
        await supabase.from('companies').update({
          'verification_status': 'verified',
          'reviewer_name': reviewerName,
          'reviewed_at': nowIso,
          'admin_feedback': null,
          'updated_at': nowIso,
        }).eq('id', target.companyId);

        if (SupabaseHelper.isUuid(target.userId)) {
          await supabase.from('profiles').update({
            'is_verified': true,
            'updated_at': nowIso,
          }).eq('id', target.userId!);
        }

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@skillbridge.edu.pk',
          'action': 'COMPANY_VERIFICATION_APPROVED',
          'target': target.companyName,
          'details': 'Approved corporate verification by $reviewerName.',
        });
      } catch (e) {
        debugPrint('AdminVerificationService approveCompany error: $e');
        return false;
      }
    }

    currentList[index] = target.copyWith(
      status: VerificationStatus.verified,
      reviewedAt: 'Just now',
      reviewerName: reviewerName,
      clearAdminFeedback: true,
    );
    verificationsNotifier.value = currentList;

    AdminCompanyService().syncLocalVerificationStatus(
      companyId: target.companyId,
      state: CompanyVerificationState.verified,
    );

    if (target.companyId.isNotEmpty &&
        target.companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().applyAdminDecision(
        status: VerificationStatus.verified,
        feedback: null,
        reviewerName: reviewerName,
      );
      CompanyProfileService().currentProfileNotifier.value =
          CompanyProfileService().currentProfile.copyWith(isVerified: true);
    }

    return true;
  }

  /// Reject a company verification with mandatory feedback in Supabase.
  Future<bool> rejectCompany({
    required String verificationId,
    required String feedback,
    required String reviewerName,
  }) async {
    final currentList =
        List<AdminCompanyVerificationItem>.from(verificationsNotifier.value);
    final index = currentList.indexWhere(
      (i) => i.id == verificationId || i.companyId == verificationId,
    );
    if (index == -1) return false;

    final target = currentList[index];
    final cleanFeedback = feedback.trim();
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(target.companyId)) {
      try {
        await supabase.from('companies').update({
          'verification_status': 'rejected',
          'reviewer_name': reviewerName,
          'reviewed_at': nowIso,
          'admin_feedback': cleanFeedback,
          'updated_at': nowIso,
        }).eq('id', target.companyId);

        if (SupabaseHelper.isUuid(target.userId)) {
          await supabase.from('profiles').update({
            'is_verified': false,
            'updated_at': nowIso,
          }).eq('id', target.userId!);
        }

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@skillbridge.edu.pk',
          'action': 'COMPANY_VERIFICATION_REJECTED',
          'target': target.companyName,
          'details': cleanFeedback,
        });
      } catch (e) {
        debugPrint('AdminVerificationService rejectCompany error: $e');
        return false;
      }
    }

    currentList[index] = target.copyWith(
      status: VerificationStatus.rejected,
      reviewedAt: 'Just now',
      reviewerName: reviewerName,
      adminFeedback: cleanFeedback,
    );
    verificationsNotifier.value = currentList;

    AdminCompanyService().syncLocalVerificationStatus(
      companyId: target.companyId,
      state: CompanyVerificationState.rejected,
      feedback: cleanFeedback,
    );

    if (target.companyId.isNotEmpty &&
        target.companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().applyAdminDecision(
        status: VerificationStatus.rejected,
        feedback: cleanFeedback,
        reviewerName: reviewerName,
      );
      CompanyProfileService().currentProfileNotifier.value =
          CompanyProfileService().currentProfile.copyWith(isVerified: false);
    }

    return true;
  }

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
