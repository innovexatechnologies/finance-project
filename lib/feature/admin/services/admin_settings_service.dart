import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_settings_model.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';

/// Centralized Administration, System Taxonomies, Support & RBAC Service
/// backed by `platform_taxonomies`, `support_tickets`, `profiles`, and `admin_audit_logs`.
class AdminSettingsService {
  static final AdminSettingsService _instance =
      AdminSettingsService._internal();
  factory AdminSettingsService() => _instance;

  AdminSettingsService._internal();

  final ValueNotifier<List<CategorySettingItem>> categoriesNotifier =
      ValueNotifier<List<CategorySettingItem>>([]);
  final ValueNotifier<List<SkillSettingItem>> skillsNotifier =
      ValueNotifier<List<SkillSettingItem>>([]);
  final ValueNotifier<List<UniversitySettingItem>> universitiesNotifier =
      ValueNotifier<List<UniversitySettingItem>>([]);
  final ValueNotifier<List<HelpRequestItem>> helpRequestsNotifier =
      ValueNotifier<List<HelpRequestItem>>([]);
  final ValueNotifier<List<ComplaintItem>> complaintsNotifier =
      ValueNotifier<List<ComplaintItem>>([]);
  final ValueNotifier<List<PlatformPolicyItem>> policiesNotifier =
      ValueNotifier<List<PlatformPolicyItem>>([]);
  final ValueNotifier<List<AdminUserModel>> adminsNotifier =
      ValueNotifier<List<AdminUserModel>>([]);
  final ValueNotifier<List<AdminSessionItem>> sessionsNotifier =
      ValueNotifier<List<AdminSessionItem>>([]);
  final ValueNotifier<List<AdminAuditLogItem>> auditLogsNotifier =
      ValueNotifier<List<AdminAuditLogItem>>([]);

  /// Loads taxonomies, tickets, complaints, policies, admins, sessions & audit logs from Supabase.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    final projects = AdminProjectService().allProjects;
    final students = AdminStudentService().allStudents;

    // 1. Load platform_taxonomies (category, skill, university, policy)
    try {
      final taxRows = await supabase
          .from('platform_taxonomies')
          .select()
          .order('created_at', ascending: true);

      final List<CategorySettingItem> cats = [];
      final List<SkillSettingItem> skills = [];
      final List<UniversitySettingItem> unis = [];
      final List<PlatformPolicyItem> policies = [];

      for (final raw in taxRows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final itemType = (row['item_type']?.toString() ?? '').toLowerCase();
        final name = row['name']?.toString() ?? '';
        final desc = row['description']?.toString() ?? '';
        final isActive = row['is_active'] != false;
        final createdAt =
            SupabaseHelper.parseDate(row['created_at']) ?? DateTime.now();
        final meta = row['metadata'] is Map
            ? Map<String, dynamic>.from(row['metadata'] as Map)
            : <String, dynamic>{};

        if (itemType == 'category') {
          final colorVal = (meta['color_value'] as num?)?.toInt() ?? 0xFF6366F1;
          final projCount = projects
              .where((p) => p.category.toLowerCase() == name.toLowerCase())
              .length;
          cats.add(
            CategorySettingItem(
              id: id,
              name: name,
              description: desc,
              color: Color(colorVal),
              projectCount: projCount,
              isActive: isActive,
              createdAt: createdAt,
            ),
          );
        } else if (itemType == 'skill') {
          final catName = meta['category_name']?.toString() ?? 'General';
          final usage = projects
              .where(
                (p) => p.skillsRequired.any(
                  (s) => s.toLowerCase() == name.toLowerCase(),
                ),
              )
              .length;
          skills.add(
            SkillSettingItem(
              id: id,
              name: name,
              categoryName: catName,
              usageCount: usage,
              isActive: isActive,
              createdAt: createdAt,
            ),
          );
        } else if (itemType == 'university') {
          final shortName = meta['short_name']?.toString() ?? name;
          final studCount = students
              .where(
                (s) =>
                    s.university.toLowerCase().contains(shortName.toLowerCase()) ||
                    s.university.toLowerCase() == name.toLowerCase(),
              )
              .length;
          unis.add(
            UniversitySettingItem(
              id: id,
              name: name,
              shortName: shortName,
              city: meta['city']?.toString() ?? '',
              province: meta['province']?.toString() ?? '',
              domain: meta['domain']?.toString() ?? '',
              studentCount: studCount,
              isActive: isActive,
              createdAt: createdAt,
            ),
          );
        } else if (itemType == 'policy') {
          final rawHistory = meta['history'];
          final List<PolicyVersionRecord> history = [];
          if (rawHistory is List) {
            for (final h in rawHistory) {
              if (h is Map) {
                history.add(
                  PolicyVersionRecord(
                    version: h['version']?.toString() ?? 'v1.0',
                    updatedAt:
                        SupabaseHelper.parseDate(h['updated_at']) ?? createdAt,
                    updatedByAdmin:
                        h['updated_by_admin']?.toString() ?? 'Administrator',
                    changeSummary: h['change_summary']?.toString() ?? '',
                  ),
                );
              }
            }
          }
          policies.add(
            PlatformPolicyItem(
              id: id,
              title: name,
              policyKey: meta['policy_key']?.toString() ?? id,
              version: meta['version']?.toString() ?? 'v1.0',
              lastUpdatedAt:
                  SupabaseHelper.parseDate(meta['last_updated_at']) ?? createdAt,
              updatedByAdmin:
                  meta['updated_by_admin']?.toString() ?? 'Administrator',
              content: desc,
              history: history,
            ),
          );
        }
      }

      categoriesNotifier.value = cats;
      skillsNotifier.value = skills;
      universitiesNotifier.value = unis;
      policiesNotifier.value = policies;
    } catch (e) {
      debugPrint('AdminSettingsService load taxonomies error: $e');
    }

    // 2. Load support_tickets -> split into Help Requests vs Complaints/Grievances
    try {
      final ticketRows = await supabase
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);

      final List<HelpRequestItem> helpItems = [];
      final List<ComplaintItem> complaintItems = [];

      for (final raw in ticketRows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final ticketNo = row['ticket_number']?.toString() ?? id;

        final category = row['category']?.toString() ?? 'General';
        final rawStatus = (row['status']?.toString() ?? 'Open').toLowerCase();
        final subject = row['subject']?.toString() ?? 'Support Inquiry';
        final message = row['message']?.toString() ?? '';
        final createdAt =
            SupabaseHelper.parseDate(row['created_at']) ?? DateTime.now();
        final updatedAt = SupabaseHelper.parseDate(row['updated_at']);
        final adminResp = row['admin_response']?.toString();
        final assignedTo = row['assigned_to']?.toString();

        final isComplaint = category.toLowerCase().contains('complaint') ||
            category.toLowerCase().contains('grievance') ||
            category.toLowerCase().contains('plagiarism') ||
            ticketNo.toUpperCase().startsWith('CMP');

        if (isComplaint) {
          ComplaintStatus compStatus;
          if (rawStatus == 'resolved') {
            compStatus = ComplaintStatus.resolved;
          } else if (rawStatus == 'dismissed') {
            compStatus = ComplaintStatus.dismissed;
          } else if (rawStatus == 'in_progress' ||
              rawStatus == 'under_investigation' ||
              rawStatus == 'in progress') {
            compStatus = ComplaintStatus.underInvestigation;
          } else {
            compStatus = ComplaintStatus.newComplaint;
          }

          complaintItems.add(
            ComplaintItem(
              id: id,
              complainantName: row['user_name']?.toString() ?? 'Platform User',
              complainantEmail: row['user_email']?.toString() ?? '',
              reportedEntityName: assignedTo ?? 'Platform Compliance',
              reportedEntityType:
                  (row['user_role']?.toString().toLowerCase() == 'company')
                      ? 'student'
                      : 'company',
              category: category,
              subject: subject,
              description: message,
              status: compStatus,
              severity: category.toLowerCase().contains('plagiarism')
                  ? ComplaintSeverity.high
                  : ComplaintSeverity.medium,
              submittedAt: createdAt,
              investigationNotes: adminResp,
              resolutionReason: compStatus == ComplaintStatus.resolved ||
                      compStatus == ComplaintStatus.dismissed
                  ? adminResp
                  : null,
              resolvedAt: compStatus == ComplaintStatus.resolved ||
                      compStatus == ComplaintStatus.dismissed
                  ? updatedAt
                  : null,
            ),
          );
        } else {
          HelpRequestStatus helpStatus;
          if (rawStatus == 'resolved' || rawStatus == 'closed') {
            helpStatus = HelpRequestStatus.resolved;
          } else if (rawStatus == 'in_progress' ||
              rawStatus == 'in progress' ||
              (adminResp?.isNotEmpty == true)) {
            helpStatus = HelpRequestStatus.inProgress;
          } else {
            helpStatus = HelpRequestStatus.pending;
          }

          helpItems.add(
            HelpRequestItem(
              id: id,
              senderName: row['user_name']?.toString() ?? 'Platform User',
              senderEmail: row['user_email']?.toString() ?? '',
              userType:
                  (row['user_role']?.toString() ?? 'student').toLowerCase(),
              subject: subject,
              message: message,
              category: category,
              status: helpStatus,
              priority: HelpRequestPriority.normal,
              submittedAt: createdAt,
              adminResponse: adminResp,
              respondedByAdmin: assignedTo,
              resolvedAt:
                  helpStatus == HelpRequestStatus.resolved ? updatedAt : null,
              resolutionNotes:
                  helpStatus == HelpRequestStatus.resolved ? adminResp : null,
            ),
          );
        }
      }

      helpRequestsNotifier.value = helpItems;
      complaintsNotifier.value = complaintItems;
    } catch (e) {
      debugPrint('AdminSettingsService load support_tickets error: $e');
    }

    // 3. Load Admin accounts from profiles
    try {
      final adminRows = await supabase
          .from('profiles')
          .select()
          .ilike('user_type', 'admin')
          .order('created_at', ascending: true);

      final List<AdminUserModel> admins = [];
      for (final raw in adminRows) {
        final row = Map<String, dynamic>.from(raw);
        final name = (row['name']?.toString().trim().isNotEmpty == true)
            ? row['name'].toString().trim()
            : 'Executive Administrator';
        final dept = (row['university']?.toString().trim().isNotEmpty == true)
            ? row['university'].toString().trim()
            : 'SkillBridge Governance Council';
        final email = row['email']?.toString() ?? '';
        admins.add(
          AdminUserModel(
            id: row['id']?.toString() ?? '',
            fullName: name,
            email: email,
            role: 'SUPER_ADMIN',
            roleDisplayName: 'Platform Administrator',
            department: dept,
            avatarInitial: SupabaseHelper.initialsFor(name, fallback: 'EA'),
            permissions: const [
              'all',
              'manage_categories',
              'manage_skills',
              'manage_universities',
              'manage_support',
              'manage_policies',
              'manage_admins',
            ],
            lastLoginAt: SupabaseHelper.formatRelativeTime(
              row['updated_at'] ?? row['created_at'],
            ),
            isActive:
                (row['account_status']?.toString().toLowerCase() ?? 'active') !=
                    'suspended',
          ),
        );
      }
      adminsNotifier.value = admins;
    } catch (e) {
      debugPrint('AdminSettingsService load admins error: $e');
    }

    // 4. Current live auth session
    final user = supabase.auth.currentUser;
    if (user != null) {
      sessionsNotifier.value = [
        AdminSessionItem(
          sessionId: user.id.length >= 8 ? 'sess_${user.id.substring(0, 8)}' : 'sess_current',
          device: 'Authenticated Supabase Session',
          browser: user.email ?? 'Admin Console',
          ipAddress: 'Active JWT Session',
          location: 'Supabase Auth Verified',
          loginAt: SupabaseHelper.parseDate(user.lastSignInAt) ?? DateTime.now(),
          isCurrent: true,
        ),
      ];
    } else {
      sessionsNotifier.value = [];
    }

    // 5. Audit Logs
    try {
      final logRows = await supabase
          .from('admin_audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      auditLogsNotifier.value = logRows.map((raw) {
        final row = Map<String, dynamic>.from(raw);
        return AdminAuditLogItem(
          id: row['id']?.toString() ?? '',
          adminEmail: row['admin_email']?.toString() ?? 'admin',
          action: row['action']?.toString() ?? 'EVENT',
          target: row['target']?.toString() ?? '',
          timestamp:
              SupabaseHelper.parseDate(row['created_at']) ?? DateTime.now(),
          details: row['details']?.toString() ?? '',
          ipAddress: 'Supabase Audit Vault',
        );
      }).toList();
    } catch (e) {
      debugPrint('AdminSettingsService load audit logs error: $e');
    }
  }

  // --- 1. CATEGORY MANAGEMENT ---
  bool isDuplicateCategory(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return categoriesNotifier.value.any(
      (c) => c.name.trim().toLowerCase() == lower && c.id != excludeId,
    );
  }

  bool addCategory({
    required String name,
    required String description,
    required Color color,
    required String adminEmail,
  }) {
    if (isDuplicateCategory(name)) return false;

    final newId = SupabaseHelper.generateUuid();
    final newCat = CategorySettingItem(
      id: newId,
      name: name.trim(),
      description: description.trim(),
      color: color,
      projectCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    categoriesNotifier.value = [...categoriesNotifier.value, newCat];
    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        await supabase.from('platform_taxonomies').insert({
          'id': newId,
          'item_type': 'category',
          'name': newCat.name,
          'description': newCat.description,
          'is_active': true,
          'metadata': {'color_value': color.toARGB32()},
        });
      }
    });
    _logAction(
      adminEmail,
      'CATEGORY_CREATE',
      newCat.name,
      'Created new category taxonomy.',
    );
    return true;
  }

  bool updateCategory({
    required String id,
    required String name,
    required String description,
    required Color color,
    required String adminEmail,
  }) {
    if (isDuplicateCategory(name, excludeId: id)) return false;

    categoriesNotifier.value = categoriesNotifier.value.map((c) {
      if (c.id == id) {
        return c.copyWith(
          name: name.trim(),
          description: description.trim(),
          color: color,
        );
      }
      return c;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(id)) {
        await supabase.from('platform_taxonomies').update({
          'name': name.trim(),
          'description': description.trim(),
          'metadata': {'color_value': color.toARGB32()},
        }).eq('id', id);
      }
    });
    _logAction(
      adminEmail,
      'CATEGORY_UPDATE',
      name.trim(),
      'Updated category description and theme color.',
    );
    return true;
  }

  void toggleCategoryActive(String id, String adminEmail) {
    categoriesNotifier.value = categoriesNotifier.value.map((c) {
      if (c.id == id) {
        final newStatus = !c.isActive;
        _persistAsync(() async {
          final supabase = SupabaseHelper.clientOrNull;
          if (supabase != null && SupabaseHelper.isUuid(id)) {
            await supabase
                .from('platform_taxonomies')
                .update({'is_active': newStatus}).eq('id', id);
          }
        });
        _logAction(
          adminEmail,
          'CATEGORY_TOGGLE',
          c.name,
          'Toggled status to ${newStatus ? 'Active' : 'Inactive'}.',
        );
        return c.copyWith(isActive: newStatus);
      }
      return c;
    }).toList();
  }

  // --- 2. SKILLS MANAGEMENT ---
  bool isDuplicateSkill(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return skillsNotifier.value.any(
      (s) => s.name.trim().toLowerCase() == lower && s.id != excludeId,
    );
  }

  bool addSkill({
    required String name,
    required String categoryName,
    required String adminEmail,
  }) {
    if (isDuplicateSkill(name)) return false;

    final newId = SupabaseHelper.generateUuid();
    final newSkill = SkillSettingItem(
      id: newId,
      name: name.trim(),
      categoryName: categoryName,
      usageCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    skillsNotifier.value = [...skillsNotifier.value, newSkill];
    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        await supabase.from('platform_taxonomies').insert({
          'id': newId,
          'item_type': 'skill',
          'name': newSkill.name,
          'description': '',
          'is_active': true,
          'metadata': {'category_name': categoryName},
        });
      }
    });
    _logAction(
      adminEmail,
      'SKILL_CREATE',
      newSkill.name,
      'Added skill to $categoryName.',
    );
    return true;
  }

  bool updateSkill({
    required String id,
    required String name,
    required String categoryName,
    required String adminEmail,
  }) {
    if (isDuplicateSkill(name, excludeId: id)) return false;

    skillsNotifier.value = skillsNotifier.value.map((s) {
      if (s.id == id) {
        return s.copyWith(name: name.trim(), categoryName: categoryName);
      }
      return s;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(id)) {
        await supabase.from('platform_taxonomies').update({
          'name': name.trim(),
          'metadata': {'category_name': categoryName},
        }).eq('id', id);
      }
    });
    _logAction(
      adminEmail,
      'SKILL_UPDATE',
      name.trim(),
      'Updated skill taxonomy metadata.',
    );
    return true;
  }

  void deleteSkill(String id, String adminEmail) {
    final idx = skillsNotifier.value.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final target = skillsNotifier.value[idx];
    skillsNotifier.value =
        skillsNotifier.value.where((s) => s.id != id).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(id)) {
        await supabase.from('platform_taxonomies').delete().eq('id', id);
      }
    });
    _logAction(
      adminEmail,
      'SKILL_DELETE',
      target.name,
      'Removed skill from taxonomy registry.',
    );
  }

  void toggleSkillActive(String id, String adminEmail) {
    skillsNotifier.value = skillsNotifier.value.map((s) {
      if (s.id == id) {
        final newStatus = !s.isActive;
        _persistAsync(() async {
          final supabase = SupabaseHelper.clientOrNull;
          if (supabase != null && SupabaseHelper.isUuid(id)) {
            await supabase
                .from('platform_taxonomies')
                .update({'is_active': newStatus}).eq('id', id);
          }
        });
        _logAction(
          adminEmail,
          'SKILL_TOGGLE',
          s.name,
          'Toggled skill status to ${newStatus ? 'Active' : 'Deactivated'}.',
        );
        return s.copyWith(isActive: newStatus);
      }
      return s;
    }).toList();
  }

  // --- 3. UNIVERSITY MANAGEMENT ---
  bool isDuplicateUniversity(String name, String domain, {String? excludeId}) {
    final lowerName = name.trim().toLowerCase();
    final lowerDomain = domain.trim().toLowerCase();
    return universitiesNotifier.value.any(
      (u) =>
          (u.name.trim().toLowerCase() == lowerName ||
              u.domain.trim().toLowerCase() == lowerDomain) &&
          u.id != excludeId,
    );
  }

  bool addUniversity({
    required String name,
    required String shortName,
    required String city,
    required String province,
    required String domain,
    required String adminEmail,
  }) {
    if (isDuplicateUniversity(name, domain)) return false;

    final newId = SupabaseHelper.generateUuid();
    final newUni = UniversitySettingItem(
      id: newId,
      name: name.trim(),
      shortName: shortName.trim(),
      city: city.trim(),
      province: province.trim(),
      domain: domain.trim().toLowerCase(),
      studentCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    universitiesNotifier.value = [...universitiesNotifier.value, newUni];
    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        await supabase.from('platform_taxonomies').insert({
          'id': newId,
          'item_type': 'university',
          'name': newUni.name,
          'description': '${newUni.city}, ${newUni.province}',
          'is_active': true,
          'metadata': {
            'short_name': newUni.shortName,
            'city': newUni.city,
            'province': newUni.province,
            'domain': newUni.domain,
          },
        });
      }
    });
    _logAction(
      adminEmail,
      'UNIVERSITY_CREATE',
      newUni.shortName,
      'Accredited university ${newUni.domain} in ${newUni.city}.',
    );
    return true;
  }

  bool updateUniversity({
    required String id,
    required String name,
    required String shortName,
    required String city,
    required String province,
    required String domain,
    required String adminEmail,
  }) {
    if (isDuplicateUniversity(name, domain, excludeId: id)) return false;

    universitiesNotifier.value = universitiesNotifier.value.map((u) {
      if (u.id == id) {
        return u.copyWith(
          name: name.trim(),
          shortName: shortName.trim(),
          city: city.trim(),
          province: province.trim(),
          domain: domain.trim().toLowerCase(),
        );
      }
      return u;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(id)) {
        await supabase.from('platform_taxonomies').update({
          'name': name.trim(),
          'description': '${city.trim()}, ${province.trim()}',
          'metadata': {
            'short_name': shortName.trim(),
            'city': city.trim(),
            'province': province.trim(),
            'domain': domain.trim().toLowerCase(),
          },
        }).eq('id', id);
      }
    });
    _logAction(
      adminEmail,
      'UNIVERSITY_UPDATE',
      shortName.trim(),
      'Updated institutional records.',
    );
    return true;
  }

  void toggleUniversityActive(String id, String adminEmail) {
    universitiesNotifier.value = universitiesNotifier.value.map((u) {
      if (u.id == id) {
        final newStatus = !u.isActive;
        _persistAsync(() async {
          final supabase = SupabaseHelper.clientOrNull;
          if (supabase != null && SupabaseHelper.isUuid(id)) {
            await supabase
                .from('platform_taxonomies')
                .update({'is_active': newStatus}).eq('id', id);
          }
        });
        _logAction(
          adminEmail,
          'UNIVERSITY_TOGGLE',
          u.shortName,
          'Changed accreditation state to ${newStatus ? 'Active' : 'Suspended'}.',
        );
        return u.copyWith(isActive: newStatus);
      }
      return u;
    }).toList();
  }

  // --- 4. HELP REQUESTS ---
  void addAdminResponse({
    required String ticketId,
    required String responseText,
    required String adminEmail,
  }) {
    final cleanResp = responseText.trim();
    helpRequestsNotifier.value = helpRequestsNotifier.value.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(
          adminResponse: cleanResp,
          respondedByAdmin: adminEmail,
          status: HelpRequestStatus.inProgress,
        );
      }
      return t;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(ticketId)) {
        await supabase.from('support_tickets').update({
          'admin_response': cleanResp,
          'assigned_to': adminEmail,
          'status': 'In Progress',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', ticketId);
      }
    });
    _logAction(
      adminEmail,
      'HELP_TICKET_RESPOND',
      ticketId,
      'Provided administrative answer.',
    );
  }

  void resolveHelpRequest({
    required String ticketId,
    required String resolutionNotes,
    required String adminEmail,
  }) {
    final cleanNotes = resolutionNotes.trim();
    helpRequestsNotifier.value = helpRequestsNotifier.value.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(
          status: HelpRequestStatus.resolved,
          resolvedAt: DateTime.now(),
          resolutionNotes: cleanNotes,
          adminResponse: t.adminResponse?.isNotEmpty == true
              ? t.adminResponse
              : cleanNotes,
          respondedByAdmin: adminEmail,
        );
      }
      return t;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(ticketId)) {
        await supabase.from('support_tickets').update({
          'admin_response': cleanNotes,
          'assigned_to': adminEmail,
          'status': 'Resolved',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', ticketId);
      }
    });
    _logAction(
      adminEmail,
      'HELP_TICKET_RESOLVE',
      ticketId,
      'Ticket resolved: $cleanNotes',
    );
  }

  // --- 5. COMPLAINT MANAGEMENT ---
  void updateInvestigationNotes({
    required String complaintId,
    required String notes,
    required String adminEmail,
  }) {
    final cleanNotes = notes.trim();
    complaintsNotifier.value = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        final newHistory = [
          ...c.history,
          ComplaintHistoryEvent(
            action: 'Investigation Note Recorded',
            performedBy: adminEmail,
            timestamp: DateTime.now(),
            notes: cleanNotes,
          ),
        ];
        return c.copyWith(
          investigationNotes: cleanNotes,
          status: ComplaintStatus.underInvestigation,
          history: newHistory,
        );
      }
      return c;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(complaintId)) {
        await supabase.from('support_tickets').update({
          'admin_response': cleanNotes,
          'assigned_to': adminEmail,
          'status': 'under_investigation',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', complaintId);
      }
    });
    _logAction(
      adminEmail,
      'COMPLAINT_NOTE',
      complaintId,
      'Recorded investigation observations.',
    );
  }

  void resolveComplaint({
    required String complaintId,
    required String reason,
    required String adminEmail,
  }) {
    final cleanReason = reason.trim();
    complaintsNotifier.value = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        final newHistory = [
          ...c.history,
          ComplaintHistoryEvent(
            action: 'Grievance Resolved',
            performedBy: adminEmail,
            timestamp: DateTime.now(),
            notes: cleanReason,
          ),
        ];
        return c.copyWith(
          status: ComplaintStatus.resolved,
          resolutionReason: cleanReason,
          resolvedByAdmin: adminEmail,
          resolvedAt: DateTime.now(),
          history: newHistory,
        );
      }
      return c;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(complaintId)) {
        await supabase.from('support_tickets').update({
          'admin_response': cleanReason,
          'assigned_to': adminEmail,
          'status': 'resolved',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', complaintId);
      }
    });
    _logAction(
      adminEmail,
      'COMPLAINT_RESOLVE',
      complaintId,
      'Resolved complaint with formal outcome.',
    );
  }

  void dismissComplaint({
    required String complaintId,
    required String reason,
    required String adminEmail,
  }) {
    final cleanReason = reason.trim();
    complaintsNotifier.value = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        final newHistory = [
          ...c.history,
          ComplaintHistoryEvent(
            action: 'Complaint Dismissed',
            performedBy: adminEmail,
            timestamp: DateTime.now(),
            notes: cleanReason,
          ),
        ];
        return c.copyWith(
          status: ComplaintStatus.dismissed,
          resolutionReason: cleanReason,
          resolvedByAdmin: adminEmail,
          resolvedAt: DateTime.now(),
          history: newHistory,
        );
      }
      return c;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(complaintId)) {
        await supabase.from('support_tickets').update({
          'admin_response': cleanReason,
          'assigned_to': adminEmail,
          'status': 'dismissed',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', complaintId);
      }
    });
    _logAction(
      adminEmail,
      'COMPLAINT_DISMISS',
      complaintId,
      'Dismissed grievance without penalty.',
    );
  }

  // --- 6. PLATFORM POLICIES ---
  void updatePolicy({
    required String policyKey,
    required String title,
    required String content,
    required String changeSummary,
    required String adminEmail,
  }) {
    PlatformPolicyItem? updatedPolicy;
    policiesNotifier.value = policiesNotifier.value.map((p) {
      if (p.policyKey == policyKey || p.id == policyKey) {
        final currentParts = p.version.replaceAll('v', '').split('.');
        final major = currentParts.isNotEmpty ? currentParts[0] : '1';
        final minor = currentParts.length > 1
            ? (int.tryParse(currentParts[1]) ?? 0) + 1
            : 1;
        final nextVersion = 'v$major.$minor';

        final newHistory = [
          PolicyVersionRecord(
            version: nextVersion,
            updatedAt: DateTime.now(),
            updatedByAdmin: adminEmail,
            changeSummary: changeSummary.trim(),
          ),
          ...p.history,
        ];

        updatedPolicy = p.copyWith(
          title: title.trim(),
          content: content.trim(),
          version: nextVersion,
          lastUpdatedAt: DateTime.now(),
          updatedByAdmin: adminEmail,
          history: newHistory,
        );
        return updatedPolicy!;
      }
      return p;
    }).toList();

    if (updatedPolicy != null) {
      final pol = updatedPolicy!;
      _persistAsync(() async {
        final supabase = SupabaseHelper.clientOrNull;
        if (supabase != null && SupabaseHelper.isUuid(pol.id)) {
          await supabase.from('platform_taxonomies').update({
            'name': pol.title,
            'description': pol.content,
            'metadata': {
              'policy_key': pol.policyKey,
              'version': pol.version,
              'last_updated_at': pol.lastUpdatedAt.toIso8601String(),
              'updated_by_admin': pol.updatedByAdmin,
              'history': pol.history
                  .map((h) => {
                        'version': h.version,
                        'updated_at': h.updatedAt.toIso8601String(),
                        'updated_by_admin': h.updatedByAdmin,
                        'change_summary': h.changeSummary,
                      })
                  .toList(),
            },
          }).eq('id', pol.id);
        }
      });
    }

    _logAction(
      adminEmail,
      'POLICY_UPDATE',
      title.trim(),
      'Published version update with audit changelog.',
    );
  }

  /// Create a brand-new policy when policy table starts empty.
  bool createPolicy({
    required String policyKey,
    required String title,
    required String content,
    required String adminEmail,
  }) {
    final newId = SupabaseHelper.generateUuid();
    final now = DateTime.now();
    final item = PlatformPolicyItem(
      id: newId,
      title: title.trim(),
      policyKey: policyKey.trim(),
      version: 'v1.0',
      lastUpdatedAt: now,
      updatedByAdmin: adminEmail,
      content: content.trim(),
      history: [
        PolicyVersionRecord(
          version: 'v1.0',
          updatedAt: now,
          updatedByAdmin: adminEmail,
          changeSummary: 'Initial policy publication.',
        ),
      ],
    );
    policiesNotifier.value = [...policiesNotifier.value, item];
    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        await supabase.from('platform_taxonomies').insert({
          'id': newId,
          'item_type': 'policy',
          'name': item.title,
          'description': item.content,
          'is_active': true,
          'metadata': {
            'policy_key': item.policyKey,
            'version': item.version,
            'last_updated_at': now.toIso8601String(),
            'updated_by_admin': adminEmail,
          },
        });
      }
    });
    _logAction(
      adminEmail,
      'POLICY_CREATE',
      item.title,
      'Created initial governance policy document.',
    );
    return true;
  }

  // --- 7. ADMIN ACCESS & RBAC ---
  bool provisionAdminAccount({
    required String fullName,
    required String email,
    required String role,
    required String roleDisplayName,
    required String department,
    required List<String> permissions,
    required String adminEmail,
  }) {
    final normalized = email.trim().toLowerCase();
    if (adminsNotifier.value.any((a) => a.email.toLowerCase() == normalized)) {
      return false;
    }

    final newAdmin = AdminUserModel(
      id: SupabaseHelper.generateUuid(),
      fullName: fullName.trim(),
      email: normalized,
      role: role,
      roleDisplayName: roleDisplayName,
      department: department.trim(),
      avatarInitial: SupabaseHelper.initialsFor(fullName, fallback: 'AD'),
      permissions: permissions,
      lastLoginAt: 'Pending Auth Activation',
      isActive: true,
    );

    adminsNotifier.value = [...adminsNotifier.value, newAdmin];
    _logAction(
      adminEmail,
      'ADMIN_PROVISION',
      normalized,
      'Provisioned trusted administrative role ($role).',
    );
    return true;
  }

  bool toggleAdminActive(String id, String adminEmail) {
    final idx = adminsNotifier.value.indexWhere((a) => a.id == id);
    if (idx == -1) return false;
    final target = adminsNotifier.value[idx];
    if (target.role == 'SUPER_ADMIN') {
      return false;
    }

    final newStatus = !target.isActive;
    adminsNotifier.value = adminsNotifier.value.map((a) {
      if (a.id == id) {
        return a.copyWith(isActive: newStatus);
      }
      return a;
    }).toList();

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null && SupabaseHelper.isUuid(id)) {
        await supabase.from('profiles').update({
          'account_status': newStatus ? 'active' : 'suspended',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      }
    });
    _logAction(
      adminEmail,
      'ADMIN_STATUS',
      target.email,
      'Changed account state to ${newStatus ? 'Active' : 'Suspended'}.',
    );
    return true;
  }

  void updateAdminPermissions({
    required String id,
    required List<String> permissions,
    required String adminEmail,
  }) {
    adminsNotifier.value = adminsNotifier.value.map((a) {
      if (a.id == id) {
        _logAction(
          adminEmail,
          'ADMIN_PERMISSIONS',
          a.email,
          'Updated assigned granular roles.',
        );
        return a.copyWith(permissions: permissions);
      }
      return a;
    }).toList();
  }

  // --- 8. ADMIN PROFILE, PASSWORD & SESSIONS ---
  void updateProfile({
    required String fullName,
    required String department,
  }) {
    final current = AdminAuthService().currentAdmin;
    if (current == null) return;

    final updated = current.copyWith(
      fullName: fullName.trim(),
      department: department.trim(),
      avatarInitial: SupabaseHelper.initialsFor(fullName, fallback: 'EA'),
    );

    AdminAuthService().currentAdminNotifier.value = updated;

    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      final uid = supabase?.auth.currentUser?.id;
      if (supabase != null && uid != null) {
        await supabase.from('profiles').update({
          'name': fullName.trim(),
          'university': department.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', uid);
      }
    });

    _logAction(
      current.email,
      'PROFILE_UPDATE',
      current.email,
      'Updated administrative profile contact info.',
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String adminEmail,
  }) async {
    final trimmedNew = newPassword.trim();
    if (trimmedNew.isEmpty) return false;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && supabase.auth.currentUser != null) {
      try {
        try {
          await supabase.auth.updateUser(UserAttributes(password: trimmedNew));
        } on AuthException catch (e) {
          if (SupabaseHelper.isWeakPasswordError(e)) {
            await SupabaseHelper.resetPasswordInApp(
              email: adminEmail,
              newPassword: trimmedNew,
            );
          } else {
            rethrow;
          }
        }
      } catch (e) {
        debugPrint('AdminSettingsService changePassword error: $e');
        return false;
      }
    }

    _logAction(
      adminEmail,
      'PASSWORD_CHANGE',
      adminEmail,
      'Administrator password updated.',
    );
    return true;
  }

  void terminateSession(String sessionId, String adminEmail) {
    sessionsNotifier.value = sessionsNotifier.value
        .where((s) => s.sessionId != sessionId)
        .toList();
    _logAction(
      adminEmail,
      'SESSION_TERMINATE',
      sessionId,
      'Terminated active session token.',
    );
  }

  void _logAction(
    String adminEmail,
    String action,
    String target,
    String details,
  ) {
    final log = AdminAuditLogItem(
      id: SupabaseHelper.generateUuid(),
      adminEmail: adminEmail,
      action: action,
      target: target,
      timestamp: DateTime.now(),
      details: details,
      ipAddress: 'Supabase Audit Vault',
    );

    auditLogsNotifier.value = [log, ...auditLogsNotifier.value];
    _persistAsync(() async {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        await supabase.from('admin_audit_logs').insert({
          'admin_email': adminEmail,
          'action': action,
          'target': target,
          'details': details,
        });
      }
    });
  }

  void _persistAsync(Future<void> Function() task) {
    unawaited(
      task().catchError((e) {
        debugPrint('AdminSettingsService background persist error: $e');
      }),
    );
  }

  void reset() {
    categoriesNotifier.value = [];
    skillsNotifier.value = [];
    universitiesNotifier.value = [];
    helpRequestsNotifier.value = [];
    complaintsNotifier.value = [];
    policiesNotifier.value = [];
    adminsNotifier.value = [];
    sessionsNotifier.value = [];
    auditLogsNotifier.value = [];
  }
}
