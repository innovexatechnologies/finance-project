import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Shared SkillBridge brand emblem displaying the bundled logo asset with a
/// clean vector fallback when asset bundles are unavailable in isolated tests.
class SkillBridgeLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool circular;
  final List<BoxShadow>? shadows;
  final Border? border;

  const SkillBridgeLogo({
    super.key,
    this.size = 76,
    this.borderRadius = 20,
    this.circular = true,
    this.shadows,
    this.border,
  });

  static const String assetPath = 'assets/skillbridge.png';

  @override
  Widget build(BuildContext context) {
    final radius = circular
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(borderRadius);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F2344),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : radius,
        border: border ??
            Border.all(
              color: AppColors.teal.withValues(alpha: 0.45),
              width: 1.5,
            ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          cacheWidth: (size * 2).round(),
          cacheHeight: (size * 2).round(),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Icon(
              Icons.hub_rounded,
              size: size * 0.48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

