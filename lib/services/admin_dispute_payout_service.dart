import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_notification_model.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

/// Assigned Student Disbursal Information Model
class StudentDisbursalDetails {
  final String studentName;
  final String studentEmail;
  final String paymentMethod; // JazzCash, EasyPaisa, or Bank Account
  final String accountNumber;
  final String accountTitle;

  const StudentDisbursalDetails({
    required this.studentName,
    required this.studentEmail,
    required this.paymentMethod,
    required this.accountNumber,
    required this.accountTitle,
  });
}

/// Assigned Company Refund Information Model
class CompanyRefundDetails {
  final String companyName;
  final String companyEmail;
  final String paymentMethod;
  final String accountNumber;
  final String accountTitle;

  const CompanyRefundDetails({
    required this.companyName,
    required this.companyEmail,
    required this.paymentMethod,
    required this.accountNumber,
    required this.accountTitle,
  });
}

/// Pure Service Layer for Admin Escrow Disputes & Payout Execution:
/// - Admin Notifications (Approvals, 5-Day Auto-Releases, Disputes)
/// - Disputed Projects & 3-Way Decisions (100% Student, 100% Refund, 50-50 Split)
/// - Payout Ready Queue & Finalization (TID, Receipt, Complete)
///
/// Strictly isolated from Flutter UI screens.
class AdminDisputePayoutService {
  static final AdminDisputePayoutService _instance =
      AdminDisputePayoutService._internal();
  factory AdminDisputePayoutService() => _instance;
  AdminDisputePayoutService._internal();

  final ValueNotifier<List<AdminNotificationModel>> notificationsNotifier =
      ValueNotifier<List<AdminNotificationModel>>([]);

  final ValueNotifier<List<ProjectModel>> disputedProjectsNotifier =
      ValueNotifier<List<ProjectModel>>([]);

  final ValueNotifier<List<ProjectModel>> payoutReadyProjectsNotifier =
      ValueNotifier<List<ProjectModel>>([]);

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  String? _lastError;
  String? get lastError => _lastError;

  int get unreadNotificationsCount =>
      notificationsNotifier.value.where((n) => !n.isRead).length;

  int get disputedCount => disputedProjectsNotifier.value.length;
  int get payoutReadyCount => payoutReadyProjectsNotifier.value.length;

  /// Fallback demo notifications for offline testing
  static final List<AdminNotificationModel> defaultNotifications = [
    AdminNotificationModel(
      id: 'notif-1',
      projectId: 'proj-demo-1',
      title: 'Dispute Raised [#SB-4092]',
      message:
          'Company raised dispute for Flutter Mobile App. Reason: "Deliverable missing payment gateway integration". Requires Admin decision.',
      notificationType: 'dispute_raised',
      isRead: false,
      createdAt: '10 mins ago',
    ),
    AdminNotificationModel(
      id: 'notif-2',
      projectId: 'proj-demo-2',
      title: '5-Day Auto-Release: AI Dashboard',
      message:
          '5 days passed without company response. System auto-released project. Send PKR 18,000 payout to Student (10% fee: PKR 2,000).',
      notificationType: 'auto_release_5_days',
      isRead: false,
      createdAt: '2 hours ago',
    ),
  ];

  /// 1. Loads Admin Notifications from Supabase.
  Future<List<AdminNotificationModel>> loadNotifications({
    bool forceRefresh = false,
  }) async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      if (notificationsNotifier.value.isEmpty) {
        notificationsNotifier.value = List.from(defaultNotifications);
      }
      isLoadingNotifier.value = false;
      return notificationsNotifier.value;
    }

    try {
      final rows = await supabase
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final list = (rows as List<dynamic>)
          .map((r) =>
              AdminNotificationModel.fromJson(r as Map<String, dynamic>))
          .toList();

      notificationsNotifier.value = list;
      return list;
    } catch (e) {
      debugPrint('AdminDisputePayoutService loadNotifications warning: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      if (notificationsNotifier.value.isEmpty) {
        notificationsNotifier.value = List.from(defaultNotifications);
      }
      return notificationsNotifier.value;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// 2. Marks a notification as read.
  Future<bool> markNotificationAsRead(String id) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && SupabaseHelper.isUuid(id)) {
      try {
        await supabase
            .from('admin_notifications')
            .update({'is_read': true})
            .eq('id', id);
      } catch (e) {
        debugPrint('AdminDisputePayoutService markNotificationAsRead error: $e');
      }
    }

    final list = List<AdminNotificationModel>.from(notificationsNotifier.value);
    final idx = list.indexWhere((n) => n.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isRead: true);
      notificationsNotifier.value = list;
    }
    return true;
  }

  /// 3. Loads disputed projects (status = 'disputed').
  Future<List<ProjectModel>> loadDisputedProjects({
    bool forceRefresh = false,
  }) async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      final local = CompanyProjectService()
          .allProjects
          .where((p) =>
              p.isDisputed ||
              p.status.toLowerCase() == 'rejected' ||
              p.disputeResolution != null ||
              p.payoutType == 'dispute_company_refunded' ||
              p.payoutType == 'dispute_student_awarded')
          .toList();
      disputedProjectsNotifier.value = local;
      isLoadingNotifier.value = false;
      return local;
    }

    try {
      List<dynamic> rows = [];
      try {
        final r = await supabase
            .from('projects')
            .select()
            .or('status.eq.disputed,status.eq.rejected,status.eq.Rejected,status.eq.Disputed,dispute_case_id.not.is.null,payout_type.eq.dispute_student_awarded,payout_type.eq.dispute_company_refunded')
            .order('updated_at', ascending: false);
        rows = (r as List<dynamic>);
      } catch (e1) {
        debugPrint('Safe disputed query 1 notice: $e1. Retrying with basic status...');
        try {
          final r2 = await supabase
              .from('projects')
              .select()
              .or('status.eq.disputed,status.eq.rejected,status.eq.Rejected,status.eq.Disputed')
              .order('updated_at', ascending: false);
          rows = (r2 as List<dynamic>);
        } catch (e2) {
          debugPrint('Safe disputed query 2 error: $e2');
        }
      }

      final list = rows
          .map((r) => ProjectModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      // Ensure any dispute mentioned in admin_notifications is represented
      final disputeNotifs = notificationsNotifier.value
          .where((n) => n.notificationType == 'dispute_raised')
          .toList();

      for (final n in disputeNotifs) {
        final pId = n.projectId.trim();
        if (pId.isEmpty) continue;
        final alreadyListed = list.any((p) => p.id == pId);
        if (!alreadyListed) {
          String? extractedCaseId;
          final caseMatch =
              RegExp(r'\[(#SB-[0-9A-Z]+)\]').firstMatch(n.title);
          if (caseMatch != null) {
            extractedCaseId = caseMatch.group(1);
          }
          String? extractedReason;
          final reasonMatch =
              RegExp(r'Reason:\s*"([^"]+)"').firstMatch(n.message);
          if (reasonMatch != null) {
            extractedReason = reasonMatch.group(1);
          }

          ProjectModel? resolved;
          if (SupabaseHelper.isUuid(pId)) {
            try {
              final pRow = await supabase
                  .from('projects')
                  .select()
                  .eq('id', pId)
                  .maybeSingle();
              if (pRow != null) {
                resolved =
                    ProjectModel.fromJson(Map<String, dynamic>.from(pRow));
              }
            } catch (_) {}
          }

          if (resolved != null) {
            list.add(resolved.copyWith(
              status: 'disputed',
              disputeCaseId: resolved.disputeCaseId ?? extractedCaseId,
              disputeReason: resolved.disputeReason ?? extractedReason,
            ));
          } else {
            String parsedTitle = n.title;
            final colonIdx = parsedTitle.indexOf(':');
            if (colonIdx != -1) {
              parsedTitle = parsedTitle.substring(colonIdx + 1).trim();
            }
            String parsedCompany = 'Company Partner';
            final compMatch =
                RegExp(r'Company\s*\(([^)]+)\)').firstMatch(n.message);
            if (compMatch != null) {
              parsedCompany = compMatch.group(1)?.trim() ?? parsedCompany;
            }

            list.add(ProjectModel(
              id: pId,
              title: parsedTitle.isNotEmpty ? parsedTitle : 'Disputed Project',
              companyName: parsedCompany,
              description:
                  'Company deliverable rejected. Dispute opened for Admin resolution.',
              category: 'Development',
              deadline: 'Flexible',
              status: 'disputed',
              disputeCaseId: extractedCaseId ?? '#SB-DISPUTE',
              disputeReason:
                  extractedReason ?? 'Deliverables rejected by company.',
              escrowAmount: 15000.0,
            ));
          }
        }
      }

      final local = CompanyProjectService()
          .allProjects
          .where((p) =>
              (p.isDisputed ||
                  p.status.toLowerCase() == 'rejected' ||
                  p.disputeResolution != null ||
                  p.payoutType == 'dispute_company_refunded' ||
                  p.payoutType == 'dispute_student_awarded') &&
              !list.any((rem) => rem.id == p.id))
          .toList();

      final combined = [...list, ...local];
      disputedProjectsNotifier.value = combined;
      return combined;
    } catch (e) {
      debugPrint('AdminDisputePayoutService loadDisputedProjects error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      final local = CompanyProjectService()
          .allProjects
          .where((p) =>
              p.isDisputed ||
              p.status.toLowerCase() == 'rejected' ||
              p.disputeResolution != null ||
              p.payoutType == 'dispute_company_refunded' ||
              p.payoutType == 'dispute_student_awarded')
          .toList();
      disputedProjectsNotifier.value = local;
      return local;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// 4. Loads payout-ready projects (status = 'ready_for_payout').
  Future<List<ProjectModel>> loadPayoutReadyProjects({
    bool forceRefresh = false,
  }) async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    final List<ProjectModel> combined = [];
    final Set<String> seenIds = {};
    final Set<String> seenTitles = {};

    void addProjectSafely(ProjectModel p) {
      final tid = p.payoutTransactionId?.trim() ?? '';
      final refTid = p.refundTransactionId?.trim() ?? '';
      if (p.isCancelled || tid.isNotEmpty || refTid.isNotEmpty) return;
      final key = p.id.trim();
      final titleKey = p.title.trim().toLowerCase();
      if (key.isNotEmpty && seenIds.contains(key)) return;
      if (titleKey.isNotEmpty && seenTitles.contains(titleKey)) return;
      if (key.isNotEmpty) seenIds.add(key);
      if (titleKey.isNotEmpty) seenTitles.add(titleKey);
      combined.add(p);
    }

    // 1. Check Supabase 'projects' table
    if (supabase != null) {
      try {
        final rows = await supabase
            .from('projects')
            .select()
            .or('status.eq.ready_for_payout,status.eq.completed,status.eq.approved_by_company')
            .order('updated_at', ascending: false);

        for (final r in (rows as List<dynamic>)) {
          final p = ProjectModel.fromJson(Map<String, dynamic>.from(r));
          if (p.status.toLowerCase() == 'ready_for_payout' ||
              p.status.toLowerCase() == 'approved_by_company' ||
              (p.status.toLowerCase() == 'completed' &&
                  (p.payoutTransactionId == null ||
                      p.payoutTransactionId!.trim().isEmpty))) {
            addProjectSafely(p);
          }
        }
      } catch (e) {
        debugPrint('loadPayoutReadyProjects Supabase projects error: $e');
      }

      // 2. Also check Supabase 'applications' table for company approved deliverables
      try {
        final appRows = await supabase
            .from('applications')
            .select()
            .or('status.eq.ready_for_payout,status.eq.Completed,status.eq.Approved,status.eq.completed,status.eq.approved')
            .order('updated_at', ascending: false);

        for (final raw in (appRows as List<dynamic>)) {
          final r = Map<String, dynamic>.from(raw);
          final tid = (r['payout_transaction_id'] ?? '').toString().trim();
          if (tid.isNotEmpty) continue;

          final pid = (r['project_id'] ?? r['id'] ?? '').toString();
          final title = (r['project_title'] ?? 'Approved Project').toString();
          final student = (r['student_name'] ??
                  r['applicant_name'] ??
                  'Awarded Student')
              .toString();

          if (seenIds.contains(pid) ||
              (title.isNotEmpty && seenTitles.contains(title.trim().toLowerCase()))) {
            continue;
          }

          ProjectModel? resolvedProj;
          if (pid.isNotEmpty && SupabaseHelper.isUuid(pid)) {
            try {
              final pRow = await supabase
                  .from('projects')
                  .select()
                  .eq('id', pid)
                  .maybeSingle();
              if (pRow != null) {
                resolvedProj =
                    ProjectModel.fromJson(Map<String, dynamic>.from(pRow));
              }
            } catch (_) {}
          }

          if (resolvedProj != null) {
            addProjectSafely(resolvedProj.copyWith(
              status: 'ready_for_payout',
              assignedStudent: student,
              escrowAmount: resolvedProj.escrowAmount > 0
                  ? resolvedProj.escrowAmount
                  : 25000.0,
            ));
          } else {
            addProjectSafely(ProjectModel(
              id: pid.isNotEmpty
                  ? pid
                  : 'proj-${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              description:
                  'Company deliverable approved. Ready for student escrow payout.',
              category: 'Development',
              duration: 'Active',
              deadline: 'Flexible',
              status: 'ready_for_payout',
              assignedStudent: student,
              escrowAmount: 25000.0,
              companyName: (r['company_name'] ?? 'Company Partner').toString(),
              payoutType: 'full_student',
              studentPayoutAmount: 22500.0,
              platformCommissionAmount: 2500.0,
            ));
          }
        }
      } catch (e) {
        debugPrint('loadPayoutReadyProjects Supabase applications error: $e');
      }
    }

    // 3. Check CompanyAssignmentService (in-memory assignments where company approved work)
    try {
      final assignments = CompanyAssignmentService().allAssignments;
      for (final a in assignments) {
        final isApproved = a.submissionStatus.toLowerCase() == 'approved' ||
            a.projectStatus.toLowerCase() == 'completed';
        if (!isApproved) continue;

        final existing = CompanyProjectService().allProjects.firstWhere(
          (p) =>
              p.id == a.projectId ||
              (a.projectTitle.isNotEmpty &&
                  p.title.trim().toLowerCase() ==
                      a.projectTitle.trim().toLowerCase()),
          orElse: () => ProjectModel(
            id: a.projectId.isNotEmpty ? a.projectId : 'proj-${a.id}',
            title: a.projectTitle,
            description: 'Corporate deliverable approved by company.',
            category: a.projectCategory,
            duration: 'Active',
            deadline: a.deadline.isNotEmpty ? a.deadline : 'Flexible',
            status: 'ready_for_payout',
            assignedStudent: a.studentName,
            escrowAmount: 25000.0,
            companyName: 'Company Partner',
            payoutType: 'full_student',
          ),
        );

        addProjectSafely(existing.copyWith(
          status: 'ready_for_payout',
          assignedStudent: a.studentName,
          escrowAmount:
              existing.escrowAmount > 0 ? existing.escrowAmount : 25000.0,
        ));
      }
    } catch (_) {}

    // 4. Check AppDataService applications
    try {
      final appDataApps = AppDataService.instance.getApplications();
      for (final app in appDataApps) {
        final s = (app['status'] ?? '').toString().toLowerCase();
        final isAppr = app['isApprovedByCompany'] == true ||
            s == 'ready_for_payout' ||
            s == 'completed' ||
            s == 'approved';
        final isPaid = app['isPaidByAdmin'] == true ||
            (app['payout_transaction_id'] != null &&
                app['payout_transaction_id'].toString().trim().isNotEmpty);

        if (isAppr && !isPaid) {
          final pId =
              app['projectId']?.toString() ?? app['id']?.toString() ?? '';
          final title = app['title']?.toString() ??
              app['projectTitle']?.toString() ??
              'Project';
          final student = app['studentName']?.toString() ??
              app['applicantName']?.toString() ??
              'Awarded Student';
          double amt = 25000.0;
          if (app['escrowAmount'] is num && app['escrowAmount'] > 0) {
            amt = (app['escrowAmount'] as num).toDouble();
          }

          addProjectSafely(ProjectModel(
            id: pId.isNotEmpty
                ? pId
                : 'proj-${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            description: 'Approved by company. Pending student payout.',
            category: app['category']?.toString() ?? 'Development',
            duration: 'Active',
            deadline: 'Flexible',
            status: 'ready_for_payout',
            assignedStudent: student,
            escrowAmount: amt,
            companyName: app['companyName']?.toString() ?? 'Company Partner',
            payoutType: 'full_student',
          ));
        }
      }
    } catch (_) {}

    // 5. Check in-memory CompanyProjectService
    final local = CompanyProjectService().allProjects;
    for (final p in local) {
      if (p.isReadyForPayout) {
        addProjectSafely(p);
      }
    }

    payoutReadyProjectsNotifier.value = combined;
    isLoadingNotifier.value = false;
    return combined;
  }

  /// 5. Applies Admin 3-Way Dispute Decision:
  /// - `full_student`: 100% Release to Student (10% fee: PKR [commission], 90% net student: PKR [studentPayout])
  /// - `full_company_refund`: 100% Refund to Company (Refund: PKR [escrow], Student: 0)
  /// - `split_50_50`: 50-50 Split (10% fee, 45% student, 45% company refund)
  ///
  /// Transitions project status to 'ready_for_payout'.
  Future<bool> resolveDisputeDecision({
    required String projectId,
    required String decisionType, // 'full_student', 'full_company_refund', 'split_50_50'
    String? adminNotes,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    // Find project to get escrow amount and title
    ProjectModel? existing;
    for (final p in disputedProjectsNotifier.value) {
      if (p.id == projectId) {
        existing = p;
        break;
      }
    }
    if (existing == null) {
      for (final p in payoutReadyProjectsNotifier.value) {
        if (p.id == projectId) {
          existing = p;
          break;
        }
      }
    }
    if (existing == null) {
      for (final p in CompanyProjectService().allProjects) {
        if (p.id == projectId) {
          existing = p;
          break;
        }
      }
    }

    double escrow = (existing != null && existing.escrowAmount > 0)
        ? existing.escrowAmount
        : 0.0;
    String projectTitle = existing?.title ?? 'Project';

    if (escrow <= 0 && supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        final r = await supabase
            .from('projects')
            .select('title, escrow_amount')
            .eq('id', projectId)
            .maybeSingle();
        if (r != null) {
          final amt = (r['escrow_amount'] as num?)?.toDouble();
          if (amt != null && amt > 0) escrow = amt;
          if (r['title'] != null) projectTitle = r['title'].toString();
        }
      } catch (_) {}
    }
    if (escrow <= 0) escrow = 10000.0;

    double commission = 0.0;
    double studentPayout = 0.0;
    double companyRefund = 0.0;

    if (decisionType == 'full_student') {
      commission = double.parse((escrow * 0.10).toStringAsFixed(2));
      studentPayout = double.parse((escrow - commission).toStringAsFixed(2));
      companyRefund = 0.00;
    } else if (decisionType == 'full_company_refund') {
      commission = 0.00;
      studentPayout = 0.00;
      companyRefund = escrow;
    } else if (decisionType == 'split_50_50') {
      commission = double.parse((escrow * 0.10).toStringAsFixed(2));
      final netDistributable = escrow - commission;
      studentPayout = double.parse((netDistributable / 2).toStringAsFixed(2));
      companyRefund = double.parse((netDistributable / 2).toStringAsFixed(2));
    }

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'ready_for_payout',
              'payout_type': decisionType,
              'platform_commission_amount': commission,
              'student_payout_amount': studentPayout,
              'company_refund_amount': companyRefund,
              'updated_at': nowIso,
              if (adminNotes != null && adminNotes.trim().isNotEmpty)
                'additional_instructions': 'Admin Resolution Note: ${adminNotes.trim()}',
            })
            .eq('id', projectId);

        // Record resolution alert
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Dispute Resolved: $projectTitle',
          'message':
              'Decision "$decisionType" applied. Student Payout: PKR $studentPayout, Company Refund: PKR $companyRefund, Platform Fee: PKR $commission.',
          'notification_type': 'payout_ready',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('AdminDisputePayoutService resolveDisputeDecision error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Remove from disputed queue
    final dList = List<ProjectModel>.from(disputedProjectsNotifier.value);
    dList.removeWhere((p) => p.id == projectId);
    disputedProjectsNotifier.value = dList;

    final updatedModel = (existing ??
            ProjectModel(
              id: projectId,
              title: projectTitle,
              description: 'Project',
              companyName: 'Company',
              category: 'General',
              deadline: 'Flexible',
              status: 'ready_for_payout',
            ))
        .copyWith(
      status: 'ready_for_payout',
      payoutType: decisionType,
      platformCommissionAmount: commission,
      studentPayoutAmount: studentPayout,
      companyRefundAmount: companyRefund,
    );

    // Add or update in payout-ready queue
    final pList = List<ProjectModel>.from(payoutReadyProjectsNotifier.value);
    pList.removeWhere((p) => p.id == projectId);
    pList.insert(0, updatedModel);
    payoutReadyProjectsNotifier.value = pList;

    // Sync into CompanyProjectService
    _syncCompanyService(projectId, 'ready_for_payout');

    return true;
  }

  /// Fetches the assigned student's banking/wallet credentials for Admin payout execution.
  Future<StudentDisbursalDetails> getStudentDisbursalDetails(
    ProjectModel project,
  ) async {
    final supabase = SupabaseHelper.clientOrNull;
    String name = project.assignedStudent?.trim().isNotEmpty == true
        ? project.assignedStudent!.trim()
        : 'Awarded Student';
    String email = 'student@skillbridge.edu';
    String method = 'JazzCash Mobile Account';
    String accountNum = '0300-1234567';
    String accountTitle = name;

    // Check CompanyAssignmentService
    try {
      final assignments = CompanyAssignmentService().allAssignments;
      final a = assignments.firstWhere(
        (a) =>
            a.projectId == project.id ||
            (project.title.isNotEmpty &&
                a.projectTitle.trim().toLowerCase() ==
                    project.title.trim().toLowerCase()),
      );
      if (a.studentName.trim().isNotEmpty) {
        name = a.studentName.trim();
        accountTitle = name;
      }
    } catch (_) {}

    // Check CompanyApplicantService
    try {
      final applicants = CompanyApplicantService().allApplicants;
      final applicant = applicants.firstWhere(
        (ap) =>
            ap.projectId == project.id ||
            (project.title.isNotEmpty &&
                ap.projectTitle.trim().toLowerCase() ==
                    project.title.trim().toLowerCase()) ||
            ap.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
      if (applicant.name.trim().isNotEmpty) {
        name = applicant.name.trim();
        accountTitle = name;
      }
      if (applicant.email.trim().isNotEmpty) {
        email = applicant.email.trim();
      }
    } catch (_) {}

    // Check AppDataService applications
    try {
      final apps = AppDataService.instance.getApplications();
      for (final app in apps) {
        final pId =
            app['projectId']?.toString() ?? app['id']?.toString() ?? '';
        final appTitle = (app['title'] ?? app['projectTitle'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (pId == project.id ||
            (project.title.isNotEmpty &&
                appTitle == project.title.trim().toLowerCase())) {
          final sName = app['studentName']?.toString() ??
              app['applicantName']?.toString();
          if (sName != null && sName.trim().isNotEmpty) {
            name = sName.trim();
            accountTitle = name;
          }
          final sEmail =
              app['studentEmail']?.toString() ?? app['email']?.toString();
          if (sEmail != null && sEmail.trim().isNotEmpty) {
            email = sEmail.trim();
          }
          final pm = app['paymentMethod'] ?? app['payment_method'];
          if (pm != null && pm.toString().trim().isNotEmpty) {
            method = pm.toString().trim();
          }
          final acc = app['accountNumber'] ?? app['account_number'];
          if (acc != null && acc.toString().trim().isNotEmpty) {
            accountNum = acc.toString().trim();
          }
          final at = app['accountTitle'] ?? app['account_title'];
          if (at != null && at.toString().trim().isNotEmpty) {
            accountTitle = at.toString().trim();
          }
          break;
        }
      }
    } catch (_) {}

    // Check Supabase applications & payment methods
    if (supabase != null) {
      try {
        final query = SupabaseHelper.isUuid(project.id)
            ? supabase
                .from('applications')
                .select(
                    'student_id, student_name, student_email, applicant_name, applicant_email, payment_method, account_number, account_title, status')
                .eq('project_id', project.id)
                .limit(10)
            : supabase
                .from('applications')
                .select(
                    'student_id, student_name, student_email, applicant_name, applicant_email, payment_method, account_number, account_title, status')
                .eq('project_title', project.title)
                .limit(10);

        final appRows = await query;
        if (appRows.isNotEmpty) {
          final accepted = (appRows as List<dynamic>).firstWhere(
            (r) {
              final s = (r['status'] ?? '').toString().toLowerCase();
              return s == 'accepted' ||
                  s == 'in progress' ||
                  s == 'in_progress' ||
                  s == 'delivered' ||
                  s == 'ready_for_payout' ||
                  s == 'completed';
            },
            orElse: () => appRows.first,
          );

          final candidateName =
              accepted['student_name'] ?? accepted['applicant_name'];
          if (candidateName != null &&
              candidateName.toString().trim().isNotEmpty) {
            name = candidateName.toString().trim();
          }

          final candidateEmail =
              accepted['student_email'] ?? accepted['applicant_email'];
          if (candidateEmail != null &&
              candidateEmail.toString().trim().isNotEmpty) {
            email = candidateEmail.toString().trim();
          }

          if (accepted['payment_method'] != null &&
              accepted['payment_method'].toString().trim().isNotEmpty) {
            method = accepted['payment_method'].toString().trim();
          }
          if (accepted['account_number'] != null &&
              accepted['account_number'].toString().trim().isNotEmpty) {
            accountNum = accepted['account_number'].toString().trim();
          }
          if (accepted['account_title'] != null &&
              accepted['account_title'].toString().trim().isNotEmpty) {
            accountTitle = accepted['account_title'].toString().trim();
          }

          final studentId = accepted['student_id']?.toString();
          if (studentId != null && SupabaseHelper.isUuid(studentId)) {
            try {
              final pmRows = await supabase
                  .from('student_payment_methods')
                  .select()
                  .or('user_id.eq.$studentId,student_id.eq.$studentId')
                  .order('updated_at', ascending: false)
                  .limit(1);

              if (pmRows.isNotEmpty) {
                final pm = pmRows.first;
                method = (pm['bank_name'] ??
                        pm['provider'] ??
                        pm['method_type'] ??
                        method)
                    .toString();
                accountNum = (pm['account_number_iban'] ??
                        pm['account_number'] ??
                        pm['iban'] ??
                        accountNum)
                    .toString();
                accountTitle = (pm['account_title'] ?? name).toString();
              }
            } catch (_) {}

            try {
              final prof = await supabase
                  .from('profiles')
                  .select('full_name, email')
                  .eq('id', studentId)
                  .maybeSingle();

              if (prof != null) {
                if (prof['full_name'] != null &&
                    prof['full_name'].toString().trim().isNotEmpty) {
                  name = prof['full_name'].toString().trim();
                }
                if (prof['email'] != null &&
                    prof['email'].toString().trim().isNotEmpty) {
                  email = prof['email'].toString().trim();
                }
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('getStudentDisbursalDetails query warning: $e');
      }
    }

    // Local cached student payment method fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final localProvider = prefs.getString('student_payment_provider');
      final localAccount = prefs.getString('student_payment_account');
      final localTitle = prefs.getString('student_payment_title');
      if (localAccount != null && localAccount.trim().isNotEmpty) {
        accountNum = localAccount.trim();
        method = localProvider ?? method;
        if (localTitle != null && localTitle.trim().isNotEmpty) {
          accountTitle = localTitle.trim();
        }
      }
    } catch (_) {}

    if (accountTitle.isEmpty || accountTitle == 'Awarded Student') {
      accountTitle = name;
    }

    return StudentDisbursalDetails(
      studentName: name,
      studentEmail: email,
      paymentMethod: method,
      accountNumber: accountNum,
      accountTitle: accountTitle,
    );
  }

  /// Fetches Company Refund bank / wallet information for escrow dispute refund.
  Future<CompanyRefundDetails> getCompanyRefundDetails(ProjectModel project) async {
    String name = project.companyName.trim().isNotEmpty
        ? project.companyName.trim()
        : 'Corporate Partner';
    String email = 'company@partner.com';
    String method = 'Bank Account';
    String accountNum = 'PK36MEZN0009876543210123';
    String accountTitle = name;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      try {
        final compId = project.companyId.isNotEmpty ? project.companyId : project.id;
        final pmRows = await supabase
            .from('company_payment_methods')
            .select()
            .or('user_id.eq.$compId,company_id.eq.$compId')
            .order('updated_at', ascending: false)
            .limit(1);

        if (pmRows.isNotEmpty) {
          final pm = pmRows.first;
          method = (pm['provider'] ?? method).toString();
          accountNum = (pm['account_number'] ?? accountNum).toString();
          accountTitle = (pm['account_title'] ?? name).toString();
        }
      } catch (e) {
        debugPrint('getCompanyRefundDetails query warning: $e');
      }
    }

    // Local cached company payment method fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final localProvider = prefs.getString('company_payment_provider');
      final localAccount = prefs.getString('company_payment_account');
      final localTitle = prefs.getString('company_payment_title');
      if (localAccount != null && localAccount.trim().isNotEmpty) {
        accountNum = localAccount.trim();
        method = localProvider ?? method;
        if (localTitle != null && localTitle.trim().isNotEmpty) {
          accountTitle = localTitle.trim();
        }
      }
    } catch (_) {}

    return CompanyRefundDetails(
      companyName: name,
      companyEmail: email,
      paymentMethod: method,
      accountNumber: accountNum,
      accountTitle: accountTitle,
    );
  }

  /// Admin Option 1: Pays Student, marks status as 'completed' / 'paid',
  /// immediately converts Student's rejected status to Paid, and notifies both parties.
  Future<bool> executeDisputePayToStudent({
    required String projectId,
    required String transactionId,
    String? receiptUrl,
    String? notes,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;
    final tid = transactionId.trim();

    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    double escrow = 0.0;
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      projectTitle = p.title;
      escrow = p.escrowAmount;
    } catch (_) {}

    if (escrow <= 0) {
      try {
        final allP = AppDataService.instance.getAllProjects();
        final raw = allP.firstWhere(
          (e) => (e['id'] ?? e['projectId'])?.toString() == projectId,
        );
        final amt = raw['escrow_amount'] ??
            raw['escrowAmount'] ??
            raw['budgetAmount'] ??
            raw['budget'] ??
            raw['stipend'];
        if (amt is num && amt > 0) escrow = amt.toDouble();
        if (amt != null && escrow <= 0) {
          final cl = amt.toString().replaceAll(RegExp(r'[^0-9.]'), '');
          final d = double.tryParse(cl);
          if (d != null && d > 0) escrow = d;
        }
      } catch (_) {}
    }
    if (escrow <= 0) escrow = 25000.0;
    final commission10 = double.parse((escrow * 0.10).toStringAsFixed(2));
    final netStudent = double.parse((escrow * 0.90).toStringAsFixed(2));

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        final projUpdate = <String, dynamic>{
          'status': 'completed',
          'payout_type': 'dispute_student_awarded',
          'student_payout_amount': netStudent,
          'platform_commission_amount': commission10,
          'company_refund_amount': 0.00,
          'payout_transaction_id': tid,
          'completed_at': nowIso,
          'updated_at': nowIso,
          'additional_instructions':
              'Dispute Resolved: Paid to Student (TID: $tid)',
        };
        if (receiptUrl != null && receiptUrl.trim().isNotEmpty) {
          projUpdate['payout_receipt_url'] = receiptUrl.trim();
        }

        await supabase
            .from('projects')
            .update(projUpdate)
            .eq('id', projectId);

        try {
          await supabase
              .from('applications')
              .update({
                'status': 'Completed',
                'company_feedback':
                    'Dispute Resolved: Admin awarded payment to student (TID: $tid). Status: Paid.',
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (eApp) {
          debugPrint('executeDisputePayToStudent applications update notice: $eApp');
        }

        // Notify both parties
        try {
          await supabase.from('admin_notifications').insert({
            'project_id': projectId,
            'title': 'Dispute Resolved: Payment Sent to Student ($projectTitle)',
            'message':
                'SkillBridge administration sent payment to student (TID: $tid) for "$projectTitle". Company notified that student was paid. Student status updated to Paid.',
            'notification_type': 'payout_completed',
            'is_read': false,
            'created_at': nowIso,
          });
        } catch (eNotif) {
          debugPrint('admin_notifications insert error: $eNotif');
        }
      } catch (e) {
        debugPrint('executeDisputePayToStudent error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // Synchronize AppDataService for Student and Company
    await AppDataService.instance.recordDisbursedPayout(
      projectId: projectId,
      transactionId: tid,
      receiptUrl: receiptUrl,
    );

    // Update in-memory CompanyProjectService
    final compList = List<ProjectModel>.from(CompanyProjectService().allProjects);
    final cIdx = compList.indexWhere((p) => p.id == projectId);
    if (cIdx != -1) {
      compList[cIdx] = compList[cIdx].copyWith(
        status: 'completed',
        paymentStatus: 'paid',
        payoutTransactionId: tid,
        payoutReceiptUrl: receiptUrl,
        payoutType: 'dispute_student_awarded',
        disputeResolution: 'paid_to_student',
        studentPayoutAmount: netStudent,
        platformCommissionAmount: commission10,
        companyRefundAmount: 0.00,
      );
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // Update in-memory CompanyAssignmentService (moves to Approved / Completed on Deliverables)
    try {
      final assignList = List<AssignmentModel>.from(CompanyAssignmentService().allAssignments);
      for (int i = 0; i < assignList.length; i++) {
        if (assignList[i].projectId == projectId ||
            (projectTitle.isNotEmpty &&
                assignList[i].projectTitle.trim().toLowerCase() ==
                    projectTitle.toLowerCase())) {
          assignList[i] = assignList[i].copyWith(
            submissionStatus: 'Approved',
            projectStatus: 'Completed',
            progress: 1.0,
          );
        }
      }
      CompanyAssignmentService().assignmentsNotifier.value = assignList;
    } catch (_) {}

    // Update in-memory disputed list in-place so buttons hide immediately on card
    final dList = List<ProjectModel>.from(disputedProjectsNotifier.value);
    final dIdx = dList.indexWhere((p) => p.id == projectId);
    if (dIdx != -1) {
      dList[dIdx] = dList[dIdx].copyWith(
        status: 'completed',
        paymentStatus: 'paid',
        payoutTransactionId: tid,
        payoutReceiptUrl: receiptUrl,
        payoutType: 'dispute_student_awarded',
        disputeResolution: 'paid_to_student',
        studentPayoutAmount: netStudent,
        platformCommissionAmount: commission10,
        companyRefundAmount: 0.00,
      );
      disputedProjectsNotifier.value = dList;
    }

    loadDisputedProjects(forceRefresh: true);
    loadPayoutReadyProjects(forceRefresh: true);

    return true;
  }

  /// Admin Option 2: Refunds Escrow to Company (0% Commission, 100% full return), cancels project,
  /// immediately sets status to 'cancelled' and notifies both parties.
  Future<bool> executeDisputeRefundToCompany({
    required String projectId,
    required String transactionId,
    String? receiptUrl,
    String? notes,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;
    final tid = transactionId.trim();

    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    double escrow = 0.0;
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      projectTitle = p.title;
      escrow = p.escrowAmount;
    } catch (_) {}

    if (escrow <= 0) {
      try {
        final allP = AppDataService.instance.getAllProjects();
        final raw = allP.firstWhere(
          (e) => (e['id'] ?? e['projectId'])?.toString() == projectId,
        );
        final amt = raw['escrow_amount'] ??
            raw['escrowAmount'] ??
            raw['budgetAmount'] ??
            raw['budget'] ??
            raw['stipend'];
        if (amt is num && amt > 0) escrow = amt.toDouble();
        if (amt != null && escrow <= 0) {
          final cl = amt.toString().replaceAll(RegExp(r'[^0-9.]'), '');
          final d = double.tryParse(cl);
          if (d != null && d > 0) escrow = d;
        }
      } catch (_) {}
    }
    if (escrow <= 0) escrow = 15000.0;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        final projUpdate = <String, dynamic>{
          'status': 'cancelled',
          'payout_type': 'dispute_company_refunded',
          'company_refund_amount': escrow,
          'student_payout_amount': 0.00,
          'platform_commission_amount': 0.00,
          'payout_transaction_id': tid,
          'completed_at': nowIso,
          'updated_at': nowIso,
          'additional_instructions':
              'Dispute Resolved: Refunded to Company (TID: $tid)',
        };
        if (receiptUrl != null && receiptUrl.trim().isNotEmpty) {
          projUpdate['payout_receipt_url'] = receiptUrl.trim();
        }

        await supabase
            .from('projects')
            .update(projUpdate)
            .eq('id', projectId);

        try {
          await supabase
              .from('applications')
              .update({
                'status': 'Cancelled',
                'company_feedback':
                    'Dispute Resolved: Escrow payment (PKR ${escrow.toStringAsFixed(0)}) refunded to company (TID: $tid). Project Cancelled.',
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (eApp) {
          debugPrint('executeDisputeRefundToCompany applications update notice: $eApp');
        }

        // Notify both parties
        try {
          await supabase.from('admin_notifications').insert({
            'project_id': projectId,
            'title': 'Dispute Resolved: Refunded to Company ($projectTitle)',
            'message':
                'SkillBridge administration refunded payment (PKR ${escrow.toStringAsFixed(0)}) to company (TID: $tid). Student notified that company has received payment back. Project Cancelled.',
            'notification_type': 'dispute_resolved',
            'is_read': false,
            'created_at': nowIso,
          });
        } catch (eNotif) {
          debugPrint('admin_notifications insert error: $eNotif');
        }
      } catch (e) {
        debugPrint('executeDisputeRefundToCompany error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // Synchronize AppDataService for Student and Company
    await AppDataService.instance.recordCancelledRefund(
      projectId: projectId,
      refundTransactionId: tid,
      refundReceiptUrl: receiptUrl,
    );

    // Update in-memory CompanyProjectService
    final compList = List<ProjectModel>.from(CompanyProjectService().allProjects);
    final cIdx = compList.indexWhere((p) => p.id == projectId);
    if (cIdx != -1) {
      compList[cIdx] = compList[cIdx].copyWith(
        status: 'cancelled',
        paymentStatus: 'refunded',
        payoutType: 'dispute_company_refunded',
        disputeResolution: 'refunded_to_company',
        refundTransactionId: tid,
        refundReceiptUrl: receiptUrl,
        companyRefundAmount: escrow,
        platformCommissionAmount: 0.00,
        studentPayoutAmount: 0.00,
      );
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // Update in-memory CompanyAssignmentService (marks Cancelled/Rejected on Deliverables)
    try {
      final assignList = List<AssignmentModel>.from(CompanyAssignmentService().allAssignments);
      for (int i = 0; i < assignList.length; i++) {
        if (assignList[i].projectId == projectId ||
            (projectTitle.isNotEmpty &&
                assignList[i].projectTitle.trim().toLowerCase() ==
                    projectTitle.toLowerCase())) {
          assignList[i] = assignList[i].copyWith(
            submissionStatus: 'Rejected',
            projectStatus: 'Cancelled',
          );
        }
      }
      CompanyAssignmentService().assignmentsNotifier.value = assignList;
    } catch (_) {}

    // Update in-memory disputed list in-place so buttons hide immediately on card
    final dList = List<ProjectModel>.from(disputedProjectsNotifier.value);
    final dIdx = dList.indexWhere((p) => p.id == projectId);
    if (dIdx != -1) {
      dList[dIdx] = dList[dIdx].copyWith(
        status: 'cancelled',
        paymentStatus: 'refunded',
        payoutType: 'dispute_company_refunded',
        disputeResolution: 'refunded_to_company',
        refundTransactionId: tid,
        refundReceiptUrl: receiptUrl,
        companyRefundAmount: escrow,
        platformCommissionAmount: 0.00,
        studentPayoutAmount: 0.00,
      );
      disputedProjectsNotifier.value = dList;
    }

    loadDisputedProjects(forceRefresh: true);
    loadPayoutReadyProjects(forceRefresh: true);

    return true;
  }

  /// Uploads Admin payout receipt screenshot to Supabase Storage with offline fallback.
  Future<String?> uploadPayoutReceipt({
    required String projectId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final path = 'payouts/$projectId/${nowMs}_$fileName';

    if (supabase != null) {
      try {
        await supabase.storage.from('payment_receipts').uploadBinary(
          path,
          bytes,
        );
        final publicUrl = supabase.storage
            .from('payment_receipts')
            .getPublicUrl(path);
        return publicUrl;
      } catch (e) {
        debugPrint('uploadPayoutReceipt storage bucket error: $e');
      }
    }

    // High quality offline fallback Data URL
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// 6. Finalizes payout by recording transfer TID and receipt screenshot.
  /// Sets: status = 'completed', completed_at = now().
  Future<bool> completePayout({
    required String projectId,
    required String transactionId,
    String? receiptUrl,
    String? notes,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;
    final tid = transactionId.trim();

    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    try {
      final p = existing.firstWhere(
        (p) =>
            p.id == projectId ||
            (projectId.isNotEmpty &&
                p.title.trim().toLowerCase() == projectId.trim().toLowerCase()),
      );
      projectTitle = p.title;
    } catch (_) {}

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'completed',
              'payment_status': 'paid',
              'payout_transaction_id': tid,
              if (receiptUrl != null && receiptUrl.trim().isNotEmpty)
                'payout_receipt_url': receiptUrl.trim(),
              'completed_at': nowIso,
              'updated_at': nowIso,
            })
            .eq('id', projectId);

        // Also synchronize into applications table so student sees payout TID & receipt immediately
        try {
          await supabase
              .from('applications')
              .update({
                'status': 'completed',
                'payout_transaction_id': tid,
                if (receiptUrl != null && receiptUrl.trim().isNotEmpty)
                  'payout_receipt_url': receiptUrl.trim(),
                'updated_at': nowIso,
              })
              .or('project_id.eq.$projectId,id.eq.$projectId');
        } catch (appErr) {
          debugPrint('Sync applications completePayout error: $appErr');
        }

        // Notify student & company
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Escrow Payout Disbursed: $projectTitle',
          'message':
              'Admin disbursed payout to student. TID: $tid. Transfer receipt shared.',
          'notification_type': 'payout_completed',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('AdminDisputePayoutService completePayout error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // Remove from payout-ready queue
    final pList = List<ProjectModel>.from(payoutReadyProjectsNotifier.value);
    pList.removeWhere(
      (p) =>
          p.id == projectId ||
          (projectTitle.isNotEmpty &&
              p.title.trim().toLowerCase() == projectTitle.toLowerCase()),
    );
    payoutReadyProjectsNotifier.value = pList;

    // Sync into CompanyProjectService
    _syncCompanyService(
      projectId,
      'completed',
      completedAt: nowIso,
      transactionId: tid,
      receiptUrl: receiptUrl,
      projectTitle: projectTitle,
    );

    // Sync into AppDataService for real-time student UI update
    try {
      await AppDataService.instance.recordDisbursedPayout(
        projectId: projectId,
        transactionId: tid,
        receiptUrl: receiptUrl,
        projectTitle: projectTitle,
      );
    } catch (e) {
      debugPrint('Sync AppDataService recordDisbursedPayout warning: $e');
    }

    await loadPayoutReadyProjects(forceRefresh: true);

    return true;
  }

  void _syncCompanyService(
    String projectId,
    String newStatus, {
    String? completedAt,
    String? transactionId,
    String? receiptUrl,
    String? projectTitle,
  }) {
    final compService = CompanyProjectService();
    final list = List<ProjectModel>.from(compService.allProjects);
    int idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1 && projectTitle != null && projectTitle.isNotEmpty) {
      idx = list.indexWhere(
        (p) =>
            p.title.trim().toLowerCase() == projectTitle.trim().toLowerCase(),
      );
    }

    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: newStatus,
        paymentStatus: newStatus.toLowerCase() == 'completed'
            ? 'paid'
            : list[idx].paymentStatus,
        paymentSent: true,
        payoutTransactionId: transactionId ?? list[idx].payoutTransactionId,
        payoutReceiptUrl: receiptUrl ?? list[idx].payoutReceiptUrl,
        completedAt: completedAt ?? list[idx].completedAt,
      );
      compService.projectsNotifier.value = list;
    }

    if (newStatus.toLowerCase() == 'completed') {
      try {
        final assignService = CompanyAssignmentService();
        final assignList =
            List<AssignmentModel>.from(assignService.allAssignments);
        bool changed = false;
        for (int i = 0; i < assignList.length; i++) {
          if (assignList[i].projectId == projectId ||
              (projectTitle != null &&
                  projectTitle.isNotEmpty &&
                  assignList[i].projectTitle.trim().toLowerCase() ==
                      projectTitle.trim().toLowerCase())) {
            assignList[i] = assignList[i].copyWith(
              submissionStatus: 'Approved',
              projectStatus: 'Completed',
              progress: 1.0,
            );
            changed = true;
          }
        }
        if (changed) {
          assignService.assignmentsNotifier.value = assignList;
        }
      } catch (_) {}
    }
  }
}

