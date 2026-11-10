import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = iconColor ?? AppColors.primaryBlue;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 28,
        vertical: compact ? 24 : 36,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 68,
            height: compact ? 52 : 68,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: tone.withValues(alpha: 0.18)),
            ),
            child: Icon(
              icon,
              size: compact ? 26 : 32,
              color: tone,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: compact ? 12.5 : 13.5,
                height: 1.45,
                color: AppColors.grayText,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? 14 : 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
