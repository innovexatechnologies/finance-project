import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_notification_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
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
          .where((p) => p.isDisputed || p.status.toLowerCase() == 'rejected')
          .toList();
      disputedProjectsNotifier.value = local;
      isLoadingNotifier.value = false;
      return local;
    }

    try {
      final rows = await supabase
          .from('projects')
          .select()
          .or('status.eq.disputed,status.eq.rejected')
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
          .where((p) => p.isDisputed || p.status.toLowerCase() == 'rejected')
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
          .or('status.eq.ready_for_payout,status.eq.completed')
          .order('updated_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((r) => ProjectModel.fromJson(Map<String, dynamic>.from(r)))
          .where((p) =>
              (p.status.toLowerCase() == 'ready_for_payout' ||
                  p.status.toLowerCase() == 'approved_by_company' ||
                  (p.status.toLowerCase() == 'completed' &&
                      (p.payoutTransactionId == null ||
                          p.payoutTransactionId!.trim().isEmpty))) &&
              p.status.toLowerCase() != 'cancelled')
          .toList();

      // Merge any local in-memory projects that are ready for payout
      final local = CompanyProjectService()
          .allProjects
          .where((p) =>
              p.isReadyForPayout && !list.any((rem) => rem.id == p.id))
          .toList();

      final combined = [...list, ...local];
      payoutReadyProjectsNotifier.value = combined;
      return combined;
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
    String name = project.assignedStudent ?? 'Assigned Student';
    String email = 'student@skillbridge.edu';
    String method = 'JazzCash Mobile Account';
    String accountNum = '0300-1234567';
    String accountTitle = name;

    if (supabase != null && SupabaseHelper.isUuid(project.id)) {
      try {
        final appRows = await supabase
            .from('applications')
            .select('student_id, student_name, student_email, applicant_name, applicant_email, payment_method, account_number, account_title, status')
            .eq('project_id', project.id)
            .limit(10);

        if (appRows.isNotEmpty) {
          final accepted = appRows.firstWhere(
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

          final candidateName = accepted['student_name'] ?? accepted['applicant_name'];
          if (candidateName != null && candidateName.toString().trim().isNotEmpty) {
            name = candidateName.toString().trim();
          }

          final candidateEmail = accepted['student_email'] ?? accepted['applicant_email'];
          if (candidateEmail != null && candidateEmail.toString().trim().isNotEmpty) {
            email = candidateEmail.toString().trim();
          }

          if (accepted['payment_method'] != null) {
            method = accepted['payment_method'].toString();
          }
          if (accepted['account_number'] != null) {
            accountNum = accepted['account_number'].toString();
          }
          if (accepted['account_title'] != null) {
            accountTitle = accepted['account_title'].toString();
          }

          final studentId = accepted['student_id']?.toString();
          if (studentId != null && SupabaseHelper.isUuid(studentId)) {
            // Check student_payment_methods
            try {
              final pmRows = await supabase
                  .from('student_payment_methods')
                  .select()
                  .or('user_id.eq.$studentId,student_id.eq.$studentId')
                  .order('updated_at', ascending: false)
                  .limit(1);

              if (pmRows.isNotEmpty) {
                final pm = pmRows.first;
                method = (pm['bank_name'] ?? pm['provider'] ?? pm['method_type'] ?? method).toString();
                accountNum = (pm['account_number_iban'] ?? pm['account_number'] ?? pm['iban'] ?? accountNum).toString();
                accountTitle = (pm['account_title'] ?? name).toString();
              }
            } catch (_) {}

            // Check profile
            try {
              final prof = await supabase
                  .from('profiles')
                  .select('full_name, email, phone')
                  .eq('id', studentId)
                  .maybeSingle();

              if (prof != null) {
                if (prof['full_name'] != null && prof['full_name'].toString().isNotEmpty) {
                  name = prof['full_name'].toString();
                }
                if (prof['email'] != null && prof['email'].toString().isNotEmpty) {
                  email = prof['email'].toString();
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
      if (localAccount != null && localAccount.trim().isNotEmpty) {
        if (method == 'JazzCash Mobile Account' || method.isEmpty) {
          method = localProvider ?? method;
        }
        if (accountNum == '0300-1234567' || accountNum.isEmpty) {
          accountNum = localAccount.trim();
        }
      }
    } catch (_) {}

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
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      projectTitle = p.title;
    } catch (_) {}

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'completed',
              'payout_type': 'dispute_student_awarded',
              'payout_transaction_id': tid,
              if (receiptUrl != null && receiptUrl.trim().isNotEmpty)
                'payout_receipt_url': receiptUrl.trim(),
              'dispute_resolution': 'paid_to_student',
              'completed_at': nowIso,
              'updated_at': nowIso,
            })
            .eq('id', projectId);

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
              .eq('project_id', projectId);
        } catch (_) {}

        // Notify both parties
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Dispute Resolved: Payment Sent to Student',
          'message':
              'SkillBridge administration sent payment to student (TID: $tid) for "$projectTitle".',
          'notification_type': 'payout_completed',
          'is_read': false,
          'created_at': nowIso,
        });
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
        payoutTransactionId: tid,
        payoutReceiptUrl: receiptUrl,
        payoutType: 'dispute_student_awarded',
      );
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // Refresh queue
    disputedProjectsNotifier.value = disputedProjectsNotifier.value
        .where((p) => p.id != projectId)
        .toList();
    loadDisputedProjects(forceRefresh: true);
    loadPayoutReadyProjects(forceRefresh: true);

    return true;
  }

  /// Admin Option 2: Refunds Escrow to Company, cancels project,
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
    try {
      final p = existing.firstWhere((p) => p.id == projectId);
      projectTitle = p.title;
    } catch (_) {}

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'cancelled',
              'payout_type': 'dispute_company_refunded',
              'refund_transaction_id': tid,
              if (receiptUrl != null && receiptUrl.trim().isNotEmpty)
                'refund_receipt_url': receiptUrl.trim(),
              'dispute_resolution': 'refunded_to_company',
              'updated_at': nowIso,
            })
            .eq('id', projectId);

        try {
          await supabase
              .from('applications')
              .update({
                'status': 'cancelled',
                'refund_transaction_id': tid,
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (_) {}

        // Notify both parties
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Dispute Resolved: Refunded to Company ($projectTitle)',
          'message':
              'SkillBridge administration payment refund to company (TID: $tid). Project Cancelled.',
          'notification_type': 'dispute_resolved',
          'is_read': false,
          'created_at': nowIso,
        });
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
        payoutType: 'dispute_company_refunded',
      );
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // Refresh queue
    disputedProjectsNotifier.value = disputedProjectsNotifier.value
        .where((p) => p.id != projectId)
        .toList();
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
              'status': 'completed',
              'payout_transaction_id': transactionId.trim(),
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
                'payout_transaction_id': transactionId.trim(),
                if (receiptUrl != null && receiptUrl.trim().isNotEmpty)
                  'payout_receipt_url': receiptUrl.trim(),
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (appErr) {
          debugPrint('Sync applications completePayout error: $appErr');
        }

        // Notify student & company
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'Escrow Payout Disbursed: $projectTitle',
          'message':
              'Admin disbursed payout to student. TID: ${transactionId.trim()}. Transfer receipt shared.',
          'notification_type': 'payout_completed',
          'is_read': false,
          'created_at': nowIso,
        });
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

    // Sync into AppDataService for real-time student UI update
    try {
      await AppDataService.instance.recordDisbursedPayout(
        projectId: projectId,
        transactionId: transactionId.trim(),
        receiptUrl: receiptUrl,
      );
    } catch (e) {
      debugPrint('Sync AppDataService recordDisbursedPayout warning: $e');
    }

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

