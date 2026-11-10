import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.showDot = true,
  });

  static Color colorForStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('open') ||
        s.contains('active') ||
        s.contains('approved') ||
        s.contains('completed') ||
        s.contains('verified') ||
        s.contains('accepted') ||
        s.contains('valid') ||
        s.contains('resolved') ||
        s.contains('clear')) {
      return AppColors.statusOpen;
    }
    if (s.contains('shortlist') ||
        s.contains('in progress') ||
        s.contains('assigned') ||
        s.contains('submitted') ||
        s.contains('under review')) {
      return AppColors.primaryBlue;
    }
    if (s.contains('pending') ||
        s.contains('revision') ||
        s.contains('investigat') ||
        s.contains('not submitted') ||
        s.contains('draft') ||
        s.contains('paused')) {
      return AppColors.statusPending;
    }
    if (s.contains('reject') ||
        s.contains('suspend') ||
        s.contains('revoked') ||
        s.contains('flagged') ||
        s.contains('closed') ||
        s.contains('error')) {
      return AppColors.statusClosed;
    }
    return AppColors.grayText;
  }

  @override
  Widget build(BuildContext context) {
    final tone = color ?? colorForStatus(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.5, color: tone),
            const SizedBox(width: 5),
          ] else if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: tone,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
