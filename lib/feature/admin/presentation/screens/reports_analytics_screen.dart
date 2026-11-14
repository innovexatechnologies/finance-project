import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_analytics_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_bar_chart.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/bi_line_chart.dart';
import 'package:link_vibe/feature/admin/services/admin_analytics_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';

/// Reports & Analytics Hub showing daily Student intake graphs,
/// daily Company registration graphs, complete day-by-day records,
/// and live Student vs Company quantity comparison from Supabase.
class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final AnalyticsTimeframe _selectedTimeframe = AnalyticsTimeframe.allTime;
  bool _isSidebarCollapsed = false;
  bool _isRefreshing = false;
  bool _onlyActivityDays = false;
  bool _showAllLedgerDays = false;

  @override
  void initState() {
    super.initState();
    if (AdminStudentService().totalCount == 0 &&
        AdminCompanyService().totalCount == 0 &&
        AdminProjectService().totalCount == 0) {
      Future.microtask(_silentInitialSync);
    }
  }

  Future<void> _silentInitialSync() async {
    if (_isRefreshing || !mounted) return;
    setState(() => _isRefreshing = true);
    await _analyticsService.reloadAllAndRefresh();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _analyticsService.reloadAllAndRefresh();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily analytics and platform records synced.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onRouteSelected(String routeId) {
    AdminSidebar.navigateToRoute(
      context,
      scaffoldKey: _scaffoldKey,
      currentRouteId: 'analytics',
      targetRouteId: routeId,
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Sign out of the administrator console and return to the login portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final isMobile = width < 680;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: isDesktop
          ? null
          : Drawer(
              width: 270,
              child: AdminSidebar(
                activeRouteId: 'analytics',
                onRouteSelected: _onRouteSelected,
                onSignOut: _handleSignOut,
              ),
            ),
      body: Row(
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
                  pageTitle: 'Reports and Analytics',
                  breadcrumb: 'Platform Analytics',
                  onOpenDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
                  onSignOut: _handleSignOut,
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      AdminStudentService().studentsNotifier,
                      AdminCompanyService().companiesNotifier,
                      AdminProjectService().projectsNotifier,
                      _analyticsService.lastRefreshedNotifier,
                    ]),
                    builder: (context, _) {
                      final dailyRecords = _analyticsService
                          .getDailyPlatformRecords(_selectedTimeframe);
                      final totalStudents = AdminStudentService().totalCount;
                      final totalCompanies = AdminCompanyService().totalCount;
                      final totalProjects = AdminProjectService().totalCount;
                      final lastSynced =
                          _analyticsService.lastRefreshedNotifier.value;

                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(
                                isMobile: isMobile,
                                totalStudents: totalStudents,
                                totalCompanies: totalCompanies,
                                totalProjects: totalProjects,
                                lastSynced: lastSynced,
                              ),
                              const SizedBox(height: 20),
                              _buildKpiSummarySection(
                                width: width,
                                dailyRecords: dailyRecords,
                                totalStudents: totalStudents,
                                totalCompanies: totalCompanies,
                              ),
                              const SizedBox(height: 22),
                              _buildDailyGraphsSection(
                                width: width,
                                dailyRecords: dailyRecords,
                              ),
                              const SizedBox(height: 22),
                              _buildQuantityComparisonSection(
                                width: width,
                                dailyRecords: dailyRecords,
                                totalStudents: totalStudents,
                                totalCompanies: totalCompanies,
                              ),
                              const SizedBox(height: 22),
                              _buildDailyLedgerSection(
                                isMobile: isMobile,
                                dailyRecords: dailyRecords,
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
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

  Widget _buildHeaderSection({
    required bool isMobile,
    required int totalStudents,
    required int totalCompanies,
    required int totalProjects,
    required DateTime lastSynced,
  }) {
    final syncedTime =
        '${lastSynced.hour.toString().padLeft(2, '0')}:${lastSynced.minute.toString().padLeft(2, '0')}';

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Daily Intake & Quantity Analytics',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 18 : 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Live day-by-day log of students joined, companies registered, and quantity comparison • Total: $totalStudents Students, $totalCompanies Companies, $totalProjects Projects • Synced at $syncedTime',
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: titleBlock,
    );
  }

  Widget _buildKpiSummarySection({
    required double width,
    required List<DailyPlatformRecord> dailyRecords,
    required int totalStudents,
    required int totalCompanies,
  }) {
    final now = DateTime.now();
    final todayKey = _formatDateKey(now);
    DailyPlatformRecord? todayRecord;
    for (final r in dailyRecords) {
      if (r.dateKey == todayKey) {
        todayRecord = r;
        break;
      }
    }

    final int todayStudents = todayRecord?.studentCount ?? 0;
    final int todayCompanies = todayRecord?.companyCount ?? 0;

    final int periodStudents = dailyRecords.fold(
      0,
      (sum, r) => sum + r.studentCount,
    );
    final int periodCompanies = dailyRecords.fold(
      0,
      (sum, r) => sum + r.companyCount,
    );

    final activeDays = dailyRecords.where((r) => r.hasActivity).toList();
    DailyPlatformRecord? peakDay;
    for (final r in activeDays) {
      final score = r.studentCount + r.companyCount;
      final peakScore =
          peakDay == null ? -1 : peakDay.studentCount + peakDay.companyCount;
      if (score >= peakScore) {
        peakDay = r;
      }
    }

    final ratioLabel = _formatQuantityRatio(totalStudents, totalCompanies);
    final diff = totalStudents - totalCompanies;
    final comparisonSummary = diff > 0
        ? 'Students ahead by +$diff overall'
        : diff < 0
            ? 'Companies ahead by +${diff.abs()} overall'
            : 'Equal quantity overall';

    final cards = [
      _buildKpiCard(
        icon: Icons.school_rounded,
        accent: AppColors.primary,
        badgeText: '+$todayStudents Today',
        value: '$totalStudents',
        label: 'Total Students',
        subtitle: '$periodStudents joined in ${_selectedTimeframe.label}',
      ),
      _buildKpiCard(
        icon: Icons.business_rounded,
        accent: AppColors.accentTeal,
        badgeText: '+$todayCompanies Today',
        value: '$totalCompanies',
        label: 'Total Companies',
        subtitle: '$periodCompanies registered in ${_selectedTimeframe.label}',
      ),
      _buildKpiCard(
        icon: Icons.compare_arrows_rounded,
        accent: AppColors.indigoAccent,
        badgeText: 'Ratio $ratioLabel',
        value: '$totalStudents vs $totalCompanies',
        label: 'Students vs Companies',
        subtitle: comparisonSummary,
      ),
      _buildKpiCard(
        icon: Icons.event_note_rounded,
        accent: AppColors.success,
        badgeText: '${activeDays.length} Active Days',
        value: peakDay?.shortLabel ?? 'None',
        label: 'Peak Activity Day',
        subtitle: peakDay == null
            ? 'No registrations in selected window'
            : '${peakDay.studentCount} students • ${peakDay.companyCount} companies',
      ),
    ];

    if (width >= 1100) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    }

    if (width >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 14),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color accent,
    required String badgeText,
    required String value,
    required String label,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGraphsSection({
    required double width,
    required List<DailyPlatformRecord> dailyRecords,
  }) {
    final studentGroups = dailyRecords
        .map(
          (r) => BiBarDataGroup(
            label: r.shortLabel,
            value1: r.studentCount.toDouble(),
            value2: 0,
          ),
        )
        .toList();

    final companyGroups = dailyRecords
        .map(
          (r) => BiBarDataGroup(
            label: r.shortLabel,
            value1: r.companyCount.toDouble(),
            value2: 0,
          ),
        )
        .toList();

    final int periodStudents = dailyRecords.fold(
      0,
      (sum, r) => sum + r.studentCount,
    );
    final int periodCompanies = dailyRecords.fold(
      0,
      (sum, r) => sum + r.companyCount,
    );

    final int peakStudents = dailyRecords.fold<int>(
      0,
      (m, r) => math.max(m, r.studentCount),
    );
    final int peakCompanies = dailyRecords.fold<int>(
      0,
      (m, r) => math.max(m, r.companyCount),
    );

    final double avgStudents = dailyRecords.isEmpty
        ? 0
        : periodStudents / dailyRecords.length;
    final double avgCompanies = dailyRecords.isEmpty
        ? 0
        : periodCompanies / dailyRecords.length;

    final studentCard = _buildCardContainer(
      title: 'Daily Student Intake Graph',
      subtitle:
          'How many students joined each day (${_selectedTimeframe.label})',
      trailingBadge: '$periodStudents joined',
      trailingColor: AppColors.primary,
      child: Column(
        children: [
          _buildScrollableBarChart(
            groups: studentGroups,
            series1Label: 'Students Joined',
            series1Color: AppColors.primary,
            isPaired: false,
            height: 230,
          ),
          const SizedBox(height: 14),
          _buildMiniMetricsStrip([
            _buildMiniMetric('Window Total', '$periodStudents'),
            _buildMiniMetric(
              'Avg / Day',
              avgStudents.toStringAsFixed(1),
            ),
            _buildMiniMetric('Peak Day', '$peakStudents'),
            _buildMiniMetric(
              'Active Days',
              '${dailyRecords.where((r) => r.studentCount > 0).length}',
            ),
          ]),
        ],
      ),
    );

    final companyCard = _buildCardContainer(
      title: 'Daily Company Registrations Graph',
      subtitle:
          'How many companies registered each day (${_selectedTimeframe.label})',
      trailingBadge: '$periodCompanies registered',
      trailingColor: AppColors.accentTeal,
      child: Column(
        children: [
          _buildScrollableBarChart(
            groups: companyGroups,
            series1Label: 'Companies Registered',
            series1Color: AppColors.accentTeal,
            isPaired: false,
            height: 230,
          ),
          const SizedBox(height: 14),
          _buildMiniMetricsStrip([
            _buildMiniMetric('Window Total', '$periodCompanies'),
            _buildMiniMetric(
              'Avg / Day',
              avgCompanies.toStringAsFixed(1),
            ),
            _buildMiniMetric('Peak Day', '$peakCompanies'),
            _buildMiniMetric(
              'Active Days',
              '${dailyRecords.where((r) => r.companyCount > 0).length}',
            ),
          ]),
        ],
      ),
    );

    if (width >= 1024) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: studentCard),
          const SizedBox(width: 18),
          Expanded(child: companyCard),
        ],
      );
    }

    return Column(
      children: [
        studentCard,
        const SizedBox(height: 18),
        companyCard,
      ],
    );
  }

  Widget _buildQuantityComparisonSection({
    required double width,
    required List<DailyPlatformRecord> dailyRecords,
    required int totalStudents,
    required int totalCompanies,
  }) {
    final int combinedTotal = totalStudents + totalCompanies;
    final double studentShare =
        combinedTotal == 0 ? 0.0 : (totalStudents / combinedTotal) * 100.0;
    final double companyShare =
        combinedTotal == 0 ? 0.0 : (totalCompanies / combinedTotal) * 100.0;
    final int diff = totalStudents - totalCompanies;
    final String ratioText = _formatQuantityRatio(totalStudents, totalCompanies);

    final int periodStudents = dailyRecords.fold(
      0,
      (sum, r) => sum + r.studentCount,
    );
    final int periodCompanies = dailyRecords.fold(
      0,
      (sum, r) => sum + r.companyCount,
    );

    final pairedGroups = dailyRecords
        .map(
          (r) => BiBarDataGroup(
            label: r.shortLabel,
            value1: r.studentCount.toDouble(),
            value2: r.companyCount.toDouble(),
          ),
        )
        .toList();

    final cumulativePoints = dailyRecords
        .map(
          (r) => BiLineDataPoint(
            label: r.shortLabel,
            value1: r.totalStudentsToDate.toDouble(),
            value2: r.totalCompaniesToDate.toDouble(),
          ),
        )
        .toList();

    final ratioHeaderCard = _buildCardContainer(
      title: 'Students vs Companies Quantity Comparison',
      subtitle:
          'Direct head-to-head comparison of registered Student and Company quantities',
      trailingBadge: 'Ratio $ratioText',
      trailingColor: AppColors.indigoAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildComparisonSideBox(
                  title: 'Students',
                  count: totalStudents,
                  sharePct: studentShare,
                  periodDelta: periodStudents,
                  color: AppColors.primary,
                  icon: Icons.school_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonSideBox(
                  title: 'Companies',
                  count: totalCompanies,
                  sharePct: companyShare,
                  periodDelta: periodCompanies,
                  color: AppColors.accentTeal,
                  icon: Icons.business_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: combinedTotal == 0
                  ? Container(
                      color: AppColors.surfaceAlt,
                      alignment: Alignment.center,
                    )
                  : Row(
                      children: [
                        if (totalStudents > 0)
                          Expanded(
                            flex: totalStudents,
                            child: Container(color: AppColors.primary),
                          ),
                        if (totalStudents > 0 && totalCompanies > 0)
                          const SizedBox(width: 2),
                        if (totalCompanies > 0)
                          Expanded(
                            flex: totalCompanies,
                            child: Container(color: AppColors.accentTeal),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendBadge(
                color: AppColors.primary,
                text:
                    'Students: $totalStudents (${studentShare.toStringAsFixed(1)}%)',
              ),
              _buildLegendBadge(
                color: AppColors.accentTeal,
                text:
                    'Companies: $totalCompanies (${companyShare.toStringAsFixed(1)}%)',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.indigoAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diff > 0
                      ? 'Difference: +$diff more Students than Companies'
                      : diff < 0
                          ? 'Difference: +${diff.abs()} more Companies than Students'
                          : 'Difference: Equal quantities ($totalStudents each)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigoAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final dailyComparisonChart = _buildCardContainer(
      title: 'Daily Quantity Comparison (Students vs Companies)',
      subtitle:
          'Side-by-side daily registration counts for ${_selectedTimeframe.label}',
      trailingBadge: '$periodStudents vs $periodCompanies',
      trailingColor: AppColors.primary,
      child: _buildScrollableBarChart(
        groups: pairedGroups,
        series1Label: 'Students',
        series1Color: AppColors.primary,
        series2Label: 'Companies',
        series2Color: AppColors.accentTeal,
        isPaired: true,
        height: 245,
      ),
    );

    final cumulativeGrowthChart = _buildCardContainer(
      title: 'Cumulative Quantity Growth Curve',
      subtitle:
          'Total Students vs Total Companies accumulated day by day',
      trailingBadge: '$totalStudents / $totalCompanies Total',
      trailingColor: AppColors.success,
      child: BiLineChart(
        points: cumulativePoints,
        metric1Label: 'Total Students',
        metric1Color: AppColors.primary,
        metric2Label: 'Total Companies',
        metric2Color: AppColors.accentTeal,
        height: 245,
      ),
    );

    return Column(
      children: [
        ratioHeaderCard,
        const SizedBox(height: 18),
        if (width >= 1024)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dailyComparisonChart),
              const SizedBox(width: 18),
              Expanded(child: cumulativeGrowthChart),
            ],
          )
        else ...[
          dailyComparisonChart,
          const SizedBox(height: 18),
          cumulativeGrowthChart,
        ],
      ],
    );
  }

  Widget _buildComparisonSideBox({
    required String title,
    required int count,
    required double sharePct,
    required int periodDelta,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Text(
                '${sharePct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '+$periodDelta in ${_selectedTimeframe.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBadge({
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyLedgerSection({
    required bool isMobile,
    required List<DailyPlatformRecord> dailyRecords,
  }) {
    final allDesc = dailyRecords.reversed.toList();
    final activeDesc = allDesc.where((r) => r.hasActivity).toList();
    final filteredList = _onlyActivityDays ? activeDesc : allDesc;

    const int initialCap = 15;
    final bool hasMoreThanCap = filteredList.length > initialCap;
    final visibleList = _showAllLedgerDays || !hasMoreThanCap
        ? filteredList
        : filteredList.take(initialCap).toList();

    final todayKey = _formatDateKey(DateTime.now());

    return _buildCardContainer(
      title: 'Complete Day-by-Day Record Book',
      subtitle:
          'Every recorded day with Student arrivals, Company registrations, Projects created, and daily Student vs Company comparison',
      trailingBadge: '${filteredList.length} Days Listed',
      trailingColor: AppColors.darkNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('All Days (${allDesc.length})'),
                selected: !_onlyActivityDays,
                selectedColor: AppColors.darkNavy,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !_onlyActivityDays ? Colors.white : AppColors.textPrimary,
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() {
                    _onlyActivityDays = false;
                    _showAllLedgerDays = false;
                  });
                },
              ),
              ChoiceChip(
                label: Text('Activity Days Only (${activeDesc.length})'),
                selected: _onlyActivityDays,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _onlyActivityDays ? Colors.white : AppColors.textPrimary,
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() {
                    _onlyActivityDays = true;
                    _showAllLedgerDays = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visibleList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 30,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No activity recorded for this filter.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _onlyActivityDays
                        ? 'Switch to "All Days" to view every calendar date.'
                        : 'New student and company registrations will automatically appear here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else if (isMobile)
            Column(
              children: visibleList
                  .map(
                    (r) => _buildDailyMobileRecordCard(
                      record: r,
                      isToday: r.dateKey == todayKey,
                    ),
                  )
                  .toList(),
            )
          else
            _buildDesktopDailyTable(visibleList, todayKey),
          if (hasMoreThanCap) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _showAllLedgerDays = !_showAllLedgerDays);
                },
                icon: Icon(
                  _showAllLedgerDays
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  _showAllLedgerDays
                      ? 'Show Recent $initialCap Days'
                      : 'Show All ${filteredList.length} Days',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyMobileRecordCard({
    required DailyPlatformRecord record,
    required bool isToday,
  }) {
    final compText = _dailyComparisonLabel(record);
    final compColor = _dailyComparisonColor(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: record.hasActivity
            ? AppColors.primary.withValues(alpha: 0.025)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        record.fullDateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: compColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    compText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: compColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDayCountPill(
                  label: 'Students Joined',
                  daily: '+${record.studentCount}',
                  cumulative: 'Total: ${record.totalStudentsToDate}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDayCountPill(
                  label: 'Companies Reg.',
                  daily: '+${record.companyCount}',
                  cumulative: 'Total: ${record.totalCompaniesToDate}',
                  color: AppColors.accentTeal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDayCountPill(
                  label: 'Projects',
                  daily: '+${record.projectCount}',
                  cumulative: 'Daily',
                  color: AppColors.indigoAccent,
                ),
              ),
            ],
          ),
          if (record.studentNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Students: ${record.studentNames.join(', ')}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
          if (record.companyNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Companies: ${record.companyNames.join(', ')}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.darkNavy,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCountPill({
    required String label,
    required String daily,
    required String cumulative,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            daily,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            cumulative,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDailyTable(
    List<DailyPlatformRecord> records,
    String todayKey,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceAlt,
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STUDENTS JOINED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'COMPANIES REGISTERED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PROJECTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DAILY COMPARISON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _buildDesktopDailyRow(records[i], records[i].dateKey == todayKey),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopDailyRow(DailyPlatformRecord r, bool isToday) {
    final compText = _dailyComparisonLabel(r);
    final compColor = _dailyComparisonColor(r);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: r.hasActivity
          ? AppColors.primary.withValues(alpha: 0.02)
          : AppColors.cardSurface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.fullDateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  r.dateKey,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${r.studentCount}  (Total: ${r.totalStudentsToDate})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: r.studentCount > 0
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                if (r.studentNames.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    r.studentNames.join(', '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${r.companyCount}  (Total: ${r.totalCompaniesToDate})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: r.companyCount > 0
                        ? AppColors.accentTeal
                        : AppColors.textPrimary,
                  ),
                ),
                if (r.companyNames.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    r.companyNames.join(', '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              '+${r.projectCount}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: r.projectCount > 0
                    ? AppColors.indigoAccent
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: compColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  compText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: compColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableBarChart({
    required List<BiBarDataGroup> groups,
    required String series1Label,
    required Color series1Color,
    String? series2Label,
    Color series2Color = AppColors.accentTeal,
    required bool isPaired,
    required double height,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double minSlotWidth = isPaired ? 32.0 : 22.0;
        final double neededWidth = groups.length * minSlotWidth;
        final bool needsHorizontalScroll = neededWidth > constraints.maxWidth;

        final chart = BiBarChart(
          dataGroups: groups,
          series1Label: series1Label,
          series1Color: series1Color,
          series2Label: series2Label,
          series2Color: series2Color,
          height: height,
        );

        if (!needsHorizontalScroll || groups.isEmpty) {
          return chart;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: neededWidth,
                child: chart,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scroll horizontally to view all days',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardContainer({
    required String title,
    required String subtitle,
    String? trailingBadge,
    Color trailingColor = AppColors.primary,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: trailingColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trailingBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trailingColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMiniMetricsStrip(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runAlignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 10,
        children: children,
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

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatQuantityRatio(int students, int companies) {
    if (students == 0 && companies == 0) return '0 : 0';
    if (companies == 0) return '$students : 0';
    if (students == 0) return '0 : $companies';
    if (students >= companies) {
      return '${(students / companies).toStringAsFixed(1)} : 1';
    }
    return '1 : ${(companies / students).toStringAsFixed(1)}';
  }

  String _dailyComparisonLabel(DailyPlatformRecord r) {
    if (r.studentCount == 0 && r.companyCount == 0) {
      return 'No Signups';
    }
    if (r.studentCount > r.companyCount) {
      final delta = r.studentCount - r.companyCount;
      return 'Students +$delta (${r.studentCount} vs ${r.companyCount})';
    }
    if (r.companyCount > r.studentCount) {
      final delta = r.companyCount - r.studentCount;
      return 'Companies +$delta (${r.studentCount} vs ${r.companyCount})';
    }
    return 'Equal (${r.studentCount} vs ${r.companyCount})';
  }

  Color _dailyComparisonColor(DailyPlatformRecord r) {
    if (r.studentCount == 0 && r.companyCount == 0) {
      return AppColors.textMuted;
    }
    if (r.studentCount > r.companyCount) return AppColors.primary;
    if (r.companyCount > r.studentCount) return AppColors.accentTeal;
    return AppColors.indigoAccent;
  }
}
