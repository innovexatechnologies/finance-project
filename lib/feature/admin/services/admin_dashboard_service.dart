import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/admin/models/admin_company_model.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';
import 'package:link_vibe/feature/admin/services/admin_analytics_service.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_certificate_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';

/// Enterprise Dashboard Service for CampusConnect Admin Console.
/// Aggregates 100% live metrics, cohort trends, and activity feeds from Supabase-backed services.
class AdminDashboardService {
  static final AdminDashboardService _instance =
      AdminDashboardService._internal();
  factory AdminDashboardService() => _instance;

  AdminDashboardService._internal() {
    _initListeners();
    _recompute();
  }

  final ValueNotifier<PlatformStatsModel> statsNotifier =
      ValueNotifier<PlatformStatsModel>(
    const PlatformStatsModel(
      totalStudents: 0,
      totalCompanies: 0,
      pendingVerifications: 0,
      totalProjects: 0,
      activeProjects: 0,
      completedProjects: 0,
      pendingReports: 0,
      studentGrowth: 0.0,
      companyGrowth: 0.0,
      projectGrowth: 0.0,
      completionRate: 0.0,
      categoryDistribution: {},
      trends: [],
    ),
  );

  final ValueNotifier<List<AdminActivityItem>> activitiesNotifier =
      ValueNotifier<List<AdminActivityItem>>([]);

  final ValueNotifier<String> selectedDateRangeNotifier =
      ValueNotifier<String>('All Time');
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  void _initListeners() {
    AdminCompanyService().companiesNotifier.addListener(_recompute);
    AdminVerificationService().verificationsNotifier.addListener(_recompute);
    AdminStudentService().studentsNotifier.addListener(_recompute);
    AdminProjectService().projectsNotifier.addListener(_recompute);
    AdminApplicationMonitoringService()
        .applicationsNotifier
        .addListener(_recompute);
    AdminCertificateService().certificatesNotifier.addListener(_recompute);
    AdminSettingsService().auditLogsNotifier.addListener(_recompute);
  }

  /// Loads every dataset for the entire Admin Console directly from Supabase.
  Future<void> loadAllAdminData({bool showLoading = true}) async {
    if (showLoading) {
      isLoadingNotifier.value = true;
    }
    try {
      await Future.wait([
        AdminCompanyService().loadFromSupabase(),
        AdminVerificationService().loadFromSupabase(),
        AdminStudentService().loadFromSupabase(),
        AdminProjectService().loadFromSupabase(),
        AdminApplicationMonitoringService().loadFromSupabase(),
        AdminCertificateService().loadFromSupabase(),
      ]);
      // Load settings after projects & students so taxonomy counts match
      await AdminSettingsService().loadFromSupabase();
      _recompute();
      AdminAnalyticsService().refreshAnalytics();
    } catch (e) {
      debugPrint('AdminDashboardService loadAllAdminData error: $e');
    } finally {
      if (isLoadingNotifier.value) {
        isLoadingNotifier.value = false;
      }
    }
  }

  void _recompute() {
    statsNotifier.value = _calculateStats(selectedDateRangeNotifier.value);
    activitiesNotifier.value = _buildLiveActivities();
  }

  DateTime? _cutoffForRange(String dateRange) {
    final now = DateTime.now();
    switch (dateRange) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'All Time':
      default:
        return null;
    }
  }

  double _computeGrowthPct(List<DateTime> dates) {
    if (dates.isEmpty) return 0.0;
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 30));
    final prevCutoff = now.subtract(const Duration(days: 60));

    final recent = dates.where((d) => !d.isBefore(recentCutoff)).length;
    final prior = dates
        .where((d) => d.isBefore(recentCutoff) && !d.isBefore(prevCutoff))
        .length;

    if (prior == 0) {
      return recent > 0 ? 100.0 : 0.0;
    }
    final pct = ((recent - prior) / prior) * 100.0;
    return double.parse(pct.toStringAsFixed(1));
  }

  PlatformStatsModel _calculateStats(String dateRange) {
    final allStudents = AdminStudentService().allStudents;
    final allCompanies = AdminCompanyService().allCompanies;
    final allVerifications = AdminVerificationService().allVerifications;
    final allProjects = AdminProjectService().allProjects;
    final allApps = AdminApplicationMonitoringService().allApplications;

    final cutoff = _cutoffForRange(dateRange);

    final filteredStudents = cutoff == null
        ? allStudents
        : allStudents
            .where((s) => !s.registrationDateTime.isBefore(cutoff))
            .toList();
    final filteredCompanies = cutoff == null
        ? allCompanies
        : allCompanies
            .where((c) => !c.registrationDateTime.isBefore(cutoff))
            .toList();
    final filteredProjects = cutoff == null
        ? allProjects
        : allProjects
            .where((p) => !p.createdDateTime.isBefore(cutoff))
            .toList();

    final activeProjectsList = filteredProjects
        .where((p) =>
            p.status == AdminProjectStatus.published ||
            p.status == AdminProjectStatus.active)
        .toList();
    final completedProjectsList = filteredProjects
        .where((p) => p.status == AdminProjectStatus.completed)
        .toList();

    final pendingCompanyVerifs = allVerifications
        .where((v) => v.status == VerificationStatus.pending)
        .length;
    final pendingStudentVerifs = allStudents
        .where((s) => s.verificationStatus == StudentVerificationStatus.pending)
        .length;

    final pendingReports = allApps
        .where((a) =>
            a.reportStatus == ApplicationReportStatus.reported ||
            a.reportStatus == ApplicationReportStatus.underInvestigation)
        .length;

    // Category distribution strictly from live projects
    final Map<String, int> categories = {};
    for (final p in filteredProjects) {
      final key = p.category.trim().isNotEmpty ? p.category.trim() : 'General';
      categories[key] = (categories[key] ?? 0) + 1;
    }

    final totalProjCount = filteredProjects.length;
    final completionRate = totalProjCount > 0
        ? double.parse(
            ((completedProjectsList.length / totalProjCount) * 100.0)
                .toStringAsFixed(1),
          )
        : 0.0;

    final trends = _buildTrendPoints(
      students: allStudents,
      companies: allCompanies,
      projects: allProjects,
    );

    return PlatformStatsModel(
      totalStudents: filteredStudents.length,
      totalCompanies: filteredCompanies.length,
      pendingVerifications: pendingCompanyVerifs + pendingStudentVerifs,
      totalProjects: totalProjCount,
      activeProjects: activeProjectsList.length,
      completedProjects: completedProjectsList.length,
      pendingReports: pendingReports,
      studentGrowth: _computeGrowthPct(
        allStudents.map((s) => s.registrationDateTime).toList(),
      ),
      companyGrowth: _computeGrowthPct(
        allCompanies.map((c) => c.registrationDateTime).toList(),
      ),
      projectGrowth: _computeGrowthPct(
        allProjects.map((p) => p.createdDateTime).toList(),
      ),
      completionRate: completionRate,
      categoryDistribution: categories,
      trends: trends,
    );
  }

  List<TrendDataPoint> _buildTrendPoints({
    required List<AdminStudentModel> students,
    required List<AdminCompanyModel> companies,
    required List<AdminProjectModel> projects,
  }) {
    if (students.isEmpty && companies.isEmpty && projects.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final List<TrendDataPoint> points = [];
    for (int offset = 5; offset >= 0; offset--) {
      final target = DateTime(now.year, now.month - offset, 1);
      final label = months[target.month - 1];

      final sCount = students
          .where((s) =>
              s.registrationDateTime.year == target.year &&
              s.registrationDateTime.month == target.month)
          .length;
      final cCount = companies
          .where((c) =>
              c.registrationDateTime.year == target.year &&
              c.registrationDateTime.month == target.month)
          .length;
      final pCreated = projects
          .where((p) =>
              p.createdDateTime.year == target.year &&
              p.createdDateTime.month == target.month)
          .length;
      final pCompleted = projects
          .where((p) =>
              p.status == AdminProjectStatus.completed &&
              p.createdDateTime.year == target.year &&
              p.createdDateTime.month == target.month)
          .length;

      points.add(
        TrendDataPoint(
          label: label,
          students: sCount,
          companies: cCount,
          projectsCreated: pCreated,
          projectsCompleted: pCompleted,
        ),
      );
    }
    return points;
  }

  List<AdminActivityItem> _buildLiveActivities() {
    final List<({DateTime time, AdminActivityItem item})> entries = [];

    for (final v in AdminVerificationService().allVerifications.take(4)) {
      final cMatch = AdminCompanyService()
          .allCompanies
          .where((c) => c.id == v.companyId)
          .toList();
      final dt =
          cMatch.isNotEmpty ? cMatch.first.registrationDateTime : DateTime.now();
      entries.add((
        time: dt,
        item: AdminActivityItem(
          id: 'verif_${v.companyId}',
          type: ActivityType.verificationSubmission,
          title: 'Company Verification',
          description: v.status == VerificationStatus.pending
              ? '${v.companyName} submitted verification documents for review.'
              : '${v.companyName} verification status: ${v.status.name}.',
          timeAgo: v.submittedAt,
          actorName: v.companyName,
          actorRole: 'Corporate Partner',
          badgeText: v.status == VerificationStatus.pending
              ? 'Pending Review'
              : v.status.name.toUpperCase(),
        ),
      ));
    }

    for (final p in AdminProjectService().allProjects.take(4)) {
      entries.add((
        time: p.createdDateTime,
        item: AdminActivityItem(
          id: 'proj_${p.id}',
          type: p.status == AdminProjectStatus.completed
              ? ActivityType.projectCompletion
              : ActivityType.newProject,
          title: p.status == AdminProjectStatus.completed
              ? 'Project Completed'
              : 'Project Listing',
          description: '${p.title} (${p.category}) — ${p.companyName}',
          timeAgo: p.createdAt,
          actorName: p.companyName,
          actorRole: 'Project Sponsor',
          badgeText: p.statusDisplay,
        ),
      ));
    }

    for (final s in AdminStudentService().allStudents.take(4)) {
      entries.add((
        time: s.registrationDateTime,
        item: AdminActivityItem(
          id: 'stud_${s.id}',
          type: ActivityType.studentRegistration,
          title: 'Student Registration',
          description:
              '${s.name}${s.university.isNotEmpty ? " (${s.university})" : ""} joined CampusConnect.',
          timeAgo: s.registrationDate,
          actorName: s.name,
          actorRole: 'Student',
          badgeText: s.verificationStatus == StudentVerificationStatus.verified
              ? 'Verified Student'
              : 'Pending Review',
        ),
      ));
    }

    for (final a in AdminApplicationMonitoringService()
        .allApplications
        .where((x) =>
            x.reportStatus == ApplicationReportStatus.reported ||
            x.reportStatus == ApplicationReportStatus.underInvestigation)
        .take(3)) {
      entries.add((
        time: a.submissionDateTime,
        item: AdminActivityItem(
          id: 'rep_${a.id}',
          type: ActivityType.reportSubmission,
          title: 'Flagged Application Case',
          description:
              '${a.studentName} applied to "${a.projectTitle}" — ${a.reportStatusDisplay}.',
          timeAgo: a.submissionDate,
          actorName: a.companyLiaison,
          actorRole: 'Compliance Alert',
          badgeText: a.reportStatusDisplay,
        ),
      ));
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries.take(8).map((e) => e.item).toList();
  }

  /// Change Date-Range filter across live platform records.
  Future<void> changeDateRange(String newRange) async {
    if (selectedDateRangeNotifier.value == newRange) return;
    selectedDateRangeNotifier.value = newRange;
    _recompute();
  }

  /// Quick Action 1: Approve first pending Company Verification directly from Admin Console.
  Future<bool> quickApproveCompanyVerification() async {
    final pending = AdminVerificationService()
        .allVerifications
        .where((v) => v.status == VerificationStatus.pending)
        .toList();
    if (pending.isEmpty) return false;

    final reviewer =
        AdminAuthService().currentAdmin?.fullName ?? 'Executive Administrator';
    final ok = await AdminVerificationService().approveCompany(
      verificationId: pending.first.id,
      reviewerName: reviewer,
    );
    _recompute();
    return ok;
  }

  /// Quick Action 2: Reject first pending Company Verification with feedback.
  Future<bool> quickRejectCompanyVerification(String feedback) async {
    final pending = AdminVerificationService()
        .allVerifications
        .where((v) => v.status == VerificationStatus.pending)
        .toList();
    if (pending.isEmpty) return false;

    final reviewer =
        AdminAuthService().currentAdmin?.fullName ?? 'Executive Administrator';
    final ok = await AdminVerificationService().rejectCompany(
      verificationId: pending.first.id,
      feedback: feedback,
      reviewerName: reviewer,
    );
    _recompute();
    return ok;
  }

  void reset() {
    selectedDateRangeNotifier.value = 'All Time';
    isLoadingNotifier.value = false;
    activitiesNotifier.value = [];
    statsNotifier.value = const PlatformStatsModel(
      totalStudents: 0,
      totalCompanies: 0,
      pendingVerifications: 0,
      totalProjects: 0,
      activeProjects: 0,
      completedProjects: 0,
      pendingReports: 0,
      studentGrowth: 0.0,
      companyGrowth: 0.0,
      projectGrowth: 0.0,
      completionRate: 0.0,
      categoryDistribution: {},
      trends: [],
    );
  }
}
