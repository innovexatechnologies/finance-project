import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Enterprise Dashboard Service for CampusConnect Admin Console.
/// Aggregates real-time data across student, company, and project domains.
class AdminDashboardService {
  static final AdminDashboardService _instance = AdminDashboardService._internal();
  factory AdminDashboardService() => _instance;

  AdminDashboardService._internal() {
    _initListeners();
    _refreshStats();
  }

  late final ValueNotifier<PlatformStatsModel> statsNotifier;
  late final ValueNotifier<List<AdminActivityItem>> activitiesNotifier;
  late final ValueNotifier<String> selectedDateRangeNotifier;
  late final ValueNotifier<bool> isLoadingNotifier;

  void _initListeners() {
    selectedDateRangeNotifier = ValueNotifier<String>('Last 30 Days');
    isLoadingNotifier = ValueNotifier<bool>(false);

    // Initial seed stats
    statsNotifier = ValueNotifier<PlatformStatsModel>(_calculateStats('Last 30 Days'));
    activitiesNotifier = ValueNotifier<List<AdminActivityItem>>(_getInitialActivities());

    // Listen to company project changes
    CompanyProjectService().projectsNotifier.addListener(() {
      statsNotifier.value = _calculateStats(selectedDateRangeNotifier.value);
    });

    // Listen to verification changes
    CompanyVerificationService().verificationNotifier.addListener(() {
      statsNotifier.value = _calculateStats(selectedDateRangeNotifier.value);
    });

    // Listen to applicant changes
    CompanyApplicantService().applicantsNotifier.addListener(() {
      statsNotifier.value = _calculateStats(selectedDateRangeNotifier.value);
    });
  }

  PlatformStatsModel _calculateStats(String dateRange) {
    final projectService = CompanyProjectService();
    final verificationService = CompanyVerificationService();
    final applicantService = CompanyApplicantService();
    final assignmentService = CompanyAssignmentService();

    final allProjects = projectService.projects;
    final activeProjectsList = allProjects
        .where((p) => p.status == 'Open' || p.status == 'In Progress')
        .toList();
    final completedProjectsList =
        allProjects.where((p) => p.status == 'Completed').toList();

    // Check verification status from CompanyVerificationService
    int pendingVerifCount = 0;
    if (verificationService.currentVerification.status == VerificationStatus.pending) {
      pendingVerifCount += 1;
    }
    // Also include student pending verifications
    pendingVerifCount += 2; // e.g. UET & PUCIT student degree verifications

    // Category distribution from real projects
    final Map<String, int> categories = {};
    for (final p in allProjects) {
      categories[p.category] = (categories[p.category] ?? 0) + 1;
    }

    // Dynamic multipliers based on selected date filter
    double scale = 1.0;
    if (dateRange == 'Today') scale = 0.2;
    if (dateRange == 'Last 7 Days') scale = 0.55;
    if (dateRange == 'Last 30 Days') scale = 1.0;
    if (dateRange == 'All Time') scale = 1.4;

    return PlatformStatsModel(
      totalStudents: (applicantService.allApplicants.length * 15 * scale).round() + 120,
      totalCompanies: 48,
      pendingVerifications: pendingVerifCount,
      totalProjects: allProjects.length,
      activeProjects: activeProjectsList.length,
      completedProjects: completedProjectsList.length,
      pendingReports: (assignmentService.allAssignments.where((a) => a.hasSubmission).length),
      categoryDistribution: categories,
      trends: const [
        TrendDataPoint(label: 'Jul', students: 85, companies: 6, projectsCreated: 4, projectsCompleted: 2),
        TrendDataPoint(label: 'Aug', students: 120, companies: 10, projectsCreated: 7, projectsCompleted: 5),
        TrendDataPoint(label: 'Sep', students: 160, companies: 14, projectsCreated: 9, projectsCompleted: 6),
        TrendDataPoint(label: 'Oct', students: 210, companies: 18, projectsCreated: 12, projectsCompleted: 9),
        TrendDataPoint(label: 'Nov', students: 285, companies: 24, projectsCreated: 15, projectsCompleted: 11),
      ],
    );
  }

  List<AdminActivityItem> _getInitialActivities() {
    return [
      const AdminActivityItem(
        id: 'act_01',
        type: ActivityType.verificationSubmission,
        title: 'Company Verification Request',
        description: 'TechVista Innovations uploaded SECP / NTN Registration documentation for authorization.',
        timeAgo: '12 mins ago',
        actorName: 'TechVista Innovations',
        actorRole: 'Corporate Partner',
        badgeText: 'Pending Review',
      ),
      const AdminActivityItem(
        id: 'act_02',
        type: ActivityType.newProject,
        title: 'New Project Published',
        description: 'Mobile App Development sprint "Flutter E-Commerce Mobile App" published to campus feed.',
        timeAgo: '45 mins ago',
        actorName: 'Danish Ali Rajpoot',
        actorRole: 'Project Manager',
        badgeText: 'Active Sprint',
      ),
      const AdminActivityItem(
        id: 'act_03',
        type: ActivityType.studentRegistration,
        title: 'New Student Profile Verified',
        description: 'Ali Khan from FAST-NUCES Islamabad completed university degree verification.',
        timeAgo: '2 hours ago',
        actorName: 'FAST-NUCES Academic Registrar',
        actorRole: 'University Liaison',
        badgeText: 'Verified Student',
      ),
      const AdminActivityItem(
        id: 'act_04',
        type: ActivityType.projectCompletion,
        title: 'Milestone Deliverable Approved',
        description: 'Ali Khan completed Milestone 2 code deliverables with 94% test coverage.',
        timeAgo: '3 hours ago',
        actorName: 'Corporate Tech Lead',
        actorRole: 'Mentor',
        badgeText: 'Deliverable Approved',
      ),
      const AdminActivityItem(
        id: 'act_05',
        type: ActivityType.reportSubmission,
        title: 'Quarterly University Accreditation Report',
        description: 'NUST Quality Enhancement Cell submitted compliance milestone documentation.',
        timeAgo: '5 hours ago',
        actorName: 'NUST QEC Directorate',
        actorRole: 'University Authority',
        badgeText: 'Compliance Logged',
      ),
      const AdminActivityItem(
        id: 'act_06',
        type: ActivityType.companyRegistration,
        title: 'New Corporate Account Onboarded',
        description: 'Innovexa Cloud Technologies initialized corporate identity setup on CampusConnect.',
        timeAgo: 'Yesterday',
        actorName: 'Innovexa HR Portal',
        actorRole: 'Corporate Partner',
        badgeText: 'Registered',
      ),
    ];
  }

  /// Change Date-Range filter with loading state simulation
  Future<void> changeDateRange(String newRange) async {
    if (selectedDateRangeNotifier.value == newRange) return;

    isLoadingNotifier.value = true;
    selectedDateRangeNotifier.value = newRange;

    // Simulate backend aggregation query latency
    await Future.delayed(const Duration(milliseconds: 400));
    statsNotifier.value = _calculateStats(newRange);
    isLoadingNotifier.value = false;
  }

  void _refreshStats() {
    statsNotifier.value = _calculateStats(selectedDateRangeNotifier.value);
  }

  /// Quick Action 1: Approve Company Verification directly from Admin Console
  Future<bool> quickApproveCompanyVerification() async {
    await Future.delayed(const Duration(milliseconds: 300));
    CompanyVerificationService().simulateAdminApproval();
    _refreshStats();
    return true;
  }

  /// Quick Action 2: Reject Company Verification with feedback
  Future<bool> quickRejectCompanyVerification(String feedback) async {
    await Future.delayed(const Duration(milliseconds: 300));
    CompanyVerificationService().simulateAdminRejection(feedback);
    _refreshStats();
    return true;
  }
}
