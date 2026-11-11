import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';

/// Enterprise Application Monitoring & Investigation Service backed by Supabase `applications`.
class AdminApplicationMonitoringService {
  static final AdminApplicationMonitoringService _instance =
      AdminApplicationMonitoringService._internal();
  factory AdminApplicationMonitoringService() => _instance;

  AdminApplicationMonitoringService._internal();

  final ValueNotifier<List<AdminApplicationModel>> applicationsNotifier =
      ValueNotifier<List<AdminApplicationModel>>([]);

  List<AdminApplicationModel> get allApplications => applicationsNotifier.value;

  int get totalCount => applicationsNotifier.value.length;
  int get pendingCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.pending)
      .length;
  int get acceptedCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.accepted)
      .length;
  int get rejectedCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.rejected)
      .length;
  int get withdrawnCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.withdrawn)
      .length;
  int get reportedCount => applicationsNotifier.value
      .where((a) => a.reportStatus == ApplicationReportStatus.reported)
      .length;
  int get requiringInvestigationCount => applicationsNotifier.value
      .where((a) =>
          a.reportStatus == ApplicationReportStatus.reported ||
          a.reportStatus == ApplicationReportStatus.underInvestigation)
      .length;

  /// Fetches live applications enriched with project, company, student verification & audit records.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final appRows = await supabase
          .from('applications')
          .select()
          .order('submitted_at', ascending: false);

      // Lookup maps for enrichment
      final Map<String, String> projectCategoryById = {};
      try {
        final projRows = await supabase.from('projects').select('id, category');
        for (final raw in projRows) {
          final id = raw['id']?.toString() ?? '';
          final cat = raw['category']?.toString() ?? '';
          if (id.isNotEmpty && cat.isNotEmpty) {
            projectCategoryById[id] = cat;
          }
        }
      } catch (_) {}

      final Map<String, String> companyLiaisonByNameOrId = {};
      try {
        final compRows = await supabase
            .from('companies')
            .select('id, company_name, contact_person');
        for (final raw in compRows) {
          final id = raw['id']?.toString() ?? '';
          final name = raw['company_name']?.toString().toLowerCase() ?? '';
          final liaison = raw['contact_person']?.toString() ?? '';
          if (liaison.isNotEmpty) {
            if (id.isNotEmpty) companyLiaisonByNameOrId[id] = liaison;
            if (name.isNotEmpty) companyLiaisonByNameOrId[name] = liaison;
          }
        }
      } catch (_) {}

      final Map<String, bool> studentVerifiedByUid = {};
      try {
        final profRows = await supabase
            .from('profiles')
            .select('id, is_verified')
            .ilike('user_type', 'student');
        for (final raw in profRows) {
          final id = raw['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            studentVerifiedByUid[id] = raw['is_verified'] == true;
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

      final List<AdminApplicationModel> loaded = [];
      for (final raw in appRows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final studentUid =
            row['student_id']?.toString() ?? row['user_id']?.toString() ?? '';
        final projId = row['project_id']?.toString() ?? '';
        final compId = row['company_id']?.toString() ?? '';
        final compName =
            row['company_name']?.toString() ?? 'Corporate Partner';

        final rawStatus = (row['status']?.toString() ?? 'Pending').toLowerCase();
        ApplicationWorkflowStatus workflowStatus;
        if (rawStatus == 'accepted' ||
            rawStatus == 'approved' ||
            rawStatus == 'shortlisted' ||
            rawStatus == 'in progress' ||
            rawStatus == 'under review' ||
            rawStatus == 'completed' ||
            rawStatus == 'certified') {
          workflowStatus = ApplicationWorkflowStatus.accepted;
        } else if (rawStatus == 'rejected') {
          workflowStatus = ApplicationWorkflowStatus.rejected;
        } else if (rawStatus == 'withdrawn') {
          workflowStatus = ApplicationWorkflowStatus.withdrawn;
        } else {
          workflowStatus = ApplicationWorkflowStatus.pending;
        }

        final rawReport =
            (row['report_status']?.toString() ?? 'clear').toLowerCase();
        ApplicationReportStatus reportStatus;
        switch (rawReport) {
          case 'reported':
            reportStatus = ApplicationReportStatus.reported;
            break;
          case 'under_investigation':
          case 'underinvestigation':
            reportStatus = ApplicationReportStatus.underInvestigation;
            break;
          case 'resolved':
            reportStatus = ApplicationReportStatus.resolved;
            break;
          case 'dismissed':
            reportStatus = ApplicationReportStatus.dismissed;
            break;
          default:
            reportStatus = ApplicationReportStatus.clear;
        }

        final reportReason = row['report_reason']?.toString() ?? '';
        final flagType = _inferFlagType(reportStatus, reportReason);

        final submittedDt =
            SupabaseHelper.parseDate(row['submitted_at']) ?? DateTime.now();
        final subDateStr =
            '${submittedDt.year}-${submittedDt.month.toString().padLeft(2, '0')}-${submittedDt.day.toString().padLeft(2, '0')}';

        final notesList = <String>[];
        if (row['investigation_notes'] is List) {
          for (final n in (row['investigation_notes'] as List)) {
            if (n.toString().trim().isNotEmpty) {
              notesList.add(n.toString().trim());
            }
          }
        }

        final resumeUrl = row['resume_link']?.toString().trim();
        final submittedWorkUrl = row['submitted_work_url']?.toString().trim();
        final fileName = row['file_name']?.toString().trim() ?? '';
        final resumeDisplay = fileName.isNotEmpty
            ? fileName
            : (resumeUrl != null && resumeUrl.isNotEmpty
                ? (Uri.tryParse(resumeUrl)?.pathSegments.lastWhere(
                          (s) => s.isNotEmpty,
                          orElse: () => 'Submitted_Resume_Link',
                        ) ??
                    'Submitted_Resume_Link')
                : '');

        final history = auditRows
            .where((l) => l['target']?.toString() == id)
            .map((l) => InvestigationRecord(
                  id: l['id']?.toString() ?? '',
                  action: l['action']?.toString() ?? 'Review Event',
                  adminName: l['admin_email']?.toString() ?? 'Administrator',
                  timestamp: SupabaseHelper.formatRelativeTime(l['created_at']),
                  findings: l['details']?.toString(),
                ))
            .toList();

        ApplicationReportDetail? reportDetail;
        if (reportStatus != ApplicationReportStatus.clear &&
            reportReason.isNotEmpty) {
          reportDetail = ApplicationReportDetail(
            reportId: 'REP-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id}',
            reportedBy: row['reported_by']?.toString() ?? compName,
            reporterRole: 'Platform Report',
            reportedDate: SupabaseHelper.formatRelativeTime(
              row['updated_at'] ?? row['submitted_at'],
            ),
            reportCategory: flagType == SuspiciousFlagType.none
                ? 'Compliance Review'
                : _flagLabel(flagType),
            reportExplanation: reportReason,
            severity: reportStatus == ApplicationReportStatus.reported
                ? 'High'
                : 'Medium',
          );
        }

        loaded.add(
          AdminApplicationModel(
            id: id,
            studentId: studentUid,
            studentName: row['student_name']?.toString() ?? 'Student Candidate',
            studentEmail: row['student_email']?.toString() ?? '',
            university: row['university']?.toString() ?? '',
            degree: row['student_degree']?.toString() ?? 'BS Computer Science',
            department:
                row['student_department']?.toString() ?? 'Computer Science',
            semester: row['student_semester']?.toString() ?? '',
            cgpa: (row['student_cgpa'] as num?)?.toDouble() ?? 0.0,
            isEducationVerified: studentVerifiedByUid[studentUid] ?? false,
            projectId: projId,
            projectTitle: row['project_title']?.toString() ?? 'Project',
            projectCategory:
                projectCategoryById[projId] ?? 'General',
            companyId: compId,
            companyName: compName,
            companyLiaison: companyLiaisonByNameOrId[compId] ??
                companyLiaisonByNameOrId[compName.toLowerCase()] ??
                compName,
            submissionDate: subDateStr,
            submissionDateTime: submittedDt,
            workflowStatus: workflowStatus,
            reportStatus: reportStatus,
            flagType: flagType,
            proposalSummary: row['cover_letter']?.toString() ?? '',
            skills: SupabaseHelper.parseStringList(row['skills']),
            resumeFileName: resumeDisplay,
            resumeUrl: (resumeUrl?.isNotEmpty == true) ? resumeUrl : null,
            submittedWorkUrl:
                (submittedWorkUrl?.isNotEmpty == true) ? submittedWorkUrl : null,
            reportDetail: reportDetail,
            investigationNotes: notesList,
            investigationHistory: history,
            isDecisionModifiedByAdmin: false,
            administrativeDecisionNote: row['company_feedback']?.toString(),
          ),
        );
      }

      applicationsNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminApplicationMonitoringService loadFromSupabase error: $e');
    }
  }

  SuspiciousFlagType _inferFlagType(
    ApplicationReportStatus status,
    String reason,
  ) {
    if (status == ApplicationReportStatus.clear ||
        status == ApplicationReportStatus.dismissed) {
      return SuspiciousFlagType.none;
    }
    final lower = reason.toLowerCase();
    if (lower.contains('whatsapp') ||
        lower.contains('off-platform') ||
        lower.contains('payment')) {
      return SuspiciousFlagType.offPlatformSolicitation;
    }
    if (lower.contains('plagiar')) return SuspiciousFlagType.plagiarism;
    if (lower.contains('cgpa') ||
        lower.contains('transcript') ||
        lower.contains('credential')) {
      return SuspiciousFlagType.credentialDiscrepancy;
    }
    if (lower.contains('spam') || lower.contains('bot')) {
      return SuspiciousFlagType.spamApplication;
    }
    if (lower.contains('imperson')) return SuspiciousFlagType.impersonation;
    return status == ApplicationReportStatus.reported ||
            status == ApplicationReportStatus.underInvestigation
        ? SuspiciousFlagType.spamApplication
        : SuspiciousFlagType.none;
  }

  String _flagLabel(SuspiciousFlagType flag) {
    switch (flag) {
      case SuspiciousFlagType.none:
        return 'None';
      case SuspiciousFlagType.spamApplication:
        return 'Spam Submissions';
      case SuspiciousFlagType.credentialDiscrepancy:
        return 'Credential Tampering';
      case SuspiciousFlagType.offPlatformSolicitation:
        return 'Off-Platform Solicitation';
      case SuspiciousFlagType.plagiarism:
        return 'Proposal Plagiarism';
      case SuspiciousFlagType.impersonation:
        return 'Identity Impersonation';
    }
  }

  Future<bool> _persistApplicationUpdate({
    required String applicationId,
    required Map<String, dynamic> fields,
    required String auditAction,
    required String auditDetails,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return true;
    if (!SupabaseHelper.isUuid(applicationId)) return false;

    try {
      final updated = await supabase
          .from('applications')
          .update(fields)
          .eq('id', applicationId)
          .select('id');
      if ((updated as List).isEmpty) return false;

      await supabase.from('admin_audit_logs').insert({
        'admin_email':
            SupabaseHelper.currentUser?.email ?? 'admin@skillbridge.edu.pk',
        'action': auditAction,
        'target': applicationId,
        'details': auditDetails,
      });
      return true;
    } catch (e) {
      debugPrint('AdminApplicationMonitoringService update error ($auditAction): $e');
      return false;
    }
  }

  Future<bool> markCaseUnderInvestigation({
    required String applicationId,
    required String adminName,
    required String initialNote,
  }) async {
    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);
    notes.insert(0, '[$adminName]: ${initialNote.trim()}');

    final ok = await _persistApplicationUpdate(
      applicationId: applicationId,
      fields: {
        'report_status': 'under_investigation',
        'investigation_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      auditAction: 'APPLICATION_INVESTIGATION_STARTED',
      auditDetails: initialNote.trim(),
    );
    if (!ok) return false;

    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Case Marked Under Active Investigation',
        adminName: adminName,
        timestamp: 'Just now',
        note: initialNote.trim(),
      ),
    );

    list[idx] = app.copyWith(
      reportStatus: ApplicationReportStatus.underInvestigation,
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;
    return true;
  }

  Future<bool> recordInvestigationNote({
    required String applicationId,
    required String adminName,
    required String note,
  }) async {
    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);
    notes.insert(0, '[$adminName]: ${note.trim()}');

    final ok = await _persistApplicationUpdate(
      applicationId: applicationId,
      fields: {
        'investigation_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      auditAction: 'APPLICATION_NOTE_RECORDED',
      auditDetails: note.trim(),
    );
    if (!ok) return false;

    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Investigation Note Recorded',
        adminName: adminName,
        timestamp: 'Just now',
        note: note.trim(),
      ),
    );

    list[idx] = app.copyWith(
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;
    return true;
  }

  Future<bool> dismissReport({
    required String applicationId,
    required String adminName,
    required String reason,
  }) async {
    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);
    notes.insert(0, '[$adminName - Dismissal]: ${reason.trim()}');

    final ok = await _persistApplicationUpdate(
      applicationId: applicationId,
      fields: {
        'report_status': 'dismissed',
        'investigation_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      auditAction: 'APPLICATION_REPORT_DISMISSED',
      auditDetails: reason.trim(),
    );
    if (!ok) return false;

    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Report Dismissed (No Policy Violation)',
        adminName: adminName,
        timestamp: 'Just now',
        findings: reason.trim(),
      ),
    );

    list[idx] = app.copyWith(
      reportStatus: ApplicationReportStatus.dismissed,
      flagType: SuspiciousFlagType.none,
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;
    return true;
  }

  Future<bool> resolveReportWithAction({
    required String applicationId,
    required String adminName,
    required String resolutionSummary,
    bool revokeApplication = false,
  }) async {
    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);

    notes.insert(
      0,
      '[$adminName - Resolution]: ${resolutionSummary.trim()}${revokeApplication ? " (Application Administratively Revoked)" : ""}',
    );

    final updatePayload = <String, dynamic>{
      'report_status': 'resolved',
      'investigation_notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (revokeApplication) {
      updatePayload['status'] = 'Rejected';
      updatePayload['company_feedback'] = resolutionSummary.trim();
    }

    final ok = await _persistApplicationUpdate(
      applicationId: applicationId,
      fields: updatePayload,
      auditAction: revokeApplication
          ? 'APPLICATION_REVOKED'
          : 'APPLICATION_REPORT_RESOLVED',
      auditDetails: resolutionSummary.trim(),
    );
    if (!ok) return false;

    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: revokeApplication
            ? 'Investigation Concluded: Application Revoked'
            : 'Investigation Concluded: Action Recorded',
        adminName: adminName,
        timestamp: 'Just now',
        findings: resolutionSummary.trim(),
      ),
    );

    list[idx] = app.copyWith(
      reportStatus: ApplicationReportStatus.resolved,
      workflowStatus: revokeApplication
          ? ApplicationWorkflowStatus.rejected
          : app.workflowStatus,
      isDecisionModifiedByAdmin: revokeApplication,
      administrativeDecisionNote: resolutionSummary.trim(),
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;

    if (revokeApplication) {
      try {
        final applicantService = CompanyApplicantService();
        final compList =
            List<ApplicantModel>.from(applicantService.applicantsNotifier.value);
        final cIdx = compList.indexWhere((a) => a.id == applicationId);
        if (cIdx != -1) {
          compList[cIdx] = compList[cIdx].copyWith(status: 'Rejected');
          applicantService.applicantsNotifier.value = compList;
        }
      } catch (_) {}
    }

    return true;
  }

  String exportApplicationsCsv(List<AdminApplicationModel> applications) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Application ID,Student Name,Email,University,Project Title,Company,Submission Date,Workflow Status,Report Status,Flag Type,Education Verified',
    );

    for (final a in applications) {
      buffer.writeln(
        '${a.id},"${a.studentName}","${a.studentEmail}","${a.university}","${a.projectTitle}","${a.companyName}",${a.submissionDate},${a.workflowStatusDisplay},${a.reportStatusDisplay},${a.flagTypeDisplay},${a.isEducationVerified}',
      );
    }
    return buffer.toString();
  }

  void reset() {
    applicationsNotifier.value = [];
  }
}
