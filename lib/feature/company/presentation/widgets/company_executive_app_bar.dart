import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';

export 'package:link_vibe/core/widgets/executive_ui.dart';

typedef CompanyExecutiveAppBar = ExecutiveAppBar;
typedef CompanyHeaderIconButton = ExecutiveHeaderIconButton;
typedef CompanyHeaderPillButton = ExecutiveHeaderPillButton;
typedef CompanyHeroBanner = ExecutiveHeroBanner;
typedef CompanySectionCard = ExecutiveSectionCard;

/// Framed 42x42 hamburger toggle button matching the Company Home AppBar drawer trigger.
class CompanyDrawerMenuButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDrawerOpen;

  const CompanyDrawerMenuButton({
    super.key,
    required this.onPressed,
    this.isDrawerOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDrawerOpen ? AppColors.lightAqua : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDrawerOpen
                  ? AppColors.primaryBlue.withValues(alpha: 0.45)
                  : AppColors.borderLight,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              isDrawerOpen ? Icons.close_rounded : Icons.menu_rounded,
              key: ValueKey<bool>(isDrawerOpen),
              color: AppColors.deepNavy,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
