import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

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

  String? _lastError;
  String? get lastError => _lastError;

  List<ProjectModel> get pendingProjects => pendingApprovalsNotifier.value;
  int get pendingCount => pendingProjects.length;

  /// 1. Fetches all projects waiting for payment verification (status = 'pending_verification').
  Future<List<ProjectModel>> loadPendingApprovals({
    bool forceRefresh = false,
  }) async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      // In offline/test environments, extract from CompanyProjectService
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isPendingVerification)
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
          .toList();

      pendingApprovalsNotifier.value = list;
      return list;
    } catch (e) {
      debugPrint('AdminProjectApprovalService loadPendingApprovals error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      final local = CompanyProjectService()
          .allProjects
          .where((p) => p.isPendingVerification)
          .toList();
      pendingApprovalsNotifier.value = local;
      return local;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// 2. Approves payment, verifies escrow, and publishes project live to students.
  /// Sets: status = 'open', is_escrow_verified = true, verified_at = now().
  Future<bool> markAsPaidAndPublish({
    required String projectId,
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
              'status': 'Open',
              'is_escrow_verified': true,
              'verified_at': nowIso,
              'updated_at': nowIso,
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('AdminProjectApprovalService markAsPaidAndPublish error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Update pending approvals list locally
    final updated = List<ProjectModel>.from(pendingApprovalsNotifier.value);
    updated.removeWhere((p) => p.id == projectId);
    pendingApprovalsNotifier.value = updated;

    // Synchronize into AdminProjectService catalog
    try {
      final adminProjService = AdminProjectService();
      await adminProjService.loadFromSupabase();
    } catch (_) {}

    // Synchronize into CompanyProjectService
    try {
      final compProjService = CompanyProjectService();
      final cList = List<ProjectModel>.from(compProjService.projectsNotifier.value);
      final idx = cList.indexWhere((p) => p.id == projectId);
      if (idx != -1) {
        cList[idx] = cList[idx].copyWith(
          status: 'Open',
          isEscrowVerified: true,
          verifiedAt: nowIso,
        );
        compProjService.projectsNotifier.value = cList;
      }
    } catch (_) {}

    return true;
  }

  /// 3. Rejects payment proof with an explanation.
  /// Sets: status = 'rejected', is_escrow_verified = false.
  Future<bool> rejectPayment({
    required String projectId,
    required String rejectionReason,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'rejected',
              'is_escrow_verified': false,
              'additional_instructions': 'Payment Verification Rejected: $rejectionReason',
              'updated_at': nowIso,
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('AdminProjectApprovalService rejectPayment error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
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
          status: 'rejected',
          isEscrowVerified: false,
          additionalInstructions: 'Payment Rejected: $rejectionReason',
        );
        compProjService.projectsNotifier.value = cList;
      }
    } catch (_) {}

    return true;
  }
}

