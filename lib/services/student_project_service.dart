import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

/// Pure Service Layer for Student Project Catalog.
/// Ensures Students ONLY receive projects that are strictly verified and escrow-funded.
class StudentProjectService {
  static final StudentProjectService _instance =
      StudentProjectService._internal();
  factory StudentProjectService() => _instance;
  StudentProjectService._internal();

  final ValueNotifier<List<ProjectModel>> verifiedProjectsNotifier =
      ValueNotifier<List<ProjectModel>>([]);

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  String? _lastError;
  String? get lastError => _lastError;

  List<ProjectModel> get verifiedProjects => verifiedProjectsNotifier.value;

  /// Fetches live open projects from Supabase.
  /// Strictly filters out unverified projects (pending_payment, pending_verification, drafts).
  Future<List<ProjectModel>> fetchVerifiedOpenProjects({
    bool forceRefresh = false,
  }) async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      // In offline/test environments, return any local open projects that are verified
      final local = CompanyProjectService()
          .allProjects
          .where((p) =>
              (p.status.toLowerCase() == 'open') && p.isEscrowVerified)
          .toList();
      verifiedProjectsNotifier.value = local;
      isLoadingNotifier.value = false;
      return local;
    }

    try {
      final rows = await supabase
          .from('projects')
          .select()
          .eq('is_escrow_verified', true)
          .order('created_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((r) => ProjectModel.fromJson(Map<String, dynamic>.from(r)))
          .where((p) => p.status.toLowerCase() == 'open')
          .toList();

      verifiedProjectsNotifier.value = list;
      return list;
    } catch (e) {
      debugPrint('StudentProjectService fetchVerifiedOpenProjects error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      final local = CompanyProjectService()
          .allProjects
          .where((p) =>
              (p.status.toLowerCase() == 'open') && p.isEscrowVerified)
          .toList();
      verifiedProjectsNotifier.value = local;
      return local;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Filters current verified projects by category and search keyword.
  List<ProjectModel> filterProjects({
    String category = 'All',
    String searchQuery = '',
  }) {
    return verifiedProjects.where((p) {
      if (category != 'All' &&
          !p.category.toLowerCase().contains(category.toLowerCase())) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final inTitle = p.title.toLowerCase().contains(q);
        final inComp = p.companyName.toLowerCase().contains(q);
        final inSkills = p.skillsRequired.any((s) => s.toLowerCase().contains(q));
        if (!inTitle && !inComp && !inSkills) return false;
      }
      return true;
    }).toList();
  }
}

