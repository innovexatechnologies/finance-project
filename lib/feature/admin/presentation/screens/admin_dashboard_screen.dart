import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_dashboard_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';

/// Enterprise Admin Home Screen for CampusConnect.
/// Displays an animated Admin Command Header and accurate live quantities for
/// Students, Companies, Total Projects, Active Projects, and Completed Projects.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminDashboardService _dashboardService = AdminDashboardService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _activeRouteId = 'dashboard';
  bool _isSidebarCollapsed = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasCachedData =
          AdminStudentService().allStudents.isNotEmpty ||
          AdminCompanyService().allCompanies.isNotEmpty ||
          AdminProjectService().allProjects.isNotEmpty;
      _syncDashboard(showSkeleton: !hasCachedData, showToast: false);
    });
  }

  Future<void> _syncDashboard({
    bool showSkeleton = false,
    bool showToast = true,
  }) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      // Ensure All Time totals are always active for accurate quantity metrics.
      await _dashboardService.changeDateRange('All Time');
      await _dashboardService.loadAllAdminData(showLoading: showSkeleton);
      if (!mounted || !showToast) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin quantities synced with live database.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

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
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (routeId == _activeRouteId) return;

    Widget? target;
    if (routeId == 'company_verifications') {
      target = const CompanyVerificationsScreen();
    } else if (routeId == 'company_management') {
      target = const CompanyManagementScreen();
    } else if (routeId == 'student_verifications') {
      target = const StudentManagementScreen();
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      target = const ProjectManagementScreen();
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      target = const ApplicationMonitoringScreen();
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      target = const CertificateManagementScreen();
    } else if (routeId == 'analytics' || routeId == 'reports') {
      target = const ReportsAnalyticsScreen();
    } else if (routeId == 'settings') {
      target = const AdminSettingsScreen();
    }

    if (target != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target!),
      );
    }
  }

  List<_QuantityMetricItem> _buildQuantityItems(PlatformStatsModel stats) {
    return [
      _QuantityMetricItem(
        title: 'Total Students',
        subtitle: 'Registered student accounts',
        quantity: stats.totalStudents,
        icon: Icons.school_rounded,
        accentColor: AppColors.primaryBlue,
        secondaryColor: const Color(0xFF3B82F6),
        routeId: 'student_verifications',
      ),
      _QuantityMetricItem(
        title: 'Total Companies',
        subtitle: 'Registered corporate partners',
        quantity: stats.totalCompanies,
        icon: Icons.domain_rounded,
        accentColor: const Color(0xFF0D9488),
        secondaryColor: AppColors.accentTeal,
        routeId: 'company_management',
      ),
      _QuantityMetricItem(
        title: 'Total Projects',
        subtitle: 'All created platform projects',
        quantity: stats.totalProjects,
        icon: Icons.assignment_rounded,
        accentColor: AppColors.indigoAccent,
        secondaryColor: const Color(0xFF6366F1),
        routeId: 'projects_audit',
      ),
      _QuantityMetricItem(
        title: 'Active Projects',
        subtitle: 'Open & in-progress projects',
        quantity: stats.activeProjects,
        icon: Icons.bolt_rounded,
        accentColor: const Color(0xFF0284C7),
        secondaryColor: const Color(0xFF0EA5E9),
        routeId: 'projects_audit',
      ),
      _QuantityMetricItem(
        title: 'Completed Projects',
        subtitle: 'Successfully completed projects',
        quantity: stats.completedProjects,
        icon: Icons.verified_rounded,
        accentColor: const Color(0xFF059669),
        secondaryColor: const Color(0xFF10B981),
        routeId: 'projects_audit',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: _activeRouteId,
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
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
              Expanded(
                child: Column(
                  children: [
                    AdminTopNavbar(
                      pageTitle: 'Admin Overview',
                      breadcrumb: 'Governance',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                    ),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _dashboardService.isLoadingNotifier,
                        builder: (context, isLoading, _) {
                          return ValueListenableBuilder<PlatformStatsModel>(
                            valueListenable: _dashboardService.statsNotifier,
                            builder: (context, stats, _) {
                              if (isLoading) {
                                return _buildLoadingSkeleton(
                                  horizontalPad: isDesktop ? 28 : 16,
                                );
                              }

                              final metrics = _buildQuantityItems(stats);
                              final horizontalPad = isDesktop ? 28.0 : 16.0;

                              return RefreshIndicator(
                                color: AppColors.primaryBlue,
                                onRefresh: () => _syncDashboard(
                                  showSkeleton: false,
                                  showToast: true,
                                ),
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPad,
                                    vertical: 22,
                                  ),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 1180),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ValueListenableBuilder<
                                              AdminUserModel?>(
                                            valueListenable: _authService
                                                .currentAdminNotifier,
                                            builder: (context, activeAdmin, _) {
                                              final admin = activeAdmin ??
                                                  const AdminUserModel(
                                                    id: 'adm_root',
                                                    fullName:
                                                        'Executive Administrator',
                                                    email:
                                                        'admin@campusconnect.edu.pk',
                                                    role: 'SUPER_ADMIN',
                                                    roleDisplayName:
                                                        'Executive Super Administrator',
                                                    department:
                                                        'CampusConnect Governance Council',
                                                    avatarInitial: 'EA',
                                                    permissions: ['all'],
                                                    lastLoginAt:
                                                        'Active Session',
                                                  );

                                              return _AnimatedAdminCommandBanner(
                                                admin: admin,
                                                isSyncing: _isSyncing,
                                                onSyncTap: () => _syncDashboard(
                                                  showSkeleton: false,
                                                  showToast: true,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          _buildQuantitiesLayout(metrics),
                                          const SizedBox(height: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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

  Widget _buildQuantitiesLayout(List<_QuantityMetricItem> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Desktop: clean balanced 2 + 3 executive grid with zero empty slots.
        if (width >= 900) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 18),
                      Expanded(
                        child: _ExecutiveQuantityCard(
                          item: metrics[i],
                          index: i,
                          isCompactRow: false,
                          onTap: () => _onRouteSelected(metrics[i].routeId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 2; i < 5; i++) ...[
                      if (i > 2) const SizedBox(width: 18),
                      Expanded(
                        child: _ExecutiveQuantityCard(
                          item: metrics[i],
                          index: i,
                          isCompactRow: false,
                          onTap: () => _onRouteSelected(metrics[i].routeId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        // Tablet: 2 + 2 + 1 full-width card layout.
        if (width >= 580) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(
                        child: _ExecutiveQuantityCard(
                          item: metrics[i],
                          index: i,
                          isCompactRow: false,
                          onTap: () => _onRouteSelected(metrics[i].routeId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 2; i < 4; i++) ...[
                      if (i > 2) const SizedBox(width: 16),
                      Expanded(
                        child: _ExecutiveQuantityCard(
                          item: metrics[i],
                          index: i,
                          isCompactRow: false,
                          onTap: () => _onRouteSelected(metrics[i].routeId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ExecutiveQuantityCard(
                item: metrics[4],
                index: 4,
                isCompactRow: true,
                onTap: () => _onRouteSelected(metrics[4].routeId),
              ),
            ],
          );
        }

        // Mobile: crisp stacked horizontal executive quantity cards.
        return Column(
          children: [
            for (int i = 0; i < metrics.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ExecutiveQuantityCard(
                item: metrics[i],
                index: i,
                isCompactRow: true,
                onTap: () => _onRouteSelected(metrics[i].routeId),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingSkeleton({required double horizontalPad}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              Container(
                height: 164,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
              ),
              const SizedBox(height: 24),
              for (int i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Container(
                  height: 108,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityMetricItem {
  final String title;
  final String subtitle;
  final int quantity;
  final IconData icon;
  final Color accentColor;
  final Color secondaryColor;
  final String routeId;

  const _QuantityMetricItem({
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.icon,
    required this.accentColor,
    required this.secondaryColor,
    required this.routeId,
  });
}

/// Animated executive Admin Panel command header shown at the top of the screen.
class _AnimatedAdminCommandBanner extends StatefulWidget {
  final AdminUserModel admin;
  final bool isSyncing;
  final VoidCallback onSyncTap;

  const _AnimatedAdminCommandBanner({
    required this.admin,
    required this.isSyncing,
    required this.onSyncTap,
  });

  @override
  State<_AnimatedAdminCommandBanner> createState() =>
      _AnimatedAdminCommandBannerState();
}

class _AnimatedAdminCommandBannerState extends State<_AnimatedAdminCommandBanner>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final AnimationController _orbitController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = curved;
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;

            return AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final t = _ambientController.value;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFF08142B),
                        Color(0xFF0F2650),
                        Color(0xFF1A3F7A),
                      ],
                      stops: [
                        0.0,
                        0.45 + (t * 0.14),
                        1.0,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.accentTeal.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkNavy.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50 + (t * 28),
                          top: -55 + (t * 14),
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accentTeal.withValues(
                                    alpha: 0.18 + (t * 0.08),
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -40 + ((1 - t) * 24),
                          bottom: -70,
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryBlue.withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 18 : 26,
                      isCompact ? 18 : 24,
                      isCompact ? 18 : 26,
                      isCompact ? 16 : 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _ambientController,
                                    builder: (context, _) {
                                      final pulse = _ambientController.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF34D399)
                                                .withValues(
                                              alpha: 0.35 + (pulse * 0.25),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF34D399),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF34D399)
                                                            .withValues(
                                                      alpha:
                                                          0.4 + (pulse * 0.5),
                                                    ),
                                                    blurRadius:
                                                        4 + (pulse * 5),
                                                    spreadRadius: pulse * 1.5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              'ADMIN CONTROL PANEL',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFFA7F3D0),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: math.max(
                                        120.0,
                                        constraints.maxWidth - 130.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      widget.admin.roleDisplayName
                                          .toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFE2E8F0),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap:
                                    widget.isSyncing ? null : widget.onSyncTap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.isSyncing)
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.sync_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.isSyncing ? 'Syncing' : 'Sync',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 16 : 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Executive Command Console',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: isCompact ? 20 : 25,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      height: 1.18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Welcome, ${widget.admin.fullName}. Live platform quantities across registered students, corporate partners, and project pipelines.',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFCBD5E1),
                                      fontSize: isCompact ? 12.5 : 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_user_rounded,
                                          size: 14,
                                          color: AppColors.accentTeal,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            widget.admin.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFFE2E8F0),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isCompact ? 12 : 24),
                            _OrbitalAdminEmblem(
                              size: isCompact ? 68 : 98,
                              orbitAnimation: _orbitController,
                              ambientAnimation: _ambientController,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, _) {
                      final sweep = _ambientController.value;
                      return Container(
                        height: 3.5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: const [
                              Color(0x0006B6D4),
                              AppColors.accentTeal,
                              Color(0xFF60A5FA),
                              Color(0x002563EB),
                            ],
                            stops: const [0.0, 0.35, 0.65, 1.0],
                            begin: Alignment(-1.4 + (sweep * 1.4), 0),
                            end: Alignment(0.2 + (sweep * 1.4), 0),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrbitalAdminEmblem extends StatelessWidget {
  final double size;
  final Animation<double> orbitAnimation;
  final Animation<double> ambientAnimation;

  const _OrbitalAdminEmblem({
    required this.size,
    required this.orbitAnimation,
    required this.ambientAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.62;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: ambientAnimation,
            builder: (context, _) {
              final glow = ambientAnimation.value;
              return Container(
                width: size * 0.82,
                height: size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentTeal
                          .withValues(alpha: 0.18 + (glow * 0.16)),
                      blurRadius: 18 + (glow * 10),
                      spreadRadius: 1 + (glow * 2),
                    ),
                  ],
                ),
              );
            },
          ),
          RotationTransition(
            turns: orbitAnimation,
            child: CustomPaint(
              size: Size(size, size),
              painter: _OrbitalRingPainter(),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: innerSize * 0.52,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitalRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 3;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, outerRadius, trackPaint);

    final arcPaint = Paint()
      ..color = AppColors.accentTeal
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final rect = Rect.fromCircle(center: center, radius: outerRadius);
    canvas.drawArc(rect, -math.pi / 4, math.pi * 0.55, false, arcPaint);
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 0.42,
      false,
      arcPaint..color = const Color(0xFF60A5FA),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Executive quantity card showing a single metric's live integer count cleanly.
class _ExecutiveQuantityCard extends StatefulWidget {
  final _QuantityMetricItem item;
  final int index;
  final bool isCompactRow;
  final VoidCallback onTap;

  const _ExecutiveQuantityCard({
    required this.item,
    required this.index,
    required this.isCompactRow,
    required this.onTap,
  });

  @override
  State<_ExecutiveQuantityCard> createState() => _ExecutiveQuantityCardState();
}

class _ExecutiveQuantityCardState extends State<_ExecutiveQuantityCard> {
  bool _isHovered = false;

  String _formatQuantity(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buffer.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final delayMs = 60 * widget.index;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 14),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Transform.translate(
          offset: Offset(0, _isHovered ? -3 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? item.accentColor.withValues(alpha: 0.45)
                    : AppColors.border,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? item.accentColor.withValues(alpha: 0.14)
                      : AppColors.darkNavy.withValues(alpha: 0.04),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [item.accentColor, item.secondaryColor],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -18,
                        top: -16,
                        child: Icon(
                          item.icon,
                          size: widget.isCompactRow ? 78 : 96,
                          color: item.accentColor.withValues(alpha: 0.045),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          widget.isCompactRow ? 18 : 22,
                          20,
                          widget.isCompactRow ? 16 : 20,
                        ),
                        child: widget.isCompactRow
                            ? _buildCompactBody(item)
                            : _buildGridBody(item),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(_QuantityMetricItem item) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.accentColor.withValues(alpha: 0.14),
            item.secondaryColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.accentColor.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(item.icon, color: item.accentColor, size: 22),
    );
  }

  Widget _buildAnimatedQuantityText(
    _QuantityMetricItem item, {
    required double fontSize,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: item.quantity),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          _formatQuantity(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
            letterSpacing: -0.9,
            height: 1.05,
          ),
        );
      },
    );
  }

  Widget _buildGridBody(_QuantityMetricItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconBadge(item),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.accentColor.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TOTAL COUNT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: item.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildAnimatedQuantityText(item, fontSize: 34),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: _isHovered ? item.accentColor : AppColors.textMuted,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactBody(_QuantityMetricItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconBadge(item),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: item.accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedQuantityText(item, fontSize: 24),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: item.accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
