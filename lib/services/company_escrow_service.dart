import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/platform_payment_method_model.dart';
import 'package:link_vibe/feature/admin/services/admin_payment_service.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

/// Pure Service Layer for Company Upfront Escrow Workflows.
/// Strictly encapsulates all Supabase database & storage calls away from UI screens.
class CompanyEscrowService {
  static final CompanyEscrowService _instance =
      CompanyEscrowService._internal();
  factory CompanyEscrowService() => _instance;
  CompanyEscrowService._internal();

  String? _lastError;
  String? get lastError => _lastError;

  /// 1. Creates a project draft with status 'pending_payment'.
  /// The project is NOT published to students until Admin verifies escrow.
  Future<ProjectModel> createProjectDraft({
    required ProjectModel project,
    required double escrowAmount,
  }) async {
    _lastError = null;
    final profile = CompanyProfileService().currentProfile;
    final cleanId = SupabaseHelper.isUuid(project.id)
        ? project.id
        : SupabaseHelper.generateUuid();

    final companyName = project.companyName.trim().isNotEmpty
        ? project.companyName.trim()
        : (profile.companyName.isNotEmpty
            ? profile.companyName
            : 'Company Partner');
    final companyId = project.companyId.isNotEmpty
        ? project.companyId
        : profile.id;

    final draftProject = project.copyWith(
      id: cleanId,
      companyName: companyName,
      companyId: companyId,
      status: 'pending_payment',
      escrowAmount: escrowAmount,
      isEscrowVerified: false,
      createdAt: 'Just now',
    );

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;

    if (supabase != null && user != null) {
      final nowIso = DateTime.now().toIso8601String();
      try {
        await supabase.from('projects').insert({
          'id': cleanId,
          if (SupabaseHelper.isUuid(companyId)) 'company_id': companyId,
          'posted_by': user.id,
          'user_id': user.id,
          'title': draftProject.title,
          'company_name': companyName,
          'category': draftProject.category,
          'description': draftProject.description,
          'requirements': draftProject.requirements,
          'deliverables': draftProject.deliverables,
          'additional_instructions': draftProject.additionalInstructions,
          'work_mode': draftProject.projectType,
          'duration': draftProject.duration,
          'deadline': draftProject.deadline,
          'openings': draftProject.openings,
          'skills': draftProject.skillsRequired,
          'status': 'pending_payment',
          'escrow_amount': escrowAmount,
          'is_escrow_verified': false,
          'progress': draftProject.progress,
          'created_at': nowIso,
          'updated_at': nowIso,
        });
      } catch (e) {
        debugPrint('CompanyEscrowService createProjectDraft error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // Update in-memory CompanyProjectService list
    final companyProjService = CompanyProjectService();
    final updatedList = List<ProjectModel>.from(companyProjService.projectsNotifier.value);
    updatedList.removeWhere((p) => p.id == draftProject.id);
    updatedList.insert(0, draftProject);
    companyProjService.projectsNotifier.value = updatedList;

    return draftProject;
  }

  /// 2. Fetches active Admin platform payment accounts from Supabase.
  Future<List<PlatformPaymentMethodModel>> getActivePlatformPaymentMethods() async {
    _lastError = null;
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase == null) {
      return AdminPaymentService.defaultFallbackMethods
          .where((m) => m.isActive)
          .toList();
    }

    try {
      final rows = await supabase
          .from('platform_payment_methods')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final list = (rows as List<dynamic>)
          .map((r) =>
              PlatformPaymentMethodModel.fromJson(r as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return AdminPaymentService.defaultFallbackMethods
            .where((m) => m.isActive)
            .toList();
      }
      return list;
    } catch (e) {
      debugPrint('CompanyEscrowService getActivePlatformPaymentMethods error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      return AdminPaymentService.defaultFallbackMethods
          .where((m) => m.isActive)
          .toList();
    }
  }

  /// 3. Uploads receipt image screenshot to Supabase Storage bucket `payment_receipts`.
  Future<String?> uploadReceiptImage({
    required String projectId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    _lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      // In offline/test environments, generate a synthetic mock storage URL
      return 'https://supabase.mock.storage/payment_receipts/$projectId-$fileName';
    }

    try {
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'jpg';
      final path = '$projectId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from('payment_receipts').uploadBinary(
            path,
            imageBytes,
          );

      final publicUrl =
          supabase.storage.from('payment_receipts').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('CompanyEscrowService uploadReceiptImage error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      return null;
    }
  }

  /// 4. Submits Transaction ID (TID), Payment Method, and Receipt URL.
  /// Transitions project status from 'pending_payment' to 'pending_verification'.
  Future<bool> submitPaymentProof({
    required String projectId,
    required String transactionId,
    required String paymentMethodUsed,
    required String receiptUrl,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': 'pending_verification',
              'transaction_id': transactionId.trim(),
              'payment_method_used': paymentMethodUsed.trim(),
              'payment_receipt_url': receiptUrl.trim(),
              'updated_at': nowIso,
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('CompanyEscrowService submitPaymentProof error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
        return false;
      }
    }

    // Update in-memory project model
    final companyProjService = CompanyProjectService();
    final list = List<ProjectModel>.from(companyProjService.projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: 'pending_verification',
        transactionId: transactionId.trim(),
        paymentMethodUsed: paymentMethodUsed.trim(),
        paymentReceiptUrl: receiptUrl.trim(),
      );
      companyProjService.projectsNotifier.value = list;
    }

    return true;
  }

  /// 5. Fetches fresh project by ID.
  Future<ProjectModel?> getProjectById(String projectId) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null || !SupabaseHelper.isUuid(projectId)) {
      final list = CompanyProjectService().allProjects;
      try {
        return list.firstWhere((p) => p.id == projectId);
      } catch (_) {
        return null;
      }
    }

    try {
      final row = await supabase
          .from('projects')
          .select()
          .eq('id', projectId)
          .maybeSingle();

      if (row == null) return null;
      return ProjectModel.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('CompanyEscrowService getProjectById error: $e');
      return null;
    }
  }
}

