import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  static const _quickRanges = [
    'Today',
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
    'Custom Range',
  ];

  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedQuickRange = 'Today';
  _ReportData? _reportData;
  DateTimeRange? _generatedRange;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today;
    _endDate = today;
    _loadReportData();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<bool> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = SupabaseHelper.clientOrNull;
      if (client == null) {
        throw StateError('Supabase is not configured for this application.');
      }

      final results = await Future.wait<List<Map<String, dynamic>>>([
        _fetchRows(client, 'students', 'id, created_at'),
        _fetchRows(client, 'companies', 'id, created_at'),
        _fetchRows(client, 'projects', 'id, created_at, status'),
      ]);
      final data = _ReportData(
        students: _recordsById(results[0]),
        companies: _recordsById(results[1]),
        projects: _recordsById(results[2], includeStatus: true),
      );

      if (!mounted) return false;
      setState(() {
        _reportData = data;
        _isLoading = false;
        _errorMessage = null;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load report data: $error';
      });
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    SupabaseClient client,
    String table,
    String columns,
  ) async {
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final page = await client
          .from(table)
          .select(columns)
          .order('id')
          .range(offset, offset + pageSize - 1);
      final mappedPage = page
          .map<Map<String, dynamic>>(
            (row) => Map<String, dynamic>.from(row as Map),
          )
          .toList();
      rows.addAll(mappedPage);
      if (mappedPage.length < pageSize) return rows;
      offset += mappedPage.length;
    }
  }

  List<_ReportRecord> _recordsById(
    List<Map<String, dynamic>> rows, {
    bool includeStatus = false,
  }) {
    final records = <String, _ReportRecord>{};
    for (final row in rows) {
      final id = row['id']?.toString().trim() ?? '';
      if (id.isEmpty) continue;

      records.putIfAbsent(
        id,
        () => _ReportRecord(
          id: id,
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')
              ?.toLocal(),
          status: includeStatus ? row['status']?.toString() : null,
        ),
      );
    }
    return records.values.toList(growable: false);
  }

  Future<void> _generateReport() async {
    final start = _dateOnly(_startDate);
    final end = _dateOnly(_endDate);
    if (start.isAfter(end)) {
      setState(() {
        _errorMessage = 'Start Date must be on or before End Date.';
      });
      return;
    }

    final loaded = await _loadReportData();
    if (!mounted || !loaded) return;
    setState(() {
      _generatedRange = DateTimeRange(start: start, end: end);
    });
  }

  void _selectQuickRange(String range) {
    final today = _dateOnly(DateTime.now());
    DateTime start;
    DateTime end = today;

    switch (range) {
      case 'Today':
        start = today;
      case 'This Week':
        start = today.subtract(Duration(days: today.weekday - 1));
      case 'This Month':
        start = DateTime(today.year, today.month);
      case 'Last Month':
        start = DateTime(today.year, today.month - 1);
        end = DateTime(
          today.year,
          today.month,
        ).subtract(const Duration(days: 1));
      case 'This Year':
        start = DateTime(today.year);
      case 'Custom Range':
        start = _startDate;
        end = _endDate;
      default:
        return;
    }

    setState(() {
      _selectedQuickRange = range;
      _startDate = start;
      _endDate = end;
      _errorMessage = null;
    });
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final currentDate = isStartDate ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1),
      lastDate: _dateOnly(DateTime.now()),
      helpText: isStartDate ? 'Select Start Date' : 'Select End Date',
    );
    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedQuickRange = 'Custom Range';
      if (isStartDate) {
        _startDate = _dateOnly(pickedDate);
      } else {
        _endDate = _dateOnly(pickedDate);
      }
      _errorMessage = null;
    });
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

    if (confirm != true) return;
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
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final data = _reportData;
    final generatedRange = _generatedRange;
    final rangedStats = data != null && generatedRange != null
        ? _ReportStats.fromData(data, generatedRange)
        : null;

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
                  onOpenDrawer: () =>
                      _scaffoldKey.currentState?.openEndDrawer(),
                  onSignOut: _handleSignOut,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(width < 680 ? 16 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPageHeading(),
                            if (_isLoading) ...[
                              const SizedBox(height: 16),
                              const LinearProgressIndicator(),
                            ],
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _buildErrorBanner(),
                            ],
                            const SizedBox(height: 24),
                            _buildSectionHeading(
                              title: 'Overall Statistics',
                              subtitle:
                                  'All-time totals across the entire platform',
                            ),
                            const SizedBox(height: 14),
                            _buildStatCards(
                              width: width,
                              stats: [
                                _StatItem(
                                  title: 'Total Students',
                                  value: data?.students.length,
                                  icon: Icons.school_rounded,
                                  color: AppColors.primary,
                                ),
                                _StatItem(
                                  title: 'Total Companies',
                                  value: data?.companies.length,
                                  icon: Icons.business_rounded,
                                  color: AppColors.accentTeal,
                                ),
                                _StatItem(
                                  title: 'Total Projects',
                                  value: data?.projects.length,
                                  icon: Icons.work_outline_rounded,
                                  color: AppColors.indigoAccent,
                                ),
                                _StatItem(
                                  title: 'Active Projects',
                                  value: data?.activeProjects,
                                  icon: Icons.play_circle_outline_rounded,
                                  color: AppColors.success,
                                ),
                                _StatItem(
                                  title: 'Completed Projects',
                                  value: data?.completedProjects,
                                  icon: Icons.task_alt_rounded,
                                  color: AppColors.accentTeal,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeading(
                              title: 'Date Range Filter',
                              subtitle: 'Choose a period to generate date-wise statistics and trends',
                            ),
                            const SizedBox(height: 14),
                            _buildDateFilter(),
                            const SizedBox(height: 28),
                            _buildSectionHeading(
                              title: 'Date-wise Statistics',
                              subtitle: generatedRange == null
                                  ? 'Generate a report to see records created in the selected period'
                                  : '${_formatDate(generatedRange.start)} – ${_formatDate(generatedRange.end)} (inclusive)',
                            ),
                            const SizedBox(height: 14),
                            if (rangedStats == null)
                              _buildReportPlaceholder()
                            else ...[
                              _buildStatCards(
                                width: width,
                                stats: [
                                  _StatItem(
                                    title: 'New Students',
                                    value: rangedStats.newStudents,
                                    icon: Icons.person_add_alt_1_rounded,
                                    color: AppColors.primary,
                                  ),
                                  _StatItem(
                                    title: 'New Companies',
                                    value: rangedStats.newCompanies,
                                    icon: Icons.add_business_rounded,
                                    color: AppColors.accentTeal,
                                  ),
                                  _StatItem(
                                    title: 'Total Projects',
                                    value: rangedStats.totalProjects,
                                    icon: Icons.work_outline_rounded,
                                    color: AppColors.indigoAccent,
                                  ),
                                  _StatItem(
                                    title: 'Active Projects',
                                    value: rangedStats.activeProjects,
                                    icon: Icons.play_circle_outline_rounded,
                                    color: AppColors.success,
                                  ),
                                  _StatItem(
                                    title: 'Completed Projects',
                                    value: rangedStats.completedProjects,
                                    icon: Icons.task_alt_rounded,
                                    color: AppColors.accentTeal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _buildSectionHeading(
                                title: 'Registration Trends',
                                subtitle: 'Student and company registrations over the selected period',
                              ),
                              const SizedBox(height: 14),
                              _buildTrendCharts(width, rangedStats),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
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

  Widget _buildPageHeading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Live platform statistics and registration trends',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards({
    required double width,
    required List<_StatItem> stats,
  }) {
    final columns = width >= 1300
        ? 5
        : width >= 900
        ? 3
        : width >= 380
        ? 2
        : 1;
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(width: cardWidth, child: _buildStatCard(stat)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(stat.icon, size: 20, color: stat.color),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            stat.value?.toString() ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 25,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick filters',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final range in _quickRanges)
                ChoiceChip(
                  label: Text(range),
                  selected: _selectedQuickRange == range,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: _selectedQuickRange == range
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedQuickRange == range
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  onSelected: (_) => _selectQuickRange(range),
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 540;
              final dateWidth = stack
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: dateWidth,
                    child: _buildDateButton(
                      label: 'Start Date',
                      date: _startDate,
                      onPressed: () => _pickDate(isStartDate: true),
                    ),
                  ),
                  SizedBox(
                    width: dateWidth,
                    child: _buildDateButton(
                      label: 'End Date',
                      date: _endDate,
                      onPressed: () => _pickDate(isStartDate: false),
                    ),
                  ),
                  SizedBox(
                    width: stack ? constraints.maxWidth : null,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _generateReport,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.assessment_outlined, size: 18),
                      label: Text(
                        _isLoading ? 'Loading Data...' : 'Generate Report',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.background,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCharts(double width, _ReportStats stats) {
    final chartCards = [
      _buildTrendCard(
        title: 'Students Registration Trend',
        subtitle: 'New student registrations by ${stats.bucketDescription}',
        color: AppColors.primary,
        points: stats.studentTrend,
      ),
      _buildTrendCard(
        title: 'Company Registration Trend',
        subtitle: 'New company registrations by ${stats.bucketDescription}',
        color: AppColors.accentTeal,
        points: stats.companyTrend,
      ),
    ];

    if (width >= 1000) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: chartCards[0]),
          const SizedBox(width: 16),
          Expanded(child: chartCards[1]),
        ],
      );
    }
    return Column(
      children: [chartCards[0], const SizedBox(height: 16), chartCards[1]],
    );
  }

  Widget _buildTrendCard({
    required String title,
    required String subtitle,
    required Color color,
    required List<_TrendPoint> points,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 14),
          if (points.every((point) => point.value == 0))
            SizedBox(
              height: 220,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 32,
                      color: color.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No registrations in this date range',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Semantics(
              label: '$title chart',
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RegistrationTrendPainter(
                    points: points,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.date_range_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            _isLoading
                ? 'Loading live report data...'
                : 'Select a date range and generate your report',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (!_isLoading)
            TextButton(onPressed: _loadReportData, child: const Text('Retry')),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ReportRecord {
  const _ReportRecord({required this.id, required this.createdAt, this.status});

  final String id;
  final DateTime? createdAt;
  final String? status;

  bool isCreatedWithin(DateTimeRange range) {
    final createdAt = this.createdAt;
    if (createdAt == null) return false;
    final localDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    return !localDate.isBefore(range.start) && !localDate.isAfter(range.end);
  }

  bool get isActiveProject {
    final normalized = (status ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    return normalized == 'active' ||
        normalized == 'in_progress' ||
        normalized == 'ongoing';
  }

  bool get isCompletedProject =>
      (status ?? '').trim().toLowerCase() == 'completed';
}

class _ReportData {
  const _ReportData({
    required this.students,
    required this.companies,
    required this.projects,
  });

  final List<_ReportRecord> students;
  final List<_ReportRecord> companies;
  final List<_ReportRecord> projects;

  int get activeProjects => projects.where((p) => p.isActiveProject).length;
  int get completedProjects =>
      projects.where((p) => p.isCompletedProject).length;
}

class _ReportStats {
  const _ReportStats({
    required this.newStudents,
    required this.newCompanies,
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.studentTrend,
    required this.companyTrend,
    required this.bucketDescription,
  });

  final int newStudents;
  final int newCompanies;
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final List<_TrendPoint> studentTrend;
  final List<_TrendPoint> companyTrend;
  final String bucketDescription;

  factory _ReportStats.fromData(_ReportData data, DateTimeRange range) {
    final students = data.students
        .where((record) => record.isCreatedWithin(range))
        .toList();
    final companies = data.companies
        .where((record) => record.isCreatedWithin(range))
        .toList();
    final projects = data.projects
        .where((record) => record.isCreatedWithin(range))
        .toList();
    final buckets = _buildBuckets(range);

    List<_TrendPoint> makeTrend(
      List<_ReportRecord> records,
      String Function(DateTime) labelFor,
    ) {
      return buckets
          .map((bucket) {
            final count = records.where((record) {
              final createdAt = record.createdAt;
              if (createdAt == null) return false;
              final date = DateTime(
                createdAt.year,
                createdAt.month,
                createdAt.day,
              );
              return !date.isBefore(bucket.start) && date.isBefore(bucket.end);
            }).length;
            return _TrendPoint(label: labelFor(bucket.start), value: count);
          })
          .toList(growable: false);
    }

    final days = range.end.difference(range.start).inDays + 1;
    final useDays = days <= 90;
    final useWeeks = days > 90 && days <= 730;
    final useMonths = days > 730 && days <= 3650;
    final bucketDescription = useDays
        ? 'day'
        : useWeeks
        ? 'week'
        : useMonths
        ? 'month'
        : 'year';

    String labelFor(DateTime date) {
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
      if (useDays || useWeeks) return '${date.day} ${months[date.month - 1]}';
      if (useMonths) return '${months[date.month - 1]} ${date.year}';
      return date.year.toString();
    }

    return _ReportStats(
      newStudents: students.length,
      newCompanies: companies.length,
      totalProjects: projects.length,
      activeProjects: projects.where((p) => p.isActiveProject).length,
      completedProjects: projects.where((p) => p.isCompletedProject).length,
      studentTrend: makeTrend(students, labelFor),
      companyTrend: makeTrend(companies, labelFor),
      bucketDescription: bucketDescription,
    );
  }

  static List<_DateBucket> _buildBuckets(DateTimeRange range) {
    final days = range.end.difference(range.start).inDays + 1;
    final dayStep = days <= 90
        ? 1
        : days <= 730
        ? 7
        : null;
    final buckets = <_DateBucket>[];
    var cursor = range.start;

    while (!cursor.isAfter(range.end)) {
      late final DateTime next;
      if (dayStep != null) {
        next = cursor.add(Duration(days: dayStep));
      } else if (days <= 3650) {
        next = DateTime(cursor.year, cursor.month + 1, 1);
      } else {
        next = DateTime(cursor.year + 1);
      }
      buckets.add(_DateBucket(start: cursor, end: next));
      cursor = next;
    }
    return buckets;
  }
}

class _DateBucket {
  const _DateBucket({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _TrendPoint {
  const _TrendPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class _StatItem {
  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int? value;
  final IconData icon;
  final Color color;
}

class _RegistrationTrendPainter extends CustomPainter {
  const _RegistrationTrendPainter({required this.points, required this.color});

  final List<_TrendPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 38.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 28.0;
    final chartWidth = math.max(1.0, size.width - left - right);
    final chartHeight = math.max(1.0, size.height - top - bottom);
    final maxValue = points.fold<int>(
      0,
      (maximum, point) => math.max(maximum, point.value),
    );
    final ceiling = math.max(4, maxValue);
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    for (var index = 0; index <= 4; index++) {
      final fraction = index / 4;
      final y = top + chartHeight * fraction;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final value = (ceiling * (1 - fraction)).round();
      labelPainter.text = TextSpan(
        text: '$value',
        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
      );
      labelPainter.layout(maxWidth: left - 6);
      labelPainter.paint(
        canvas,
        Offset(left - labelPainter.width - 6, y - labelPainter.height / 2),
      );
    }

    final path = Path();
    final stepX = points.length == 1 ? 0.0 : chartWidth / (points.length - 1);
    Offset pointAt(int index) {
      final x = points.length == 1
          ? left + chartWidth / 2
          : left + stepX * index;
      final y = top + chartHeight * (1 - points[index].value / ceiling);
      return Offset(x, y);
    }

    for (var index = 0; index < points.length; index++) {
      final point = pointAt(index);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (points.length <= 60) {
      final dotPaint = Paint()..color = color;
      final haloPaint = Paint()..color = Colors.white;
      for (var index = 0; index < points.length; index++) {
        final point = pointAt(index);
        canvas.drawCircle(point, 4.5, haloPaint);
        canvas.drawCircle(point, 3, dotPaint);
      }
    }

    final labelStep = (points.length / 5).ceil().clamp(1, points.length);
    for (var index = 0; index < points.length; index++) {
      if (index != 0 && index != points.length - 1 && index % labelStep != 0) {
        continue;
      }
      labelPainter.text = TextSpan(
        text: points[index].label,
        style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
      );
      labelPainter.layout(maxWidth: 52);
      final x = points.length == 1
          ? left + chartWidth / 2
          : left + stepX * index;
      final labelX = (x - labelPainter.width / 2).clamp(
        0.0,
        size.width - labelPainter.width,
      );
      labelPainter.paint(
        canvas,
        Offset(labelX, size.height - labelPainter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RegistrationTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
