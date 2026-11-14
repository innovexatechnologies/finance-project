import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_notification_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

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
          .where((p) => p.isDisputed)
          .toList();
      disputedProjectsNotifier.value = local;
      isLoadingNotifier.value = false;
      return local;
    }

    try {
      final rows = await supabase
          .from('projects')
          .select()
          .eq('status', 'disputed')
          .order('updated_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((r) => ProjectModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      disputedProjectsNotifier.value = list;
      return list;
    } catch (e) {
      debugPrint('AdminDisputePayoutService loadDisputedProjects error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isDisputed)
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
    if (supabase == null) {
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isReadyForPayout)
          .toList();
      payoutReadyProjectsNotifier.value = local;
      isLoadingNotifier.value = false;
      return local;
    }

    try {
      final rows = await supabase
          .from('projects')
          .select()
          .eq('status', 'ready_for_payout')
          .order('updated_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((r) => ProjectModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      payoutReadyProjectsNotifier.value = list;
      return list;
    } catch (e) {
      debugPrint('AdminDisputePayoutService loadPayoutReadyProjects error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isReadyForPayout)
          .toList();
      payoutReadyProjectsNotifier.value = local;
      return local;
    } finally {
      isLoadingNotifier.value = false;
    }
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

    // Get escrow amount
    double escrow = 0.0;
    String projectTitle = 'Project';
    final currentList = disputedProjectsNotifier.value;
    try {
      final p = currentList.firstWhere((p) => p.id == projectId);
      escrow = p.escrowAmount > 0 ? p.escrowAmount : 10000.0;
      projectTitle = p.title;
    } catch (_) {
      escrow = 10000.0;
    }

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
    final idx = dList.indexWhere((p) => p.id == projectId);
    ProjectModel? updatedModel;
    if (idx != -1) {
      updatedModel = dList[idx].copyWith(
        status: 'ready_for_payout',
        payoutType: decisionType,
        platformCommissionAmount: commission,
        studentPayoutAmount: studentPayout,
        companyRefundAmount: companyRefund,
      );
      dList.removeAt(idx);
      disputedProjectsNotifier.value = dList;
    }

    // Add to payout-ready queue
    if (updatedModel != null) {
      final pList = List<ProjectModel>.from(payoutReadyProjectsNotifier.value);
      pList.removeWhere((p) => p.id == projectId);
      pList.insert(0, updatedModel);
      payoutReadyProjectsNotifier.value = pList;
    }

    // Sync into CompanyProjectService
    _syncCompanyService(projectId, 'ready_for_payout');

    return true;
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

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'completed',
              'payout_transaction_id': transactionId.trim(),
              if (receiptUrl != null && receiptUrl.trim().isNotEmpty)
                'payout_receipt_url': receiptUrl.trim(),
              'completed_at': nowIso,
              'updated_at': nowIso,
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('AdminDisputePayoutService completePayout error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Remove from payout-ready queue
    final pList = List<ProjectModel>.from(payoutReadyProjectsNotifier.value);
    pList.removeWhere((p) => p.id == projectId);
    payoutReadyProjectsNotifier.value = pList;

    // Sync into CompanyProjectService
    _syncCompanyService(projectId, 'completed', completedAt: nowIso);

    return true;
  }

  void _syncCompanyService(String projectId, String newStatus, {String? completedAt}) {
    final compService = CompanyProjectService();
    final list = List<ProjectModel>.from(compService.allProjects);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: newStatus,
        completedAt: completedAt ?? list[idx].completedAt,
      );
      compService.projectsNotifier.value = list;
    }
  }
}

