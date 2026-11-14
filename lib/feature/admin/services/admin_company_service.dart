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
  int get activeAccountCount => companiesNotifier.value
      .where((c) => c.accountStatus == CompanyAccountState.active)
      .length;
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

      // Count unique projects per company_id / posted_by
      final Map<String, Set<String>> projectIdsByCompany = {};
      final Map<String, Set<String>> projectIdsByUser = {};
      try {
        final projRows = await supabase
            .from('projects')
            .select('id, company_id, posted_by, user_id');
        for (final raw in projRows) {
          final p = Map<String, dynamic>.from(raw);
          final pId = p['id']?.toString() ?? '';
          final cId = p['company_id']?.toString() ?? '';
          final pBy = p['posted_by']?.toString() ?? '';
          final uId = p['user_id']?.toString() ?? '';
          if (pId.isEmpty) continue;
          if (cId.isNotEmpty) {
            projectIdsByCompany.putIfAbsent(cId, () => <String>{}).add(pId);
          }
          if (pBy.isNotEmpty) {
            projectIdsByUser.putIfAbsent(pBy, () => <String>{}).add(pId);
          }
          if (uId.isNotEmpty) {
            projectIdsByUser.putIfAbsent(uId, () => <String>{}).add(pId);
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

      // Enrich with profiles rows (handles newly registered companies and filters out non-company accounts)
      final Map<String, Map<String, dynamic>> companyProfilesById = {};
      final Map<String, Map<String, dynamic>> allProfilesById = {};
      try {
        final profRows = await supabase.from('profiles').select();
        for (final raw in profRows) {
          final p = Map<String, dynamic>.from(raw);
          final id = p['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          allProfilesById[id] = p;
          final uType = (p['user_type']?.toString() ?? '').trim().toLowerCase();
          if (uType == 'company') {
            companyProfilesById[id] = p;
          }
        }
      } catch (e) {
        debugPrint('AdminCompanyService profiles lookup skipped: $e');
      }

      final Set<String> seenUserIds = {};
      final List<AdminCompanyModel> loaded = [];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final userId = row['user_id']?.toString();
        final mergedProjIds = <String>{
          ...(projectIdsByCompany[id] ?? const <String>{}),
          if (userId != null) ...(projectIdsByUser[userId] ?? const <String>{}),
        };
        final anyProf = userId != null ? allProfilesById[userId] : null;
        final anyRole = (anyProf?['user_type']?.toString() ?? '').trim().toLowerCase();
        if ((anyRole == 'student' || anyRole == 'admin') && mergedProjIds.isEmpty) {
          continue;
        }
        if (userId != null && userId.isNotEmpty) seenUserIds.add(userId);
        final prof = userId != null ? companyProfilesById[userId] : null;
        final rawAcc = (row['account_status']?.toString().trim().toLowerCase() ??
            prof?['account_status']?.toString().trim().toLowerCase() ??
            'active');
        final rawCompanyName = row['company_name']?.toString().trim() ?? '';
        final profName = prof?['name']?.toString().trim() ?? '';
        final name = rawCompanyName.isNotEmpty
            ? rawCompanyName
            : (profName.isNotEmpty ? profName : 'Corporate Partner');
        if (rawAcc == 'deleted' || name.toLowerCase() == 'deleted account') {
          continue;
        }
        final officialEmail = (row['email']?.toString().trim().isNotEmpty == true)
            ? row['email'].toString().trim()
            : (prof?['email']?.toString().trim() ?? '');

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

        final projCount = mergedProjIds.length;

        final evidenceFileName = row['evidence_file_name']?.toString() ?? '';

        loaded.add(
          AdminCompanyModel(
            id: id,
            userId: userId,
            companyName: name,
            logoInitial: (row['logo_initial']?.toString().trim().isNotEmpty == true)
                ? row['logo_initial'].toString().trim()
                : SupabaseHelper.initialsFor(name, fallback: 'CO'),
            officialEmail: officialEmail,
            isEmailVerified:
                row['is_email_verified'] == true || prof?['is_verified'] == true,
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

      // Include any registered company profiles that do not yet have a companies table row
      for (final entry in companyProfilesById.entries) {
        if (seenUserIds.contains(entry.key)) continue;
        final p = entry.value;
        final accRaw = p['account_status']?.toString().trim().toLowerCase() ?? '';
        final rawName = p['name']?.toString().trim() ?? '';
        if (accRaw == 'deleted' || rawName.toLowerCase() == 'deleted account') {
          continue;
        }
        final companyName =
            rawName.isNotEmpty ? rawName : 'Corporate Partner';
        final createdDt =
            SupabaseHelper.parseDate(p['created_at']) ?? DateTime.now();
        final regDateStr =
            '${createdDt.year}-${createdDt.month.toString().padLeft(2, '0')}-${createdDt.day.toString().padLeft(2, '0')}';
        final industry = (p['university']?.toString().trim().isNotEmpty == true)
            ? p['university'].toString().trim()
            : 'General Technology';

        loaded.add(
          AdminCompanyModel(
            id: entry.key,
            userId: entry.key,
            companyName: companyName,
            logoInitial: SupabaseHelper.initialsFor(companyName, fallback: 'CO'),
            officialEmail: p['email']?.toString() ?? '',
            isEmailVerified: p['is_verified'] == true,
            industry: industry,
            city: '',
            completeAddress: '',
            contactPersonName: '',
            phoneNumber: p['phone']?.toString() ?? '',
            websiteUrl: '',
            description: p['bio']?.toString() ?? '',
            registrationNumber: '',
            verificationStatus: p['is_verified'] == true
                ? CompanyVerificationState.verified
                : CompanyVerificationState.pending,
            accountStatus: accRaw == 'suspended'
                ? CompanyAccountState.suspended
                : CompanyAccountState.active,
            registrationDate: regDateStr,
            registrationDateTime: createdDt,
            evidenceFileName: '',
            evidenceFileType: 'Not Uploaded',
            evidenceFileSize: '',
            postedProjectsCount: (projectIdsByUser[entry.key] ?? const <String>{}).length,
            auditHistory: const [],
          ),
        );
      }

      companiesNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminCompanyService loadFromSupabase error: $e');
    }
  }

  /// Shared helper to persist corporate verification or account state to Supabase.
  /// Handles both full `companies` rows and synthesized profile-only companies (`id == userId`).
  Future<({bool ok, String resolvedId})> _persistCompanyUpdate(
    AdminCompanyModel company, {
    required Map<String, dynamic> companyFields,
    Map<String, dynamic>? profileFields,
    required String auditAction,
    required String auditDetails,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      return (ok: true, resolvedId: company.id);
    }

    final effectiveUserId = SupabaseHelper.isUuid(company.userId)
        ? company.userId!
        : (SupabaseHelper.isUuid(company.id) ? company.id : '');

    if (!SupabaseHelper.isUuid(company.id) && effectiveUserId.isEmpty) {
      return (ok: false, resolvedId: company.id);
    }

    try {
      String resolvedId = company.id;
      List<dynamic> updated = const [];

      if (SupabaseHelper.isUuid(company.id) && company.id != effectiveUserId) {
        updated = await supabase
            .from('companies')
            .update(companyFields)
            .eq('id', company.id)
            .select('id');
      }

      if (updated.isEmpty && effectiveUserId.isNotEmpty) {
        updated = await supabase
            .from('companies')
            .update(companyFields)
            .eq('user_id', effectiveUserId)
            .select('id');
      }

      if (updated.isNotEmpty) {
        final firstId = updated.first['id']?.toString() ?? '';
        if (firstId.isNotEmpty) resolvedId = firstId;
      } else if (effectiveUserId.isNotEmpty) {
        final inserted = await supabase
            .from('companies')
            .insert({
              'user_id': effectiveUserId,
              'company_name': company.companyName,
              'email': company.officialEmail,
              'industry': company.industry,
              'city': company.city,
              'location': company.city,
              'address': company.completeAddress,
              'contact_person': company.contactPersonName,
              'phone': company.phoneNumber,
              'website': company.websiteUrl,
              'description': company.description,
              'registration_number': company.registrationNumber,
              'logo_initial': company.logoInitial,
              ...companyFields,
            })
            .select('id')
            .single();
        final newId = inserted['id']?.toString() ?? '';
        if (newId.isNotEmpty) resolvedId = newId;
      } else {
        return (ok: false, resolvedId: company.id);
      }

      if (profileFields != null &&
          profileFields.isNotEmpty &&
          effectiveUserId.isNotEmpty) {
        await supabase
            .from('profiles')
            .update(profileFields)
            .eq('id', effectiveUserId);
      }

      await _writeAuditLog(
        action: auditAction,
        target: company.companyName,
        details: auditDetails,
      );

      return (ok: true, resolvedId: resolvedId);
    } catch (e) {
      debugPrint('AdminCompanyService _persistCompanyUpdate error: $e');
      return (ok: false, resolvedId: company.id);
    }
  }

  /// Approve Company Verification in Supabase & synchronize Verification Desk cleanly.
  Future<bool> approveCompanyVerification({
    required String companyId,
    required String adminName,
  }) async {
    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId || c.userId == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistCompanyUpdate(
      company,
      companyFields: {
        'verification_status': 'verified',
        'reviewer_name': adminName,
        'reviewed_at': nowIso,
        'admin_feedback': null,
        'updated_at': nowIso,
      },
      profileFields: {
        'is_verified': true,
        'updated_at': nowIso,
      },
      auditAction: 'COMPANY_VERIFICATION_APPROVED',
      auditDetails: 'Corporate entity approved by $adminName.',
    );
    if (!persisted.ok) return false;

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
      id: persisted.resolvedId,
      verificationStatus: CompanyVerificationState.verified,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    AdminVerificationService().syncVerificationStateLocal(
      companyId: persisted.resolvedId,
      status: VerificationStatus.verified,
      reviewerName: adminName,
      adminFeedback: null,
    );

    if (persisted.resolvedId.isNotEmpty &&
        (persisted.resolvedId == CompanyProfileService().currentProfile.id ||
            (company.userId != null &&
                company.userId == SupabaseHelper.currentUserId))) {
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
    final idx = list.indexWhere((c) => c.id == companyId || c.userId == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistCompanyUpdate(
      company,
      companyFields: {
        'verification_status': 'rejected',
        'reviewer_name': adminName,
        'reviewed_at': nowIso,
        'admin_feedback': reason.trim(),
        'updated_at': nowIso,
      },
      profileFields: {
        'is_verified': false,
        'updated_at': nowIso,
      },
      auditAction: 'COMPANY_VERIFICATION_REJECTED',
      auditDetails: reason.trim(),
    );
    if (!persisted.ok) return false;

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
      id: persisted.resolvedId,
      verificationStatus: CompanyVerificationState.rejected,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    AdminVerificationService().syncVerificationStateLocal(
      companyId: persisted.resolvedId,
      status: VerificationStatus.rejected,
      reviewerName: adminName,
      adminFeedback: reason.trim(),
    );

    if (persisted.resolvedId.isNotEmpty &&
        (persisted.resolvedId == CompanyProfileService().currentProfile.id ||
            (company.userId != null &&
                company.userId == SupabaseHelper.currentUserId))) {
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
    final idx = list.indexWhere((c) => c.id == companyId || c.userId == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistCompanyUpdate(
      company,
      companyFields: {
        'verification_status': 'pending',
        'admin_feedback': instructions.trim(),
        'reviewer_name': adminName,
        'updated_at': nowIso,
      },
      auditAction: 'COMPANY_DOCS_REQUESTED',
      auditDetails: instructions.trim(),
    );
    if (!persisted.ok) return false;

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
      id: persisted.resolvedId,
      verificationStatus: CompanyVerificationState.pending,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    AdminVerificationService().syncVerificationStateLocal(
      companyId: persisted.resolvedId,
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
    final idx = list.indexWhere((c) => c.id == companyId || c.userId == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistCompanyUpdate(
      company,
      companyFields: {
        'account_status': 'suspended',
        'suspension_reason': reason.trim(),
        'updated_at': nowIso,
      },
      profileFields: {
        'account_status': 'suspended',
        'updated_at': nowIso,
      },
      auditAction: 'COMPANY_SUSPENDED',
      auditDetails: reason.trim(),
    );
    if (!persisted.ok) return false;

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
      id: persisted.resolvedId,
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
    final idx = list.indexWhere((c) => c.id == companyId || c.userId == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistCompanyUpdate(
      company,
      companyFields: {
        'account_status': 'active',
        'suspension_reason': null,
        'updated_at': nowIso,
      },
      profileFields: {
        'account_status': 'active',
        'updated_at': nowIso,
      },
      auditAction: 'COMPANY_REACTIVATED',
      auditDetails: 'Account reactivated by $adminName.',
    );
    if (!persisted.ok) return false;

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
      id: persisted.resolvedId,
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
    final idx = list.indexWhere((c) => c.id == companyId || c.userId == companyId);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(verificationStatus: state);
    companiesNotifier.value = list;
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
        'admin_email': SupabaseHelper.currentUser?.email ?? 'admin@skillbridge.edu.pk',
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
      'ID,Company Name,Email,Industry,City,Address,Registration Number,Account Status,Registration Date,Projects Count',
    );

    for (final c in companies) {
      buffer.writeln(
        '${c.id},"${c.companyName}","${c.officialEmail}","${c.industry}","${c.city}","${c.completeAddress}","${c.registrationNumber}",${c.accountStatus.name},${c.registrationDate},${c.postedProjectsCount}',
      );
    }
    return buffer.toString();
  }

  void reset() {
    companiesNotifier.value = [];
  }
}
