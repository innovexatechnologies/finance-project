import 'dart:math';
import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Data model for paired bar entries
class BiBarDataGroup {
  final String label;
  final double value1; // First series (e.g. Published / Approved)
  final double value2; // Second series (e.g. Completed / Rejected)

  const BiBarDataGroup({
    required this.label,
    required this.value1,
    required this.value2,
  });
}

/// Interactive Enterprise Grouped Bar Comparison Chart
class BiBarChart extends StatefulWidget {
  final List<BiBarDataGroup> dataGroups;
  final String series1Label;
  final Color series1Color;
  final String series2Label;
  final Color series2Color;
  final double height;

  const BiBarChart({
    super.key,
    required this.dataGroups,
    required this.series1Label,
    this.series1Color = const Color(0xFF6366F1), // Indigo
    required this.series2Label,
    this.series2Color = AppColors.success,
    this.height = 240,
  });

  @override
  State<BiBarChart> createState() => _BiBarChartState();
}

class _BiBarChartState extends State<BiBarChart> {
  int? _hoveredGroupIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dataGroups.isEmpty) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        child: const Text('No bar data available'),
      );
    }

    double maxVal = 10;
    for (final g in widget.dataGroups) {
      maxVal = max(maxVal, max(g.value1, g.value2));
    }
    final double yCeiling = (maxVal * 1.2).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _buildLegendPill(widget.series1Label, widget.series1Color),
            const SizedBox(width: 16),
            _buildLegendPill(widget.series2Label, widget.series2Color),
          ],
        ),
        const SizedBox(height: 16),

        // Chart Canvas Area
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return MouseRegion(
                onHover: (event) {
                  const leftPad = 40.0;
                  final chartWidth = width - leftPad;
                  final localX = event.localPosition.dx - leftPad;
                  if (localX >= 0 && localX <= chartWidth) {
                    final groupWidth = chartWidth / widget.dataGroups.length;
                    final idx = (localX / groupWidth).floor().clamp(0, widget.dataGroups.length - 1);
                    if (_hoveredGroupIndex != idx) {
                      setState(() => _hoveredGroupIndex = idx);
                    }
                  }
                },
                onExit: (_) => setState(() => _hoveredGroupIndex = null),
                child: CustomPaint(
                  size: Size(width, widget.height),
                  painter: _BarChartPainter(
                    groups: widget.dataGroups,
                    yCeiling: yCeiling,
                    series1Color: widget.series1Color,
                    series2Color: widget.series2Color,
                    hoveredIndex: _hoveredGroupIndex,
                  ),
                ),
              );
            },
          ),
        ),

        // Hover tooltip
        if (_hoveredGroupIndex != null && _hoveredGroupIndex! < widget.dataGroups.length) ...[
          const SizedBox(height: 8),
          _buildTooltipPill(widget.dataGroups[_hoveredGroupIndex!]),
        ],
      ],
    );
  }

  Widget _buildLegendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTooltipPill(BiBarDataGroup g) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${g.label}: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.series1Color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('${widget.series1Label}: ${g.value1.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(width: 10),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.series2Color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('${widget.series2Label}: ${g.value2.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<BiBarDataGroup> groups;
  final double yCeiling;
  final Color series1Color;
  final Color series2Color;
  final int? hoveredIndex;

  _BarChartPainter({
    required this.groups,
    required this.yCeiling,
    required this.series1Color,
    required this.series2Color,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const bottomPad = 26.0;
    const topPad = 12.0;

    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - bottomPad - topPad;

    // 1. Gridlines
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const divisions = 4;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= divisions; i++) {
      final y = topPad + (chartHeight / divisions) * i;
      final val = (yCeiling * (1 - (i / divisions))).round();

      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPad - textPainter.width - 6, y - (textPainter.height / 2)));
    }

    if (groups.isEmpty) return;

    final groupStep = chartWidth / groups.length;
    final barWidth = (groupStep * 0.32).clamp(8.0, 28.0);
    const barGap = 4.0;

    for (int i = 0; i < groups.length; i++) {
      final g = groups[i];
      final groupCenterX = leftPad + (i * groupStep) + (groupStep / 2);
      final isHovered = hoveredIndex == i;

      // Group hover background highlight
      if (isHovered) {
        final highlightPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.05);
        canvas.drawRect(
          Rect.fromLTWH(leftPad + (i * groupStep), topPad, groupStep, chartHeight),
          highlightPaint,
        );
      }

      // Bar 1
      final h1 = (g.value1 / yCeiling).clamp(0.0, 1.0) * chartHeight;
      final bar1X = groupCenterX - barWidth - (barGap / 2);
      final bar1Y = topPad + chartHeight - h1;
      final bar1Rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(bar1X, bar1Y, barWidth, h1),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final paint1 = Paint()..color = isHovered ? series1Color : series1Color.withValues(alpha: 0.88);
      canvas.drawRRect(bar1Rect, paint1);

      // Bar 2
      final h2 = (g.value2 / yCeiling).clamp(0.0, 1.0) * chartHeight;
      final bar2X = groupCenterX + (barGap / 2);
      final bar2Y = topPad + chartHeight - h2;
      final bar2Rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(bar2X, bar2Y, barWidth, h2),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final paint2 = Paint()..color = isHovered ? series2Color : series2Color.withValues(alpha: 0.88);
      canvas.drawRRect(bar2Rect, paint2);

      // X-axis label
      textPainter.text = TextSpan(
        text: g.label,
        style: TextStyle(
          color: isHovered ? AppColors.textPrimary : AppColors.textMuted,
          fontSize: 10,
          fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(groupCenterX - (textPainter.width / 2), size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.groups != groups ||
        oldDelegate.yCeiling != yCeiling;
  }
}
