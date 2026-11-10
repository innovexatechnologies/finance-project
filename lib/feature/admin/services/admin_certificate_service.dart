import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_certificate_model.dart';

/// Enterprise Certificate Administration & Verification Service backed by Supabase `certificates`.
class AdminCertificateService {
  static final AdminCertificateService _instance =
      AdminCertificateService._internal();
  factory AdminCertificateService() => _instance;

  AdminCertificateService._internal();

  final ValueNotifier<List<AdminCertificateModel>> certificatesNotifier =
      ValueNotifier<List<AdminCertificateModel>>([]);

  List<AdminCertificateModel> get allCertificates => certificatesNotifier.value;

  int get totalCount => certificatesNotifier.value.length;
  int get issuedCount =>
      certificatesNotifier.value.where((c) => c.isIssued).length;
  int get validCount => certificatesNotifier.value
      .where((c) => c.status == AdminCertificateStatus.valid)
      .length;
  int get revokedCount => certificatesNotifier.value
      .where((c) => c.status == AdminCertificateStatus.revoked)
      .length;
  int get requiringReviewCount => certificatesNotifier.value
      .where((c) => c.status == AdminCertificateStatus.pendingReview)
      .length;

  /// Loads issued credentials from Supabase `certificates` table enriched with project categories.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final rows = await supabase
          .from('certificates')
          .select()
          .order('created_at', ascending: false);

      final Map<String, String> projectCategories = {};
      try {
        final projRows = await supabase.from('projects').select('id, category');
        for (final raw in projRows) {
          final id = raw['id']?.toString() ?? '';
          final cat = raw['category']?.toString() ?? '';
          if (id.isNotEmpty && cat.isNotEmpty) {
            projectCategories[id] = cat;
          }
        }
      } catch (_) {}

      final List<Map<String, dynamic>> auditRows = [];
      try {
        final rawLogs = await supabase
            .from('admin_audit_logs')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        for (final raw in rawLogs) {
          auditRows.add(Map<String, dynamic>.from(raw));
        }
      } catch (_) {}

      final List<AdminCertificateModel> loaded = [];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final credId =
            row['certificate_id']?.toString().trim().isNotEmpty == true
                ? row['certificate_id'].toString().trim()
                : id;

        final rawStatus = (row['status']?.toString().toLowerCase() ?? 'valid');
        AdminCertificateStatus status;
        switch (rawStatus) {
          case 'revoked':
            status = AdminCertificateStatus.revoked;
            break;
          case 'pending_review':
          case 'pending':
          case 'requires_review':
            status = AdminCertificateStatus.pendingReview;
            break;
          case 'draft':
            status = AdminCertificateStatus.draft;
            break;
          default:
            status = AdminCertificateStatus.valid;
        }

        final rawType =
            (row['certificate_type']?.toString().toLowerCase() ?? 'completion');
        CertificateType type;
        switch (rawType) {
          case 'excellence':
            type = CertificateType.excellence;
            break;
          case 'innovation':
            type = CertificateType.innovation;
            break;
          case 'leadership':
            type = CertificateType.leadership;
            break;
          default:
            type = CertificateType.completion;
        }

        final issueDt = SupabaseHelper.parseDate(
              row['issue_date'] ?? row['created_at'],
            ) ??
            DateTime.now();
        final issueDateStr = row['issue_date']?.toString().isNotEmpty == true
            ? row['issue_date'].toString()
            : '${issueDt.year}-${issueDt.month.toString().padLeft(2, '0')}-${issueDt.day.toString().padLeft(2, '0')}';

        final rating = (row['overall_rating'] as num?)?.toDouble() ?? 5.0;
        final projId = row['project_id']?.toString() ?? '';

        final history = auditRows
            .where((l) {
              final target = l['target']?.toString() ?? '';
              return target == id || target == credId;
            })
            .map((l) => CertificateAuditRecord(
                  id: l['id']?.toString() ?? '',
                  action: l['action']?.toString() ?? 'Audit Event',
                  adminName: l['admin_email']?.toString() ?? 'Administrator',
                  timestamp: SupabaseHelper.formatRelativeTime(l['created_at']),
                  reason: l['details']?.toString(),
                ))
            .toList();

        loaded.add(
          AdminCertificateModel(
            id: id,
            credentialId: credId,
            certificateTitle:
                row['certificate_title']?.toString().trim().isNotEmpty == true
                    ? row['certificate_title'].toString().trim()
                    : 'Certificate of Project Completion',
            type: type,
            studentId: row['student_id']?.toString() ?? '',
            studentName: row['student_name']?.toString() ?? 'Student',
            studentUniversity: row['student_university']?.toString() ?? '',
            studentDegree: row['student_degree']?.toString() ?? '',
            projectId: projId,
            projectTitle: row['project_title']?.toString() ?? 'Project',
            projectCategory: projectCategories[projId] ?? 'General',
            companyId: row['company_id']?.toString() ?? '',
            companyName: row['company_name']?.toString().trim().isNotEmpty == true
                ? row['company_name'].toString().trim()
                : (row['issuer']?.toString() ?? 'Corporate Partner'),
            signatoryName: row['signatory_name']?.toString() ?? '',
            signatoryTitle:
                row['signatory_title']?.toString() ?? 'Corporate Partner',
            issueDate: issueDateStr,
            issueDateTime: issueDt,
            status: status,
            cryptographicHash:
                row['cryptographic_hash']?.toString().trim().isNotEmpty == true
                    ? row['cryptographic_hash'].toString().trim()
                    : credId,
            performanceRatings: {
              'Overall Evaluation': rating,
            },
            recommendationLetter: row['recommendation_letter']?.toString() ?? '',
            revocationReason: row['revocation_reason']?.toString(),
            revocationDate:
                status == AdminCertificateStatus.revoked ? 'Recorded' : null,
            revokingAdminName: row['revoking_admin_name']?.toString(),
            verificationHistory: history,
            isIssued: status != AdminCertificateStatus.draft,
            pdfUrl: row['pdf_url']?.toString(),
            verificationUrl: row['verification_url']?.toString(),
          ),
        );
      }

      certificatesNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminCertificateService loadFromSupabase error: $e');
    }
  }

  AdminCertificateModel? verifyCertificate(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final c in certificatesNotifier.value) {
      if (c.id.toLowerCase() == clean ||
          c.credentialId.toLowerCase() == clean ||
          c.cryptographicHash.toLowerCase().contains(clean)) {
        return c;
      }
    }
    return null;
  }

  Future<bool> revokeCertificate({
    required String certificateId,
    required String reason,
    required String adminName,
  }) async {
    final list = List<AdminCertificateModel>.from(certificatesNotifier.value);
    final idx = list.indexWhere(
      (c) => c.id == certificateId || c.credentialId == certificateId,
    );
    if (idx == -1) return false;

    final cert = list[idx];
    final cleanReason = reason.trim();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(cert.id)) {
      try {
        await supabase.from('certificates').update({
          'status': 'revoked',
          'revocation_reason': cleanReason,
          'revoking_admin_name': adminName,
        }).eq('id', cert.id);

        if (SupabaseHelper.isUuid(cert.studentId)) {
          await supabase.from('notifications').insert({
            'user_id': cert.studentId,
            'title': 'Certificate Revoked: ${cert.credentialId}',
            'message': cleanReason,
            'type': 'certificate',
            'actor_name': adminName,
          });
        }

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@campusconnect.edu.pk',
          'action': 'CERTIFICATE_REVOKED',
          'target': cert.credentialId,
          'details': cleanReason,
        });
      } catch (e) {
        debugPrint('revokeCertificate error: $e');
        return false;
      }
    }

    final history = List<CertificateAuditRecord>.from(cert.verificationHistory);
    history.insert(
      0,
      CertificateAuditRecord(
        id: 'aud_cert_rev_${DateTime.now().millisecondsSinceEpoch}',
        action: 'CREDENTIAL REVOKED & NULLIFIED',
        adminName: adminName,
        timestamp: 'Just now',
        reason: cleanReason,
      ),
    );

    final now = DateTime.now();
    list[idx] = cert.copyWith(
      status: AdminCertificateStatus.revoked,
      revocationReason: cleanReason,
      revocationDate:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      revokingAdminName: adminName,
      verificationHistory: history,
    );
    certificatesNotifier.value = list;
    return true;
  }

  Future<bool> markCertificateForReview({
    required String certificateId,
    required String reason,
    required String adminName,
  }) async {
    final list = List<AdminCertificateModel>.from(certificatesNotifier.value);
    final idx = list.indexWhere(
      (c) => c.id == certificateId || c.credentialId == certificateId,
    );
    if (idx == -1) return false;

    final cert = list[idx];
    final cleanReason = reason.trim();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(cert.id)) {
      try {
        await supabase.from('certificates').update({
          'status': 'pending_review',
        }).eq('id', cert.id);

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@campusconnect.edu.pk',
          'action': 'CERTIFICATE_REVIEW_HOLD',
          'target': cert.credentialId,
          'details': cleanReason,
        });
      } catch (e) {
        debugPrint('markCertificateForReview error: $e');
        return false;
      }
    }

    final history = List<CertificateAuditRecord>.from(cert.verificationHistory);
    history.insert(
      0,
      CertificateAuditRecord(
        id: 'aud_cert_hold_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Credential Marked For Review (Verification Hold)',
        adminName: adminName,
        timestamp: 'Just now',
        reason: cleanReason,
      ),
    );

    list[idx] = cert.copyWith(
      status: AdminCertificateStatus.pendingReview,
      verificationHistory: history,
    );
    certificatesNotifier.value = list;
    return true;
  }

  Future<bool> reinstateCertificate({
    required String certificateId,
    required String justification,
    required String adminName,
  }) async {
    final list = List<AdminCertificateModel>.from(certificatesNotifier.value);
    final idx = list.indexWhere(
      (c) => c.id == certificateId || c.credentialId == certificateId,
    );
    if (idx == -1) return false;

    final cert = list[idx];
    final cleanJustification = justification.trim();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(cert.id)) {
      try {
        await supabase.from('certificates').update({
          'status': 'valid',
          'revocation_reason': null,
          'revoking_admin_name': null,
        }).eq('id', cert.id);

        if (SupabaseHelper.isUuid(cert.studentId)) {
          await supabase.from('notifications').insert({
            'user_id': cert.studentId,
            'title': 'Certificate Reinstated: ${cert.credentialId}',
            'message': cleanJustification,
            'type': 'certificate',
            'actor_name': adminName,
          });
        }

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@campusconnect.edu.pk',
          'action': 'CERTIFICATE_REINSTATED',
          'target': cert.credentialId,
          'details': cleanJustification,
        });
      } catch (e) {
        debugPrint('reinstateCertificate error: $e');
        return false;
      }
    }

    final history = List<CertificateAuditRecord>.from(cert.verificationHistory);
    history.insert(
      0,
      CertificateAuditRecord(
        id: 'aud_cert_reinstate_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Credential Reinstated & Authenticity Confirmed',
        adminName: adminName,
        timestamp: 'Just now',
        reason: cleanJustification,
      ),
    );

    list[idx] = cert.copyWith(
      status: AdminCertificateStatus.valid,
      clearRevocation: true,
      verificationHistory: history,
    );
    certificatesNotifier.value = list;
    return true;
  }

  String exportCertificatesCsv(List<AdminCertificateModel> certificates) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Certificate ID,Credential ID,Title,Student Name,University,Degree,Project Title,Company Name,Issue Date,Status,Cryptographic Hash,Revocation Reason',
    );

    for (final c in certificates) {
      buffer.writeln(
        '${c.id},"${c.credentialId}","${c.certificateTitle}","${c.studentName}","${c.studentUniversity}","${c.studentDegree}","${c.projectTitle}","${c.companyName}",${c.issueDate},${c.statusDisplay},"${c.cryptographicHash}","${c.revocationReason ?? ''}"',
      );
    }
    return buffer.toString();
  }

  void reset() {
    certificatesNotifier.value = [];
  }
}
