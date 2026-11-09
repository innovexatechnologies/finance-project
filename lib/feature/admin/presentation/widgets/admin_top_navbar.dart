import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';

/// Clean, modern Enterprise Top Navigation Bar
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

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Administrative Alerts (3)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss All'),
                ),
              ],
            ),
            const Divider(),
            _buildNotificationItem(
              title: 'New SECP Verification Request',
              description: 'TechVista Innovations submitted corporate registration certificate.',
              time: '15 mins ago',
              color: AppColors.warning,
              icon: Icons.domain_verification_rounded,
            ),
            _buildNotificationItem(
              title: 'Student Credential Sync',
              description: 'FAST-NUCES batch validation completed for 42 student profiles.',
              time: '1 hour ago',
              color: AppColors.primary,
              icon: Icons.school_rounded,
            ),
            _buildNotificationItem(
              title: 'Audit Vault Backup',
              description: 'Automated encrypted cryptographic snapshot finalized.',
              time: '3 hours ago',
              color: AppColors.success,
              icon: Icons.shield_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required String time,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final admin = AdminAuthService().currentAdmin ??
        const AdminUserModel(
          id: 'adm_root',
          fullName: 'Dr. Tariq Mahmood',
          email: 'admin@campusconnect.edu.pk',
          role: 'SUPER_ADMIN',
          roleDisplayName: 'Super Administrator',
          department: 'Executive Governance Council',
          avatarInitial: 'TM',
          permissions: ['all'],
          lastLoginAt: 'Just now',
        );

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Mobile Menu Icon (Drawer)
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.darkNavy),
              onPressed: onOpenDrawer,
              tooltip: 'Open Navigation Menu',
            ),
            const SizedBox(width: 8),
          ],

          // Title & Breadcrumb
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    breadcrumb ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(' / ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    pageTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                pageTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Global Search Bar (on Widescreen)
          if (isDesktop)
            Container(
              width: 280,
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
                  hintText: 'Search audits, companies, students...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

          // System Health Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3.5, backgroundColor: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Live Realm',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Notifications Bell Icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.darkNavy),
                tooltip: 'Alerts',
                onPressed: () => _showNotificationsSheet(context),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Admin Profile Avatar & Dropdown Menu
          PopupMenuButton<String>(
            tooltip: 'Administrator Account',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      admin.email,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightIceBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        admin.roleDisplayName,
                        style: const TextStyle(
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
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Council Credentials', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'security',
                child: Row(
                  children: [
                    Icon(Icons.security_outlined, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Cryptographic Vault', style: TextStyle(fontSize: 12.5)),
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
                  style: const TextStyle(
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
  }
}

