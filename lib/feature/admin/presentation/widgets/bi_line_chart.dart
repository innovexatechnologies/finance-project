import 'dart:math';
import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Data model for a point in the BI Line Chart
class BiLineDataPoint {
  final String label;
  final double value1; // Primary metric (e.g. Students)
  final double value2; // Secondary metric (e.g. Companies)
  final double? value3; // Tertiary metric (e.g. Applications)

  const BiLineDataPoint({
    required this.label,
    required this.value1,
    required this.value2,
    this.value3,
  });
}

/// Interactive Business Intelligence Multi-Line Trend Chart
class BiLineChart extends StatefulWidget {
  final List<BiLineDataPoint> points;
  final String metric1Label;
  final Color metric1Color;
  final String metric2Label;
  final Color metric2Color;
  final String? metric3Label;
  final Color? metric3Color;
  final double height;

  const BiLineChart({
    super.key,
    required this.points,
    required this.metric1Label,
    this.metric1Color = AppColors.primary,
    required this.metric2Label,
    this.metric2Color = AppColors.accentTeal,
    this.metric3Label,
    this.metric3Color,
    this.height = 260,
  });

  @override
  State<BiLineChart> createState() => _BiLineChartState();
}

class _BiLineChartState extends State<BiLineChart> {
  int? _hoveredIndex;
  bool _showSeries1 = true;
  bool _showSeries2 = true;
  bool _showSeries3 = true;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        child: const Text('No data available for selected timeframe'),
      );
    }

    // Determine max value for Y axis scaling
    double maxVal = 10;
    for (final p in widget.points) {
      if (_showSeries1) maxVal = max(maxVal, p.value1);
      if (_showSeries2) maxVal = max(maxVal, p.value2);
      if (_showSeries3 && p.value3 != null) maxVal = max(maxVal, p.value3!);
    }
    // Round maxVal upwards to nice interval
    final double yCeiling = (maxVal * 1.15).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend & Series Visibility Toggles
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendToggle(
              label: widget.metric1Label,
              color: widget.metric1Color,
              isActive: _showSeries1,
              onTap: () => setState(() => _showSeries1 = !_showSeries1),
            ),
            _buildLegendToggle(
              label: widget.metric2Label,
              color: widget.metric2Color,
              isActive: _showSeries2,
              onTap: () => setState(() => _showSeries2 = !_showSeries2),
            ),
            if (widget.metric3Label != null && widget.metric3Color != null)
              _buildLegendToggle(
                label: widget.metric3Label!,
                color: widget.metric3Color!,
                isActive: _showSeries3,
                onTap: () => setState(() => _showSeries3 = !_showSeries3),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Chart Canvas Area with gesture/hover detection
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return MouseRegion(
                onHover: (event) {
                  final chartWidth = width - 40; // left padding for Y axis
                  final localX = event.localPosition.dx - 40;
                  if (localX >= 0 && localX <= chartWidth) {
                    final segmentWidth = chartWidth / (widget.points.length - 1);
                    final index = (localX / segmentWidth).round().clamp(0, widget.points.length - 1);
                    if (_hoveredIndex != index) {
                      setState(() => _hoveredIndex = index);
                    }
                  }
                },
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: CustomPaint(
                  size: Size(width, widget.height),
                  painter: _BiLineChartPainter(
                    points: widget.points,
                    yCeiling: yCeiling,
                    metric1Color: widget.metric1Color,
                    metric2Color: widget.metric2Color,
                    metric3Color: widget.metric3Color ?? Colors.amber,
                    showSeries1: _showSeries1,
                    showSeries2: _showSeries2,
                    showSeries3: _showSeries3,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
              );
            },
          ),
        ),

        // Hover Tooltip Display Pill below if hovered
        if (_hoveredIndex != null && _hoveredIndex! < widget.points.length) ...[
          const SizedBox(height: 10),
          _buildHoverTooltip(widget.points[_hoveredIndex!]),
        ],
      ],
    );
  }

  Widget _buildLegendToggle({
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoverTooltip(BiLineDataPoint p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${p.label}: ',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (_showSeries1) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.metric1Color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              '${widget.metric1Label}: ${p.value1.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 12),
          ],
          if (_showSeries2) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.metric2Color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              '${widget.metric2Label}: ${p.value2.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 12),
          ],
          if (_showSeries3 && p.value3 != null && widget.metric3Label != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.metric3Color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              '${widget.metric3Label}: ${p.value3!.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _BiLineChartPainter extends CustomPainter {
  final List<BiLineDataPoint> points;
  final double yCeiling;
  final Color metric1Color;
  final Color metric2Color;
  final Color metric3Color;
  final bool showSeries1;
  final bool showSeries2;
  final bool showSeries3;
  final int? hoveredIndex;

  _BiLineChartPainter({
    required this.points,
    required this.yCeiling,
    required this.metric1Color,
    required this.metric2Color,
    required this.metric3Color,
    required this.showSeries1,
    required this.showSeries2,
    required this.showSeries3,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const bottomPad = 26.0;
    const topPad = 12.0;

    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - bottomPad - topPad;

    // 1. Draw horizontal gridlines & Y axis values
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const divisions = 4;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= divisions; i++) {
      final y = topPad + (chartHeight / divisions) * i;
      final val = (yCeiling * (1 - (i / divisions))).round();

      // Horizontal dashed/subtle line
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      // Label
      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPad - textPainter.width - 6, y - (textPainter.height / 2)));
    }

    if (points.length < 2) return;

    final stepX = chartWidth / (points.length - 1);

    // 2. Draw X-axis date labels
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + (i * stepX);
      textPainter.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          color: hoveredIndex == i ? AppColors.textPrimary : AppColors.textMuted,
          fontSize: 10,
          fontWeight: hoveredIndex == i ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 18));
    }

    // Helper to calculate (x, y) coordinates
    Offset getCoord(int i, double val) {
      final x = leftPad + (i * stepX);
      final normalizedVal = (val / yCeiling).clamp(0.0, 1.0);
      final y = topPad + chartHeight * (1 - normalizedVal);
      return Offset(x, y);
    }

    // 3. Draw Vertical Crosshair if hovered
    if (hoveredIndex != null && hoveredIndex! < points.length) {
      final crossX = leftPad + (hoveredIndex! * stepX);
      final crossPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(crossX, topPad), Offset(crossX, topPad + chartHeight), crossPaint);
    }

    // 4. Draw Line Series
    void drawSeries(List<double> values, Color color, bool filled) {
      final path = Path();
      final fillPath = Path();

      final firstPoint = getCoord(0, values[0]);
      path.moveTo(firstPoint.dx, firstPoint.dy);
      fillPath.moveTo(firstPoint.dx, topPad + chartHeight);
      fillPath.lineTo(firstPoint.dx, firstPoint.dy);

      for (int i = 0; i < values.length - 1; i++) {
        final current = getCoord(i, values[i]);
        final next = getCoord(i + 1, values[i + 1]);

        // Smooth cubic Bézier interpolation
        final controlX1 = current.dx + (next.dx - current.dx) / 2;
        final controlY1 = current.dy;
        final controlX2 = current.dx + (next.dx - current.dx) / 2;
        final controlY2 = next.dy;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, next.dx, next.dy);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, next.dx, next.dy);
      }

      final last = getCoord(values.length - 1, values.last);
      fillPath.lineTo(last.dx, topPad + chartHeight);
      fillPath.close();

      // Shaded area under primary line
      if (filled) {
        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.01),
            ],
          ).createShader(Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight));
        canvas.drawPath(fillPath, fillPaint);
      }

      // Line Stroke
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, strokePaint);

      // Data Point Dots
      final dotPaint = Paint()..color = color;
      final whitePaint = Paint()..color = Colors.white;

      for (int i = 0; i < values.length; i++) {
        final pt = getCoord(i, values[i]);
        final isHovered = hoveredIndex == i;
        final radius = isHovered ? 6.0 : 3.5;

        canvas.drawCircle(pt, radius + 1.5, whitePaint);
        canvas.drawCircle(pt, radius, dotPaint);
      }
    }

    if (showSeries1) {
      drawSeries(points.map((p) => p.value1).toList(), metric1Color, true);
    }
    if (showSeries2) {
      drawSeries(points.map((p) => p.value2).toList(), metric2Color, false);
    }
    if (showSeries3 && points.first.value3 != null) {
      drawSeries(points.map((p) => p.value3 ?? 0).toList(), metric3Color, false);
    }
  }

  @override
  bool shouldRepaint(covariant _BiLineChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.showSeries1 != showSeries1 ||
        oldDelegate.showSeries2 != showSeries2 ||
        oldDelegate.showSeries3 != showSeries3 ||
        oldDelegate.points != points;
  }
}
