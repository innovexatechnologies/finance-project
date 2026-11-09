import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

/// Enterprise Project Management & Moderation Service for CampusConnect Admin Panel.
/// Provides project moderation, policy compliance auditing, cross-panel synchronization,
/// and authorized lifecycle retention controls.
class AdminProjectService {
  static final AdminProjectService _instance = AdminProjectService._internal();
  factory AdminProjectService() => _instance;

  AdminProjectService._internal() {
    _initProjects();
  }

  late final ValueNotifier<List<AdminProjectModel>> projectsNotifier;

  List<AdminProjectModel> get allProjects => projectsNotifier.value;

  // 1. Overview Metric Counts
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

  void _initProjects() {
    projectsNotifier = ValueNotifier<List<AdminProjectModel>>([
      // 1. Flutter E-Commerce Mobile App (Active / In Progress)
      AdminProjectModel(
        id: 'proj_01',
        title: 'Flutter E-Commerce Mobile App',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        category: 'Mobile App Development',
        description:
            'Design a modular UI/UX experience and integrate scalable catalog browsing and checkout pathways for university supply shops.',
        requirements:
            'Solid knowledge of Flutter state management (Bloc/Provider), REST API consumption, and clean architecture principles.',
        skillsRequired: ['Flutter', 'Dart', 'REST API', 'Figma'],
        deliverables:
            'Complete GitHub repository, production APK build, modular component documentation.',
        deadline: '2026-12-15',
        deadlineDateTime: DateTime(2026, 12, 15),
        projectType: 'Remote',
        duration: '4 weeks',
        openings: 2,
        additionalInstructions: 'Weekly sprint progress check-in on Zoom every Friday.',
        applicantsCount: 5,
        assignedStudent: 'Ali Khan (Fast-NUCES)',
        progress: 0.65,
        status: AdminProjectStatus.active,
        publicationStatus: AdminPublicationStatus.published,
        createdAt: '2026-11-01',
        createdDateTime: DateTime(2026, 11, 1, 10, 30),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_01_1',
            action: 'Project Approved & Published',
            moderatorName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-11-01 11:00 AM',
            reason: 'Academic scope and deliverables meet platform guidelines.',
          ),
        ],
      ),

      // 2. Barcode & QR Scanner Mobile Utility (Published / Open for Students)
      AdminProjectModel(
        id: 'proj_02',
        title: 'Barcode & QR Scanner Mobile Utility',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        category: 'Mobile App Development',
        description:
            'Develop a high-speed camera scanning utility with local scan history and export capabilities for library book tagging.',
        requirements:
            'Experience with camera plugins, local caching (SQLite/SharedPreferences), and clean UI widgets.',
        skillsRequired: ['Dart', 'Flutter', 'SQLite', 'Camera API'],
        deliverables:
            'Clean source code, unit test coverage, and runnable demo APK.',
        deadline: '2026-12-01',
        deadlineDateTime: DateTime(2026, 12, 1),
        projectType: 'Hybrid',
        duration: '2 weeks',
        openings: 1,
        additionalInstructions: 'Must follow Material 3 clean guidelines.',
        applicantsCount: 3,
        progress: 0.15,
        status: AdminProjectStatus.published,
        publicationStatus: AdminPublicationStatus.published,
        createdAt: '2026-11-03',
        createdDateTime: DateTime(2026, 11, 3, 14, 15),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_02_1',
            action: 'Auto-Moderated & Published',
            moderatorName: 'Automated Compliance Engine',
            timestamp: '2026-11-03 02:20 PM',
            reason: 'Verified corporate sponsor with good standing.',
          ),
        ],
      ),

      // 3. Automated Multi-Cloud Kubernetes Orchestrator (Pending Review)
      AdminProjectModel(
        id: 'proj_03',
        title: 'Automated Multi-Cloud Kubernetes Orchestrator',
        companyId: 'comp_02',
        companyName: 'Innovexa Cloud Technologies',
        category: 'Cloud Infrastructure & DevOps',
        description:
            'Create Helm charts and automated Terraform manifests for spinning up fault-tolerant Kubernetes testing clusters on demand.',
        requirements:
            'Familiarity with Kubernetes, Docker containerization, Helm 3, and basic Terraform configuration.',
        skillsRequired: ['Kubernetes', 'Docker', 'Terraform', 'Helm'],
        deliverables:
            'Terraform IaC scripts, production-tested Helm chart, architectural topology documentation.',
        deadline: '2026-12-28',
        deadlineDateTime: DateTime(2026, 12, 28),
        projectType: 'Remote',
        duration: '4 weeks',
        openings: 2,
        additionalInstructions: 'Cloud sandbox credits provided by Innovexa.',
        applicantsCount: 0,
        progress: 0.0,
        status: AdminProjectStatus.pendingReview,
        publicationStatus: AdminPublicationStatus.pendingModeration,
        createdAt: '2026-11-08',
        createdDateTime: DateTime(2026, 11, 8, 16, 45),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_03_1',
            action: 'Submitted for Administrative Review',
            moderatorName: 'System Gatekeeper',
            timestamp: '2026-11-08 04:45 PM',
            reason: 'New company listing queued for moderation review.',
          ),
        ],
      ),

      // 4. Corporate Sentiment Analysis Pipeline (Active / In Progress)
      AdminProjectModel(
        id: 'proj_04',
        title: 'Corporate Sentiment Analysis Pipeline',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        category: 'AI / Machine Learning & Data',
        description:
            'Build an automated NLP sentiment pipeline to classify student project feedback datasets for university research.',
        requirements:
            'Strong Python background, HuggingFace transformers, and FastAPI backend development.',
        skillsRequired: ['Python', 'NLP', 'FastAPI', 'Pandas'],
        deliverables:
            'Jupyter evaluation notebook, containerized FastAPI service, model metrics report.',
        deadline: '2026-12-30',
        deadlineDateTime: DateTime(2026, 12, 30),
        projectType: 'Remote',
        duration: '4 weeks',
        openings: 2,
        additionalInstructions: 'Datasets will be provided upon orientation.',
        applicantsCount: 4,
        assignedStudent: 'Ayesha Ahmed (NUST)',
        progress: 0.40,
        status: AdminProjectStatus.active,
        publicationStatus: AdminPublicationStatus.published,
        createdAt: '2026-10-28',
        createdDateTime: DateTime(2026, 10, 28, 09, 10),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_04_1',
            action: 'Reviewed & Published',
            moderatorName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-10-28 10:00 AM',
            reason: 'Approved for university data science research sprint.',
          ),
        ],
      ),

      // 5. Campus Ambassador Portal Dashboard (Completed)
      AdminProjectModel(
        id: 'proj_05',
        title: 'Campus Ambassador Portal Dashboard',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        category: 'Web Development',
        description:
            'Frontend dashboard for student community engagement and campus academic event management across 15 universities.',
        requirements: 'React 18, TypeScript, TailwindCSS, REST API.',
        skillsRequired: ['React', 'TypeScript', 'Tailwind', 'Git'],
        deliverables:
            'Production web deployment link, clean source code repository.',
        deadline: '2026-11-05',
        deadlineDateTime: DateTime(2026, 11, 5),
        projectType: 'Remote',
        duration: '3 weeks',
        openings: 3,
        additionalInstructions: 'Sprint completed with 100% test passing rate.',
        applicantsCount: 6,
        assignedStudent: 'Hamza Tariq (LUMS)',
        progress: 1.0,
        status: AdminProjectStatus.completed,
        publicationStatus: AdminPublicationStatus.published,
        createdAt: '2026-10-12',
        createdDateTime: DateTime(2026, 10, 12, 11, 20),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_05_1',
            action: 'Sprint Concluded & Milestone Audited',
            moderatorName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-11-05 06:00 PM',
            reason: 'Student submitted deliverables verified by corporate sponsor.',
          ),
        ],
      ),

      // 6. Smart IoT Campus Attendance Hardware Hook (Draft)
      AdminProjectModel(
        id: 'proj_06',
        title: 'Smart IoT Campus Attendance Hardware Hook',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        category: 'IoT & Embedded Systems',
        description:
            'Firmware interface between RFID attendance hardware and university server endpoints.',
        requirements: 'C++, ESP32, MQTT protocols.',
        skillsRequired: ['C++', 'IoT', 'MQTT', 'Embedded Systems'],
        deliverables: 'Arduino/ESP32 sketch, circuit wiring schematic.',
        deadline: '2026-12-20',
        deadlineDateTime: DateTime(2026, 12, 20),
        projectType: 'On-site',
        duration: '2 weeks',
        openings: 1,
        additionalInstructions: 'Lab access provided on campus.',
        applicantsCount: 0,
        progress: 0.0,
        status: AdminProjectStatus.draft,
        publicationStatus: AdminPublicationStatus.unpublished,
        createdAt: '2026-11-07',
        createdDateTime: DateTime(2026, 11, 7, 18, 00),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_06_1',
            action: 'Draft Saved by Company',
            moderatorName: 'TechVista Admin',
            timestamp: '2026-11-07 06:00 PM',
            reason: 'Under corporate preparation; not yet submitted for review.',
          ),
        ],
      ),

      // 7. Legacy Database Migration to Cloud SQL (Closed)
      AdminProjectModel(
        id: 'proj_07',
        title: 'Legacy Database Migration to Cloud SQL',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        category: 'Cloud Infrastructure & DevOps',
        description:
            'Migration scripts to transfer legacy MySQL student registration tables to PostgreSQL with zero data loss.',
        requirements: 'PostgreSQL, Docker, Database indexing.',
        skillsRequired: ['SQL', 'PostgreSQL', 'Docker', 'Python'],
        deliverables: 'Migration script suite, validation sanity check report.',
        deadline: '2026-10-30',
        deadlineDateTime: DateTime(2026, 10, 30),
        projectType: 'Remote',
        duration: '3 weeks',
        openings: 1,
        additionalInstructions: 'Project concluded after initial sprint.',
        applicantsCount: 4,
        progress: 0.90,
        status: AdminProjectStatus.closed,
        publicationStatus: AdminPublicationStatus.unpublished,
        createdAt: '2026-10-05',
        createdDateTime: DateTime(2026, 10, 5, 12, 00),
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_07_1',
            action: 'Project Concluded & Closed',
            moderatorName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-31 11:30 AM',
            reason: 'Application window expired; all sprint objectives concluded.',
          ),
        ],
      ),

      // 8. Crypto Payment Gateway Bridge Prototype (Removed / Policy Violation)
      AdminProjectModel(
        id: 'proj_08',
        title: 'Crypto Payment Gateway Bridge Prototype',
        companyId: 'comp_05',
        companyName: 'Apex Distributed Technologies',
        category: 'Blockchain & Distributed Systems',
        description:
            'Proof-of-concept multi-chain signature verification utility for cryptocurrency and token wallet integrations.',
        requirements: 'Solidity, Web3.js, Smart contract auditing.',
        skillsRequired: ['Solidity', 'Web3', 'TypeScript'],
        deliverables: 'Smart contract test suite on testnet.',
        deadline: '2026-11-01',
        deadlineDateTime: DateTime(2026, 11, 1),
        projectType: 'Remote',
        duration: '2 weeks',
        openings: 1,
        additionalInstructions: 'De-listed due to policy violations.',
        applicantsCount: 2,
        progress: 0.10,
        status: AdminProjectStatus.removed,
        publicationStatus: AdminPublicationStatus.removed,
        createdAt: '2026-10-18',
        createdDateTime: DateTime(2026, 10, 18, 15, 20),
        moderationReason:
            'Platform Policy Violation: CampusConnect strictly excludes financial token and cryptocurrency payment instruments from academic listings.',
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_08_1',
            action: 'De-listed & Removed for Policy Non-Compliance',
            moderatorName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-20 03:15 PM',
            reason:
                'Platform Policy Violation: CampusConnect strictly excludes financial token and cryptocurrency payment instruments from academic listings.',
          ),
        ],
      ),

      // 9. High-Frequency Commercial Arbitrage Bot (Rejected)
      AdminProjectModel(
        id: 'proj_09',
        title: 'High-Frequency Commercial Arbitrage Bot',
        companyId: 'comp_03',
        companyName: 'CodeCraft Mobile Systems',
        category: 'AI / Machine Learning & Data',
        description:
            'Develop an automated trading algorithm to exploit microsecond price discrepancies across exchange orderbooks.',
        requirements: 'Python, C++, Quantitative Finance, Orderbook APIs.',
        skillsRequired: ['Python', 'C++', 'Algorithmic Trading', 'WebSockets'],
        deliverables: 'Order execution bot with simulated backtest results.',
        deadline: '2026-11-20',
        deadlineDateTime: DateTime(2026, 11, 20),
        projectType: 'Remote',
        duration: '3 weeks',
        openings: 1,
        additionalInstructions: 'Commercial financial speculation project.',
        applicantsCount: 1,
        progress: 0.0,
        status: AdminProjectStatus.rejected,
        publicationStatus: AdminPublicationStatus.rejected,
        createdAt: '2026-10-25',
        createdDateTime: DateTime(2026, 10, 25, 17, 30),
        moderationReason:
            'Rejected: Commercial financial speculation projects are barred under CampusConnect non-financial terms.',
        moderationHistory: const [
          ProjectModerationRecord(
            id: 'mod_09_1',
            action: 'Listing Rejected',
            moderatorName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-10-26 10:15 AM',
            reason:
                'Rejected: Commercial financial speculation projects are barred under CampusConnect non-financial terms.',
          ),
        ],
      ),
    ]);
  }

  // 5. Moderation Action: Publish / Approve Project
  Future<bool> publishProject({
    required String projectId,
    required String moderatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Published & Open for Applications',
        moderatorName: moderatorName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: 'Project review completed and verified by governance officer.',
      ),
    );

    list[idx] = project.copyWith(
      status: AdminProjectStatus.published,
      publicationStatus: AdminPublicationStatus.published,
      moderationReason: null,
      moderationHistory: history,
    );
    projectsNotifier.value = list;

    // Cross-panel synchronization with CompanyProjectService
    _syncToCompanyProjectService(projectId, 'Open');
    return true;
  }

  // 5. Moderation Action: Unpublish Project
  Future<bool> unpublishProject({
    required String projectId,
    required String reason,
    required String moderatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Listing Unpublished',
        moderatorName: moderatorName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: reason,
      ),
    );

    list[idx] = project.copyWith(
      status: AdminProjectStatus.closed,
      publicationStatus: AdminPublicationStatus.unpublished,
      moderationReason: reason,
      moderationHistory: history,
    );
    projectsNotifier.value = list;

    // Cross-panel synchronization with CompanyProjectService
    _syncToCompanyProjectService(projectId, 'Closed');
    return true;
  }

  // 5. Moderation Action: Close Project
  Future<bool> closeProject({
    required String projectId,
    required String moderatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Project Concluded & Closed',
        moderatorName: moderatorName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: 'Project closed by administrative governance.',
      ),
    );

    list[idx] = project.copyWith(
      status: AdminProjectStatus.closed,
      publicationStatus: AdminPublicationStatus.unpublished,
      moderationHistory: history,
    );
    projectsNotifier.value = list;

    // Cross-panel synchronization with CompanyProjectService
    _syncToCompanyProjectService(projectId, 'Closed');
    return true;
  }

  // 5. Moderation Action: Remove Policy-Violating Listing (Soft Removal Retention)
  Future<bool> removePolicyViolatingProject({
    required String projectId,
    required String reason,
    required String moderatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Removed for Policy Violation',
        moderatorName: moderatorName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: reason,
      ),
    );

    list[idx] = project.copyWith(
      status: AdminProjectStatus.removed,
      publicationStatus: AdminPublicationStatus.removed,
      moderationReason: reason,
      moderationHistory: history,
      isArchived: true, // Archived for legal retention
    );
    projectsNotifier.value = list;

    // Cross-panel synchronization with CompanyProjectService
    _syncToCompanyProjectService(projectId, 'Cancelled');
    return true;
  }

  // 5. Moderation Action: Reject Project with Mandatory Reason
  Future<bool> rejectProject({
    required String projectId,
    required String reason,
    required String moderatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Listing Rejected',
        moderatorName: moderatorName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: reason,
      ),
    );

    list[idx] = project.copyWith(
      status: AdminProjectStatus.rejected,
      publicationStatus: AdminPublicationStatus.rejected,
      moderationReason: reason,
      moderationHistory: history,
    );
    projectsNotifier.value = list;

    // Cross-panel synchronization with CompanyProjectService
    _syncToCompanyProjectService(projectId, 'Cancelled');
    return true;
  }

  // 5. Moderation Action: Restore Removed Project
  Future<bool> restoreRemovedProject({
    required String projectId,
    required String moderatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    final idx = list.indexWhere((p) => p.id == projectId);
    if (idx == -1) return false;

    final project = list[idx];
    final history = List<ProjectModerationRecord>.from(project.moderationHistory);
    history.insert(
      0,
      ProjectModerationRecord(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Listing Restored from Policy Removal',
        moderatorName: moderatorName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: 'Restored after compliance audit clarification.',
      ),
    );

    list[idx] = project.copyWith(
      status: AdminProjectStatus.published,
      publicationStatus: AdminPublicationStatus.published,
      moderationReason: null,
      moderationHistory: history,
      isArchived: false,
    );
    projectsNotifier.value = list;

    // Cross-panel synchronization with CompanyProjectService
    _syncToCompanyProjectService(projectId, 'Open');
    return true;
  }

  // 7. Bulk Moderation
  Future<void> bulkModerateProjects({
    required List<String> projectIds,
    required AdminProjectStatus newStatus,
    required String moderatorName,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final list = List<AdminProjectModel>.from(projectsNotifier.value);
    for (int i = 0; i < list.length; i++) {
      if (projectIds.contains(list[i].id)) {
        final history = List<ProjectModerationRecord>.from(list[i].moderationHistory);
        history.insert(
          0,
          ProjectModerationRecord(
            id: 'mod_bulk_${DateTime.now().millisecondsSinceEpoch}_$i',
            action: 'Bulk Status Updated to ${newStatus.name}',
            moderatorName: moderatorName,
            timestamp: 'Today',
            reason: reason ?? 'Batch moderation executed across ${projectIds.length} projects.',
          ),
        );

        final pubStatus = newStatus == AdminProjectStatus.published
            ? AdminPublicationStatus.published
            : newStatus == AdminProjectStatus.closed
                ? AdminPublicationStatus.unpublished
                : newStatus == AdminProjectStatus.removed
                    ? AdminPublicationStatus.removed
                    : AdminPublicationStatus.rejected;

        list[i] = list[i].copyWith(
          status: newStatus,
          publicationStatus: pubStatus,
          moderationReason: reason,
          moderationHistory: history,
        );

        final companyStatus = newStatus == AdminProjectStatus.published
            ? 'Open'
            : newStatus == AdminProjectStatus.closed
                ? 'Closed'
                : 'Cancelled';
        _syncToCompanyProjectService(list[i].id, companyStatus);
      }
    }
    projectsNotifier.value = list;
  }

  // Cross-Panel Synchronization Helper
  void _syncToCompanyProjectService(String projectId, String newCompanyStatus) {
    try {
      final compService = CompanyProjectService();
      final currentList = List<ProjectModel>.from(compService.projectsNotifier.value);
      final idx = currentList.indexWhere((p) => p.id == projectId);
      if (idx != -1) {
        currentList[idx] = currentList[idx].copyWith(status: newCompanyStatus);
        compService.projectsNotifier.value = currentList;
      }
    } catch (_) {
      // Graceful fallback if service not initialized in testing
    }
  }

  // 7. Export Projects to CSV (Strictly Non-Financial)
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
}

