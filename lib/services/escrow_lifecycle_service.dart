import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

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

  /// 2. Company approves delivered work and releases payment to Student.
  /// Sets: status = 'ready_for_payout', payout_type = 'full_student'.
  /// Calculates: 10% platform fee, 90% net student payout.
  Future<bool> approveAndReleasePayment({
    required String projectId,
    String? companyFeedback,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    // Fetch escrow amount for calculation
    double escrow = 0.0;
    String projectTitle = 'Project';
    final existing = CompanyProjectService().allProjects;
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      escrow = p.escrowAmount > 0 ? p.escrowAmount : 10000.0;
      projectTitle = p.title;
    } catch (_) {
      escrow = 10000.0;
    }

    final commission = double.parse((escrow * 0.10).toStringAsFixed(2));
    final studentPayout = double.parse((escrow - commission).toStringAsFixed(2));

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
                'additional_instructions': 'Company Feedback: ${companyFeedback.trim()}',
            })
            .eq('id', projectId);

        // Alert Admin for payout execution
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Company Approved: $projectTitle',
          'message':
              'Company approved deliverables. Send 100% payout to Student: PKR $studentPayout (Platform fee: PKR $commission).',
          'notification_type': 'company_approval',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('EscrowLifecycleService approveAndReleasePayment error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Update in-memory project
    _updateLocalProjectStatus(
      projectId: projectId,
      newStatus: 'ready_for_payout',
      payoutType: 'full_student',
      studentPayout: studentPayout,
      commission: commission,
      refund: 0.00,
    );

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
    required String newStatus,
    String? deliveredAt,
    String? disputeCaseId,
    String? disputeReason,
    String? payoutType,
    double? studentPayout,
    double? commission,
    double? refund,
  }) {
    final compProjService = CompanyProjectService();
    final list = List<ProjectModel>.from(compProjService.allProjects);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: newStatus,
        deliveredAt: deliveredAt ?? list[idx].deliveredAt,
        disputeCaseId: disputeCaseId ?? list[idx].disputeCaseId,
        disputeReason: disputeReason ?? list[idx].disputeReason,
        payoutType: payoutType ?? list[idx].payoutType,
        studentPayoutAmount: studentPayout ?? list[idx].studentPayoutAmount,
        platformCommissionAmount: commission ?? list[idx].platformCommissionAmount,
        companyRefundAmount: refund ?? list[idx].companyRefundAmount,
      );
      compProjService.projectsNotifier.value = list;
    }
  }
}

