import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/services/admin_dispute_payout_service.dart';
import 'package:link_vibe/services/helpdesk_service.dart';

/// Pure Service Layer for Escrow Lifecycle Transitions:
/// - Student Project Delivery (`delivered`)
/// - Company Approval (`ready_for_payout`)
/// - 5-Day Auto-Release Check (`ready_for_payout`)
/// - Dispute Escalation (`disputed` with unique Case ID)
///
/// Strictly isolated from Flutter UI screens.
class EscrowLifecycleService {
  static final EscrowLifecycleService _instance =
      EscrowLifecycleService._internal();
  factory EscrowLifecycleService() => _instance;
  EscrowLifecycleService._internal();

  String? _lastError;
  String? get lastError => _lastError;

  static final Random _rng = Random();

  /// Generates unique dispute case ID, e.g. #SB-4819
  String generateCaseId() {
    final num = _rng.nextInt(9000) + 1000;
    return '#SB-$num';
  }

  /// 1. Student delivers the project.
  /// Sets: status = 'delivered', delivered_at = now().
  Future<bool> deliverProject({
    required String projectId,
    String? workUrl,
    String? summary,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'delivered',
              'delivered_at': nowIso,
              'updated_at': nowIso,
              if (workUrl != null && workUrl.trim().isNotEmpty)
                'attachment_url': workUrl.trim(),
            })
            .eq('id', projectId);

        // Notify company / admin
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Project Delivered for Review',
          'message':
              'Student submitted final deliverable. Company has 5 days to inspect before auto-release.',
          'notification_type': 'payout_ready',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('EscrowLifecycleService deliverProject error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // Update in-memory CompanyProjectService
    _updateLocalProjectStatus(
      projectId: projectId,
      newStatus: 'delivered',
      deliveredAt: nowIso,
    );

    return _lastError == null;
  }

  /// 2. Company requests revisions on delivered deliverables (Strictly 1 Review Request & 2-Day Deadline).
  /// Sets: status = 'revision_requested', revision_count = currentCount + 1,
  /// revision_notes = revisionNotes, last_revision_requested_at = now(),
  /// revision_deadline = now + 2 days.
  /// Pauses 5-day auto-release countdown since status is no longer 'delivered'.
  Future<bool> requestProjectRevision({
    required String projectId,
    required String revisionNotes,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final deadlineIso = DateTime.now().add(const Duration(days: 2)).toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    int currentCount = 0;
    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      currentCount = p.revisionCount;
      projectTitle = p.title;
    } catch (_) {}

    // Enforce strictly 1 revision request policy
    if (currentCount >= 1) {
      _lastError = 'Only 1 review request is allowed. Maximum limit of 1 revision reached.';
      return false;
    }

    final newCount = currentCount + 1;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'revision_requested',
              'revision_count': newCount,
              'revision_notes': revisionNotes.trim(),
              'last_revision_requested_at': nowIso,
              'revision_deadline': deadlineIso,
              'updated_at': nowIso,
            })
            .eq('id', projectId);

        // Insert alert for Admin/Student
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Improvement Requested (1 Review Allowed): $projectTitle',
          'message':
              'Company requested improvement. Student has strictly 2 Days (48 Hours) to re-deliver work. Notes: "${revisionNotes.trim()}".',
          'notification_type': 'revision_requested',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('EscrowLifecycleService requestProjectRevision error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Update in-memory project state
    _updateLocalProjectStatus(
      projectId: projectId,
      newStatus: 'revision_requested',
      revisionCount: newCount,
      revisionNotes: revisionNotes.trim(),
      lastRevisionRequestedAt: nowIso,
      revisionDeadline: deadlineIso,
    );

    return true;
  }

  /// 3. Student submits revised work ("Re-Deliver Project").
  /// Sets: status = 'delivered', delivered_at = now().
  /// Resets and restarts the 5-Day Auto-Release countdown from zero.
  Future<bool> reDeliverProject({
    required String projectId,
    String? workUrl,
    String? summary,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      projectTitle = p.title;
    } catch (_) {}

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
          'status': 'delivered',
          'delivered_at': nowIso,
          'updated_at': nowIso,
          if (workUrl != null && workUrl.trim().isNotEmpty)
            'attachment_url': workUrl.trim(),
        }).eq('id', projectId);

        // Notify company / admin
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Project Re-Delivered for Review: $projectTitle',
          'message':
              'Student submitted revised work. 5-day review window reset to 120 hours.',
          'notification_type': 'payout_ready',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('EscrowLifecycleService reDeliverProject error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Update in-memory project state with fresh deliveredAt
    _updateLocalProjectStatus(
      projectId: projectId,
      newStatus: 'delivered',
      deliveredAt: nowIso,
    );

    return true;
  }

  /// 4. Company approves delivered work and releases payment to Student.
  /// Sets: status = 'ready_for_payout', payout_type = 'full_student'.
  /// Calculates: 10% platform fee, 90% net student payout.
  Future<bool> approveAndReleasePayment({
    required String projectId,
    String? projectTitle,
    String? studentName,
    String? studentId,
    String? companyFeedback,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    // Fetch escrow amount for calculation
    double escrow = 0.0;
    String resolvedProjectTitle = projectTitle ?? 'Project';

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        final projRow = await supabase
            .from('projects')
            .select('title, escrow_amount')
            .eq('id', projectId)
            .maybeSingle();
        if (projRow != null) {
          final amt = (projRow['escrow_amount'] as num?)?.toDouble();
          if (amt != null && amt > 0) escrow = amt;
          if (projRow['title'] != null &&
              projRow['title'].toString().trim().isNotEmpty) {
            resolvedProjectTitle = projRow['title'].toString().trim();
          }
        }
      } catch (_) {}
    }

    if (escrow <= 0) {
      final existing = CompanyProjectService().allProjects;
      try {
        final p = existing.firstWhere(
          (p) =>
              p.id == projectId ||
              (resolvedProjectTitle.isNotEmpty &&
                  p.title.trim().toLowerCase() ==
                      resolvedProjectTitle.toLowerCase()),
        );
        escrow = p.escrowAmount > 0 ? p.escrowAmount : 25000.0;
        resolvedProjectTitle = p.title;
      } catch (_) {}
    }

    if (escrow <= 0) {
      try {
        final assigns = CompanyAssignmentService().allAssignments;
        final a = assigns.firstWhere(
          (a) =>
              a.projectId == projectId ||
              (resolvedProjectTitle.isNotEmpty &&
                  a.projectTitle.trim().toLowerCase() ==
                      resolvedProjectTitle.toLowerCase()),
        );
        if (resolvedProjectTitle.isEmpty || resolvedProjectTitle == 'Project') {
          resolvedProjectTitle = a.projectTitle;
        }
      } catch (_) {}
    }

    if (escrow <= 0) {
      try {
        final allP = AppDataService.instance.getAllProjects();
        final raw = allP.firstWhere(
          (e) =>
              (e['id'] ?? e['projectId'])?.toString() == projectId ||
              (resolvedProjectTitle.isNotEmpty &&
                  (e['title'] ?? e['projectTitle'])
                          ?.toString()
                          .trim()
                          .toLowerCase() ==
                      resolvedProjectTitle.toLowerCase()),
        );
        final amt = raw['escrow_amount'] ??
            raw['escrowAmount'] ??
            raw['budgetAmount'] ??
            raw['budget'] ??
            raw['stipend'];
        if (amt is num && amt > 0) escrow = amt.toDouble();
      } catch (_) {}
    }

    if (escrow <= 0) escrow = 25000.0;

    final commission = double.parse((escrow * 0.10).toStringAsFixed(2));
    final studentPayout = double.parse((escrow * 0.90).toStringAsFixed(2));

    // Resilient Supabase updates with automatic fallback
    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'ready_for_payout',
              'payout_type': 'full_student',
              'platform_commission_amount': commission,
              'student_payout_amount': studentPayout,
              'company_refund_amount': 0.00,
              'updated_at': nowIso,
              if (companyFeedback != null && companyFeedback.trim().isNotEmpty)
                'additional_instructions':
                    'Company Feedback: ${companyFeedback.trim()}',
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('approveAndReleasePayment full projects update error: $e');
        try {
          await supabase
              .from('projects')
              .update({
                'status': 'ready_for_payout',
                'updated_at': nowIso,
              })
              .eq('id', projectId);
        } catch (e2) {
          debugPrint('approveAndReleasePayment simple projects update error: $e2');
          try {
            await supabase
                .from('projects')
                .update({
                  'status': 'completed',
                  'updated_at': nowIso,
                })
                .eq('id', projectId);
          } catch (_) {}
        }
      }

      // Also update applications table in Supabase
      try {
        await supabase
            .from('applications')
            .update({
              'status': 'ready_for_payout',
              if (companyFeedback != null && companyFeedback.trim().isNotEmpty)
                'company_feedback': companyFeedback.trim(),
              'updated_at': nowIso,
            })
            .eq('project_id', projectId);
      } catch (appErr) {
        try {
          await supabase
              .from('applications')
              .update({
                'status': 'Completed',
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (_) {}
      }

      // Alert Admin for payout execution
      try {
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Company Approved: $resolvedProjectTitle',
          'message':
              'Company approved deliverables. Send 90% payout to Student: PKR $studentPayout (10% fee: PKR $commission).',
          'notification_type': 'company_approval',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (_) {}
    }

    // Always synchronize in-memory project
    _updateLocalProjectStatus(
      projectId: projectId,
      projectTitle: resolvedProjectTitle,
      studentName: studentName,
      escrowAmount: escrow,
      newStatus: 'ready_for_payout',
      payoutType: 'full_student',
      studentPayout: studentPayout,
      commission: commission,
      refund: 0.00,
    );

    // Update CompanyAssignmentService in-memory
    try {
      final assignList =
          List<AssignmentModel>.from(CompanyAssignmentService().allAssignments);
      bool assignChanged = false;
      for (int i = 0; i < assignList.length; i++) {
        if (assignList[i].projectId == projectId ||
            (resolvedProjectTitle.isNotEmpty &&
                assignList[i].projectTitle.trim().toLowerCase() ==
                    resolvedProjectTitle.toLowerCase())) {
          assignList[i] = assignList[i].copyWith(
            submissionStatus: 'Approved',
            projectStatus: 'Completed',
            progress: 1.0,
          );
          assignChanged = true;
        }
      }
      if (assignChanged) {
        CompanyAssignmentService().assignmentsNotifier.value = assignList;
      }
    } catch (_) {}

    // Update AppDataService so student sees deliverables accepted while keeping project in Active tab
    try {
      await AppDataService.instance.recordCompanyApprovedReadyForPayout(
        projectId: projectId,
        projectTitle: resolvedProjectTitle,
        companyFeedback: companyFeedback,
      );
    } catch (_) {}

    // Resolve any open HelpDesk ticket for this project
    await HelpdeskService.instance.onCompanyApprove(projectId);

    // Refresh Admin Payout queue immediately
    try {
      await AdminDisputePayoutService().loadPayoutReadyProjects(forceRefresh: true);
    } catch (_) {}

    return true;
  }

  /// 3. Raises a formal dispute.
  /// Sets: status = 'disputed', dispute_case_id = '#SB-XXXX', dispute_reason = reason.
  /// Alerts Admin Console for 3-way resolution.
  Future<String?> raiseDispute({
    required String projectId,
    required String reason,
    required String raisedByRole,
  }) async {
    _lastError = null;
    final caseId = generateCaseId();
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      projectTitle = p.title;
    } catch (_) {}

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'disputed',
              'dispute_case_id': caseId,
              'dispute_reason': reason.trim(),
              'updated_at': nowIso,
            })
            .eq('id', projectId);

        // Also update applications table in Supabase so status reflects Rejected
        try {
          await supabase
              .from('applications')
              .update({
                'status': 'Rejected',
                'company_feedback': reason.trim(),
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (_) {}

        // Insert high-priority dispute alert
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Dispute Raised [$caseId]: $projectTitle',
          'message':
              '$raisedByRole raised dispute for case $caseId. Reason: "${reason.trim()}". Requires Admin 3-way decision.',
          'notification_type': 'dispute_raised',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('EscrowLifecycleService raiseDispute error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return null;
      }
    }

    // Update in-memory project
    _updateLocalProjectStatus(
      projectId: projectId,
      newStatus: 'disputed',
      disputeCaseId: caseId,
      disputeReason: reason.trim(),
    );

    // Update in-memory company assignments
    try {
      final assignService = CompanyAssignmentService();
      final updatedList = assignService.allAssignments.map((a) {
        if (a.projectId == projectId) {
          return a.copyWith(
            submissionStatus: 'Rejected',
            projectStatus: 'Rejected',
          );
        }
        return a;
      }).toList();
      assignService.assignmentsNotifier.value = updatedList;
    } catch (_) {}

    // Synchronize AppDataService for Student Portal & persistence
    await AppDataService.instance.recordDisputedProject(
      projectId: projectId,
      disputeCaseId: caseId,
      disputeReason: reason.trim(),
    );

    // Refresh Admin Dispute service queue
    AdminDisputePayoutService().loadDisputedProjects(forceRefresh: true);

    // Resolve any open HelpDesk ticket for this project
    await HelpdeskService.instance.onCompanyReject(projectId);

    return caseId;
  }

  /// 4. 5-Day Auto-Release Check.
  /// Calls PostgreSQL function or processes local auto-releases for projects delivered 5+ days ago.
  Future<int> checkAndProcessFiveDayAutoRelease() async {
    final supabase = SupabaseHelper.clientOrNull;
    int processed = 0;

    if (supabase != null) {
      try {
        final res = await supabase.rpc('process_five_day_auto_releases');
        if (res is num) {
          processed = res.toInt();
        }
      } catch (e) {
        debugPrint('EscrowLifecycleService rpc auto-release skipped: $e');
      }
    }

    // Local in-memory check for offline or test resilience
    final compProjService = CompanyProjectService();
    final list = List<ProjectModel>.from(compProjService.allProjects);
    bool changed = false;

    for (int i = 0; i < list.length; i++) {
      final p = list[i];
      if (p.isDelivered && p.isAutoReleaseEligible) {
        final escrow = p.escrowAmount > 0 ? p.escrowAmount : 10000.0;
        final commission = double.parse((escrow * 0.10).toStringAsFixed(2));
        final studentPayout = double.parse((escrow - commission).toStringAsFixed(2));

        list[i] = p.copyWith(
          status: 'ready_for_payout',
          payoutType: 'auto_released_student',
          platformCommissionAmount: commission,
          studentPayoutAmount: studentPayout,
          companyRefundAmount: 0.00,
        );
        changed = true;
        processed++;
      }
    }

    if (changed) {
      compProjService.projectsNotifier.value = list;
    }

    return processed;
  }

  void _updateLocalProjectStatus({
    required String projectId,
    String? projectTitle,
    String? studentName,
    double? escrowAmount,
    required String newStatus,
    String? deliveredAt,
    String? disputeCaseId,
    String? disputeReason,
    String? payoutType,
    double? studentPayout,
    double? commission,
    double? refund,
    int? revisionCount,
    String? revisionNotes,
    String? lastRevisionRequestedAt,
    String? revisionDeadline,
  }) {
    final compProjService = CompanyProjectService();
    final list = List<ProjectModel>.from(compProjService.allProjects);
    int idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1 && projectTitle != null && projectTitle.trim().isNotEmpty) {
      idx = list.indexWhere(
        (p) =>
            p.title.trim().toLowerCase() == projectTitle.trim().toLowerCase(),
      );
    }

    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: newStatus,
        assignedStudent: studentName ?? list[idx].assignedStudent,
        escrowAmount: (escrowAmount != null && escrowAmount > 0)
            ? escrowAmount
            : list[idx].escrowAmount,
        deliveredAt: deliveredAt ?? list[idx].deliveredAt,
        disputeCaseId: disputeCaseId ?? list[idx].disputeCaseId,
        disputeReason: disputeReason ?? list[idx].disputeReason,
        payoutType: payoutType ?? list[idx].payoutType,
        studentPayoutAmount: studentPayout ?? list[idx].studentPayoutAmount,
        platformCommissionAmount:
            commission ?? list[idx].platformCommissionAmount,
        companyRefundAmount: refund ?? list[idx].companyRefundAmount,
        revisionCount: revisionCount ?? list[idx].revisionCount,
        revisionNotes: revisionNotes ?? list[idx].revisionNotes,
        lastRevisionRequestedAt:
            lastRevisionRequestedAt ?? list[idx].lastRevisionRequestedAt,
        revisionDeadline: revisionDeadline ?? list[idx].revisionDeadline,
      );
      compProjService.projectsNotifier.value = list;
    } else {
      // Synthesize new ProjectModel and add to allProjects
      final newProj = ProjectModel(
        id: projectId,
        title: projectTitle ?? 'Corporate Project',
        description: 'Company deliverable approved.',
        category: 'Development',
        duration: 'Active',
        deadline: 'Flexible',
        status: newStatus,
        assignedStudent: studentName ?? 'Awarded Student',
        escrowAmount: (escrowAmount != null && escrowAmount > 0)
            ? escrowAmount
            : 25000.0,
        companyName: 'Company Partner',
        payoutType: payoutType,
        studentPayoutAmount: studentPayout,
        platformCommissionAmount: commission,
        companyRefundAmount: refund ?? 0.0,
        deliveredAt: deliveredAt,
        disputeCaseId: disputeCaseId,
        disputeReason: disputeReason,
      );
      list.insert(0, newProj);
      compProjService.projectsNotifier.value = list;
    }
  }
}

