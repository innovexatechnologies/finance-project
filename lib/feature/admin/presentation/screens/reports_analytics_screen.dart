import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_analytics_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_bar_chart.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_donut_chart.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_line_chart.dart';
import 'package:link_vibe/feature/admin/services/admin_analytics_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';

/// Enterprise Reports & Business Intelligence Analytics Hub (Screen 40)
/// Comprehensive non-financial dashboard providing cohort registration trends,
/// verification SLAs, project lifecycle analysis, skills demand matrix,
/// interactive visualizations, and executive printable report generation.
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

  late TabController _tabController;

  final List<String> _categories = [
    'All Categories',
    'Artificial Intelligence & Machine Learning',
    'Mobile Application Development',
    'Cloud Infrastructure & DevOps',
    'Full Stack Web Engineering',
    'Cybersecurity & Threat Intelligence',
    'UI/UX & Product Design Systems',
  ];

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

  void _onRouteSelected(String routeId) {
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
    } else if (routeId == 'company_verifications' || routeId == 'company_management') {
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
        MaterialPageRoute(builder: (_) => const ApplicationMonitoringScreen()),
      );
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CertificateManagementScreen()),
      );
    } else if (routeId == 'settings') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
      );
    }
    // If routeId is 'analytics', we are already on this screen.
  }

  void _handleSignOut() async {
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
    final verificationSummary = _analyticsService.getVerificationAnalytics();
    final engagementSummary = _analyticsService.getUserEngagement();
    final regTrends = _analyticsService.getRegistrationTrends(_selectedTimeframe, _selectedCategory);
    final projTrends = _analyticsService.getProjectTrends(_selectedTimeframe, _selectedCategory);
    final categoryDist = _analyticsService.getCategoryDistribution(_selectedCategory);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
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
          // Desktop Collapsible Sidebar
          if (MediaQuery.of(context).size.width >= 1024)
            AdminSidebar(
              activeRouteId: 'analytics',
              onRouteSelected: _onRouteSelected,
              onSignOut: _handleSignOut,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
              },
            ),

          // Main BI Workstation Body
          Expanded(
            child: Column(
              children: [
                AdminTopNavbar(
                  pageTitle: 'Reports & Business Intelligence',
                  breadcrumb: 'Analytics Hub',
                  onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                  onSignOut: _handleSignOut,
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Control Header with Filters & Actions
                        _buildControlHeader(),
                        const SizedBox(height: 20),

                        // 2. High-Impact KPI Stat Cards
                        _buildKpiCards(verificationSummary, engagementSummary, regTrends, projTrends),
                        const SizedBox(height: 24),

                        // 3. Tab Bar Navigation
                        _buildTabBar(),
                        const SizedBox(height: 20),

                        // 4. Tab Views
                        _buildTabViews(
                          regTrends: regTrends,
                          projTrends: projTrends,
                          categoryDist: categoryDist,
                          verificationSummary: verificationSummary,
                          engagementSummary: engagementSummary,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. CONTROL HEADER WITH DATE RANGE & CATEGORY FILTERS
  Widget _buildControlHeader() {
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
          final isNarrow = constraints.maxWidth < 850;

          final filters = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Timeframe Dropdown
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
                    icon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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

              // Category Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    icon: const Icon(Icons.filter_list, size: 16, color: AppColors.accentTeal),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.length > 28 ? '${c.substring(0, 25)}...' : c),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Live Refresh Action
              IconButton(
                onPressed: () {
                  _analyticsService.refreshAnalytics();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Platform analytics refreshed with latest ledger counts.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.darkNavy,
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textMuted),
                tooltip: 'Refresh Metrics',
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Export CSV Button
              OutlinedButton.icon(
                onPressed: _showExportCsvModal,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),

              // Generate Executive Report CTA
              ElevatedButton.icon(
                onPressed: _handleGenerateReport,
                icon: const Icon(Icons.assessment_outlined, size: 16),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                filters,
                const SizedBox(height: 16),
                actions,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                filters,
                actions,
              ],
            );
          }
        },
      ),
    );
  }

  // 2. HIGH-IMPACT KPI SUMMARY CARDS
  Widget _buildKpiCards(
    VerificationAnalyticsSummary verification,
    UserEngagementSummary engagement,
    List<RegistrationTrendPoint> regTrends,
    List<ProjectTrendPoint> projTrends,
  ) {
    final latestReg = regTrends.isNotEmpty ? regTrends.last : null;
    final latestProj = projTrends.isNotEmpty ? projTrends.last : null;

    final studentTotal = latestReg?.cumulativeStudents ?? 1640;
    final companyTotal = latestReg?.cumulativeCompanies ?? 130;
    final activeSprints = latestProj?.projectsActive ?? 28;
    final completionVelocity = latestProj?.completionRatePercentage ?? 88.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 1200
            ? 6
            : width >= 800
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.45,
          children: [
            _buildKpiCard(
              title: 'Total Students',
              value: '$studentTotal',
              delta: '+${latestReg?.growthRatePercentage.toStringAsFixed(1) ?? '24.8'}%',
              isPositiveDelta: true,
              subtitle: '7 Universities Verified',
              icon: Icons.school_rounded,
              accentColor: AppColors.primary,
            ),
            _buildKpiCard(
              title: 'Partner Companies',
              value: '$companyTotal',
              delta: '+18.2%',
              isPositiveDelta: true,
              subtitle: 'SECP Authenticated',
              icon: Icons.business_rounded,
              accentColor: AppColors.accentTeal,
            ),
            _buildKpiCard(
              title: 'Active Sprints',
              value: '$activeSprints',
              delta: '$completionVelocity% Velocity',
              isPositiveDelta: true,
              subtitle: 'Active Project Teams',
              icon: Icons.rocket_launch_rounded,
              accentColor: const Color(0xFF6366F1), // Indigo
            ),
            _buildKpiCard(
              title: 'Verification SLA',
              value: '${verification.approvalRatePercentage}%',
              delta: '${verification.averageTurnaroundHours}h Avg Turn',
              isPositiveDelta: true,
              subtitle: '${verification.approvedCount} Approved Credentials',
              icon: Icons.verified_user_rounded,
              accentColor: AppColors.success,
            ),
            _buildKpiCard(
              title: 'Applications Log',
              value: '${engagement.totalApplications}',
              delta: '${engagement.averageApplicationsPerProject} Avg/Project',
              isPositiveDelta: true,
              subtitle: '${engagement.acceptedApplications} Placed Students',
              icon: Icons.send_rounded,
              accentColor: const Color(0xFFF59E0B), // Amber
            ),
            _buildKpiCard(
              title: 'Platform Health',
              value: engagement.engagementIndex.toStringAsFixed(1),
              delta: 'Optimal Index',
              isPositiveDelta: true,
              subtitle: 'Zero Critical Flags',
              icon: Icons.favorite_rounded,
              accentColor: const Color(0xFF10B981), // Emerald
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
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositiveDelta ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositiveDelta ? AppColors.success : AppColors.error,
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

  // 3. TAB BAR NAVIGATION
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
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

  // 4. TAB VIEWS
  Widget _buildTabViews({
    required List<RegistrationTrendPoint> regTrends,
    required List<ProjectTrendPoint> projTrends,
    required List<CategoryDistributionItem> categoryDist,
    required VerificationAnalyticsSummary verificationSummary,
    required UserEngagementSummary engagementSummary,
  }) {
    return SizedBox(
      height: 680,
      child: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Executive Overview
          _buildExecutiveOverviewTab(regTrends, categoryDist, projTrends),

          // Tab 2: Registration & Verifications
          _buildRegistrationAndVerificationTab(regTrends, verificationSummary),

          // Tab 3: Projects & Completion
          _buildProjectsAndCompletionTab(projTrends),

          // Tab 4: Categories & Skills Demand
          _buildCategoriesAndSkillsTab(categoryDist),

          // Tab 5: Engagement & Funnel
          _buildEngagementAndFunnelTab(engagementSummary),

          // Tab 6: Detailed Data Ledger
          _buildDetailedDataLedgerTab(),
        ],
      ),
    );
  }

  // --- TAB 1: EXECUTIVE OVERVIEW ---
  Widget _buildExecutiveOverviewTab(
    List<RegistrationTrendPoint> regTrends,
    List<CategoryDistributionItem> categoryDist,
    List<ProjectTrendPoint> projTrends,
  ) {
    final linePoints = regTrends.map((r) {
      return BiLineDataPoint(
        label: r.label,
        value1: r.studentRegistrations.toDouble(),
        value2: r.companyRegistrations.toDouble(),
        value3: (r.studentRegistrations * 1.4), // Applications correlation
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
          subtitle: 'Interactive comparison between student intake, corporate partners, and applications.',
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
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                lineCard,
                const SizedBox(height: 20),
                donutCard,
              ],
            ),
          );
        }
      },
    );
  }

  // --- TAB 2: REGISTRATION & VERIFICATIONS ---
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
          subtitle: 'Periodic registration volume across authenticated academic and corporate entities.',
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
          title: 'Verification SLA & Quality Audit',
          subtitle: 'Institutional credentials evaluated across HEC and SECP registries.',
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('Turnaround SLA', '${verification.averageTurnaroundHours} Hours'),
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
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                barCard,
                const SizedBox(height: 20),
                verifCard,
              ],
            ),
          );
        }
      },
    );
  }

  // --- TAB 3: PROJECTS & COMPLETION ---
  Widget _buildProjectsAndCompletionTab(List<ProjectTrendPoint> projTrends) {
    final barGroups = projTrends.map((p) {
      return BiBarDataGroup(
        label: p.label,
        value1: p.projectsPublished.toDouble(),
        value2: p.projectsCompleted.toDouble(),
      );
    }).toList();

    final statusSegments = [
      const BiDonutSegment(label: 'Active Ongoing', value: 28, color: Color(0xFF6366F1)),
      const BiDonutSegment(label: 'Completed & Certified', value: 42, color: AppColors.success),
      const BiDonutSegment(label: 'Published (Recruiting)', value: 16, color: AppColors.accentTeal),
      const BiDonutSegment(label: 'Archived / Closed', value: 8, color: AppColors.textMuted),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final barCard = _buildCardContainer(
          title: 'Project Lifecycle Velocity (Published vs Completed)',
          subtitle: 'Comparison between project openings and successful deliverable sign-offs.',
          child: BiBarChart(
            dataGroups: barGroups,
            series1Label: 'Published Sprints',
            series1Color: const Color(0xFF6366F1),
            series2Label: 'Completed & Signed',
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
                centerTitle: '94',
                centerSubtitle: 'Total Projects',
                chartRadius: 75,
                strokeWidth: 20,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('Deliverable Rate', '92.4%'),
                    _buildMiniMetric('Mentor Review', '96.1%'),
                    _buildMiniMetric('Peer Endorsements', '88.3%'),
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
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                barCard,
                const SizedBox(height: 20),
                statusCard,
              ],
            ),
          );
        }
      },
    );
  }

  // --- TAB 4: CATEGORIES & SKILLS DEMAND ---
  Widget _buildCategoriesAndSkillsTab(List<CategoryDistributionItem> categoryDist) {
    final skills = _analyticsService.getTopSkills();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final categoryTableCard = _buildCardContainer(
          title: 'Academic Category Throughput',
          subtitle: 'Student participation, corporate sponsor count, and completed sprints by domain.',
          child: SingleChildScrollView(
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
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(c.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(Text('${c.projectCount}')),
                    DataCell(Text('${c.studentParticipants}')),
                    DataCell(Text('${c.companyCount}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${c.percentage}%', style: TextStyle(color: c.color, fontWeight: FontWeight.bold, fontSize: 11)),
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
          subtitle: 'Technical competencies requested in corporate project scopes vs student credential count.',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: skills.length,
            separatorBuilder: (_, index) => const Divider(height: 12, color: AppColors.border),
            itemBuilder: (context, i) {
              final s = skills[i];
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.skillName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(s.primaryCategory, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${s.projectRequirementCount} Projects (${s.certifiedStudentCount} Certs)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${s.demandGrowthRate}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
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
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                categoryTableCard,
                const SizedBox(height: 20),
                skillsCard,
              ],
            ),
          );
        }
      },
    );
  }

  // --- TAB 5: ENGAGEMENT & FUNNEL ---
  Widget _buildEngagementAndFunnelTab(UserEngagementSummary engagement) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 960;

        final funnelCard = _buildCardContainer(
          title: 'Application Pipeline Funnel',
          subtitle: 'Progressive screening and placement conversion rate from application to active sprint.',
          child: Column(
            children: [
              _buildFunnelStage('1. Applications Submitted', engagement.totalApplications, 1.0, AppColors.primary),
              const SizedBox(height: 10),
              _buildFunnelStage('2. Under Corporate Review', engagement.pendingApplications, 0.72, const Color(0xFF6366F1)),
              const SizedBox(height: 10),
              _buildFunnelStage('3. Accepted & Assigned', engagement.acceptedApplications, 0.35, AppColors.success),
              const SizedBox(height: 10),
              _buildFunnelStage('4. Rejected / Closed', engagement.rejectedApplications, 0.25, AppColors.error),
            ],
          ),
        );

        final userStatsCard = _buildCardContainer(
          title: 'Active Community Health & Retention',
          subtitle: 'Daily platform participation, student-to-corporate ratio, and review latency.',
          child: Column(
            children: [
              _buildParticipationBar('Active Student Cohort', engagement.activeStudents, engagement.totalStudents, AppColors.primary),
              const SizedBox(height: 16),
              _buildParticipationBar('Active Corporate Partners', engagement.activeCompanies, engagement.totalCompanies, AppColors.accentTeal),
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
                        const Text('Acceptance Conversion Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${engagement.applicationAcceptanceRate}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Average Applications Per Project', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${engagement.averageApplicationsPerProject}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentTeal)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Engagement Index', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${engagement.engagementIndex}/100', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
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
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                funnelCard,
                const SizedBox(height: 20),
                userStatsCard,
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildFunnelStage(String label, int count, double widthFactor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$count Applicants', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipationBar(String label, int active, int total, Color color) {
    final pct = total > 0 ? (active / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$active / $total (${(pct * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  // --- TAB 6: DETAILED DATA LEDGER ---
  Widget _buildDetailedDataLedgerTab() {
    final rows = _analyticsService.getDetailedTableRows(_selectedTimeframe);

    return _buildCardContainer(
      title: 'Historical Audit Data Ledger',
      subtitle: 'Precise tabular cohort records across selected timeframe: ${_selectedTimeframe.label}.',
      child: SingleChildScrollView(
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
              if (r.healthStatus == 'Optimal') {
                badgeColor = AppColors.success;
              } else if (r.healthStatus == 'Expanding') {
                badgeColor = AppColors.primary;
              } else {
                badgeColor = AppColors.accentTeal;
              }

              return DataRow(
                cells: [
                  DataCell(Text(r.periodLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataCell(Text('${r.studentRegistrations}')),
                  DataCell(Text('${r.companyRegistrations}')),
                  DataCell(Text('${r.projectsPublished}')),
                  DataCell(Text('${r.projectsCompleted}')),
                  DataCell(Text('${r.applicationsSubmitted}')),
                  DataCell(Text('${r.completionRate}%', style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(
                    Text('+${r.growthRate}%',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.healthStatus,
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
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

  // --- REUSABLE CARD CONTAINER ---
  Widget _buildCardContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  // --- MODAL: GENERATE EXECUTIVE REPORT PREVIEW ---
  void _handleGenerateReport() {
    final report = _analyticsService.generateExecutiveReport(
      timeframe: _selectedTimeframe,
      categoryFilter: _selectedCategory,
      adminEmail: _authService.currentAdmin?.email ?? 'superadmin@campusconnect.edu.pk',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 780,
            constraints: const BoxConstraints(maxHeight: 740),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Official Platform Crest
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CampusConnect Executive Business Intelligence Audit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Report Identifier: ${report.reportId} • ${report.timeframe.label}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 28, color: AppColors.border),

                // Report Printable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Generated By: ${report.generatedByAdmin}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('Date: ${report.generatedAt.toLocal().toString().substring(0, 16)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Category Focus: ${report.categoryFilter}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Status: AUTHORIZED & SEALED',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Executive Summary Commentary
                        const Text('1. Executive Analysis & Summary',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          report.executiveSummary,
                          style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),

                        // Summary Statistics Matrix
                        const Text('2. Platform Throughput Ledger',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        Table(
                          border: TableBorder.all(color: AppColors.border, width: 1),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: AppColors.background),
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('Current Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('Institutional Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Student Registrations', style: TextStyle(fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('1,640', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8), child: Text('+24.8% Cohort Growth', style: TextStyle(fontSize: 12, color: AppColors.success))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Verified Corporate Partners', style: TextStyle(fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('130', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8), child: Text('SECP Compliant (100%)', style: TextStyle(fontSize: 12, color: AppColors.primary))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Project Completion Velocity', style: TextStyle(fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('88.5%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8), child: Text('Optimal Benchmark', style: TextStyle(fontSize: 12, color: AppColors.success))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Verification SLA Response', style: TextStyle(fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('5.8 Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8), child: Text('SLA Maintained (< 24h)', style: TextStyle(fontSize: 12, color: AppColors.success))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Cryptographic Checksum Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security_rounded, size: 18, color: AppColors.darkNavy),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cryptographic Integrity Checksum: ${report.cryptographicChecksum}',
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textPrimary),
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

                // Modal Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: report.executiveSummary));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Summary copied to clipboard.')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Summary'),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showExportCsvModal();
                          },
                          icon: const Icon(Icons.table_view_rounded, size: 16),
                          label: const Text('Export Ledger Data'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Executive Report ${report.reportId} generated for printing.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Print / Save PDF'),
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
        );
      },
    );
  }

  // --- MODAL: EXPORT CSV PREVIEW ---
  void _showExportCsvModal() {
    final csvData = _analyticsService.exportAnalyticsCsv(_selectedTimeframe, _selectedCategory);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 700,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.download_for_offline_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Export Platform Analytics (CSV Format)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'The standard CSV format below contains tabular breakdown cohorts, category shares, and skill demand matrices for spreadsheet ingestion.',
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
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
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
        );
      },
    );
  }
}
