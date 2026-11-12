import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';

class CompanyProjectService {
  static final CompanyProjectService _instance =
      CompanyProjectService._internal();

  factory CompanyProjectService() => _instance;

  CompanyProjectService._internal();

  final ValueNotifier<List<ProjectModel>> projectsNotifier =
      ValueNotifier<List<ProjectModel>>([]);

  List<ProjectModel> get allProjects => projectsNotifier.value;
  List<ProjectModel> get projects => projectsNotifier.value;

  List<ProjectModel> getProjectsForCompany(String companyId) {
    if (companyId.isEmpty) return projectsNotifier.value;
    return projectsNotifier.value
        .where((p) => p.companyId == companyId || p.companyId.isEmpty)
        .toList();
  }

  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final profile = CompanyProfileService().currentProfile;
      final List<String> orParts = [
        'posted_by.eq.${user.id}',
        'user_id.eq.${user.id}',
      ];
      if (SupabaseHelper.isUuid(profile.id)) {
        orParts.add('company_id.eq.${profile.id}');
      }
      if (profile.companyName.trim().isNotEmpty) {
        orParts.add('company_name.eq.${profile.companyName.trim()}');
      }

      var rows = await supabase
          .from('projects')
          .select()
          .or(orParts.join(','))
          .order('created_at', ascending: false);

      if (rows.isEmpty) {
        final allRows = await supabase
            .from('projects')
            .select()
            .order('created_at', ascending: false);
        rows = allRows.where((r) {
          final pBy = r['posted_by']?.toString() ?? '';
          final uId = r['user_id']?.toString() ?? '';
          final cId = r['company_id']?.toString() ?? '';
          final cName =
              r['company_name']?.toString().toLowerCase().trim() ?? '';
          final profileName = profile.companyName.toLowerCase().trim();
          return pBy == user.id ||
              uId == user.id ||
              (profile.id.isNotEmpty && cId == profile.id) ||
              (profileName.isNotEmpty && cName == profileName) ||
              (pBy.isEmpty && cId.isEmpty);
        }).toList();
      }

      final projectIds = rows
          .map((r) => r['id']?.toString() ?? '')
          .where((id) => SupabaseHelper.isUuid(id))
          .toList();

      final Map<String, int> appCounts = {};
      final Map<String, String> assignedNames = {};

      if (projectIds.isNotEmpty) {
        try {
          final appRows = await supabase
              .from('applications')
              .select('project_id, student_name, university, status')
              .inFilter('project_id', projectIds);

          for (final raw in appRows) {
            final pid = raw['project_id']?.toString() ?? '';
            if (pid.isEmpty) continue;
            appCounts[pid] = (appCounts[pid] ?? 0) + 1;
            final st = raw['status']?.toString() ?? '';
            if ((st == 'Accepted' ||
                    st == 'In Progress' ||
                    st == 'Under Review' ||
                    st == 'Revision Requested' ||
                    st == 'Completed') &&
                !assignedNames.containsKey(pid)) {
              final sName = raw['student_name']?.toString().trim() ?? '';
              final sUni = raw['university']?.toString().trim() ?? '';
              if (sName.isNotEmpty) {
                assignedNames[pid] = sUni.isNotEmpty ? '$sName ($sUni)' : sName;
              }
            }
          }
        } catch (e) {
          debugPrint('CompanyProjectService app count load skipped: $e');
        }
      }

      final List<ProjectModel> loaded = rows.map((raw) {
        final p = Map<String, dynamic>.from(raw);
        final pid = p['id']?.toString() ?? '';
        final skills = SupabaseHelper.parseStringList(p['skills']);
        final dbAssigned = p['assigned_student']?.toString().trim() ?? '';
        final computedAssigned = dbAssigned.isNotEmpty
            ? dbAssigned
            : assignedNames[pid];

        return ProjectModel(
          id: pid,
          title: p['title']?.toString() ?? 'Untitled Project',
          category: p['category']?.toString() ?? 'Development',
          description: p['description']?.toString() ?? '',
          requirements: p['requirements']?.toString() ?? '',
          skillsRequired: skills,
          deliverables: p['deliverables']?.toString() ?? '',
          deadline: p['deadline']?.toString() ?? 'Flexible',
          projectType: p['work_mode']?.toString() ?? 'Remote',
          openings: (p['openings'] as num?)?.toInt() ?? 1,
          additionalInstructions:
              p['additional_instructions']?.toString() ?? '',
          companyName: (p['company_name']?.toString().trim().isNotEmpty == true)
              ? p['company_name'].toString().trim()
              : (profile.companyName.isNotEmpty
                    ? profile.companyName
                    : 'Company Partner'),
          companyId: p['company_id']?.toString() ?? profile.id,
          status: p['status']?.toString() ?? 'Open',
          duration: p['duration']?.toString() ?? '3-4 weeks',
          budget: p['budget']?.toString() ?? '',
          applicantsCount: appCounts[pid] ?? 0,
          assignedStudent: computedAssigned,
          progress: (p['progress'] as num?)?.toDouble() ?? 0.0,
          createdAt: SupabaseHelper.formatRelativeTime(p['created_at']),
          paymentSent: p['payment_sent'] == true,
        );
      }).toList();

      projectsNotifier.value = loaded;
    } catch (e) {
      debugPrint('CompanyProjectService loadFromSupabase error: $e');
    }
  }

  Future<void> publishProject(ProjectModel project) async {
    await _persistNewProject(project.copyWith(status: 'Open'));
  }

  Future<void> saveDraft(ProjectModel project) async {
    await _persistNewProject(project.copyWith(status: 'Draft'));
  }

  Future<void> _persistNewProject(ProjectModel project) async {
    final profile = CompanyProfileService().currentProfile;
    final cleanId = SupabaseHelper.isUuid(project.id)
        ? project.id
        : SupabaseHelper.generateUuid();
    final companyName = project.companyName.trim().isNotEmpty
        ? project.companyName.trim()
        : (profile.companyName.isNotEmpty
              ? profile.companyName
              : 'Company Partner');
    var companyId = project.companyId.isNotEmpty
        ? project.companyId
        : profile.id;

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;

    if (supabase != null && user != null && !SupabaseHelper.isUuid(companyId)) {
      try {
        final cRow = await supabase
            .from('companies')
            .select('id')
            .eq('user_id', user.id)
            .limit(1)
            .maybeSingle();
        if (cRow != null &&
            SupabaseHelper.isUuid(cRow['id']?.toString() ?? '')) {
          companyId = cRow['id'].toString();
        }
      } catch (_) {}
    }

    final nowIso = DateTime.now().toIso8601String();
    final savedProject = project.copyWith(
      id: cleanId,
      openings: 1,
      companyName: companyName,
      companyId: companyId,
      createdAt: 'Just now',
    );

    if (supabase != null && user != null) {
      await supabase.from('projects').insert({
        'id': cleanId,
        if (SupabaseHelper.isUuid(companyId)) 'company_id': companyId,
        'posted_by': user.id,
        'user_id': user.id,
        'title': savedProject.title,
        'company_name': companyName,
        'category': savedProject.category,
        'description': savedProject.description,
        'requirements': savedProject.requirements,
        'deliverables': savedProject.deliverables,
        'additional_instructions': savedProject.additionalInstructions,
        'work_mode': savedProject.projectType,
        'duration': savedProject.duration,
        'deadline': savedProject.deadline,
        'openings': 1,
        'skills': savedProject.skillsRequired,
        'stipend': savedProject.budget.isNotEmpty
            ? savedProject.budget
            : 'Academic Credit / Verified Certificate',
        'budget': savedProject.budget,
        'status': savedProject.status,
        'progress': savedProject.progress,
        'payment_sent': savedProject.paymentSent,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
    }

    final updatedList = List<ProjectModel>.from(projectsNotifier.value);
    updatedList.insert(0, savedProject);
    projectsNotifier.value = updatedList;

    // Keep AppDataService synchronized for immediate student visibility
    AppDataService.instance.addProjectLocally({
      'id': cleanId,
      'title': savedProject.title,
      'company': companyName,
      'companyId': companyId,
      'companyUserId': user?.id ?? '',
      'category': savedProject.category,
      'duration': savedProject.duration,
      'workMode': savedProject.projectType,
      'deadline': savedProject.deadline,
      'status': savedProject.status,
      'stipend': savedProject.budget.isNotEmpty
          ? savedProject.budget
          : 'Academic Credit / Verified Certificate',
      'budget': savedProject.budget,
      'description': savedProject.description,
      'requirements': savedProject.requirements,
      'deliverables': savedProject.deliverables,
      'additionalInstructions': savedProject.additionalInstructions,
      'openings': 1,
      'skills': savedProject.skillsRequired,
      'createdAt': nowIso,
    });

    await CompanyProfileService.persistLocalCache();
  }

  Future<void> updateProject(ProjectModel project) async {
    final normalizedProject = project.copyWith(openings: 1);
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null &&
        user != null &&
        SupabaseHelper.isUuid(normalizedProject.id)) {
      await supabase
          .from('projects')
          .update({
            'title': normalizedProject.title,
            'category': normalizedProject.category,
            'description': normalizedProject.description,
            'requirements': normalizedProject.requirements,
            'deliverables': normalizedProject.deliverables,
            'additional_instructions': normalizedProject.additionalInstructions,
            'work_mode': normalizedProject.projectType,
            'duration': normalizedProject.duration,
            'deadline': normalizedProject.deadline,
            'openings': 1,
            'skills': normalizedProject.skillsRequired,
            'status': normalizedProject.status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', normalizedProject.id);
    }

    projectsNotifier.value = projectsNotifier.value
        .map((p) => p.id == normalizedProject.id ? normalizedProject : p)
        .toList();
  }

  Future<void> updateProjectStatus(
    String projectId,
    String newStatus, {
    String? assignedStudent,
    double? progress,
  }) async {
    final resolvedProgress =
        progress ?? (newStatus == 'Completed' ? 1.0 : null);

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('projects')
            .update({
              'status': newStatus,
              'assigned_student': ?assignedStudent,
              'progress': ?resolvedProgress,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('CompanyProjectService updateProjectStatus error: $e');
      }
    }

    projectsNotifier.value = projectsNotifier.value.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          status: newStatus,
          assignedStudent: assignedStudent ?? p.assignedStudent,
          progress: resolvedProgress ?? p.progress,
        );
      }
      return p;
    }).toList();
  }

  Future<void> markProjectPaymentSent(String projectId) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw StateError('A signed-in company account is required.');
    }
    if (!SupabaseHelper.isUuid(projectId)) {
      throw ArgumentError.value(projectId, 'projectId', 'Must be a UUID.');
    }

    await supabase.rpc(
      'mark_project_payment_sent',
      params: {'p_project_id': projectId},
    );

    projectsNotifier.value = projectsNotifier.value
        .map(
          (project) => project.id == projectId
              ? project.copyWith(paymentSent: true)
              : project,
        )
        .toList();
  }

  void updateApplicantCount(String projectId, int count) {
    projectsNotifier.value = projectsNotifier.value
        .map((p) => p.id == projectId ? p.copyWith(applicantsCount: count) : p)
        .toList();
  }

  Future<void> deleteProject(String projectId) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase.from('projects').delete().eq('id', projectId);
      } catch (e) {
        debugPrint('CompanyProjectService deleteProject error: $e');
      }
    }

    projectsNotifier.value = projectsNotifier.value
        .where((p) => p.id != projectId)
        .toList();

    AppDataService.instance.removeProjectLocal(projectId);
    await CompanyProfileService.persistLocalCache();
  }

  List<ProjectModel> getOpenProjectsForStudents() {
    return projectsNotifier.value.where((p) => p.status == 'Open').toList();
  }

  void reset() {
    projectsNotifier.value = [];
  }
}
