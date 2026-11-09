import 'dart:math';
import 'package:flutter/material.dart';
import 'package:link_vibe/feature/admin/models/admin_settings_model.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';

/// Centralized Administration, System Taxonomies, Support & RBAC Service
class AdminSettingsService {
  static final AdminSettingsService _instance = AdminSettingsService._internal();
  factory AdminSettingsService() => _instance;

  AdminSettingsService._internal() {
    _initData();
  }

  late final ValueNotifier<List<CategorySettingItem>> categoriesNotifier;
  late final ValueNotifier<List<SkillSettingItem>> skillsNotifier;
  late final ValueNotifier<List<UniversitySettingItem>> universitiesNotifier;
  late final ValueNotifier<List<HelpRequestItem>> helpRequestsNotifier;
  late final ValueNotifier<List<ComplaintItem>> complaintsNotifier;
  late final ValueNotifier<List<PlatformPolicyItem>> policiesNotifier;
  late final ValueNotifier<List<AdminUserModel>> adminsNotifier;
  late final ValueNotifier<List<AdminSessionItem>> sessionsNotifier;
  late final ValueNotifier<List<AdminAuditLogItem>> auditLogsNotifier;

  void _initData() {
    // 1. Initial Categories
    categoriesNotifier = ValueNotifier<List<CategorySettingItem>>([
      CategorySettingItem(
        id: 'cat_01',
        name: 'Artificial Intelligence & Machine Learning',
        description: 'Computer vision, natural language processing, LLM fine-tuning, and predictive modeling.',
        color: const Color(0xFF6366F1), // Indigo
        projectCount: 28,
        isActive: true,
        createdAt: DateTime(2026, 1, 15),
      ),
      CategorySettingItem(
        id: 'cat_02',
        name: 'Mobile Application Development',
        description: 'Cross-platform Flutter/Dart and native iOS/Android corporate applications.',
        color: const Color(0xFF0D9488), // Teal
        projectCount: 22,
        isActive: true,
        createdAt: DateTime(2026, 1, 15),
      ),
      CategorySettingItem(
        id: 'cat_03',
        name: 'Cloud Infrastructure & DevOps',
        description: 'Docker containerization, Kubernetes orchestration, CI/CD pipelines, and cloud security.',
        color: const Color(0xFF3B82F6), // Blue
        projectCount: 15,
        isActive: true,
        createdAt: DateTime(2026, 2, 1),
      ),
      CategorySettingItem(
        id: 'cat_04',
        name: 'Full Stack Web Engineering',
        description: 'Modern reactive web apps with React, Next.js, Node.js, and scalable APIs.',
        color: const Color(0xFF10B981), // Emerald
        projectCount: 12,
        isActive: true,
        createdAt: DateTime(2026, 2, 10),
      ),
      CategorySettingItem(
        id: 'cat_05',
        name: 'Cybersecurity & Threat Intelligence',
        description: 'Vulnerability assessment, penetration testing, OWASP compliance, and security audits.',
        color: const Color(0xFFF59E0B), // Amber
        projectCount: 7,
        isActive: true,
        createdAt: DateTime(2026, 3, 5),
      ),
      CategorySettingItem(
        id: 'cat_06',
        name: 'UI/UX & Product Design Systems',
        description: 'Design token architecture, Figma component libraries, and user experience research.',
        color: const Color(0xFFEC4899), // Pink
        projectCount: 5,
        isActive: true,
        createdAt: DateTime(2026, 3, 20),
      ),
    ]);

    // 2. Initial Skills
    skillsNotifier = ValueNotifier<List<SkillSettingItem>>([
      SkillSettingItem(id: 'skl_01', name: 'Flutter & Dart', categoryName: 'Mobile Application Development', usageCount: 26, isActive: true, createdAt: DateTime(2026, 1, 15)),
      SkillSettingItem(id: 'skl_02', name: 'Python & PyTorch', categoryName: 'Artificial Intelligence & Machine Learning', usageCount: 24, isActive: true, createdAt: DateTime(2026, 1, 15)),
      SkillSettingItem(id: 'skl_03', name: 'Docker & Kubernetes', categoryName: 'Cloud Infrastructure & DevOps', usageCount: 18, isActive: true, createdAt: DateTime(2026, 1, 20)),
      SkillSettingItem(id: 'skl_04', name: 'React & Next.js 14', categoryName: 'Full Stack Web Engineering', usageCount: 16, isActive: true, createdAt: DateTime(2026, 2, 1)),
      SkillSettingItem(id: 'skl_05', name: 'PostgreSQL & Supabase', categoryName: 'Full Stack Web Engineering', usageCount: 15, isActive: true, createdAt: DateTime(2026, 2, 5)),
      SkillSettingItem(id: 'skl_06', name: 'FastAPI Microservices', categoryName: 'Full Stack Web Engineering', usageCount: 13, isActive: true, createdAt: DateTime(2026, 2, 15)),
      SkillSettingItem(id: 'skl_07', name: 'OWASP & Penetration Testing', categoryName: 'Cybersecurity & Threat Intelligence', usageCount: 9, isActive: true, createdAt: DateTime(2026, 3, 1)),
      SkillSettingItem(id: 'skl_08', name: 'Figma & Design Tokens', categoryName: 'UI/UX & Product Design Systems', usageCount: 8, isActive: true, createdAt: DateTime(2026, 3, 10)),
      SkillSettingItem(id: 'skl_09', name: 'Node.js & Express', categoryName: 'Full Stack Web Engineering', usageCount: 11, isActive: true, createdAt: DateTime(2026, 3, 15)),
      SkillSettingItem(id: 'skl_10', name: 'Git & GitHub Actions', categoryName: 'Cloud Infrastructure & DevOps', usageCount: 21, isActive: true, createdAt: DateTime(2026, 3, 22)),
    ]);

    // 3. Initial Universities
    universitiesNotifier = ValueNotifier<List<UniversitySettingItem>>([
      UniversitySettingItem(id: 'uni_01', name: 'National University of Computer and Emerging Sciences', shortName: 'FAST-NUCES', city: 'Islamabad', province: 'ICT', domain: 'nu.edu.pk', studentCount: 420, isActive: true, createdAt: DateTime(2026, 1, 10)),
      UniversitySettingItem(id: 'uni_02', name: 'National University of Sciences & Technology', shortName: 'NUST', city: 'Islamabad', province: 'ICT', domain: 'seecs.edu.pk', studentCount: 385, isActive: true, createdAt: DateTime(2026, 1, 10)),
      UniversitySettingItem(id: 'uni_03', name: 'Punjab University College of Information Technology', shortName: 'PUCIT', city: 'Lahore', province: 'Punjab', domain: 'pucit.edu.pk', studentCount: 290, isActive: true, createdAt: DateTime(2026, 1, 12)),
      UniversitySettingItem(id: 'uni_04', name: 'Lahore University of Management Sciences', shortName: 'LUMS', city: 'Lahore', province: 'Punjab', domain: 'lums.edu.pk', studentCount: 210, isActive: true, createdAt: DateTime(2026, 1, 15)),
      UniversitySettingItem(id: 'uni_05', name: 'University of Engineering and Technology', shortName: 'UET Lahore', city: 'Lahore', province: 'Punjab', domain: 'uet.edu.pk', studentCount: 195, isActive: true, createdAt: DateTime(2026, 1, 20)),
      UniversitySettingItem(id: 'uni_06', name: 'Ghulam Ishaq Khan Institute', shortName: 'GIKI', city: 'Topi', province: 'KPK', domain: 'giki.edu.pk', studentCount: 160, isActive: true, createdAt: DateTime(2026, 2, 1)),
      UniversitySettingItem(id: 'uni_07', name: 'Institute of Business Administration', shortName: 'IBA Karachi', city: 'Karachi', province: 'Sindh', domain: 'iba.edu.pk', studentCount: 140, isActive: true, createdAt: DateTime(2026, 2, 5)),
      UniversitySettingItem(id: 'uni_08', name: 'COMSATS University Islamabad', shortName: 'CUI', city: 'Islamabad', province: 'ICT', domain: 'comsats.edu.pk', studentCount: 230, isActive: true, createdAt: DateTime(2026, 2, 15)),
    ]);

    // 4. Initial Help Requests
    helpRequestsNotifier = ValueNotifier<List<HelpRequestItem>>([
      HelpRequestItem(
        id: 'TKT-2026-081',
        senderName: 'Hamza Tariq',
        senderEmail: 'hamza.tariq@nu.edu.pk',
        userType: 'student',
        subject: 'Degree transcript verification upload issue',
        message: 'I received an error while uploading my 7th semester official grade card PDF. It keeps saying document exceeded size.',
        category: 'Document Verification',
        status: HelpRequestStatus.pending,
        priority: HelpRequestPriority.high,
        submittedAt: DateTime(2026, 11, 9, 14, 20),
      ),
      HelpRequestItem(
        id: 'TKT-2026-079',
        senderName: 'Arbisoft Talent Acquisition',
        senderEmail: 'careers@arbisoft.com',
        userType: 'company',
        subject: 'Project deadline extension for sprint team',
        message: 'We wish to extend the final sprint milestone deliverable by 5 working days due to university mid-term schedules.',
        category: 'Project Milestones',
        status: HelpRequestStatus.inProgress,
        priority: HelpRequestPriority.normal,
        submittedAt: DateTime(2026, 11, 8, 11, 15),
        adminResponse: 'Under review with academic department liaison.',
        respondedByAdmin: 'ops@campusconnect.edu.pk',
      ),
      HelpRequestItem(
        id: 'TKT-2026-072',
        senderName: 'Ayesha Siddiqui',
        senderEmail: 'ayesha.s@seecs.edu.pk',
        userType: 'student',
        subject: 'Certificate verification ID not generating QR',
        message: 'My completed sprint certificate CC-CERT-2026-N044 QR code links to a 404 page.',
        category: 'Credential Vault',
        status: HelpRequestStatus.resolved,
        priority: HelpRequestPriority.urgent,
        submittedAt: DateTime(2026, 11, 6, 9, 30),
        adminResponse: 'FIPS cryptographic ledger re-indexed and public URL regenerated.',
        respondedByAdmin: 'admin@campusconnect.edu.pk',
        resolvedAt: DateTime(2026, 11, 6, 12, 10),
        resolutionNotes: 'Verified DNS routing and ledger sync resolved.',
      ),
    ]);

    // 5. Initial Complaints
    complaintsNotifier = ValueNotifier<List<ComplaintItem>>([
      ComplaintItem(
        id: 'CMP-2026-014',
        complainantName: 'Systems Limited (Corporate Sponsor)',
        complainantEmail: 'projects@systemsltd.com',
        reportedEntityName: 'Student Candidate (Usman Farooq)',
        reportedEntityType: 'student',
        category: 'Deliverable Integrity & Plagiarism',
        subject: 'Suspected third-party repository code submitted without attribution',
        description: 'Candidate submitted sprint module that closely mirrors an open-source MIT repository without disclosing libraries or attribution.',
        status: ComplaintStatus.underInvestigation,
        severity: ComplaintSeverity.high,
        submittedAt: DateTime(2026, 11, 7, 16, 45),
        investigationNotes: 'Administrative code diff audit scheduled with candidate and mentor.',
        history: [
          ComplaintHistoryEvent(
            action: 'Complaint Logged',
            performedBy: 'System Auto-Ingest',
            timestamp: DateTime(2026, 11, 7, 16, 45),
            notes: 'Corporate grievance ticket opened with repository comparison log.',
          ),
          ComplaintHistoryEvent(
            action: 'Status updated to Under Investigation',
            performedBy: 'ops@campusconnect.edu.pk',
            timestamp: DateTime(2026, 11, 8, 10, 0),
            notes: 'Code integrity review initiated.',
          ),
        ],
      ),
      ComplaintItem(
        id: 'CMP-2026-011',
        complainantName: 'PUCIT Student Cohort Team',
        complainantEmail: 'lead@pucit.edu.pk',
        reportedEntityName: 'NexGen Cloud Solutions',
        reportedEntityType: 'company',
        category: 'Unresponsive Corporate Liaison',
        subject: 'Corporate mentor has not responded for 10 consecutive days',
        description: 'Sprint deliverable review is blocked because company mentor has not scheduled weekly check-in or reviewed PR.',
        status: ComplaintStatus.resolved,
        severity: ComplaintSeverity.medium,
        submittedAt: DateTime(2026, 11, 3, 10, 15),
        investigationNotes: 'Contacted company VP of Engineering. Mentor on emergency medical leave.',
        resolutionReason: 'Corporate sponsor appointed alternate senior engineering lead to unblock sprint evaluations.',
        resolvedByAdmin: 'admin@campusconnect.edu.pk',
        resolvedAt: DateTime(2026, 11, 5, 15, 30),
      ),
    ]);

    // 6. Initial Platform Policies
    policiesNotifier = ValueNotifier<List<PlatformPolicyItem>>([
      PlatformPolicyItem(
        id: 'pol_terms',
        title: 'Institutional Terms of Service & Collaboration Charter',
        policyKey: 'terms',
        version: 'v2.4',
        lastUpdatedAt: DateTime(2026, 10, 15),
        updatedByAdmin: 'admin@campusconnect.edu.pk',
        content: 'CampusConnect facilitates non-monetary academic and corporate student collaboration. All projects are strictly educational and non-financial sprints. No financial compensation, salaries, or stipend claims are mediated through the platform.',
        history: [
          PolicyVersionRecord(version: 'v2.4', updatedAt: DateTime(2026, 10, 15), updatedByAdmin: 'admin@campusconnect.edu.pk', changeSummary: 'Clarified educational project governance and non-financial charter.'),
          PolicyVersionRecord(version: 'v2.3', updatedAt: DateTime(2026, 7, 1), updatedByAdmin: 'admin@campusconnect.edu.pk', changeSummary: 'Integrated HEC accreditation compliance clauses.'),
        ],
      ),
      PlatformPolicyItem(
        id: 'pol_privacy',
        title: 'Academic Data Privacy & FERPA Compliance',
        policyKey: 'privacy',
        version: 'v2.1',
        lastUpdatedAt: DateTime(2026, 9, 20),
        updatedByAdmin: 'admin@campusconnect.edu.pk',
        content: 'Student academic records, transcript credentials, and corporate evaluation documents are encrypted using AES-256 at rest and TLS 1.3 in transit. Personal contact details are disclosed solely to verified project mentors.',
        history: [
          PolicyVersionRecord(version: 'v2.1', updatedAt: DateTime(2026, 9, 20), updatedByAdmin: 'admin@campusconnect.edu.pk', changeSummary: 'Updated data retention policies for graduated students.'),
        ],
      ),
      PlatformPolicyItem(
        id: 'pol_community',
        title: 'Community Code of Conduct & Academic Integrity',
        policyKey: 'community',
        version: 'v1.8',
        lastUpdatedAt: DateTime(2026, 8, 14),
        updatedByAdmin: 'ops@campusconnect.edu.pk',
        content: 'Members agree to professional conduct, mutual respect, and honest academic attribution. Plagiarism, unauthorized code duplication, or harassment results in immediate credential nullification and institutional report.',
      ),
    ]);

    // 7. Initial Admin Accounts
    adminsNotifier = ValueNotifier<List<AdminUserModel>>([
      const AdminUserModel(
        id: 'adm_root_001',
        fullName: 'Dr. Tariq Mahmood',
        email: 'admin@campusconnect.edu.pk',
        role: 'SUPER_ADMIN',
        roleDisplayName: 'Executive Super Administrator',
        department: 'CampusConnect Governance Council',
        avatarInitial: 'TM',
        permissions: ['all', 'manage_categories', 'manage_skills', 'manage_universities', 'manage_support', 'manage_policies', 'manage_admins'],
        lastLoginAt: 'Today at 09:15 AM',
        isActive: true,
      ),
      const AdminUserModel(
        id: 'adm_ops_002',
        fullName: 'Syeda Fatima Noor',
        email: 'ops@campusconnect.edu.pk',
        role: 'OPERATIONS_ADMIN',
        roleDisplayName: 'Operations & Verification Director',
        department: 'Corporate & University Partnerships',
        avatarInitial: 'FN',
        permissions: ['manage_categories', 'manage_skills', 'manage_universities', 'manage_support'],
        lastLoginAt: 'Yesterday at 04:30 PM',
        isActive: true,
      ),
      const AdminUserModel(
        id: 'adm_sec_003',
        fullName: 'Zainab Malik',
        email: 'compliance@campusconnect.edu.pk',
        role: 'AUDIT_ADMIN',
        roleDisplayName: 'Compliance & Audit Officer',
        department: 'Institutional Integrity Unit',
        avatarInitial: 'ZM',
        permissions: ['manage_support', 'manage_policies'],
        lastLoginAt: 'Nov 6 at 11:20 AM',
        isActive: true,
      ),
    ]);

    // 8. Initial Login Sessions
    sessionsNotifier = ValueNotifier<List<AdminSessionItem>>([
      AdminSessionItem(
        sessionId: 'sess_cur_9821',
        device: 'Windows 11 PC (Workstation)',
        browser: 'Google Chrome 131.0',
        ipAddress: '111.68.102.45 (PTCL Islamabad)',
        location: 'Islamabad, Pakistan',
        loginAt: DateTime.now().subtract(const Duration(hours: 2)),
        isCurrent: true,
      ),
      AdminSessionItem(
        sessionId: 'sess_sec_4102',
        device: 'MacBook Pro 16" M3',
        browser: 'Safari 18.1',
        ipAddress: '39.40.118.22 (Nayatel Lahore)',
        location: 'Lahore, Pakistan',
        loginAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        isCurrent: false,
      ),
    ]);

    // 9. Initial Audit Logs
    auditLogsNotifier = ValueNotifier<List<AdminAuditLogItem>>([
      AdminAuditLogItem(
        id: 'LOG-2026-9041',
        adminEmail: 'admin@campusconnect.edu.pk',
        action: 'POLICY_UPDATE',
        target: 'Institutional Terms of Service',
        timestamp: DateTime(2026, 11, 9, 18, 20),
        details: 'Updated collaboration charter version to v2.4.',
        ipAddress: '111.68.102.45',
      ),
      AdminAuditLogItem(
        id: 'LOG-2026-9038',
        adminEmail: 'ops@campusconnect.edu.pk',
        action: 'HELP_TICKET_ASSIGNED',
        target: 'TKT-2026-079',
        timestamp: DateTime(2026, 11, 8, 11, 30),
        details: 'Assigned Arbisoft extension inquiry to academic liaison.',
        ipAddress: '39.40.118.22',
      ),
      AdminAuditLogItem(
        id: 'LOG-2026-9012',
        adminEmail: 'admin@campusconnect.edu.pk',
        action: 'UNIVERSITY_ACCREDITATION',
        target: 'FAST-NUCES Islamabad',
        timestamp: DateTime(2026, 11, 5, 14, 0),
        details: 'Re-validated institutional domain and SSL cert binding.',
        ipAddress: '111.68.102.45',
      ),
    ]);
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

    final newCat = CategorySettingItem(
      id: 'cat_${Random().nextInt(9000) + 1000}',
      name: name.trim(),
      description: description.trim(),
      color: color,
      projectCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    categoriesNotifier.value = [...categoriesNotifier.value, newCat];
    _logAction(adminEmail, 'CATEGORY_CREATE', newCat.name, 'Created new category taxonomy.');
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
        return c.copyWith(name: name.trim(), description: description.trim(), color: color);
      }
      return c;
    }).toList();

    _logAction(adminEmail, 'CATEGORY_UPDATE', name, 'Updated category description and theme color.');
    return true;
  }

  void toggleCategoryActive(String id, String adminEmail) {
    categoriesNotifier.value = categoriesNotifier.value.map((c) {
      if (c.id == id) {
        final newStatus = !c.isActive;
        _logAction(adminEmail, 'CATEGORY_TOGGLE', c.name, 'Toggled status to ${newStatus ? 'Active' : 'Inactive'}.');
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

    final newSkill = SkillSettingItem(
      id: 'skl_${Random().nextInt(9000) + 1000}',
      name: name.trim(),
      categoryName: categoryName,
      usageCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    skillsNotifier.value = [...skillsNotifier.value, newSkill];
    _logAction(adminEmail, 'SKILL_CREATE', newSkill.name, 'Added skill to $categoryName.');
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

    _logAction(adminEmail, 'SKILL_UPDATE', name, 'Updated skill taxonomy metadata.');
    return true;
  }

  void deleteSkill(String id, String adminEmail) {
    final target = skillsNotifier.value.firstWhere((s) => s.id == id);
    skillsNotifier.value = skillsNotifier.value.where((s) => s.id != id).toList();
    _logAction(adminEmail, 'SKILL_DELETE', target.name, 'Removed skill from taxonomy registry.');
  }

  void toggleSkillActive(String id, String adminEmail) {
    skillsNotifier.value = skillsNotifier.value.map((s) {
      if (s.id == id) {
        final newStatus = !s.isActive;
        _logAction(adminEmail, 'SKILL_TOGGLE', s.name, 'Toggled skill status to ${newStatus ? 'Active' : 'Deactivated'}.');
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
          (u.name.trim().toLowerCase() == lowerName || u.domain.trim().toLowerCase() == lowerDomain) &&
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

    final newUni = UniversitySettingItem(
      id: 'uni_${Random().nextInt(9000) + 1000}',
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
    _logAction(adminEmail, 'UNIVERSITY_CREATE', newUni.shortName, 'Accredited university $domain in $city.');
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

    _logAction(adminEmail, 'UNIVERSITY_UPDATE', shortName, 'Updated institutional records.');
    return true;
  }

  void toggleUniversityActive(String id, String adminEmail) {
    universitiesNotifier.value = universitiesNotifier.value.map((u) {
      if (u.id == id) {
        final newStatus = !u.isActive;
        _logAction(adminEmail, 'UNIVERSITY_TOGGLE', u.shortName, 'Changed accreditation state to ${newStatus ? 'Active' : 'Suspended'}.');
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
    helpRequestsNotifier.value = helpRequestsNotifier.value.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(
          adminResponse: responseText.trim(),
          respondedByAdmin: adminEmail,
          status: HelpRequestStatus.inProgress,
        );
      }
      return t;
    }).toList();

    _logAction(adminEmail, 'HELP_TICKET_RESPOND', ticketId, 'Provided administrative answer.');
  }

  void resolveHelpRequest({
    required String ticketId,
    required String resolutionNotes,
    required String adminEmail,
  }) {
    helpRequestsNotifier.value = helpRequestsNotifier.value.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(
          status: HelpRequestStatus.resolved,
          resolvedAt: DateTime.now(),
          resolutionNotes: resolutionNotes.trim(),
        );
      }
      return t;
    }).toList();

    _logAction(adminEmail, 'HELP_TICKET_RESOLVE', ticketId, 'Ticket resolved: $resolutionNotes');
  }

  // --- 5. COMPLAINT MANAGEMENT ---
  void updateInvestigationNotes({
    required String complaintId,
    required String notes,
    required String adminEmail,
  }) {
    complaintsNotifier.value = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        final newHistory = [
          ...c.history,
          ComplaintHistoryEvent(
            action: 'Investigation Note Recorded',
            performedBy: adminEmail,
            timestamp: DateTime.now(),
            notes: notes.trim(),
          ),
        ];
        return c.copyWith(
          investigationNotes: notes.trim(),
          status: ComplaintStatus.underInvestigation,
          history: newHistory,
        );
      }
      return c;
    }).toList();

    _logAction(adminEmail, 'COMPLAINT_NOTE', complaintId, 'Recorded investigation observations.');
  }

  void resolveComplaint({
    required String complaintId,
    required String reason,
    required String adminEmail,
  }) {
    complaintsNotifier.value = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        final newHistory = [
          ...c.history,
          ComplaintHistoryEvent(
            action: 'Grievance Resolved',
            performedBy: adminEmail,
            timestamp: DateTime.now(),
            notes: reason.trim(),
          ),
        ];
        return c.copyWith(
          status: ComplaintStatus.resolved,
          resolutionReason: reason.trim(),
          resolvedByAdmin: adminEmail,
          resolvedAt: DateTime.now(),
          history: newHistory,
        );
      }
      return c;
    }).toList();

    _logAction(adminEmail, 'COMPLAINT_RESOLVE', complaintId, 'Resolved complaint with formal outcome.');
  }

  void dismissComplaint({
    required String complaintId,
    required String reason,
    required String adminEmail,
  }) {
    complaintsNotifier.value = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        final newHistory = [
          ...c.history,
          ComplaintHistoryEvent(
            action: 'Complaint Dismissed',
            performedBy: adminEmail,
            timestamp: DateTime.now(),
            notes: reason.trim(),
          ),
        ];
        return c.copyWith(
          status: ComplaintStatus.dismissed,
          resolutionReason: reason.trim(),
          resolvedByAdmin: adminEmail,
          resolvedAt: DateTime.now(),
          history: newHistory,
        );
      }
      return c;
    }).toList();

    _logAction(adminEmail, 'COMPLAINT_DISMISS', complaintId, 'Dismissed grievance without penalty.');
  }

  // --- 6. PLATFORM POLICIES ---
  void updatePolicy({
    required String policyKey,
    required String title,
    required String content,
    required String changeSummary,
    required String adminEmail,
  }) {
    policiesNotifier.value = policiesNotifier.value.map((p) {
      if (p.policyKey == policyKey) {
        // Increment minor version (e.g. v2.4 -> v2.5)
        final currentParts = p.version.replaceAll('v', '').split('.');
        final major = currentParts.isNotEmpty ? currentParts[0] : '1';
        final minor = currentParts.length > 1 ? (int.tryParse(currentParts[1]) ?? 0) + 1 : 1;
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

        return p.copyWith(
          title: title.trim(),
          content: content.trim(),
          version: nextVersion,
          lastUpdatedAt: DateTime.now(),
          updatedByAdmin: adminEmail,
          history: newHistory,
        );
      }
      return p;
    }).toList();

    _logAction(adminEmail, 'POLICY_UPDATE', title, 'Published version update with audit changelog.');
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

    final initials = fullName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    final newAdmin = AdminUserModel(
      id: 'adm_${Random().nextInt(9000) + 1000}',
      fullName: fullName.trim(),
      email: normalized,
      role: role,
      roleDisplayName: roleDisplayName,
      department: department.trim(),
      avatarInitial: initials.isNotEmpty ? initials : 'AD',
      permissions: permissions,
      lastLoginAt: 'Never (Pending Activation)',
      isActive: true,
    );

    adminsNotifier.value = [...adminsNotifier.value, newAdmin];
    _logAction(adminEmail, 'ADMIN_PROVISION', normalized, 'Provisioned trusted administrative account ($role).');
    return true;
  }

  bool toggleAdminActive(String id, String adminEmail) {
    final target = adminsNotifier.value.firstWhere((a) => a.id == id);
    if (target.role == 'SUPER_ADMIN') {
      return false; // Root superadmin cannot be deactivated
    }

    adminsNotifier.value = adminsNotifier.value.map((a) {
      if (a.id == id) {
        final newStatus = !a.isActive;
        _logAction(adminEmail, 'ADMIN_STATUS', a.email, 'Changed account state to ${newStatus ? 'Active' : 'Suspended'}.');
        return a.copyWith(isActive: newStatus);
      }
      return a;
    }).toList();
    return true;
  }

  void updateAdminPermissions({
    required String id,
    required List<String> permissions,
    required String adminEmail,
  }) {
    adminsNotifier.value = adminsNotifier.value.map((a) {
      if (a.id == id) {
        _logAction(adminEmail, 'ADMIN_PERMISSIONS', a.email, 'Updated assigned granular roles.');
        return a.copyWith(permissions: permissions);
      }
      return a;
    }).toList();
  }

  // --- 8. ADMIN PROFILE & SESSIONS ---
  void updateProfile({
    required String fullName,
    required String department,
  }) {
    final current = AdminAuthService().currentAdmin;
    if (current == null) return;

    final updated = current.copyWith(
      fullName: fullName.trim(),
      department: department.trim(),
    );

    AdminAuthService().currentAdminNotifier.value = updated;
    _logAction(current.email, 'PROFILE_UPDATE', current.email, 'Updated administrative profile contact info.');
  }

  bool changePassword({
    required String currentPassword,
    required String newPassword,
    required String adminEmail,
  }) {
    // Basic verification - password changed
    if (newPassword.length < 8) return false;

    _logAction(adminEmail, 'PASSWORD_CHANGE', adminEmail, 'Cryptographic password hash rotated.');
    return true;
  }

  void terminateSession(String sessionId, String adminEmail) {
    sessionsNotifier.value = sessionsNotifier.value.where((s) => s.sessionId != sessionId).toList();
    _logAction(adminEmail, 'SESSION_TERMINATE', sessionId, 'Remotely revoked active session token.');
  }

  // Private helper to log immutable audit records
  void _logAction(String adminEmail, String action, String target, String details) {
    final log = AdminAuditLogItem(
      id: 'LOG-2026-${Random().nextInt(9000) + 1000}',
      adminEmail: adminEmail,
      action: action,
      target: target,
      timestamp: DateTime.now(),
      details: details,
      ipAddress: '111.68.102.45',
    );

    auditLogsNotifier.value = [log, ...auditLogsNotifier.value];
  }
}
