import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
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

  String? lastError;

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
    final Map<String, Map<String, dynamic>> adminRbacByEmail = {};

    // 1. Load platform_taxonomies (category, skill, university, policy, admin_rbac)
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

        if (itemType == 'admin_rbac') {
          final key = name.trim().toLowerCase();
          if (key.isNotEmpty) {
            adminRbacByEmail[key] = meta;
          }
          continue;
        } else if (itemType == 'category') {
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

        String senderName =
            (row['user_name']?.toString().trim().isNotEmpty == true)
                ? row['user_name'].toString().trim()
                : '';
        final senderEmail = row['user_email']?.toString().trim() ?? '';
        final senderUserId = row['user_id']?.toString() ?? '';

        // If the name is generic or missing, cross-reference against all registered students
        if (senderName.isEmpty ||
            senderName.toLowerCase() == 'user' ||
            senderName.toLowerCase() == 'student' ||
            senderName.toLowerCase() == 'platform user') {
          final matchedStudent = students.where((s) {
            if (senderUserId.isNotEmpty && s.id == senderUserId) return true;
            if (senderEmail.isNotEmpty &&
                s.email.toLowerCase() == senderEmail.toLowerCase()) {
              return true;
            }
            return false;
          }).firstOrNull;

          if (matchedStudent != null && matchedStudent.name.trim().isNotEmpty) {
            senderName = matchedStudent.name.trim();
          }
        }
        if (senderName.isEmpty) {
          senderName = senderEmail.isNotEmpty ? senderEmail : 'Student';
        }

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
              complainantName: senderName,
              complainantEmail: senderEmail,
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
              senderName: senderName,
              senderEmail: senderEmail,
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

      // Merge local AppDataService support tickets so new messages show instantly
      final localTickets = AppDataService.instance.getSupportTickets();
      for (final lt in localTickets) {
        final ltId = lt['id']?.toString() ?? '';
        final alreadyPresent =
            helpItems.any((h) => h.id == ltId) ||
            complaintItems.any((c) => c.id == ltId);
        if (!alreadyPresent) {
          final ltCat = lt['category']?.toString() ?? 'General';
          final ltMsg = lt['message']?.toString() ?? '';
          final ltSub = lt['subject']?.toString() ?? 'Support Inquiry';
          final ltEmail = lt['email']?.toString() ??
              lt['user_email']?.toString() ??
              '';
          final ltName =
              (lt['senderName']?.toString().trim().isNotEmpty == true)
                  ? lt['senderName'].toString().trim()
                  : (lt['user_name']?.toString().trim().isNotEmpty == true
                      ? lt['user_name'].toString().trim()
                      : (ltEmail.isNotEmpty ? ltEmail : 'Student'));
          final ltCreated =
              DateTime.tryParse(lt['createdAt']?.toString() ?? '') ??
              DateTime.now();

          helpItems.add(
            HelpRequestItem(
              id: ltId,
              senderName: ltName,
              senderEmail: ltEmail,
              userType: 'student',
              subject: ltSub,
              message: ltMsg,
              category: ltCat,
              status: HelpRequestStatus.pending,
              priority: HelpRequestPriority.normal,
              submittedAt: ltCreated,
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
        final rbac = adminRbacByEmail[email.trim().toLowerCase()];
        final roleKey = rbac?['role']?.toString().trim().isNotEmpty == true
            ? rbac!['role'].toString().trim()
            : 'SUPER_ADMIN';
        final roleDisplay =
            rbac?['role_display_name']?.toString().trim().isNotEmpty == true
                ? rbac!['role_display_name'].toString().trim()
                : 'Platform Administrator';
        final parsedPerms = SupabaseHelper.parseStringList(rbac?['permissions']);
        final permissions = parsedPerms.isNotEmpty
            ? parsedPerms
            : const [
                'all',
                'manage_categories',
                'manage_skills',
                'manage_universities',
                'manage_support',
                'manage_policies',
                'manage_admins',
              ];
        admins.add(
          AdminUserModel(
            id: row['id']?.toString() ?? '',
            fullName: name,
            email: email,
            role: roleKey,
            roleDisplayName: roleDisplay,
            department: dept,
            avatarInitial: SupabaseHelper.initialsFor(name, fallback: 'EA'),
            permissions: permissions,
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

  Future<bool> _insertTaxonomyRow(Map<String, dynamic> row) async {
    lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return true;
    try {
      await supabase.from('platform_taxonomies').insert(row);
      return true;
    } catch (e) {
      lastError = SupabaseHelper.friendlyError(e);
      debugPrint('AdminSettingsService _insertTaxonomyRow error: $e');
      return false;
    }
  }

  Future<bool> _updateTaxonomyRow(String id, Map<String, dynamic> fields) async {
    lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return true;
    if (!SupabaseHelper.isUuid(id)) {
      lastError = 'Invalid record identifier.';
      return false;
    }
    try {
      final updated = await supabase
          .from('platform_taxonomies')
          .update(fields)
          .eq('id', id)
          .select('id');
      if ((updated as List).isEmpty) {
        lastError = 'Database record was not updated. Check administrator permissions.';
        return false;
      }
      return true;
    } catch (e) {
      lastError = SupabaseHelper.friendlyError(e);
      debugPrint('AdminSettingsService _updateTaxonomyRow error: $e');
      return false;
    }
  }

  Future<bool> _deleteTaxonomyRow(String id) async {
    lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return true;
    if (!SupabaseHelper.isUuid(id)) {
      lastError = 'Invalid record identifier.';
      return false;
    }
    try {
      final deleted = await supabase
          .from('platform_taxonomies')
          .delete()
          .eq('id', id)
          .select('id');
      if ((deleted as List).isEmpty) {
        lastError = 'Unable to remove record from Supabase.';
        return false;
      }
      return true;
    } catch (e) {
      lastError = SupabaseHelper.friendlyError(e);
      debugPrint('AdminSettingsService _deleteTaxonomyRow error: $e');
      return false;
    }
  }

  Future<bool> _updateSupportTicketRow(
    String ticketId,
    Map<String, dynamic> fields,
  ) async {
    lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return true;
    if (!SupabaseHelper.isUuid(ticketId)) {
      lastError = 'Invalid support ticket identifier.';
      return false;
    }
    try {
      final updated = await supabase
          .from('support_tickets')
          .update(fields)
          .eq('id', ticketId)
          .select('id');
      if ((updated as List).isEmpty) {
        lastError = 'Ticket update did not match any row in Supabase.';
        return false;
      }
      return true;
    } catch (e) {
      lastError = SupabaseHelper.friendlyError(e);
      debugPrint('AdminSettingsService _updateSupportTicketRow error: $e');
      return false;
    }
  }

  Future<bool> _upsertAdminRbacRow({
    required String email,
    required String department,
    required String role,
    required String roleDisplayName,
    required List<String> permissions,
  }) async {
    lastError = null;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return true;
    final normalizedEmail = email.trim().toLowerCase();
    try {
      await supabase.from('platform_taxonomies').upsert(
        {
          'item_type': 'admin_rbac',
          'name': normalizedEmail,
          'description': roleDisplayName,
          'is_active': true,
          'metadata': {
            'role': role,
            'role_display_name': roleDisplayName,
            'department': department.trim(),
            'permissions': permissions,
          },
        },
        onConflict: 'item_type,name',
      );
      return true;
    } catch (e) {
      lastError = SupabaseHelper.friendlyError(e);
      debugPrint('AdminSettingsService _upsertAdminRbacRow error: $e');
      return false;
    }
  }

  // --- 1. CATEGORY MANAGEMENT ---
  bool isDuplicateCategory(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return categoriesNotifier.value.any(
      (c) => c.name.trim().toLowerCase() == lower && c.id != excludeId,
    );
  }

  Future<bool> addCategory({
    required String name,
    required String description,
    required Color color,
    required String adminEmail,
  }) async {
    if (isDuplicateCategory(name)) {
      lastError = 'Category with this title already exists.';
      return false;
    }

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

    final ok = await _insertTaxonomyRow({
      'id': newId,
      'item_type': 'category',
      'name': newCat.name,
      'description': newCat.description,
      'is_active': true,
      'metadata': {'color_value': color.toARGB32()},
    });
    if (!ok) return false;

    categoriesNotifier.value = [...categoriesNotifier.value, newCat];
    await _logAction(
      adminEmail,
      'CATEGORY_CREATE',
      newCat.name,
      'Created new category taxonomy.',
    );
    return true;
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String description,
    required Color color,
    required String adminEmail,
  }) async {
    if (isDuplicateCategory(name, excludeId: id)) {
      lastError = 'Duplicate category name detected.';
      return false;
    }

    final ok = await _updateTaxonomyRow(id, {
      'name': name.trim(),
      'description': description.trim(),
      'metadata': {'color_value': color.toARGB32()},
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'CATEGORY_UPDATE',
      name.trim(),
      'Updated category description and theme color.',
    );
    return true;
  }

  Future<bool> toggleCategoryActive(String id, String adminEmail) async {
    final idx = categoriesNotifier.value.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    final target = categoriesNotifier.value[idx];
    final newStatus = !target.isActive;

    final ok = await _updateTaxonomyRow(id, {'is_active': newStatus});
    if (!ok) return false;

    categoriesNotifier.value = categoriesNotifier.value.map((c) {
      if (c.id == id) return c.copyWith(isActive: newStatus);
      return c;
    }).toList();

    await _logAction(
      adminEmail,
      'CATEGORY_TOGGLE',
      target.name,
      'Toggled status to ${newStatus ? 'Active' : 'Inactive'}.',
    );
    return true;
  }

  // --- 2. SKILLS MANAGEMENT ---
  bool isDuplicateSkill(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return skillsNotifier.value.any(
      (s) => s.name.trim().toLowerCase() == lower && s.id != excludeId,
    );
  }

  Future<bool> addSkill({
    required String name,
    required String categoryName,
    required String adminEmail,
  }) async {
    if (isDuplicateSkill(name)) {
      lastError = 'Duplicate skill name detected.';
      return false;
    }

    final newId = SupabaseHelper.generateUuid();
    final newSkill = SkillSettingItem(
      id: newId,
      name: name.trim(),
      categoryName: categoryName,
      usageCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final ok = await _insertTaxonomyRow({
      'id': newId,
      'item_type': 'skill',
      'name': newSkill.name,
      'description': '',
      'is_active': true,
      'metadata': {'category_name': categoryName},
    });
    if (!ok) return false;

    skillsNotifier.value = [...skillsNotifier.value, newSkill];
    await _logAction(
      adminEmail,
      'SKILL_CREATE',
      newSkill.name,
      'Added skill to $categoryName.',
    );
    return true;
  }

  Future<bool> updateSkill({
    required String id,
    required String name,
    required String categoryName,
    required String adminEmail,
  }) async {
    if (isDuplicateSkill(name, excludeId: id)) {
      lastError = 'Duplicate skill name detected.';
      return false;
    }

    final ok = await _updateTaxonomyRow(id, {
      'name': name.trim(),
      'metadata': {'category_name': categoryName},
    });
    if (!ok) return false;

    skillsNotifier.value = skillsNotifier.value.map((s) {
      if (s.id == id) {
        return s.copyWith(name: name.trim(), categoryName: categoryName);
      }
      return s;
    }).toList();

    await _logAction(
      adminEmail,
      'SKILL_UPDATE',
      name.trim(),
      'Updated skill taxonomy metadata.',
    );
    return true;
  }

  Future<bool> deleteSkill(String id, String adminEmail) async {
    final idx = skillsNotifier.value.indexWhere((s) => s.id == id);
    if (idx == -1) return false;
    final target = skillsNotifier.value[idx];

    final ok = await _deleteTaxonomyRow(id);
    if (!ok) return false;

    skillsNotifier.value =
        skillsNotifier.value.where((s) => s.id != id).toList();

    await _logAction(
      adminEmail,
      'SKILL_DELETE',
      target.name,
      'Removed skill from taxonomy registry.',
    );
    return true;
  }

  Future<bool> toggleSkillActive(String id, String adminEmail) async {
    final idx = skillsNotifier.value.indexWhere((s) => s.id == id);
    if (idx == -1) return false;
    final target = skillsNotifier.value[idx];
    final newStatus = !target.isActive;

    final ok = await _updateTaxonomyRow(id, {'is_active': newStatus});
    if (!ok) return false;

    skillsNotifier.value = skillsNotifier.value.map((s) {
      if (s.id == id) return s.copyWith(isActive: newStatus);
      return s;
    }).toList();

    await _logAction(
      adminEmail,
      'SKILL_TOGGLE',
      target.name,
      'Toggled skill status to ${newStatus ? 'Active' : 'Deactivated'}.',
    );
    return true;
  }

  // --- 3. UNIVERSITY MANAGEMENT ---
  bool isDuplicateUniversity(String name, String domain, {String? excludeId}) {
    final lowerName = name.trim().toLowerCase();
    final lowerDomain = domain.trim().toLowerCase();
    return universitiesNotifier.value.any(
      (u) =>
          (u.name.trim().toLowerCase() == lowerName ||
              (lowerDomain.isNotEmpty &&
                  u.domain.trim().toLowerCase() == lowerDomain)) &&
          u.id != excludeId,
    );
  }

  Future<bool> addUniversity({
    required String name,
    required String shortName,
    required String city,
    required String province,
    required String domain,
    required String adminEmail,
  }) async {
    if (isDuplicateUniversity(name, domain)) {
      lastError = 'University with this name or domain already accredited.';
      return false;
    }

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

    final ok = await _insertTaxonomyRow({
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
    if (!ok) return false;

    universitiesNotifier.value = [...universitiesNotifier.value, newUni];
    await _logAction(
      adminEmail,
      'UNIVERSITY_CREATE',
      newUni.shortName,
      'Accredited university ${newUni.domain} in ${newUni.city}.',
    );
    return true;
  }

  Future<bool> updateUniversity({
    required String id,
    required String name,
    required String shortName,
    required String city,
    required String province,
    required String domain,
    required String adminEmail,
  }) async {
    if (isDuplicateUniversity(name, domain, excludeId: id)) {
      lastError = 'Duplicate university records detected.';
      return false;
    }

    final ok = await _updateTaxonomyRow(id, {
      'name': name.trim(),
      'description': '${city.trim()}, ${province.trim()}',
      'metadata': {
        'short_name': shortName.trim(),
        'city': city.trim(),
        'province': province.trim(),
        'domain': domain.trim().toLowerCase(),
      },
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'UNIVERSITY_UPDATE',
      shortName.trim(),
      'Updated institutional records.',
    );
    return true;
  }

  Future<bool> toggleUniversityActive(String id, String adminEmail) async {
    final idx = universitiesNotifier.value.indexWhere((u) => u.id == id);
    if (idx == -1) return false;
    final target = universitiesNotifier.value[idx];
    final newStatus = !target.isActive;

    final ok = await _updateTaxonomyRow(id, {'is_active': newStatus});
    if (!ok) return false;

    universitiesNotifier.value = universitiesNotifier.value.map((u) {
      if (u.id == id) return u.copyWith(isActive: newStatus);
      return u;
    }).toList();

    await _logAction(
      adminEmail,
      'UNIVERSITY_TOGGLE',
      target.shortName,
      'Changed accreditation state to ${newStatus ? 'Active' : 'Suspended'}.',
    );
    return true;
  }

  // --- 4. HELP REQUESTS ---
  Future<bool> addAdminResponse({
    required String ticketId,
    required String responseText,
    required String adminEmail,
  }) async {
    final cleanResp = responseText.trim();
    final ok = await _updateSupportTicketRow(ticketId, {
      'admin_response': cleanResp,
      'assigned_to': adminEmail,
      'status': 'In Progress',
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'HELP_TICKET_RESPOND',
      ticketId,
      'Provided administrative answer.',
    );
    return true;
  }

  Future<bool> resolveHelpRequest({
    required String ticketId,
    required String resolutionNotes,
    required String adminEmail,
  }) async {
    final cleanNotes = resolutionNotes.trim();
    final ok = await _updateSupportTicketRow(ticketId, {
      'admin_response': cleanNotes,
      'assigned_to': adminEmail,
      'status': 'Resolved',
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'HELP_TICKET_RESOLVE',
      ticketId,
      'Ticket resolved: $cleanNotes',
    );
    return true;
  }

  // --- 5. COMPLAINT MANAGEMENT ---
  Future<bool> updateInvestigationNotes({
    required String complaintId,
    required String notes,
    required String adminEmail,
  }) async {
    final cleanNotes = notes.trim();
    final ok = await _updateSupportTicketRow(complaintId, {
      'admin_response': cleanNotes,
      'assigned_to': adminEmail,
      'status': 'under_investigation',
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'COMPLAINT_NOTE',
      complaintId,
      'Recorded investigation observations.',
    );
    return true;
  }

  Future<bool> resolveComplaint({
    required String complaintId,
    required String reason,
    required String adminEmail,
  }) async {
    final cleanReason = reason.trim();
    final ok = await _updateSupportTicketRow(complaintId, {
      'admin_response': cleanReason,
      'assigned_to': adminEmail,
      'status': 'resolved',
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'COMPLAINT_RESOLVE',
      complaintId,
      'Resolved complaint with formal outcome.',
    );
    return true;
  }

  Future<bool> dismissComplaint({
    required String complaintId,
    required String reason,
    required String adminEmail,
  }) async {
    final cleanReason = reason.trim();
    final ok = await _updateSupportTicketRow(complaintId, {
      'admin_response': cleanReason,
      'assigned_to': adminEmail,
      'status': 'dismissed',
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!ok) return false;

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

    await _logAction(
      adminEmail,
      'COMPLAINT_DISMISS',
      complaintId,
      'Dismissed grievance without penalty.',
    );
    return true;
  }

  // --- 6. PLATFORM POLICIES ---
  Future<bool> updatePolicy({
    required String policyKey,
    required String title,
    required String content,
    required String changeSummary,
    required String adminEmail,
  }) async {
    final idx = policiesNotifier.value.indexWhere(
      (p) => p.policyKey == policyKey || p.id == policyKey,
    );
    if (idx == -1) return false;

    final p = policiesNotifier.value[idx];
    final currentParts = p.version.replaceAll('v', '').split('.');
    final major = currentParts.isNotEmpty ? currentParts[0] : '1';
    final minor = currentParts.length > 1
        ? (int.tryParse(currentParts[1]) ?? 0) + 1
        : 1;
    final nextVersion = 'v$major.$minor';
    final now = DateTime.now();

    final newHistory = [
      PolicyVersionRecord(
        version: nextVersion,
        updatedAt: now,
        updatedByAdmin: adminEmail,
        changeSummary: changeSummary.trim(),
      ),
      ...p.history,
    ];

    final updatedPolicy = p.copyWith(
      title: title.trim(),
      content: content.trim(),
      version: nextVersion,
      lastUpdatedAt: now,
      updatedByAdmin: adminEmail,
      history: newHistory,
    );

    final ok = await _updateTaxonomyRow(updatedPolicy.id, {
      'name': updatedPolicy.title,
      'description': updatedPolicy.content,
      'metadata': {
        'policy_key': updatedPolicy.policyKey,
        'version': updatedPolicy.version,
        'last_updated_at': updatedPolicy.lastUpdatedAt.toIso8601String(),
        'updated_by_admin': updatedPolicy.updatedByAdmin,
        'history': updatedPolicy.history
            .map((h) => {
                  'version': h.version,
                  'updated_at': h.updatedAt.toIso8601String(),
                  'updated_by_admin': h.updatedByAdmin,
                  'change_summary': h.changeSummary,
                })
            .toList(),
      },
    });
    if (!ok) return false;

    final nextList = List<PlatformPolicyItem>.from(policiesNotifier.value);
    nextList[idx] = updatedPolicy;
    policiesNotifier.value = nextList;

    await _logAction(
      adminEmail,
      'POLICY_UPDATE',
      title.trim(),
      'Published version update with audit changelog.',
    );
    return true;
  }

  /// Create a brand-new policy when policy table starts empty.
  Future<bool> createPolicy({
    required String policyKey,
    required String title,
    required String content,
    required String adminEmail,
  }) async {
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

    final ok = await _insertTaxonomyRow({
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
        'history': [
          {
            'version': 'v1.0',
            'updated_at': now.toIso8601String(),
            'updated_by_admin': adminEmail,
            'change_summary': 'Initial policy publication.',
          },
        ],
      },
    });
    if (!ok) return false;

    policiesNotifier.value = [...policiesNotifier.value, item];
    await _logAction(
      adminEmail,
      'POLICY_CREATE',
      item.title,
      'Created initial governance policy document.',
    );
    return true;
  }

  // --- 7. ADMIN ACCESS & RBAC ---
  Future<bool> provisionAdminAccount({
    required String fullName,
    required String email,
    String password = '',
    required String role,
    required String roleDisplayName,
    required String department,
    required List<String> permissions,
    required String adminEmail,
  }) async {
    lastError = null;
    final normalized = email.trim().toLowerCase();
    if (adminsNotifier.value.any((a) => a.email.toLowerCase() == normalized)) {
      lastError = 'Administrator with this email already exists.';
      return false;
    }

    String newId = SupabaseHelper.generateUuid();
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      final cleanPass = password.trim();
      if (cleanPass.isEmpty) {
        lastError = 'Initial password is required to create a Supabase admin account.';
        return false;
      }
      try {
        final rpcId = await SupabaseHelper.provisionAdminInApp(
          email: normalized,
          password: cleanPass,
          fullName: fullName.trim(),
          department: department.trim(),
        );
        if (SupabaseHelper.isUuid(rpcId)) {
          newId = rpcId;
        }
      } catch (e) {
        lastError = SupabaseHelper.friendlyError(e);
        debugPrint('AdminSettingsService provisionAdminAccount RPC error: $e');
        return false;
      }

      final rbacSaved = await _upsertAdminRbacRow(
        email: normalized,
        department: department,
        role: role,
        roleDisplayName: roleDisplayName,
        permissions: permissions,
      );
      if (!rbacSaved) return false;
    }

    final newAdmin = AdminUserModel(
      id: newId,
      fullName: fullName.trim(),
      email: normalized,
      role: role,
      roleDisplayName: roleDisplayName,
      department: department.trim(),
      avatarInitial: SupabaseHelper.initialsFor(fullName, fallback: 'AD'),
      permissions: permissions,
      lastLoginAt: 'Provisioned & Active',
      isActive: true,
    );

    adminsNotifier.value = [...adminsNotifier.value, newAdmin];
    await _logAction(
      adminEmail,
      'ADMIN_PROVISION',
      normalized,
      'Provisioned trusted administrative role ($role).',
    );
    return true;
  }

  Future<bool> toggleAdminActive(String id, String adminEmail) async {
    lastError = null;
    final idx = adminsNotifier.value.indexWhere((a) => a.id == id);
    if (idx == -1) return false;
    final target = adminsNotifier.value[idx];
    if (target.role == 'SUPER_ADMIN') {
      lastError = 'Root Super Administrator accounts cannot be deactivated.';
      return false;
    }

    final newStatus = !target.isActive;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      if (!SupabaseHelper.isUuid(id)) return false;
      try {
        final updated = await supabase
            .from('profiles')
            .update({
              'account_status': newStatus ? 'active' : 'suspended',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select('id');
        if ((updated as List).isEmpty) {
          lastError = 'Unable to update administrator account status in Supabase.';
          return false;
        }
      } catch (e) {
        lastError = SupabaseHelper.friendlyError(e);
        debugPrint('AdminSettingsService toggleAdminActive error: $e');
        return false;
      }
    }

    adminsNotifier.value = adminsNotifier.value.map((a) {
      if (a.id == id) {
        return a.copyWith(isActive: newStatus);
      }
      return a;
    }).toList();

    await _logAction(
      adminEmail,
      'ADMIN_STATUS',
      target.email,
      'Changed account state to ${newStatus ? 'Active' : 'Suspended'}.',
    );
    return true;
  }

  Future<bool> updateAdminPermissions({
    required String id,
    required List<String> permissions,
    required String adminEmail,
  }) async {
    final idx = adminsNotifier.value.indexWhere((a) => a.id == id);
    if (idx == -1) return false;
    final target = adminsNotifier.value[idx];

    final ok = await _upsertAdminRbacRow(
      email: target.email,
      department: target.department,
      role: target.role,
      roleDisplayName: target.roleDisplayName,
      permissions: permissions,
    );
    if (!ok) return false;

    adminsNotifier.value = adminsNotifier.value.map((a) {
      if (a.id == id) return a.copyWith(permissions: permissions);
      return a;
    }).toList();

    await _logAction(
      adminEmail,
      'ADMIN_PERMISSIONS',
      target.email,
      'Updated assigned granular roles.',
    );
    return true;
  }

  // --- 8. ADMIN PROFILE, PASSWORD & SESSIONS ---
  Future<bool> updateProfile({
    required String fullName,
    required String department,
  }) async {
    lastError = null;
    final current = AdminAuthService().currentAdmin;
    if (current == null) return false;

    final supabase = SupabaseHelper.clientOrNull;
    final uid = supabase?.auth.currentUser?.id;
    if (supabase != null && uid != null) {
      try {
        final updated = await supabase
            .from('profiles')
            .update({
              'name': fullName.trim(),
              'university': department.trim(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', uid)
            .select('id');
        if ((updated as List).isEmpty) {
          lastError = 'Administrator profile record not found in Supabase.';
          return false;
        }
      } catch (e) {
        lastError = SupabaseHelper.friendlyError(e);
        debugPrint('AdminSettingsService updateProfile error: $e');
        return false;
      }
    }

    final updatedAdmin = current.copyWith(
      fullName: fullName.trim(),
      department: department.trim(),
      avatarInitial: SupabaseHelper.initialsFor(fullName, fallback: 'EA'),
    );

    AdminAuthService().currentAdminNotifier.value = updatedAdmin;
    adminsNotifier.value = adminsNotifier.value
        .map((a) => a.id == updatedAdmin.id ? updatedAdmin : a)
        .toList();

    await _logAction(
      current.email,
      'PROFILE_UPDATE',
      current.email,
      'Updated administrative profile contact info.',
    );
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String adminEmail,
  }) async {
    lastError = null;
    final trimmedNew = newPassword.trim();
    if (trimmedNew.isEmpty) return false;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && supabase.auth.currentUser != null) {
      try {
        if (currentPassword.trim().isNotEmpty) {
          final currentEmail =
              supabase.auth.currentUser?.email ?? adminEmail.trim();
          SupabaseHelper.beginInteractiveAuth();
          try {
            await supabase.auth.signInWithPassword(
              email: currentEmail,
              password: currentPassword.trim(),
            );
          } finally {
            SupabaseHelper.endInteractiveAuth();
          }
        }
        await supabase.auth.updateUser(UserAttributes(password: trimmedNew));
      } catch (e) {
        lastError = SupabaseHelper.friendlyError(e);
        debugPrint('AdminSettingsService changePassword error: $e');
        return false;
      }
    }

    await _logAction(
      adminEmail,
      'PASSWORD_CHANGE',
      adminEmail,
      'Administrator password updated.',
    );
    return true;
  }

  Future<void> terminateSession(String sessionId, String adminEmail) async {
    sessionsNotifier.value = sessionsNotifier.value
        .where((s) => s.sessionId != sessionId)
        .toList();
    await _logAction(
      adminEmail,
      'SESSION_TERMINATE',
      sessionId,
      'Terminated active session token.',
    );
  }

  Future<void> _logAction(
    String adminEmail,
    String action,
    String target,
    String details,
  ) async {
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
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      try {
        await supabase.from('admin_audit_logs').insert({
          'admin_email': adminEmail,
          'action': action,
          'target': target,
          'details': details,
        });
      } catch (e) {
        debugPrint('AdminSettingsService audit log insert error: $e');
      }
    }
  }

  void reset() {
    lastError = null;
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
