import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';

/// Interactive Analytics Card with Trend Visualizer & Category Distribution
class AnalyticsChartCard extends StatefulWidget {
  final PlatformStatsModel stats;

  const AnalyticsChartCard({super.key, required this.stats});

  @override
  State<AnalyticsChartCard> createState() => _AnalyticsChartCardState();
}

class _AnalyticsChartCardState extends State<AnalyticsChartCard> {
  int _selectedMetricIndex = 0; // 0: Students, 1: Companies, 2: Projects Created, 3: Completed
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
              // Left: Monthly Trends Interactive Chart (60% width)
              Expanded(
                flex: 6,
                child: _buildTrendsContainer(),
              ),
              const SizedBox(width: 20),

              // Right: Category Distribution (40% width)
              Expanded(
                flex: 4,
                child: _buildCategoryDistributionContainer(),
              ),
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

  // 1. Monthly Trends Chart Container
  Widget _buildTrendsContainer() {
    final trends = widget.stats.trends;

    // Determine values according to selected metric tab
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
        metricUnit = 'Sprints';
        themeColor = const Color(0xFF6366F1); // Indigo
        break;
      case 3:
        values = trends.map((t) => t.projectsCompleted).toList();
        metricUnit = 'Completed';
        themeColor = AppColors.success;
        break;
    }

    final int maxValue = values.fold(1, (prev, curr) => curr > prev ? curr : prev);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Metric Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Growth & Velocity Trends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Historical verification & activity progression',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // Interactive Legend Badge
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
                    Text(
                      _metrics[_selectedMetricIndex],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metric Tab Selector Chips
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
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

          // Interactive Bars Visualization with Tooltips
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(trends.length, (i) {
                final heightFactor = (values[i] / maxValue).clamp(0.08, 1.0);
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
                          // Tooltip / Number on Hover
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: isHovered ? 1.0 : 0.6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHovered ? AppColors.darkNavy : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${values[i]}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isHovered ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Animated Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: 120 * heightFactor,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeColor,
                                  themeColor.withValues(alpha: isHovered ? 0.9 : 0.65),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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

                          // Month Label
                          Text(
                            trends[i].label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
                              color: isHovered ? AppColors.darkNavy : AppColors.textSecondary,
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

          // Footnote summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peak volume: ${maxValue.toString()} $metricUnit (${trends.last.label})',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const Text(
                '• Continuous verification enabled',
                style: TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Project Category Distribution Container
  Widget _buildCategoryDistributionContainer() {
    final categories = widget.stats.categoryDistribution;
    final int total = categories.values.fold(0, (sum, count) => sum + count);

    final colors = [
      AppColors.primary,
      AppColors.accentTeal,
      const Color(0xFF8B5CF6), // Purple
      AppColors.warning,
      const Color(0xFFEC4899), // Pink
      AppColors.success,
    ];

    int colorIdx = 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Active student sprint disciplines',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  '$total Sprints',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Multi-segmented Progress Bar
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

          // Categories List with Percentages
          ...categories.entries.map((entry) {
            final color = colors[(categories.keys.toList().indexOf(entry.key)) % colors.length];
            final percent = total > 0 ? ((entry.value / total) * 100).toStringAsFixed(0) : '0';

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
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.value} (${percent}%)',
                    style: const TextStyle(
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
      ),
    );
  }
}
