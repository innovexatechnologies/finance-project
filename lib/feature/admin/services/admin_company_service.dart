import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_company_model.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Enterprise Company Management Service backed by Supabase `companies` & `projects`.
class AdminCompanyService {
  static final AdminCompanyService _instance = AdminCompanyService._internal();
  factory AdminCompanyService() => _instance;

  AdminCompanyService._internal();

  final ValueNotifier<List<AdminCompanyModel>> companiesNotifier =
      ValueNotifier<List<AdminCompanyModel>>([]);

  List<AdminCompanyModel> get allCompanies => companiesNotifier.value;

  int get totalCount => companiesNotifier.value.length;
  int get verifiedCount => companiesNotifier.value
      .where((c) => c.verificationStatus == CompanyVerificationState.verified)
      .length;
  int get pendingCount => companiesNotifier.value
      .where((c) => c.verificationStatus == CompanyVerificationState.pending)
      .length;
  int get rejectedCount => companiesNotifier.value
      .where((c) => c.verificationStatus == CompanyVerificationState.rejected)
      .length;
  int get suspendedCount => companiesNotifier.value
      .where((c) => c.accountStatus == CompanyAccountState.suspended)
      .length;

  /// Fetches live corporate accounts, project counts, and audit records from Supabase.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final rows = await supabase
          .from('companies')
          .select()
          .order('created_at', ascending: false);

      // Count projects per company_id / posted_by
      final Map<String, int> projectCountsByCompany = {};
      final Map<String, int> projectCountsByUser = {};
      try {
        final projRows = await supabase
            .from('projects')
            .select('id, company_id, posted_by, user_id');
        for (final raw in projRows) {
          final p = Map<String, dynamic>.from(raw);
          final cId = p['company_id']?.toString() ?? '';
          final uId = p['posted_by']?.toString() ?? p['user_id']?.toString() ?? '';
          if (cId.isNotEmpty) {
            projectCountsByCompany[cId] = (projectCountsByCompany[cId] ?? 0) + 1;
          }
          if (uId.isNotEmpty) {
            projectCountsByUser[uId] = (projectCountsByUser[uId] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint('AdminCompanyService projects count skipped: $e');
      }

      // Optional audit trail lookup
      final List<Map<String, dynamic>> auditRows = [];
      try {
        final rawLogs = await supabase
            .from('admin_audit_logs')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        for (final r in rawLogs) {
          auditRows.add(Map<String, dynamic>.from(r));
        }
      } catch (_) {}

      final List<AdminCompanyModel> loaded = [];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final userId = row['user_id']?.toString();
        final name = (row['company_name']?.toString().trim().isNotEmpty == true)
            ? row['company_name'].toString().trim()
            : 'Corporate Partner';

        final rawVerif =
            (row['verification_status']?.toString().toLowerCase() ?? 'not_submitted');
        CompanyVerificationState verifState;
        if (rawVerif == 'verified') {
          verifState = CompanyVerificationState.verified;
        } else if (rawVerif == 'rejected') {
          verifState = CompanyVerificationState.rejected;
        } else {
          verifState = CompanyVerificationState.pending;
        }

        final rawAcc = (row['account_status']?.toString().toLowerCase() ?? 'active');
        final accState = rawAcc == 'suspended'
            ? CompanyAccountState.suspended
            : CompanyAccountState.active;

        final createdDt =
            SupabaseHelper.parseDate(row['created_at']) ?? DateTime.now();
        final regDateStr =
            '${createdDt.year}-${createdDt.month.toString().padLeft(2, '0')}-${createdDt.day.toString().padLeft(2, '0')}';

        final matchingLogs = auditRows
            .where((l) {
              final target = l['target']?.toString() ?? '';
              return target == id ||
                  target.toLowerCase() == name.toLowerCase() ||
                  target.toLowerCase() ==
                      (row['email']?.toString().toLowerCase() ?? '');
            })
            .map((l) => CompanyAuditRecord(
                  id: l['id']?.toString() ?? '',
                  action: l['action']?.toString() ?? 'Audit Event',
                  adminName: l['admin_email']?.toString() ?? 'Administrator',
                  timestamp: SupabaseHelper.formatRelativeTime(l['created_at']),
                  note: l['details']?.toString(),
                ))
            .toList();

        final projCount = projectCountsByCompany[id] ??
            (userId != null ? (projectCountsByUser[userId] ?? 0) : 0);

        final evidenceFileName = row['evidence_file_name']?.toString() ?? '';

        loaded.add(
          AdminCompanyModel(
            id: id,
            userId: userId,
            companyName: name,
            logoInitial: (row['logo_initial']?.toString().trim().isNotEmpty == true)
                ? row['logo_initial'].toString().trim()
                : SupabaseHelper.initialsFor(name, fallback: 'CO'),
            officialEmail: row['email']?.toString() ?? '',
            isEmailVerified: row['is_email_verified'] == true,
            industry: (row['industry']?.toString().trim().isNotEmpty == true)
                ? row['industry'].toString().trim()
                : 'General Technology',
            city: (row['city']?.toString().trim().isNotEmpty == true)
                ? row['city'].toString().trim()
                : (row['location']?.toString().trim() ?? ''),
            completeAddress: row['address']?.toString() ?? '',
            contactPersonName: row['contact_person']?.toString() ?? '',
            phoneNumber: row['phone']?.toString() ?? '',
            websiteUrl: row['website']?.toString() ?? '',
            description: row['description']?.toString() ?? '',
            registrationNumber: row['registration_number']?.toString() ?? '',
            verificationStatus: verifState,
            accountStatus: accState,
            registrationDate: regDateStr,
            registrationDateTime: createdDt,
            suspensionReason: row['suspension_reason']?.toString(),
            evidenceFileName: evidenceFileName,
            evidenceFileType: row['evidence_file_type']?.toString() ??
                (evidenceFileName.isNotEmpty
                    ? 'Corporate Evidence'
                    : 'Not Uploaded'),
            evidenceFileSize: row['evidence_file_size']?.toString() ?? '',
            evidenceUrl: row['evidence_url']?.toString(),
            postedProjectsCount: projCount,
            auditHistory: matchingLogs,
          ),
        );
      }

      companiesNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminCompanyService loadFromSupabase error: $e');
    }
  }

  /// Approve Company Verification in Supabase & synchronize Verification Desk cleanly.
  Future<bool> approveCompanyVerification({
    required String companyId,
    required String adminName,
  }) async {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(companyId)) {
      try {
        await supabase.from('companies').update({
          'verification_status': 'verified',
          'reviewer_name': adminName,
          'reviewed_at': nowIso,
          'admin_feedback': null,
          'updated_at': nowIso,
        }).eq('id', companyId);

        if (SupabaseHelper.isUuid(company.userId)) {
          await supabase.from('profiles').update({
            'is_verified': true,
            'updated_at': nowIso,
          }).eq('id', company.userId!);

          await _notifyUser(
            userId: company.userId!,
            title: 'Company Verification Approved',
            message:
                '${company.companyName} has been verified by CampusConnect Administration.',
            type: 'verification',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'COMPANY_VERIFICATION_APPROVED',
          target: company.companyName,
          details: 'Corporate entity approved by $adminName.',
        );
      } catch (e) {
        debugPrint('AdminCompanyService approveCompanyVerification error: $e');
        return false;
      }
    }

    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Approved',
        adminName: adminName,
        timestamp: 'Just now',
        note: 'Corporate credentials authenticated and approved.',
      ),
    );

    list[idx] = company.copyWith(
      verificationStatus: CompanyVerificationState.verified,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    AdminVerificationService().syncVerificationStateLocal(
      companyId: companyId,
      status: VerificationStatus.verified,
      reviewerName: adminName,
      adminFeedback: null,
    );

    if (companyId.isNotEmpty &&
        companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().applyAdminDecision(
        status: VerificationStatus.verified,
        feedback: null,
        reviewerName: adminName,
      );
      CompanyProfileService().currentProfileNotifier.value =
          CompanyProfileService().currentProfile.copyWith(isVerified: true);
    }

    return true;
  }

  /// Reject Company Verification with Mandatory Reason.
  Future<bool> rejectCompanyVerification({
    required String companyId,
    required String reason,
    required String adminName,
  }) async {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(companyId)) {
      try {
        await supabase.from('companies').update({
          'verification_status': 'rejected',
          'reviewer_name': adminName,
          'reviewed_at': nowIso,
          'admin_feedback': reason.trim(),
          'updated_at': nowIso,
        }).eq('id', companyId);

        if (SupabaseHelper.isUuid(company.userId)) {
          await supabase.from('profiles').update({
            'is_verified': false,
            'updated_at': nowIso,
          }).eq('id', company.userId!);

          await _notifyUser(
            userId: company.userId!,
            title: 'Company Verification Rejected',
            message: reason.trim(),
            type: 'verification',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'COMPANY_VERIFICATION_REJECTED',
          target: company.companyName,
          details: reason.trim(),
        );
      } catch (e) {
        debugPrint('AdminCompanyService rejectCompanyVerification error: $e');
        return false;
      }
    }

    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Rejected',
        adminName: adminName,
        timestamp: 'Just now',
        note: reason.trim(),
      ),
    );

    list[idx] = company.copyWith(
      verificationStatus: CompanyVerificationState.rejected,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    AdminVerificationService().syncVerificationStateLocal(
      companyId: companyId,
      status: VerificationStatus.rejected,
      reviewerName: adminName,
      adminFeedback: reason.trim(),
    );

    if (companyId.isNotEmpty &&
        companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().applyAdminDecision(
        status: VerificationStatus.rejected,
        feedback: reason.trim(),
        reviewerName: adminName,
      );
      CompanyProfileService().currentProfileNotifier.value =
          CompanyProfileService().currentProfile.copyWith(isVerified: false);
    }

    return true;
  }

  /// Request Additional Verification Documents.
  Future<bool> requestAdditionalDocuments({
    required String companyId,
    required String instructions,
    required String adminName,
  }) async {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(companyId)) {
      try {
        await supabase.from('companies').update({
          'verification_status': 'pending',
          'admin_feedback': instructions.trim(),
          'reviewer_name': adminName,
          'updated_at': nowIso,
        }).eq('id', companyId);

        if (SupabaseHelper.isUuid(company.userId)) {
          await _notifyUser(
            userId: company.userId!,
            title: 'Additional Verification Documents Requested',
            message: instructions.trim(),
            type: 'verification',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'COMPANY_DOCS_REQUESTED',
          target: company.companyName,
          details: instructions.trim(),
        );
      } catch (e) {
        debugPrint('AdminCompanyService requestAdditionalDocuments error: $e');
        return false;
      }
    }

    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Additional Documents Requested',
        adminName: adminName,
        timestamp: 'Just now',
        note: instructions.trim(),
      ),
    );

    list[idx] = company.copyWith(
      verificationStatus: CompanyVerificationState.pending,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    AdminVerificationService().syncVerificationStateLocal(
      companyId: companyId,
      status: VerificationStatus.pending,
      reviewerName: adminName,
      adminFeedback: instructions.trim(),
    );

    return true;
  }

  /// Suspend Company Account with Mandatory Reason.
  Future<bool> suspendCompanyAccount({
    required String companyId,
    required String reason,
    required String adminName,
  }) async {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(companyId)) {
      try {
        await supabase.from('companies').update({
          'account_status': 'suspended',
          'suspension_reason': reason.trim(),
          'updated_at': nowIso,
        }).eq('id', companyId);

        if (SupabaseHelper.isUuid(company.userId)) {
          await supabase.from('profiles').update({
            'account_status': 'suspended',
            'updated_at': nowIso,
          }).eq('id', company.userId!);

          await _notifyUser(
            userId: company.userId!,
            title: 'Corporate Account Suspended',
            message: reason.trim(),
            type: 'governance',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'COMPANY_SUSPENDED',
          target: company.companyName,
          details: reason.trim(),
        );
      } catch (e) {
        debugPrint('AdminCompanyService suspendCompanyAccount error: $e');
        return false;
      }
    }

    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Suspended',
        adminName: adminName,
        timestamp: 'Just now',
        note: reason.trim(),
      ),
    );

    list[idx] = company.copyWith(
      accountStatus: CompanyAccountState.suspended,
      suspensionReason: reason.trim(),
      auditHistory: history,
    );
    companiesNotifier.value = list;
    return true;
  }

  /// Reactivate Suspended Company Account.
  Future<bool> reactivateCompanyAccount({
    required String companyId,
    required String adminName,
  }) async {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(companyId)) {
      try {
        await supabase.from('companies').update({
          'account_status': 'active',
          'suspension_reason': null,
          'updated_at': nowIso,
        }).eq('id', companyId);

        if (SupabaseHelper.isUuid(company.userId)) {
          await supabase.from('profiles').update({
            'account_status': 'active',
            'updated_at': nowIso,
          }).eq('id', company.userId!);

          await _notifyUser(
            userId: company.userId!,
            title: 'Corporate Account Reactivated',
            message: 'Your corporate account has been restored to active standing.',
            type: 'governance',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'COMPANY_REACTIVATED',
          target: company.companyName,
          details: 'Account reactivated by $adminName.',
        );
      } catch (e) {
        debugPrint('AdminCompanyService reactivateCompanyAccount error: $e');
        return false;
      }
    }

    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Reactivated',
        adminName: adminName,
        timestamp: 'Just now',
        note: 'Corporate account reactivated by administrative governance sign-off.',
      ),
    );

    list[idx] = company.copyWith(
      accountStatus: CompanyAccountState.active,
      clearSuspensionReason: true,
      auditHistory: history,
    );
    companiesNotifier.value = list;
    return true;
  }

  void syncLocalVerificationStatus({
    required String companyId,
    required CompanyVerificationState state,
    String? feedback,
  }) {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(verificationStatus: state);
    companiesNotifier.value = list;
  }

  Future<void> _notifyUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    required String actorName,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null || !SupabaseHelper.isUuid(userId)) return;
    try {
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'actor_name': actorName,
      });
    } catch (e) {
      debugPrint('AdminCompanyService notify error: $e');
    }
  }

  Future<void> _writeAuditLog({
    required String action,
    required String target,
    required String details,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;
    try {
      await supabase.from('admin_audit_logs').insert({
        'admin_email': SupabaseHelper.currentUser?.email ?? 'admin@campusconnect.edu.pk',
        'action': action,
        'target': target,
        'details': details,
      });
    } catch (e) {
      debugPrint('AdminCompanyService audit error: $e');
    }
  }

  /// Export Permitted Company Records to CSV
  String exportCompaniesCsv(List<AdminCompanyModel> companies) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Company Name,Email,Industry,City,Address,Registration Number,Verification Status,Account Status,Registration Date,Projects Count',
    );

    for (final c in companies) {
      buffer.writeln(
        '${c.id},"${c.companyName}","${c.officialEmail}","${c.industry}","${c.city}","${c.completeAddress}","${c.registrationNumber}",${c.verificationStatus.name},${c.accountStatus.name},${c.registrationDate},${c.postedProjectsCount}',
      );
    }
    return buffer.toString();
  }

  void reset() {
    companiesNotifier.value = [];
  }
}
