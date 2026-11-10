import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

/// Enterprise Project Management & Moderation Service backed by Supabase `projects` & `applications`.
class AdminProjectService {
  static final AdminProjectService _instance = AdminProjectService._internal();
  factory AdminProjectService() => _instance;

  AdminProjectService._internal();

  final ValueNotifier<List<AdminProjectModel>> projectsNotifier =
      ValueNotifier<List<AdminProjectModel>>([]);

  // Stores project_id -> owner user_id for targeted governance notifications
  final Map<String, String> _projectOwnerUserIds = {};

  List<AdminProjectModel> get allProjects => projectsNotifier.value;

  int get totalCount => projectsNotifier.value.length;
  int get pendingReviewCount => projectsNotifier.value
      .where((p) => p.status == AdminProjectStatus.pendingReview)
      .length;
  int get publishedCount => projectsNotifier.value
      .where((p) => p.status == AdminProjectStatus.published)
      .length;
  int get activeCount => projectsNotifier.value
      .where((p) => p.status == AdminProjectStatus.active)
      .length;
  int get completedCount => projectsNotifier.value
      .where((p) => p.status == AdminProjectStatus.completed)
      .length;
  int get closedCount => projectsNotifier.value
      .where((p) => p.status == AdminProjectStatus.closed)
      .length;
  int get removedCount => projectsNotifier.value
      .where((p) => p.status == AdminProjectStatus.removed)
      .length;

  /// Fetches live projects catalog, application counts, and moderation history from Supabase.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final rows = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      final Map<String, int> appCounts = {};
      try {
        final appRows =
            await supabase.from('applications').select('project_id');
        for (final raw in appRows) {
          final pid = raw['project_id']?.toString() ?? '';
          if (pid.isNotEmpty) {
            appCounts[pid] = (appCounts[pid] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint('AdminProjectService application counts skipped: $e');
      }

      final List<Map<String, dynamic>> auditRows = [];
      try {
        final rawLogs = await supabase
            .from('admin_audit_logs')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        for (final raw in rawLogs) {
          auditRows.add(Map<String, dynamic>.from(raw));
        }
      } catch (_) {}

      final List<AdminProjectModel> loaded = [];
      _projectOwnerUserIds.clear();

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final title = row['title']?.toString() ?? 'Untitled Project';
        final ownerUid =
            row['posted_by']?.toString() ?? row['user_id']?.toString() ?? '';
        if (id.isNotEmpty && ownerUid.isNotEmpty) {
          _projectOwnerUserIds[id] = ownerUid;
        }

        final dbStatus = (row['status']?.toString() ?? 'Open').trim();
        final parsed = _parseDbStatus(dbStatus);

        final createdDt =
            SupabaseHelper.parseDate(row['created_at']) ?? DateTime.now();
        final createdStr =
            '${createdDt.year}-${createdDt.month.toString().padLeft(2, '0')}-${createdDt.day.toString().padLeft(2, '0')}';

        final rawDeadline = row['deadline']?.toString() ?? '';
        final deadlineDt = SupabaseHelper.parseDate(rawDeadline) ??
            createdDt.add(const Duration(days: 30));
        final deadlineStr = rawDeadline.isNotEmpty ? rawDeadline : 'Flexible';

        final matchingLogs = auditRows
            .where((l) {
              final target = l['target']?.toString() ?? '';
              return target == id ||
                  target.toLowerCase() == title.toLowerCase();
            })
            .map((l) => ProjectModerationRecord(
                  id: l['id']?.toString() ?? '',
                  action: l['action']?.toString() ?? 'Moderation Event',
                  moderatorName: l['admin_email']?.toString() ?? 'Administrator',
                  timestamp: SupabaseHelper.formatRelativeTime(l['created_at']),
                  reason: l['details']?.toString(),
                ))
            .toList();

        loaded.add(
          AdminProjectModel(
            id: id,
            title: title,
            companyId: row['company_id']?.toString() ?? ownerUid,
            companyName: row['company_name']?.toString() ?? 'Corporate Partner',
            category: row['category']?.toString() ?? 'Development',
            description: row['description']?.toString() ?? '',
            requirements: row['requirements']?.toString() ?? '',
            skillsRequired: SupabaseHelper.parseStringList(row['skills']),
            deliverables: row['deliverables']?.toString() ?? '',
            deadline: deadlineStr,
            deadlineDateTime: deadlineDt,
            projectType: row['work_mode']?.toString() ?? 'Remote',
            duration: row['duration']?.toString() ?? '3-4 Weeks',
            openings: (row['openings'] as num?)?.toInt() ?? 1,
            additionalInstructions:
                row['additional_instructions']?.toString() ?? '',
            applicantsCount: appCounts[id] ?? 0,
            assignedStudent: row['assigned_student']?.toString(),
            progress: (row['progress'] as num?)?.toDouble() ?? 0.0,
            status: parsed.$1,
            publicationStatus: parsed.$2,
            createdAt: createdStr,
            createdDateTime: createdDt,
            moderationReason: row['moderation_reason']?.toString(),
            moderationHistory: matchingLogs,
            isArchived: parsed.$1 == AdminProjectStatus.removed,
          ),
        );
      }

      projectsNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminProjectService loadFromSupabase error: $e');
    }
  }

  (AdminProjectStatus, AdminPublicationStatus) _parseDbStatus(String dbStatus) {
    switch (dbStatus.toLowerCase()) {
      case 'draft':
        return (AdminProjectStatus.draft, AdminPublicationStatus.unpublished);
      case 'pending review':
      case 'pending':
        return (
          AdminProjectStatus.pendingReview,
          AdminPublicationStatus.pendingModeration,
        );
      case 'in progress':
      case 'active':
        return (AdminProjectStatus.active, AdminPublicationStatus.published);
      case 'completed':
        return (AdminProjectStatus.completed, AdminPublicationStatus.published);
      case 'closed':
        return (AdminProjectStatus.closed, AdminPublicationStatus.unpublished);
      case 'rejected':
        return (AdminProjectStatus.rejected, AdminPublicationStatus.rejected);
      case 'removed':
      case 'cancelled':
      case 'flagged':
        return (AdminProjectStatus.removed, AdminPublicationStatus.removed);
      case 'open':
      case 'published':
      default:
        return (AdminProjectStatus.published, AdminPublicationStatus.published);
    }
  }

  Future<bool> publishProject({
    required String projectId,
    required String moderatorName,
  }) async {
    return _updateProjectModeration(
      projectId: projectId,
      dbStatus: 'Open',
      adminStatus: AdminProjectStatus.published,
      pubStatus: AdminPublicationStatus.published,
      moderatorName: moderatorName,
      actionLabel: 'Published & Open for Applications',
      auditAction: 'PROJECT_PUBLISHED',
      reason: 'Approved and published to student explore feed.',
      clearModerationReason: true,
      isArchived: false,
    );
  }

  Future<bool> unpublishProject({
    required String projectId,
    required String reason,
    required String moderatorName,
  }) async {
    return _updateProjectModeration(
      projectId: projectId,
      dbStatus: 'Closed',
      adminStatus: AdminProjectStatus.closed,
      pubStatus: AdminPublicationStatus.unpublished,
      moderatorName: moderatorName,
      actionLabel: 'Listing Unpublished',
      auditAction: 'PROJECT_UNPUBLISHED',
      reason: reason,
    );
  }

  Future<bool> closeProject({
    required String projectId,
    required String moderatorName,
  }) async {
    return _updateProjectModeration(
      projectId: projectId,
      dbStatus: 'Closed',
      adminStatus: AdminProjectStatus.closed,
      pubStatus: AdminPublicationStatus.unpublished,
      moderatorName: moderatorName,
      actionLabel: 'Project Concluded & Closed',
      auditAction: 'PROJECT_CLOSED',
      reason: 'Project closed by administrative governance.',
    );
  }

  Future<bool> removePolicyViolatingProject({
    required String projectId,
    required String reason,
    required String moderatorName,
  }) async {
    return _updateProjectModeration(
      projectId: projectId,
      dbStatus: 'Removed',
      adminStatus: AdminProjectStatus.removed,
      pubStatus: AdminPublicationStatus.removed,
      moderatorName: moderatorName,
      actionLabel: 'Removed for Policy Violation',
      auditAction: 'PROJECT_REMOVED_POLICY',
      reason: reason,
      isArchived: true,
    );
  }

  Future<bool> rejectProject({
    required String projectId,
    required String reason,
    required String moderatorName,
  }) async {
    return _updateProjectModeration(
      projectId: projectId,
      dbStatus: 'Rejected',
      adminStatus: AdminProjectStatus.rejected,
      pubStatus: AdminPublicationStatus.rejected,
      moderatorName: moderatorName,
      actionLabel: 'Listing Rejected',
      auditAction: 'PROJECT_REJECTED',
      reason: reason,
    );
  }

  Future<bool> restoreRemovedProject({
    required String projectId,
    required String moderatorName,
  }) async {
    return _updateProjectModeration(
      projectId: projectId,
      dbStatus: 'Open',
      adminStatus: AdminProjectStatus.published,
      pubStatus: AdminPublicationStatus.published,
      moderatorName: moderatorName,
      actionLabel: 'Listing Restored from Policy Removal',
      auditAction: 'PROJECT_RESTORED',
      reason: 'Restored after compliance audit clarification.',
      clearModerationReason: true,
      isArchived: false,
    );
  }

  Future<bool> _updateProjectModeration({
    required String projectId,
    required String dbStatus,
    required AdminProjectStatus adminStatus,
    required AdminPublicationStatus pubStatus,
    required String moderatorName,
    required String actionLabel,
    required String auditAction,
    String? reason,
    bool clearModerationReason = false,
    bool? isArchived,
  }) async {
    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase.from('projects').update({
          'status': dbStatus,
          'moderation_reason': clearModerationReason ? null : reason,
          'moderator_name': moderatorName,
          'updated_at': nowIso,
        }).eq('id', projectId);

        final ownerId = _projectOwnerUserIds[projectId];
        if (SupabaseHelper.isUuid(ownerId)) {
          await supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'Project Governance Update: ${project.title}',
            'message': reason?.isNotEmpty == true
                ? '$actionLabel — $reason'
                : actionLabel,
            'type': 'moderation',
            'project_id': projectId,
            'actor_name': moderatorName,
          });
        }

        await supabase.from('admin_audit_logs').insert({
          'admin_email':
              SupabaseHelper.currentUser?.email ?? 'admin@campusconnect.edu.pk',
          'action': auditAction,
          'target': project.title,
          'details': reason ?? actionLabel,
        });
      } catch (e) {
        debugPrint('AdminProjectService _updateProjectModeration error: $e');
        return false;
      }
    }

    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: actionLabel,
        moderatorName: moderatorName,
        timestamp: 'Just now',
        reason: reason,
      ),
    );

    list[idx] = AdminProjectModel(
      id: project.id,
      title: project.title,
      companyId: project.companyId,
      companyName: project.companyName,
      category: project.category,
      description: project.description,
      requirements: project.requirements,
      skillsRequired: project.skillsRequired,
      deliverables: project.deliverables,
      deadline: project.deadline,
      deadlineDateTime: project.deadlineDateTime,
      projectType: project.projectType,
      duration: project.duration,
      openings: project.openings,
      additionalInstructions: project.additionalInstructions,
      applicantsCount: project.applicantsCount,
      assignedStudent: project.assignedStudent,
      progress: project.progress,
      status: adminStatus,
      publicationStatus: pubStatus,
      createdAt: project.createdAt,
      createdDateTime: project.createdDateTime,
      moderationReason: clearModerationReason ? null : reason,
      moderationHistory: history,
      isArchived: isArchived ?? project.isArchived,
    );
    projectsNotifier.value = list;

    _syncToCompanyProjectService(projectId, dbStatus);
    return true;
  }

  /// Bulk Moderation across selected projects.
  Future<void> bulkModerateProjects({
    required List<String> projectIds,
    required AdminProjectStatus newStatus,
    required String moderatorName,
    String? reason,
  }) async {
    for (final pid in projectIds) {
      if (newStatus == AdminProjectStatus.published) {
        await publishProject(projectId: pid, moderatorName: moderatorName);
      } else if (newStatus == AdminProjectStatus.closed) {
        await closeProject(projectId: pid, moderatorName: moderatorName);
      } else if (newStatus == AdminProjectStatus.removed) {
        await removePolicyViolatingProject(
          projectId: pid,
          reason: reason ?? 'Batch policy moderation removal.',
          moderatorName: moderatorName,
        );
      } else if (newStatus == AdminProjectStatus.rejected) {
        await rejectProject(
          projectId: pid,
          reason: reason ?? 'Batch listing rejection.',
          moderatorName: moderatorName,
        );
      }
    }
  }

  void _syncToCompanyProjectService(String projectId, String newCompanyStatus) {
    try {
      final compService = CompanyProjectService();
      final currentList =
          List<ProjectModel>.from(compService.projectsNotifier.value);
      final idx = currentList.indexWhere((p) => p.id == projectId);
      if (idx != -1) {
        currentList[idx] = currentList[idx].copyWith(status: newCompanyStatus);
        compService.projectsNotifier.value = currentList;
      }
    } catch (_) {}
  }

  String exportProjectsCsv(List<AdminProjectModel> projects) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Title,Company,Category,Project Type,Duration,Deadline,Applicants,Status,Publication Status,Created Date,Is Archived',
    );

    for (final p in projects) {
      buffer.writeln(
        '${p.id},"${p.title}","${p.companyName}","${p.category}",${p.projectType},"${p.duration}",${p.deadline},${p.applicantsCount},${p.statusDisplay},${p.publicationStatusDisplay},${p.createdAt},${p.isArchived}',
      );
    }
    return buffer.toString();
  }

  void reset() {
    projectsNotifier.value = [];
    _projectOwnerUserIds.clear();
  }
}
