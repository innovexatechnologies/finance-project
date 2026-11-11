import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Crisp white executive header bar shared across Company secondary screens,
/// featuring a framed back/close action, clean title hierarchy, and hairline divider.
class CompanyExecutiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final VoidCallback? onLeadingPressed;
  final Widget? leadingBadge;
  final List<Widget>? actions;

  const CompanyExecutiveAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon = Icons.arrow_back_ios_new_rounded,
    this.onLeadingPressed,
    this.leadingBadge,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 61,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                CompanyHeaderIconButton(
                  icon: leadingIcon,
                  tooltip: leadingIcon == Icons.close_rounded ? 'Close' : 'Back',
                  onPressed:
                      onLeadingPressed ?? () => Navigator.maybePop(context),
                ),
                if (leadingBadge != null) ...[
                  const SizedBox(width: 10),
                  leadingBadge!,
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                          height: 1.15,
                          letterSpacing: -0.25,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.grayText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Framed 38x38 rounded square icon action matching the Home portal chrome.
class CompanyHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const CompanyHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final fg = isDisabled
        ? AppColors.textMuted
        : (iconColor ?? AppColors.deepNavy);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? AppColors.background,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onPressed,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: borderColor ?? AppColors.borderLight,
              ),
            ),
            child: Icon(icon, size: 18.5, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Compact pill button placed cleanly inside [CompanyExecutiveAppBar.actions].
class CompanyHeaderPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool filled;

  const CompanyHeaderPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryBlue : AppColors.background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onPressed,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: filled
                ? null
                : Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: filled ? Colors.white : AppColors.primaryBlue,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : AppColors.deepNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable corporate hero card aligned with the dashboard welcome aesthetic.
class CompanyHeroBanner extends StatelessWidget {
  final String initial;
  final Color monogramColor;
  final bool monogramTextOnWhite;
  final String title;
  final String subtitle;
  final String? secondaryLine;
  final String? footerText;
  final Widget? bottomContent;
  final Widget? trailingAction;
  final Widget? monogramBadgeOverlay;
  final VoidCallback? onMonogramTap;

  const CompanyHeroBanner({
    super.key,
    required this.initial,
    required this.title,
    required this.subtitle,
    this.monogramColor = Colors.white,
    this.monogramTextOnWhite = true,
    this.secondaryLine,
    this.footerText,
    this.bottomContent,
    this.trailingAction,
    this.monogramBadgeOverlay,
    this.onMonogramTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -34,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 70,
              bottom: -44,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onMonogramTap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: monogramColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.poppins(
                                    color: monogramTextOnWhite
                                        ? AppColors.deepNavy
                                        : Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            if (monogramBadgeOverlay != null)
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: monogramBadgeOverlay!,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (secondaryLine != null &&
                                secondaryLine!.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 13.5,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      secondaryLine!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailingAction != null) ...[
                        const SizedBox(width: 8),
                        trailingAction!,
                      ],
                    ],
                  ),
                  if (bottomContent != null) ...[
                    const SizedBox(height: 16),
                    bottomContent!,
                  ],
                  if (footerText != null && footerText!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        footerText!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared corporate surface card with a framed header icon and subtle shadow.
class CompanySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CompanySectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor = AppColors.primaryBlue,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
