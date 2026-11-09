import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Navigation item model for Admin Sidebar
class AdminNavItem {
  final String title;
  final IconData icon;
  final String routeId;
  final String? badgeText;
  final Color? badgeColor;

  const AdminNavItem({
    required this.title,
    required this.icon,
    required this.routeId,
    this.badgeText,
    this.badgeColor,
  });
}

/// Enterprise Admin Sidebar Navigation Component
/// Renders as persistent sidebar on Desktop and drawer on Mobile/Tablet.
class AdminSidebar extends StatelessWidget {
  final String activeRouteId;
  final ValueChanged<String> onRouteSelected;
  final VoidCallback onSignOut;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.activeRouteId,
    required this.onRouteSelected,
    required this.onSignOut,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  static const List<AdminNavItem> navItems = [
    AdminNavItem(
      title: 'Platform Overview',
      icon: Icons.dashboard_outlined,
      routeId: 'dashboard',
    ),
    AdminNavItem(
      title: 'Company Verifications',
      icon: Icons.domain_verification_outlined,
      routeId: 'company_verifications',
      badgeText: '1 Pending',
      badgeColor: AppColors.warning,
    ),
    AdminNavItem(
      title: 'Student Credentials',
      icon: Icons.school_outlined,
      routeId: 'student_verifications',
      badgeText: '3 New',
      badgeColor: AppColors.accentTeal,
    ),
    AdminNavItem(
      title: 'Projects & Sprints',
      icon: Icons.assignment_outlined,
      routeId: 'projects_audit',
      badgeText: '7 Active',
      badgeColor: AppColors.primary,
    ),
    AdminNavItem(
      title: 'Application Monitoring',
      icon: Icons.shield_outlined,
      routeId: 'compliance',
      badgeText: '2 Flags',
      badgeColor: AppColors.error,
    ),
    AdminNavItem(
      title: 'Audit Logs & Vault',
      icon: Icons.history_edu_outlined,
      routeId: 'audit_logs',
    ),
    AdminNavItem(
      title: 'Platform Settings',
      icon: Icons.settings_outlined,
      routeId: 'settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 76 : 260,
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header / Brand
          _buildBrandHeader(),

          const Divider(color: Colors.white12, height: 1),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = item.routeId == activeRouteId;
                return _buildNavItemTile(item, isSelected);
              },
            ),
          ),

          // Bottom System Status & Sign Out
          _buildFooterSection(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAMPUSCONNECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'GOVERNANCE CONSOLE',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (!isCollapsed && onToggleCollapse != null)
            IconButton(
              icon: const Icon(Icons.menu_open_rounded, color: Colors.white70, size: 20),
              onPressed: onToggleCollapse,
              tooltip: 'Collapse Sidebar',
            ),
        ],
      ),
    );
  }

  Widget _buildNavItemTile(AdminNavItem item, bool isSelected) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: item.title,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onRouteSelected(item.routeId),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onRouteSelected(item.routeId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (item.badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : (item.badgeColor ?? AppColors.primary).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white38
                            : (item.badgeColor ?? AppColors.primary).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      item.badgeText!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (item.badgeColor ?? AppColors.primary),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: isCollapsed
          ? IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              tooltip: 'Sign Out Session',
              onPressed: onSignOut,
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'TM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dr. Tariq Mahmood',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Super Administrator',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                  tooltip: 'Sign Out',
                  onPressed: onSignOut,
                ),
              ],
            ),
    );
  }
}

