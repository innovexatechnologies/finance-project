import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/analytics_chart_card.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/quick_actions_bar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/recent_activity_list.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/stat_metric_card.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_dashboard_service.dart';

/// Enterprise Admin Dashboard Screen for CampusConnect
/// Features responsive layout, 7 live metric cards, interactive analytics charts,
/// functional quick action drawers, real-time activity feed, and date-range filtering.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _activeRouteId = 'dashboard';
  bool _isSidebarCollapsed = false;
  String _searchQuery = '';

  final List<String> _dateRanges = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'All Time',
  ];

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out Console'),
          ],
        ),
        content: const Text(
          'Are you sure you want to conclude this active administrative session? Session credentials will be invalidated securely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  void _onRouteSelected(String routeId) {
    setState(() => _activeRouteId = routeId);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context); // Close mobile drawer
    }

    if (routeId == 'company_verifications' || routeId == 'company_management') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
      );
    } else if (routeId == 'student_verifications') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
      );
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
      );
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApplicationMonitoringScreen()),
      );
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CertificateManagementScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,

          // Drawer for Mobile / Tablet view
          drawer: isDesktop
              ? null
              : Drawer(
                  child: AdminSidebar(
                    activeRouteId: _activeRouteId,
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),

          body: Row(
            children: [
              // Persistent Sidebar on Desktop
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: _activeRouteId,
                  onRouteSelected: _onRouteSelected,
                  onSignOut: _handleSignOut,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),

              // Main Dashboard Area
              Expanded(
                child: Column(
                  children: [
                    // Top Navigation Bar
                    AdminTopNavbar(
                      pageTitle: 'Platform Overview',
                      breadcrumb: 'Governance',
                      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (query) {
                        setState(() => _searchQuery = query);
                      },
                    ),

                    // Scrollable Dashboard Body
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _dashboardService.isLoadingNotifier,
                        builder: (context, isLoading, _) {
                          return ValueListenableBuilder<PlatformStatsModel>(
                            valueListenable: _dashboardService.statsNotifier,
                            builder: (context, stats, _) {
                              return ValueListenableBuilder<List<AdminActivityItem>>(
                                valueListenable: _dashboardService.activitiesNotifier,
                                builder: (context, activities, _) {
                                  if (isLoading) {
                                    return _buildLoadingSkeleton();
                                  }

                                  final displayActivities = _searchQuery.isEmpty
                                      ? activities
                                      : activities
                                          .where((act) =>
                                              act.title
                                                  .toLowerCase()
                                                  .contains(_searchQuery.toLowerCase()) ||
                                              act.description
                                                  .toLowerCase()
                                                  .contains(_searchQuery.toLowerCase()) ||
                                              act.actorName
                                                  .toLowerCase()
                                                  .contains(_searchQuery.toLowerCase()))
                                          .toList();

                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 24,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 1. Welcome Hero Banner & Date Range Filter
                                        _buildHeroHeaderSection(),
                                        const SizedBox(height: 24),

                                        // 2. 7 Statistics Cards
                                        _buildStatisticsCardsGrid(stats),
                                        const SizedBox(height: 24),

                                        // 3. Quick Actions Bar
                                        const QuickActionsBar(),
                                        const SizedBox(height: 24),

                                        // 4. Analytics Visualizer & Category Distribution
                                        AnalyticsChartCard(stats: stats),
                                        const SizedBox(height: 24),

                                        // 5. Recent Platform Activity Stream
                                        RecentActivityList(activities: displayActivities),
                                        const SizedBox(height: 36),

                                        // 6. Security Audit Footnote
                                        _buildAuditFootnote(),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
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
      },
    );
  }

  // 1. Welcome Hero Header & Date Range Filter
  Widget _buildHeroHeaderSection() {
    final admin = _authService.currentAdmin ??
        const AdminUserModel(
          id: 'adm_root',
          fullName: 'Dr. Tariq Mahmood',
          email: 'admin@campusconnect.edu.pk',
          role: 'SUPER_ADMIN',
          roleDisplayName: 'Super Administrator',
          department: 'Executive Governance Council',
          avatarInitial: 'TM',
          permissions: ['all'],
          lastLoginAt: 'Just now',
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        admin.roleDisplayName.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentTeal,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome to CampusConnect Governance, ${admin.fullName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Complete administrative visibility over registered universities, corporate SECP verifications, and student project sprints.',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.accentTeal, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Date Range Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.accentTeal),
                  SizedBox(width: 6),
                  Text(
                    'Audit Timeframe:',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ValueListenableBuilder<String>(
                valueListenable: _dashboardService.selectedDateRangeNotifier,
                builder: (context, activeRange, _) {
                  return Wrap(
                    spacing: 8,
                    children: _dateRanges.map((range) {
                      final isSelected = activeRange == range;
                      return InkWell(
                        onTap: () => _dashboardService.changeDateRange(range),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              color: isSelected ? AppColors.darkNavy : Colors.white,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. 7 Statistics Cards Grid
  Widget _buildStatisticsCardsGrid(PlatformStatsModel stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Responsive columns: 4 on large desktop, 2 on tablet, 1 on mobile
        int crossAxisCount = 4;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 1000) {
          crossAxisCount = 2;
        }

        final cards = [
          StatMetricCard(
            title: 'Total Students',
            value: '${stats.totalStudents}',
            subtitle: 'Verified university students',
            icon: Icons.school_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.lightIceBlue,
            trendText: '+${stats.studentGrowth}%',
            isPositiveTrend: true,
          ),
          StatMetricCard(
            title: 'Total Companies',
            value: '${stats.totalCompanies}',
            subtitle: 'Registered corporate sponsors',
            icon: Icons.domain_rounded,
            iconColor: AppColors.accentTeal,
            iconBgColor: AppColors.accentTeal.withValues(alpha: 0.12),
            trendText: '+${stats.companyGrowth}%',
            isPositiveTrend: true,
          ),
          StatMetricCard(
            title: 'Pending Verifications',
            value: '${stats.pendingVerifications}',
            subtitle: 'SECP & student reviews awaiting',
            icon: Icons.domain_verification_rounded,
            iconColor: AppColors.warning,
            iconBgColor: AppColors.warningBg,
            trendText: stats.pendingVerifications > 0 ? 'Action Req' : 'Clear',
            isPositiveTrend: stats.pendingVerifications == 0,
          ),
          StatMetricCard(
            title: 'Total Projects',
            value: '${stats.totalProjects}',
            subtitle: 'All created collaboration sprints',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF6366F1), // Indigo
            iconBgColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
            trendText: '+${stats.projectGrowth}%',
            isPositiveTrend: true,
          ),
          StatMetricCard(
            title: 'Active Projects',
            value: '${stats.activeProjects}',
            subtitle: 'Open & in-progress sprints',
            icon: Icons.pending_actions_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.lightIceBlue,
            trendText: 'Live',
            isPositiveTrend: true,
          ),
          StatMetricCard(
            title: 'Completed Projects',
            value: '${stats.completedProjects}',
            subtitle: 'Successfully delivered sprints',
            icon: Icons.verified_rounded,
            iconColor: AppColors.success,
            iconBgColor: AppColors.successBg,
            trendText: '${stats.completionRate}% Rate',
            isPositiveTrend: true,
          ),
          StatMetricCard(
            title: 'Pending Reports',
            value: '${stats.pendingReports}',
            subtitle: 'Milestone deliverables to audit',
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFFEC4899), // Pink
            iconBgColor: const Color(0xFFEC4899).withValues(alpha: 0.12),
            trendText: 'Audit Queue',
            isPositiveTrend: stats.pendingReports < 5,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.65,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  // Loading skeleton placeholder during date filter transitions
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  height: 120,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Security audit footnote
  Widget _buildAuditFootnote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'CampusConnect Administration & Governance Console • Strictly Non-Financial Academic Realm',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(
            'Cryptographic Audit Hash: FIPS-180-4 Verified',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
