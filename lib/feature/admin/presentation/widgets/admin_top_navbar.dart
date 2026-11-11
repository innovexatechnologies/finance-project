import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';

/// Clean Enterprise Top Navigation Bar with Admin Session Badge
class AdminTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final String? breadcrumb;
  final VoidCallback onOpenDrawer;
  final VoidCallback onSignOut;
  final ValueChanged<String>? onSearch;

  const AdminTopNavbar({
    super.key,
    required this.pageTitle,
    this.breadcrumb = 'Console',
    required this.onOpenDrawer,
    required this.onSignOut,
    this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return ValueListenableBuilder<AdminUserModel?>(
      valueListenable: AdminAuthService().currentAdminNotifier,
      builder: (context, currentAdmin, _) {
        final admin = currentAdmin ??
            const AdminUserModel(
              id: 'adm_root',
              fullName: 'Executive Administrator',
              email: 'admin@skillbridge.edu.pk',
              role: 'SUPER_ADMIN',
              roleDisplayName: 'Executive Super Administrator',
              department: 'SkillBridge Governance Council',
              avatarInitial: 'EA',
              permissions: ['all'],
              lastLoginAt: 'Active Session',
            );

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.darkNavy),
                  onPressed: onOpenDrawer,
                  tooltip: 'Open Navigation Menu',
                ),
                const SizedBox(width: 8),
              ],

              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            breadcrumb ?? 'Admin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Text(
                          ' / ',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Flexible(
                          child: Text(
                            pageTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pageTitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              if (isDesktop && onSearch != null)
                Container(
                  width: 260,
                  height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search companies, students, projects...',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

              if (MediaQuery.of(context).size.width >= 540) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3.5, backgroundColor: AppColors.success),
                      SizedBox(width: 6),
                      Text(
                        'Live Database',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              PopupMenuButton<String>(
                tooltip: 'Administrator Account',
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) {
                  if (val == 'logout') {
                    onSignOut();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin.fullName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          admin.email,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightIceBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            admin.roleDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text(
                          'Sign Out Session',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.darkNavy,
                    child: Text(
                      admin.avatarInitial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
