import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_analytics_model.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_bar_chart.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_donut_chart.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_line_chart.dart';
import 'package:link_vibe/feature/admin/services/admin_analytics_service.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_certificate_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_dashboard_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';

/// Enterprise Reports & Business Intelligence Analytics Hub.
/// Computes all KPIs, trends, category distributions, skills matrix,
/// verification metrics, and printable reports strictly from live Supabase state.
class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AnalyticsTimeframe _selectedTimeframe = AnalyticsTimeframe.last30Days;
  String _selectedCategory = 'All Categories';
  bool _isSidebarCollapsed = false;
  bool _isRefreshing = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _buildCategoryOptions() {
    final set = <String>{'All Categories'};
    for (final c in AdminSettingsService().categoriesNotifier.value) {
      if (c.name.trim().isNotEmpty) set.add(c.name.trim());
    }
    for (final p in AdminProjectService().allProjects) {
      if (p.category.trim().isNotEmpty) set.add(p.category.trim());
    }
    return set.toList();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _analyticsService.reloadAllAndRefresh();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Platform analytics refreshed from live database.'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onRouteSelected(String routeId) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (routeId == 'analytics' || routeId == 'reports') {
      return;
    }
    if (routeId == 'dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (routeId == 'student_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
      );
    } else if (routeId == 'company_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyVerificationsScreen()),
      );
    } else if (routeId == 'company_management') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
      );
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
      );
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ApplicationMonitoringScreen(),
        ),
      );
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CertificateManagementScreen(),
        ),
      );
    } else if (routeId == 'settings') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                activeRouteId: 'analytics',
                onRouteSelected: _onRouteSelected,
                onSignOut: _handleSignOut,
                isCollapsed: false,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AdminSidebar(
              activeRouteId: 'analytics',
              onRouteSelected: _onRouteSelected,
              onSignOut: _handleSignOut,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
              },
            ),
          Expanded(
            child: Column(
              children: [
                AdminTopNavbar(
                  pageTitle: 'Reports & Business Intelligence',
                  breadcrumb: 'Analytics Hub',
                  onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                  onSignOut: _handleSignOut,
                ),
                Expanded(
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: _analyticsService.lastRefreshedNotifier,
                    builder: (context, _, _) {
                      final categories = _buildCategoryOptions();
                      final effectiveCategory = categories.contains(_selectedCategory)
                          ? _selectedCategory
                          : 'All Categories';

                      final verificationSummary =
                          _analyticsService.getVerificationAnalytics();
                      final engagementSummary =
                          _analyticsService.getUserEngagement();
                      final regTrends = _analyticsService.getRegistrationTrends(
                        _selectedTimeframe,
                        effectiveCategory,
                      );
                      final projTrends = _analyticsService.getProjectTrends(
                        _selectedTimeframe,
                        effectiveCategory,
                      );
                      final categoryDist = _analyticsService
                          .getCategoryDistribution(effectiveCategory);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildControlHeader(categories, effectiveCategory),
                            const SizedBox(height: 20),
                            _buildKpiCards(
                              verificationSummary,
                              engagementSummary,
                              regTrends,
                            ),
                            const SizedBox(height: 24),
                            _buildTabBar(),
                            const SizedBox(height: 20),
                            _buildTabViews(
                              categoryFilter: effectiveCategory,
                              regTrends: regTrends,
                              projTrends: projTrends,
                              categoryDist: categoryDist,
                              verificationSummary: verificationSummary,
                              engagementSummary: engagementSummary,
                            ),
                            const SizedBox(height: 36),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlHeader(
    List<String> categories,
    String effectiveCategory,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 860;

          final filters = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnalyticsTimeframe>(
                    value: _selectedTimeframe,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimeframe = val);
                    },
                    items: AnalyticsTimeframe.values.map((tf) {
                      return DropdownMenuItem(
                        value: tf,
                        child: Text(tf.label),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: effectiveCategory,
                    isExpanded: false,
                    icon: const Icon(
                      Icons.filter_list,
                      size: 16,
                      color: AppColors.accentTeal,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.length > 26 ? '${c.substring(0, 23)}...' : c,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                onPressed: _isRefreshing ? null : _handleRefresh,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                tooltip: 'Refresh Live Metrics',
              ),
            ],
          );

          final actions = Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _showExportCsvModal,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _handleGenerateReport(effectiveCategory),
                icon: const Icon(Icons.assessment_outlined, size: 16),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                filters,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: filters),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCards(
    VerificationAnalyticsSummary verification,
    UserEngagementSummary engagement,
    List<RegistrationTrendPoint> regTrends,
  ) {
    final studentService = AdminStudentService();
    final companyService = AdminCompanyService();
    final projectService = AdminProjectService();
    final appMonitoringService = AdminApplicationMonitoringService();

    final latestReg = regTrends.isNotEmpty ? regTrends.last : null;
    final studentTotal = studentService.totalCount;
    final companyTotal = companyService.totalCount;
    final projects = projectService.allProjects;
    final activeSprints =
        projects.where((p) => p.status == AdminProjectStatus.active).length;
    final completedSprints =
        projects.where((p) => p.status == AdminProjectStatus.completed).length;
    final completionVelocity = projects.isEmpty
        ? 0.0
        : double.parse(
            ((completedSprints / projects.length) * 100.0).toStringAsFixed(1),
          );

    final representedUnis = studentService.allStudents
        .map((s) => s.university.trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .length;
    final growthDelta = latestReg != null
        ? '${latestReg.growthRatePercentage >= 0 ? "+" : ""}${latestReg.growthRatePercentage.toStringAsFixed(1)}%'
        : '0.0%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 1200
            ? 6
            : width >= 800
                ? 3
                : width >= 460
                    ? 2
                    : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.45,
          children: [
            _buildKpiCard(
              title: 'Total Students',
              value: '$studentTotal',
              delta: growthDelta,
              isPositiveDelta: true,
              subtitle: '$representedUnis Institutions Represented',
              icon: Icons.school_rounded,
              accentColor: AppColors.primary,
            ),
            _buildKpiCard(
              title: 'Partner Companies',
              value: '$companyTotal',
              delta: '${companyService.verifiedCount} Verified',
              isPositiveDelta: true,
              subtitle: '${companyService.pendingCount} Pending Verification',
              icon: Icons.business_rounded,
              accentColor: AppColors.accentTeal,
            ),
            _buildKpiCard(
              title: 'Active Sprints',
              value: '$activeSprints',
              delta: '${completionVelocity.toStringAsFixed(1)}% Done',
              isPositiveDelta: true,
              subtitle: '${projects.length} Total Projects',
              icon: Icons.rocket_launch_rounded,
              accentColor: const Color(0xFF6366F1),
            ),
            _buildKpiCard(
              title: 'Verification Rate',
              value: '${verification.approvalRatePercentage}%',
              delta: '${verification.pendingCount} Pending',
              isPositiveDelta: verification.pendingCount == 0,
              subtitle: '${verification.approvedCount} Approved Accounts',
              icon: Icons.verified_user_rounded,
              accentColor: AppColors.success,
            ),
            _buildKpiCard(
              title: 'Applications Log',
              value: '${engagement.totalApplications}',
              delta: '${engagement.averageApplicationsPerProject} Avg/Proj',
              isPositiveDelta: true,
              subtitle: '${engagement.acceptedApplications} Placed Students',
              icon: Icons.send_rounded,
              accentColor: const Color(0xFFF59E0B),
            ),
            _buildKpiCard(
              title: 'Verification Coverage',
              value: '${engagement.engagementIndex.toStringAsFixed(1)}%',
              delta: '${appMonitoringService.reportedCount} Flagged',
              isPositiveDelta: appMonitoringService.reportedCount == 0,
              subtitle:
                  '${appMonitoringService.requiringInvestigationCount} Under Review',
              icon: Icons.favorite_rounded,
              accentColor: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String delta,
    required bool isPositiveDelta,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositiveDelta ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    delta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositiveDelta
                          ? AppColors.success
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Executive Overview'),
          Tab(icon: Icon(Icons.how_to_reg_outlined, size: 16), text: 'Registration & Verifications'),
          Tab(icon: Icon(Icons.task_alt_outlined, size: 16), text: 'Projects & Completion'),
          Tab(icon: Icon(Icons.category_outlined, size: 16), text: 'Categories & Skills Demand'),
          Tab(icon: Icon(Icons.group_work_outlined, size: 16), text: 'Engagement & Funnel'),
          Tab(icon: Icon(Icons.table_chart_outlined, size: 16), text: 'Detailed Data Ledger'),
        ],
      ),
    );
  }

  Widget _buildTabViews({
    required String categoryFilter,
    required List<RegistrationTrendPoint> regTrends,
    required List<ProjectTrendPoint> projTrends,
    required List<CategoryDistributionItem> categoryDist,
    required VerificationAnalyticsSummary verificationSummary,
    required UserEngagementSummary engagementSummary,
  }) {
    return SizedBox(
      height: 660,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildExecutiveOverviewTab(regTrends, categoryDist),
          _buildRegistrationAndVerificationTab(regTrends, verificationSummary),
          _buildProjectsAndCompletionTab(projTrends, categoryFilter),
          _buildCategoriesAndSkillsTab(categoryDist),
          _buildEngagementAndFunnelTab(engagementSummary),
          _buildDetailedDataLedgerTab(),
        ],
      ),
    );
  }

  Widget _buildExecutiveOverviewTab(
    List<RegistrationTrendPoint> regTrends,
    List<CategoryDistributionItem> categoryDist,
  ) {
    final tableRows = _analyticsService.getDetailedTableRows(_selectedTimeframe);
    final appsByPeriod = {
      for (final row in tableRows) row.periodLabel: row.applicationsSubmitted,
    };

    final linePoints = regTrends.map((r) {
      return BiLineDataPoint(
        label: r.label,
        value1: r.studentRegistrations.toDouble(),
        value2: r.companyRegistrations.toDouble(),
        value3: (appsByPeriod[r.label] ?? 0).toDouble(),
      );
    }).toList();

    final donutSegments = categoryDist.map((c) {
      return BiDonutSegment(
        label: c.categoryName,
        value: c.projectCount.toDouble(),
        color: c.color,
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final lineCard = _buildCardContainer(
          title: 'Cohort Registration & Application Trends',
          subtitle: 'Live periodic comparison between student signups, companies, and applications.',
          child: BiLineChart(
            points: linePoints,
            metric1Label: 'Students',
            metric1Color: AppColors.primary,
            metric2Label: 'Companies',
            metric2Color: AppColors.accentTeal,
            metric3Label: 'Applications',
            metric3Color: const Color(0xFFF59E0B),
            height: 250,
          ),
        );

        final donutCard = _buildCardContainer(
          title: 'Project Category Distribution',
          subtitle: 'Share of academic sprints hosted across engineering disciplines.',
          child: BiDonutChart(
            segments: donutSegments,
            centerTitle: '${categoryDist.fold(0, (sum, c) => sum + c.projectCount)}',
            centerSubtitle: 'Total Sprints',
            chartRadius: 80,
            strokeWidth: 22,
          ),
        );

        if (isWidescreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: lineCard),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: donutCard),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              lineCard,
              const SizedBox(height: 20),
              donutCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegistrationAndVerificationTab(
    List<RegistrationTrendPoint> regTrends,
    VerificationAnalyticsSummary verification,
  ) {
    final barGroups = regTrends.map((r) {
      return BiBarDataGroup(
        label: r.label,
        value1: r.studentRegistrations.toDouble(),
        value2: r.companyRegistrations.toDouble(),
      );
    }).toList();

    final verificationSegments = [
      BiDonutSegment(
        label: 'Approved Credentials',
        value: verification.approvedCount.toDouble(),
        color: AppColors.success,
      ),
      BiDonutSegment(
        label: 'Pending In-Review',
        value: verification.pendingCount.toDouble(),
        color: AppColors.warning,
      ),
      BiDonutSegment(
        label: 'Rejected Submissions',
        value: verification.rejectedCount.toDouble(),
        color: AppColors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final barCard = _buildCardContainer(
          title: 'New Registrations (Students vs Companies)',
          subtitle: 'Periodic registration volume across authenticated student and corporate users.',
          child: BiBarChart(
            dataGroups: barGroups,
            series1Label: 'Students',
            series1Color: AppColors.primary,
            series2Label: 'Companies',
            series2Color: AppColors.accentTeal,
            height: 250,
          ),
        );

        final verifCard = _buildCardContainer(
          title: 'Verification Breakdown & Audit',
          subtitle: 'Institutional student & corporate accounts across verification stages.',
          child: Column(
            children: [
              BiDonutChart(
                segments: verificationSegments,
                centerTitle: '${verification.approvalRatePercentage}%',
                centerSubtitle: 'Approval Rate',
                chartRadius: 75,
                strokeWidth: 20,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('Pending Queue', '${verification.pendingCount}'),
                    _buildMiniMetric('Student Total', '${verification.studentVerificationsTotal}'),
                    _buildMiniMetric('Corporate Total', '${verification.companyVerificationsTotal}'),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isWidescreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: barCard),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: verifCard),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              barCard,
              const SizedBox(height: 20),
              verifCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectsAndCompletionTab(
    List<ProjectTrendPoint> projTrends,
    String categoryFilter,
  ) {
    final allProjects = AdminProjectService().allProjects;
    final filteredProjects = categoryFilter == 'All Categories'
        ? allProjects
        : allProjects
            .where((p) => p.category.toLowerCase() == categoryFilter.toLowerCase())
            .toList();

    final activeCount =
        filteredProjects.where((p) => p.status == AdminProjectStatus.active).length;
    final completedCount =
        filteredProjects.where((p) => p.status == AdminProjectStatus.completed).length;
    final publishedCount =
        filteredProjects.where((p) => p.status == AdminProjectStatus.published).length;
    final closedOrOtherCount = filteredProjects
        .where((p) =>
            p.status == AdminProjectStatus.closed ||
            p.status == AdminProjectStatus.draft ||
            p.status == AdminProjectStatus.pendingReview ||
            p.status == AdminProjectStatus.rejected ||
            p.status == AdminProjectStatus.removed)
        .length;

    final completionRateStr = filteredProjects.isEmpty
        ? '0.0%'
        : '${((completedCount / filteredProjects.length) * 100.0).toStringAsFixed(1)}%';
    final issuedCerts = AdminCertificateService().issuedCount;
    final totalApps = AdminApplicationMonitoringService().totalCount;

    final barGroups = projTrends.map((p) {
      return BiBarDataGroup(
        label: p.label,
        value1: p.projectsPublished.toDouble(),
        value2: p.projectsCompleted.toDouble(),
      );
    }).toList();

    final statusSegments = [
      BiDonutSegment(
        label: 'Active Ongoing',
        value: activeCount.toDouble(),
        color: const Color(0xFF6366F1),
      ),
      BiDonutSegment(
        label: 'Completed & Certified',
        value: completedCount.toDouble(),
        color: AppColors.success,
      ),
      BiDonutSegment(
        label: 'Published (Recruiting)',
        value: publishedCount.toDouble(),
        color: AppColors.accentTeal,
      ),
      BiDonutSegment(
        label: 'Closed / Pending / Draft',
        value: closedOrOtherCount.toDouble(),
        color: AppColors.textMuted,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final barCard = _buildCardContainer(
          title: 'Project Lifecycle Velocity (Published vs Completed)',
          subtitle: 'Comparison between open listings and completed project deliverables.',
          child: BiBarChart(
            dataGroups: barGroups,
            series1Label: 'Published Sprints',
            series1Color: const Color(0xFF6366F1),
            series2Label: 'Completed',
            series2Color: AppColors.success,
            height: 250,
          ),
        );

        final statusCard = _buildCardContainer(
          title: 'Project Status Distribution',
          subtitle: 'Current operational state of all corporate collaboration projects.',
          child: Column(
            children: [
              BiDonutChart(
                segments: statusSegments,
                centerTitle: '${filteredProjects.length}',
                centerSubtitle: 'Total Projects',
                chartRadius: 75,
                strokeWidth: 20,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('Completion Rate', completionRateStr),
                    _buildMiniMetric('Certificates Issued', '$issuedCerts'),
                    _buildMiniMetric('Applications Logged', '$totalApps'),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isWidescreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: barCard),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: statusCard),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              barCard,
              const SizedBox(height: 20),
              statusCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesAndSkillsTab(
    List<CategoryDistributionItem> categoryDist,
  ) {
    final skills = _analyticsService.getTopSkills();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final categoryTableCard = _buildCardContainer(
          title: 'Academic Category Throughput',
          subtitle: 'Student participation, corporate sponsor count, and completed sprints by domain.',
          child: categoryDist.isEmpty
              ? const AppEmptyState(
                  compact: true,
                  icon: Icons.category_outlined,
                  title: 'No Category Metrics Yet',
                  subtitle: 'Category participation metrics will populate once projects exist.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 52,
                    columns: const [
                      DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Projects', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Students', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Companies', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Share', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: categoryDist.map((c) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: c.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text('${c.projectCount}')),
                          DataCell(Text('${c.studentParticipants}')),
                          DataCell(Text('${c.companyCount}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${c.percentage}%',
                                style: TextStyle(
                                  color: c.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        );

        final skillsCard = _buildCardContainer(
          title: 'Most In-Demand Industry Skills',
          subtitle: 'Technical competencies requested in corporate project scopes vs student profiles.',
          child: skills.isEmpty
              ? const AppEmptyState(
                  compact: true,
                  icon: Icons.psychology_outlined,
                  title: 'No Skills Data Yet',
                  subtitle: 'Skill demand statistics will appear once projects or student profiles list skills.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: skills.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 12, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final s = skills[i];
                    return Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.skillName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                s.primaryCategory,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${s.projectRequirementCount} Projects (${s.certifiedStudentCount} Students)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${s.demandGrowthRate}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );

        if (isWidescreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: categoryTableCard),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: skillsCard),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              categoryTableCard,
              const SizedBox(height: 20),
              skillsCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildEngagementAndFunnelTab(UserEngagementSummary engagement) {
    final totalApps = engagement.totalApplications;
    final denom = totalApps > 0 ? totalApps.toDouble() : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final funnelCard = _buildCardContainer(
          title: 'Application Pipeline Funnel',
          subtitle: 'Live screening and placement conversion rate from submission to sprint assignment.',
          child: totalApps == 0
              ? const AppEmptyState(
                  compact: true,
                  icon: Icons.filter_alt_outlined,
                  title: 'No Application Funnel Data',
                  subtitle: 'Funnel conversion stages will populate once students submit applications.',
                )
              : Column(
                  children: [
                    _buildFunnelStage(
                      '1. Applications Submitted',
                      totalApps,
                      1.0,
                      AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _buildFunnelStage(
                      '2. Under Corporate Review',
                      engagement.pendingApplications,
                      (engagement.pendingApplications / denom).clamp(0.0, 1.0),
                      const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 12),
                    _buildFunnelStage(
                      '3. Accepted & Assigned',
                      engagement.acceptedApplications,
                      (engagement.acceptedApplications / denom).clamp(0.0, 1.0),
                      AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    _buildFunnelStage(
                      '4. Rejected / Closed',
                      engagement.rejectedApplications,
                      (engagement.rejectedApplications / denom).clamp(0.0, 1.0),
                      AppColors.error,
                    ),
                  ],
                ),
        );

        final userStatsCard = _buildCardContainer(
          title: 'Active Community Health & Retention',
          subtitle: 'Platform participation, corporate-student balance, and acceptance efficiency.',
          child: Column(
            children: [
              _buildParticipationBar(
                'Active Student Cohort',
                engagement.activeStudents,
                engagement.totalStudents,
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildParticipationBar(
                'Active Corporate Partners',
                engagement.activeCompanies,
                engagement.totalCompanies,
                AppColors.accentTeal,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Acceptance Conversion Rate',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${engagement.applicationAcceptanceRate}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Average Applications Per Project',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${engagement.averageApplicationsPerProject}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Verified Account Coverage',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${engagement.engagementIndex}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isWidescreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: funnelCard),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: userStatsCard),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              funnelCard,
              const SizedBox(height: 20),
              userStatsCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunnelStage(
    String label,
    int count,
    double widthFactor,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count Applicants',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widthFactor.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipationBar(
    String label,
    int active,
    int total,
    Color color,
  ) {
    final pct = total > 0 ? (active / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$active / $total (${(pct * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildDetailedDataLedgerTab() {
    final rows = _analyticsService.getDetailedTableRows(_selectedTimeframe);

    return _buildCardContainer(
      title: 'Historical Audit Data Ledger',
      subtitle: 'Precise tabular cohort records across selected timeframe: ${_selectedTimeframe.label}.',
      child: rows.isEmpty
          ? const AppEmptyState(
              compact: true,
              icon: Icons.table_rows_outlined,
              title: 'No Cohort Ledger Data',
              subtitle: 'Cohort breakdowns appear once students, companies, projects, or applications are recorded.',
            )
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(label: Text('Period / Interval', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Student Intake', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Corporate Signups', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Projects Published', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Completed', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Applications', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Completion Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Growth Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Health Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: rows.map((r) {
                    Color badgeColor;
                    if (r.healthStatus == 'Optimal' ||
                        r.healthStatus == 'Expanding') {
                      badgeColor = AppColors.success;
                    } else if (r.healthStatus == 'Active') {
                      badgeColor = AppColors.primary;
                    } else {
                      badgeColor = AppColors.textMuted;
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r.periodLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(Text('${r.studentRegistrations}')),
                        DataCell(Text('${r.companyRegistrations}')),
                        DataCell(Text('${r.projectsPublished}')),
                        DataCell(Text('${r.projectsCompleted}')),
                        DataCell(Text('${r.applicationsSubmitted}')),
                        DataCell(
                          Text(
                            '${r.completionRate}%',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${r.growthRate}%',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.healthStatus,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _handleGenerateReport(String categoryFilter) {
    final report = _analyticsService.generateExecutiveReport(
      timeframe: _selectedTimeframe,
      categoryFilter: categoryFilter,
      adminEmail: _authService.currentAdmin?.email ?? 'admin@campusconnect.edu.pk',
    );
    final stats = AdminDashboardService().statsNotifier.value;
    final verif = _analyticsService.getVerificationAnalytics();
    final studentVerified = AdminStudentService().verifiedCount;
    final companyVerified = AdminCompanyService().verifiedCount;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780, maxHeight: 740),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assessment_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CampusConnect Executive Business Intelligence Audit',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Report Identifier: ${report.reportId} • ${report.timeframe.label}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Generated By: ${report.generatedByAdmin}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Date: ${report.generatedAt.toLocal().toString().substring(0, 16)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Category Focus: ${report.categoryFilter}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Status: AUTHORIZED & SEALED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '1. Executive Analysis & Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.executiveSummary,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '2. Live Platform Throughput Ledger',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Table(
                            border: TableBorder.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Metric',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Live Value',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Platform Standing',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Student Registrations',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${stats.totalStudents}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '$studentVerified Verified Accounts',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Registered Corporate Partners',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${stats.totalCompanies}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '$companyVerified Verified Entities',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Project Completion Rate',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${stats.completionRate.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${stats.completedProjects} / ${stats.totalProjects} Projects Completed',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Verification Approval Rate',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${verif.approvalRatePercentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${verif.pendingCount} Pending Queue',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.darkNavy.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.security_rounded,
                                  size: 18,
                                  color: AppColors.darkNavy,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Integrity Checksum: ${report.cryptographicChecksum}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 24, color: AppColors.border),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: report.executiveSummary),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Summary copied to clipboard.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Summary'),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showExportCsvModal();
                            },
                            icon: const Icon(Icons.table_view_rounded, size: 16),
                            label: const Text('Export Ledger Data'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: report.executiveSummary),
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Executive Report ${report.reportId} logged & copied.',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExportCsvModal() {
    final categories = _buildCategoryOptions();
    final effectiveCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : 'All Categories';
    final csvData = _analyticsService.exportAnalyticsCsv(
      _selectedTimeframe,
      effectiveCategory,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.download_for_offline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Export Platform Analytics (CSV)',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The CSV output below contains live cohort breakdowns, category shares, and skill demand statistics:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          csvData,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: csvData));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('CSV Data successfully copied to clipboard.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy to Clipboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
