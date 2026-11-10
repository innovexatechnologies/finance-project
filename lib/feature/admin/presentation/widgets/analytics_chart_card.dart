import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';

/// Interactive Analytics Card with Trend Visualizer & Category Distribution
class AnalyticsChartCard extends StatefulWidget {
  final PlatformStatsModel stats;

  const AnalyticsChartCard({super.key, required this.stats});

  @override
  State<AnalyticsChartCard> createState() => _AnalyticsChartCardState();
}

class _AnalyticsChartCardState extends State<AnalyticsChartCard> {
  int _selectedMetricIndex = 0;
  int? _hoveredBarIndex;

  final List<String> _metrics = [
    'Student Registrations',
    'Company Registrations',
    'Projects Published',
    'Projects Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 900;

        if (isWidescreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildTrendsContainer()),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: _buildCategoryDistributionContainer()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildTrendsContainer(),
              const SizedBox(height: 20),
              _buildCategoryDistributionContainer(),
            ],
          );
        }
      },
    );
  }

  Widget _buildTrendsContainer() {
    final trends = widget.stats.trends;

    List<int> values = [];
    String metricUnit = '';
    Color themeColor = AppColors.primary;

    switch (_selectedMetricIndex) {
      case 0:
        values = trends.map((t) => t.students).toList();
        metricUnit = 'Students';
        themeColor = AppColors.primary;
        break;
      case 1:
        values = trends.map((t) => t.companies).toList();
        metricUnit = 'Companies';
        themeColor = AppColors.accentTeal;
        break;
      case 2:
        values = trends.map((t) => t.projectsCreated).toList();
        metricUnit = 'Projects';
        themeColor = AppColors.indigoAccent;
        break;
      case 3:
        values = trends.map((t) => t.projectsCompleted).toList();
        metricUnit = 'Completed';
        themeColor = AppColors.success;
        break;
    }

    final int maxValue = values.fold(0, (prev, curr) => curr > prev ? curr : prev);
    final int safeMax = maxValue > 0 ? maxValue : 1;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Growth & Velocity Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly registrations, listings & completions from database',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: themeColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _metrics[_selectedMetricIndex],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_metrics.length, (index) {
                final isSelected = _selectedMetricIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_metrics[index]),
                    selected: isSelected,
                    selectedColor: AppColors.darkNavy,
                    backgroundColor: AppColors.background,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMetricIndex = index);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          if (trends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: AppEmptyState(
                compact: true,
                icon: Icons.bar_chart_rounded,
                title: 'No Trend History Yet',
                subtitle:
                    'Monthly growth bars will populate automatically once users and projects are registered.',
              ),
            )
          else ...[
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(trends.length, (i) {
                  final heightFactor = values[i] == 0
                      ? 0.05
                      : (values[i] / safeMax).clamp(0.08, 1.0);
                  final isHovered = _hoveredBarIndex == i;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredBarIndex = i),
                        onExit: (_) => setState(() => _hoveredBarIndex = null),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: isHovered ? 1.0 : 0.7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? AppColors.darkNavy
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${values[i]}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isHovered
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              height: 120 * heightFactor,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    themeColor,
                                    themeColor.withValues(
                                      alpha: isHovered ? 0.9 : 0.65,
                                    ),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                boxShadow: isHovered
                                    ? [
                                        BoxShadow(
                                          color: themeColor.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, -2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trends[i].label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isHovered
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isHovered
                                    ? AppColors.darkNavy
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Peak volume: $maxValue $metricUnit (${trends.last.label})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live database metrics',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionContainer() {
    final categories = widget.stats.categoryDistribution;
    final int total = categories.values.fold(0, (sum, count) => sum + count);

    final colors = [
      AppColors.primary,
      AppColors.accentTeal,
      AppColors.indigoAccent,
      AppColors.warning,
      const Color(0xFFEC4899),
      AppColors.success,
    ];

    int colorIdx = 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Distribution',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posted project disciplines',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$total Projects',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (categories.isEmpty)
            const AppEmptyState(
              compact: true,
              icon: Icons.pie_chart_outline_rounded,
              title: 'No Project Categories Yet',
              subtitle:
                  'Category breakdown appears as companies publish new project sprints.',
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: categories.entries.map((entry) {
                    final color = colors[colorIdx % colors.length];
                    colorIdx++;
                    final double flex = (entry.value / (total == 0 ? 1 : total));
                    return Expanded(
                      flex: (flex * 100).round().clamp(1, 100),
                      child: Container(color: color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...categories.entries.map((entry) {
              final idx = categories.keys.toList().indexOf(entry.key);
              final color = colors[idx % colors.length];
              final percent =
                  total > 0 ? ((entry.value / total) * 100).toStringAsFixed(0) : '0';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entry.value} ($percent%)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
