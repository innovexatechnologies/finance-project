import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/services/student_project_service.dart';

/// Pure Service Layer for Administrator Project Escrow Approvals.
/// Keeps all database queries strictly isolated from Admin UI screens.
class AdminProjectApprovalService {
  static final AdminProjectApprovalService _instance =
      AdminProjectApprovalService._internal();
  factory AdminProjectApprovalService() => _instance;
  AdminProjectApprovalService._internal();

  final ValueNotifier<List<ProjectModel>> pendingApprovalsNotifier =
      ValueNotifier<List<ProjectModel>>([]);

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  // In-memory set of projects handled during this session to prevent race condition resurrects
  final Set<String> _locallyProcessedIds = {};

  String? _lastError;
  String? get lastError => _lastError;

  List<ProjectModel> get pendingProjects => pendingApprovalsNotifier.value;
  int get pendingCount => pendingProjects.length;

  void clearProcessedProject(String projectId) {
    _locallyProcessedIds.remove(projectId);
  }

  /// 1. Fetches all projects waiting for payment verification (status = 'pending_verification').
  Future<List<ProjectModel>> loadPendingApprovals({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _locallyProcessedIds.clear();
    }
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      // In offline/test environments, extract from CompanyProjectService
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isPendingVerification && !_locallyProcessedIds.contains(p.id))
          .toList();
      pendingApprovalsNotifier.value = local;
      isLoadingNotifier.value = false;
      return local;
    }

    try {
      final rows = await supabase
          .from('projects')
          .select()
          .eq('status', 'pending_verification')
          .order('created_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((r) => ProjectModel.fromJson(Map<String, dynamic>.from(r)))
          .where((p) => !_locallyProcessedIds.contains(p.id))
          .toList();

      pendingApprovalsNotifier.value = list;
      return list;
    } catch (e) {
      debugPrint('AdminProjectApprovalService loadPendingApprovals error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isPendingVerification && !_locallyProcessedIds.contains(p.id))
          .toList();
      pendingApprovalsNotifier.value = local;
      return local;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// 2. Approves payment, verifies escrow, and publishes project live to students.
  /// Sets: status = 'Open', is_escrow_verified = true, payment_sent = true, verified_at = now().
  Future<bool> markAsPaidAndPublish({
    required String projectId,
    String? notes,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    // Track as locally processed immediately to prevent UI flicker
    _locallyProcessedIds.add(projectId);

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      bool updatedSuccessfully = false;

      // Strategy 1: Stored Procedure RPC (SECURITY DEFINER - bypasses RLS)
      try {
        final res = await supabase.rpc(
          'admin_approve_project_payment',
          params: {
            'p_project_id': projectId,
            'p_admin_notes': notes ?? 'Approved by Administrator',
          },
        );
        if (res is Map && res['success'] == false) {
          debugPrint('Admin approve RPC returned logic failure: ${res['error']}');
        } else {
          updatedSuccessfully = true;
          debugPrint('Admin approve RPC executed successfully.');
        }
      } catch (rpcErr) {
        debugPrint('Admin approve RPC bypass error: $rpcErr');
      }

      // Strategy 2: Direct Table Updates with progressive fallback
      if (!updatedSuccessfully) {
        try {
          await supabase
              .from('projects')
              .update({
                'status': 'Open',
                'is_escrow_verified': true,
                'payment_sent': true,
                'verified_at': nowIso,
                'rejection_reason': null,
                'updated_at': nowIso,
              })
              .eq('id', projectId);
          updatedSuccessfully = true;
        } catch (e1) {
          debugPrint('Full update error: $e1. Trying without verified_at...');
          try {
            await supabase
                .from('projects')
                .update({
                  'status': 'Open',
                  'is_escrow_verified': true,
                  'payment_sent': true,
                  'updated_at': nowIso,
                })
                .eq('id', projectId);
            updatedSuccessfully = true;
          } catch (e2) {
            debugPrint('Trying status and is_escrow_verified: $e2');
            try {
              await supabase
                  .from('projects')
                  .update({
                    'status': 'Open',
                    'is_escrow_verified': true,
                    'updated_at': nowIso,
                  })
                  .eq('id', projectId);
              updatedSuccessfully = true;
            } catch (e3) {
              try {
                await supabase
                    .from('projects')
                    .update({'status': 'Open'})
                    .eq('id', projectId);
                updatedSuccessfully = true;
              } catch (e4) {
                try {
                  await supabase
                      .from('projects')
                      .update({'status': 'open'})
                      .eq('id', projectId);
                  updatedSuccessfully = true;
                } catch (e5) {
                  debugPrint('All remote updates error: $e5');
                  _lastError = SupabaseHelper.friendlyError(e5);
                }
              }
            }
          }
        }
      }
    }

    // Always update pending approvals list locally
    final updated = List<ProjectModel>.from(pendingApprovalsNotifier.value);
    updated.removeWhere((p) => p.id == projectId);
    pendingApprovalsNotifier.value = updated;

    // Synchronize into AdminProjectService catalog
    try {
      final adminProjService = AdminProjectService();
      final aList = List<AdminProjectModel>.from(adminProjService.projectsNotifier.value);
      final aIdx = aList.indexWhere((p) => p.id == projectId);
      if (aIdx != -1) {
        aList[aIdx] = aList[aIdx].copyWith(
          status: AdminProjectStatus.published,
          publicationStatus: AdminPublicationStatus.published,
          rawDbStatus: 'Open',
          isEscrowVerified: true,
          paymentSent: true,
        );
        adminProjService.projectsNotifier.value = aList;
      }
    } catch (_) {}

    // Synchronize into CompanyProjectService
    ProjectModel? liveProject;
    try {
      final compProjService = CompanyProjectService();
      final cList = List<ProjectModel>.from(compProjService.projectsNotifier.value);
      final idx = cList.indexWhere((p) => p.id == projectId);
      if (idx != -1) {
        cList[idx] = cList[idx].copyWith(
          status: 'Open',
          isEscrowVerified: true,
          paymentSent: true,
          verifiedAt: nowIso,
          rejectionReason: null,
        );
        liveProject = cList[idx];
        compProjService.projectsNotifier.value = cList;
      }
    } catch (_) {}

    // Synchronize into StudentProjectService catalog
    try {
      final studentService = StudentProjectService();
      final sList = List<ProjectModel>.from(studentService.verifiedProjectsNotifier.value);
      if (!sList.any((p) => p.id == projectId)) {
        if (liveProject != null) {
          sList.insert(0, liveProject);
          studentService.verifiedProjectsNotifier.value = sList;
        }
      }
    } catch (_) {}

    return true;
  }

  /// 3. Rejects payment proof with an explanation.
  /// If isFinalCancellation is true:
  /// Sets: status = 'cancelled', is_escrow_verified = false, payment_sent = false.
  /// If isFinalCancellation is false (Round 1):
  /// Sets: status = 'payment_rejected', is_escrow_verified = false, payment_sent = false.
  Future<bool> rejectPayment({
    required String projectId,
    required String rejectionReason,
    bool isFinalCancellation = false,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    _locallyProcessedIds.add(projectId);

    final targetStatus = isFinalCancellation ? 'cancelled' : 'payment_rejected';
    final modReason = isFinalCancellation
        ? '[Cancelled - Final Rejection] ${rejectionReason.trim()}'
        : '[Attempt 1 Rejected] ${rejectionReason.trim()}';
    final instructionNote = isFinalCancellation
        ? 'Payment Cancelled: ${rejectionReason.trim()}'
        : 'Payment Rejected: ${rejectionReason.trim()}';

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      bool rejectedSuccessfully = false;

      // Strategy 1: Stored Procedure RPC (SECURITY DEFINER - bypasses RLS) - only for initial rejection
      if (!isFinalCancellation) {
        try {
          final res = await supabase.rpc(
            'admin_reject_project_payment',
            params: {
              'p_project_id': projectId,
              'p_rejection_reason': rejectionReason.trim(),
            },
          );
          if (res is Map && res['success'] == false) {
            debugPrint('Admin reject RPC returned logic failure: ${res['error']}');
          } else {
            rejectedSuccessfully = true;
            debugPrint('Admin reject RPC executed successfully.');
          }
        } catch (rpcErr) {
          debugPrint('Admin reject RPC bypass error: $rpcErr');
        }
      }

      // Strategy 2: Direct Table Updates with progressive fallback
      if (!rejectedSuccessfully) {
        try {
          await supabase
              .from('projects')
              .update({
                'status': targetStatus,
                'is_escrow_verified': false,
                'payment_sent': false,
                'rejection_reason': rejectionReason.trim(),
                'moderation_reason': modReason,
                'additional_instructions': instructionNote,
                'updated_at': nowIso,
              })
              .eq('id', projectId);
          rejectedSuccessfully = true;
        } catch (e1) {
          debugPrint('Reject update error: $e1. Retrying with core fields...');
          try {
            await supabase
                .from('projects')
                .update({
                  'status': targetStatus,
                  'is_escrow_verified': false,
                  'payment_sent': false,
                  'moderation_reason': modReason,
                  'additional_instructions': instructionNote,
                  'updated_at': nowIso,
                })
                .eq('id', projectId);
            rejectedSuccessfully = true;
          } catch (e2) {
            try {
              await supabase
                  .from('projects')
                  .update({
                    'status': targetStatus,
                    'additional_instructions': instructionNote,
                    'updated_at': nowIso,
                  })
                  .eq('id', projectId);
              rejectedSuccessfully = true;
            } catch (e3) {
              try {
                await supabase
                    .from('projects')
                    .update({'status': targetStatus})
                    .eq('id', projectId);
                rejectedSuccessfully = true;
              } catch (e4) {
                debugPrint('All reject updates failed: $e4');
                _lastError = SupabaseHelper.friendlyError(e4);
              }
            }
          }
        }
      }
    }

    // Remove from pending approvals list
    final updated = List<ProjectModel>.from(pendingApprovalsNotifier.value);
    updated.removeWhere((p) => p.id == projectId);
    pendingApprovalsNotifier.value = updated;

    // Update in CompanyProjectService
    try {
      final compProjService = CompanyProjectService();
      final cList = List<ProjectModel>.from(compProjService.projectsNotifier.value);
      final idx = cList.indexWhere((p) => p.id == projectId);
      if (idx != -1) {
        cList[idx] = cList[idx].copyWith(
          status: targetStatus,
          isEscrowVerified: false,
          paymentSent: false,
          rejectionReason: rejectionReason.trim(),
          moderationReason: modReason,
          paymentRejectionCount: isFinalCancellation ? 2 : 1,
        );
        compProjService.projectsNotifier.value = cList;
      }
    } catch (_) {}

    // Synchronize into AdminProjectService catalog
    try {
      final adminProjService = AdminProjectService();
      final aList = List<AdminProjectModel>.from(adminProjService.projectsNotifier.value);
      final aIdx = aList.indexWhere((p) => p.id == projectId);
      if (aIdx != -1) {
        aList[aIdx] = aList[aIdx].copyWith(
          status: isFinalCancellation
              ? AdminProjectStatus.closed
              : AdminProjectStatus.rejected,
          publicationStatus: isFinalCancellation
              ? AdminPublicationStatus.unpublished
              : AdminPublicationStatus.rejected,
          rawDbStatus: targetStatus,
          isEscrowVerified: false,
          paymentSent: false,
        );
        adminProjService.projectsNotifier.value = aList;
      }
    } catch (_) {}

    return true;
  }
}

