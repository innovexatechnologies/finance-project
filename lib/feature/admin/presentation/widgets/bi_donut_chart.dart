import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';

/// Data item for the BI Donut Chart
class BiDonutSegment {
  final String label;
  final double value;
  final Color color;
  final String? subtitle;

  const BiDonutSegment({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });
}

/// Interactive Enterprise Donut Chart with Hover Focus, Center Metric, and Dynamic Legend
class BiDonutChart extends StatefulWidget {
  final List<BiDonutSegment> segments;
  final String centerTitle;
  final String? centerSubtitle;
  final double chartRadius;
  final double strokeWidth;

  const BiDonutChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    this.centerSubtitle,
    this.chartRadius = 85,
    this.strokeWidth = 24,
  });

  @override
  State<BiDonutChart> createState() => _BiDonutChartState();
}

class _BiDonutChartState extends State<BiDonutChart> {
  int? _hoveredSegmentIndex;

  @override
  Widget build(BuildContext context) {
    final double totalValue =
        widget.segments.fold(0.0, (sum, item) => sum + item.value);

    if (widget.segments.isEmpty || totalValue <= 0) {
      return const AppEmptyState(
        compact: true,
        icon: Icons.donut_large_rounded,
        title: 'No Distribution Data',
        subtitle: 'Breakdown segments will display here once records exist.',
      );
    }

    String centerPrimaryText = widget.centerTitle;
    String centerSubText = widget.centerSubtitle ?? '${totalValue.toInt()} Total';

    if (_hoveredSegmentIndex != null &&
        _hoveredSegmentIndex! < widget.segments.length &&
        totalValue > 0) {
      final seg = widget.segments[_hoveredSegmentIndex!];
      final pct = ((seg.value / totalValue) * 100).toStringAsFixed(1);
      centerPrimaryText = '$pct%';
      centerSubText = seg.label;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        Widget chartCore = SizedBox(
          width: widget.chartRadius * 2,
          height: widget.chartRadius * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.chartRadius * 2, widget.chartRadius * 2),
                painter: _DonutChartPainter(
                  segments: widget.segments,
                  totalValue: totalValue,
                  strokeWidth: widget.strokeWidth,
                  hoveredIndex: _hoveredSegmentIndex,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerPrimaryText,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: widget.chartRadius * 1.3,
                    child: Text(
                      centerSubText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        Widget legend = _buildLegend(totalValue);

        if (isNarrow) {
          return Column(
            children: [
              chartCore,
              const SizedBox(height: 18),
              legend,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              chartCore,
              const SizedBox(width: 24),
              Expanded(child: legend),
            ],
          );
        }
      },
    );
  }

  Widget _buildLegend(double totalValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.segments.length, (index) {
        final seg = widget.segments[index];
        final pct = totalValue > 0
            ? ((seg.value / totalValue) * 100).toStringAsFixed(1)
            : '0';
        final isHovered = _hoveredSegmentIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredSegmentIndex = index),
          onExit: (_) => setState(() => _hoveredSegmentIndex = null),
          child: InkWell(
            onTap: () {
              setState(() {
                _hoveredSegmentIndex =
                    _hoveredSegmentIndex == index ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isHovered ? AppColors.background : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: seg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seg.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isHovered ? FontWeight.bold : FontWeight.w500,
                        color: isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${seg.value.toInt()} ($pct%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<BiDonutSegment> segments;
  final double totalValue;
  final double strokeWidth;
  final int? hoveredIndex;

  _DonutChartPainter({
    required this.segments,
    required this.totalValue,
    required this.strokeWidth,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalValue <= 0 || segments.isEmpty) {
      final emptyPaint = Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - strokeWidth) / 2,
        emptyPaint,
      );
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width - strokeWidth) / 2;

    double startAngle = -pi / 2;
    final nonZeroCount = segments.where((s) => s.value > 0).length;
    final double gapAngle = nonZeroCount > 1 ? 0.04 : 0.0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / totalValue) * (2 * pi);

      if (sweepAngle <= gapAngle) continue;

      final isHovered = hoveredIndex == i;
      final currentStroke = isHovered ? strokeWidth + 4 : strokeWidth;
      final currentRadius = isHovered ? baseRadius + 2 : baseRadius;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = nonZeroCount > 1 ? StrokeCap.round : StrokeCap.butt;

      final rect = Rect.fromCircle(center: center, radius: currentRadius);
      canvas.drawArc(
        rect,
        startAngle + (gapAngle / 2),
        sweepAngle - gapAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.totalValue != totalValue ||
        oldDelegate.segments != segments;
  }
}
