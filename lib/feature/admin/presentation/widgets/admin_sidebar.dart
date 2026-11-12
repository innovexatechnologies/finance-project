import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';

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
/// Shows the 5 core Admin Console screens and dynamically computes live counts.
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

  /// Normalizes legacy route IDs used by the Admin navigation.
  static String normalizeRouteId(String routeId) {
    switch (routeId) {
      case 'students':
      case 'student_credentials':
      case 'student_verifications':
        return 'student_verifications';
      case 'company_verifications':
        return 'company_verifications';
      case 'company':
      case 'companies':
      case 'company_management':
        return 'company_management';
      case 'projects':
      case 'projects_audit':
        return 'projects_audit';
      case 'compliance':
      case 'application_monitoring':
        return 'application_monitoring';
      case 'audit_logs':
      case 'certificates':
        return 'audit_logs';
      case 'reports':
      case 'analytics':
        return 'analytics';
      case 'settings':
        return 'settings';
      case 'dashboard':
      default:
        return 'dashboard';
    }
  }

  /// Keeps Platform Overview beneath admin pages for predictable back navigation.
  static void navigateToRoute(
    BuildContext context, {
    required GlobalKey<ScaffoldState> scaffoldKey,
    required String currentRouteId,
    required String targetRouteId,
  }) {
    if (scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    final current = normalizeRouteId(currentRouteId);
    final next = normalizeRouteId(targetRouteId);
    if (current == next) return;

    if (next == 'dashboard') {
      if (current != 'dashboard' && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final Widget destination;
    switch (next) {
      case 'student_verifications':
        destination = const StudentManagementScreen();
        break;
      case 'company_verifications':
        destination = const CompanyVerificationsScreen();
        break;
      case 'company_management':
        destination = const CompanyManagementScreen();
        break;
      case 'projects_audit':
        destination = const ProjectManagementScreen();
        break;
      case 'application_monitoring':
        destination = const ApplicationMonitoringScreen();
        break;
      case 'audit_logs':
        destination = const CertificateManagementScreen();
        break;
      case 'analytics':
        destination = const ReportsAnalyticsScreen();
        break;
      case 'settings':
        destination = const AdminSettingsScreen();
        break;
      case 'dashboard':
      default:
        destination = const AdminDashboardScreen();
        break;
    }

    final route = MaterialPageRoute(builder: (_) => destination);
    if (current == 'dashboard') {
      Navigator.push(context, route);
    } else {
      Navigator.pushReplacement(context, route);
    }
  }

  List<AdminNavItem> _buildLiveNavItems() {
    final studentCount = AdminStudentService().totalCount;
    final companyCount = AdminCompanyService().totalCount;
    final projectCount = AdminProjectService().totalCount;

    return [
      const AdminNavItem(
        title: 'Platform Overview',
        icon: Icons.dashboard_rounded,
        routeId: 'dashboard',
      ),
      AdminNavItem(
        title: 'Student',
        icon: Icons.school_rounded,
        routeId: 'student_verifications',
        badgeText: studentCount > 0 ? '$studentCount' : null,
        badgeColor: AppColors.accentTeal,
      ),
      AdminNavItem(
        title: 'Company',
        icon: Icons.domain_rounded,
        routeId: 'company_management',
        badgeText: companyCount > 0 ? '$companyCount' : null,
        badgeColor: AppColors.primary,
      ),
      AdminNavItem(
        title: 'Projects',
        icon: Icons.assignment_rounded,
        routeId: 'projects_audit',
        badgeText: projectCount > 0 ? '$projectCount' : null,
        badgeColor: const Color(0xFF6366F1),
      ),
      const AdminNavItem(
        title: 'Reports and Analytics',
        icon: Icons.insights_rounded,
        routeId: 'analytics',
        badgeText: 'Live',
        badgeColor: AppColors.accentTeal,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([
      AdminAuthService().currentAdminNotifier,
      AdminStudentService().studentsNotifier,
      AdminCompanyService().companiesNotifier,
      AdminProjectService().projectsNotifier,
    ]);

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final items = _buildLiveNavItems();
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
          child: SafeArea(
            left: false,
            right: false,
            child: Column(
              children: [
                _buildBrandHeader(context),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected =
                          normalizeRouteId(item.routeId) ==
                          normalizeRouteId(activeRouteId);
                      return _buildNavItemTile(item, isSelected);
                    },
                  ),
                ),
                _buildFooterSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
      child: Row(
        mainAxisAlignment: isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (isCollapsed)
            SkillBridgeLogo(
              size: 36,
              circular: false,
              borderRadius: 10,
              shadows: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            )
          else
            Expanded(
              child: Row(
                children: [
                  SkillBridgeLogo(
                    size: 36,
                    circular: false,
                    borderRadius: 10,
                    shadows: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SKILLBRIDGE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'GOVERNANCE CONSOLE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!isCollapsed && onToggleCollapse != null)
            IconButton(
              icon: const Icon(
                Icons.menu_open_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: onToggleCollapse,
              tooltip: 'Collapse Sidebar',
            )
          else if (!isCollapsed)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Close Menu',
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
              color: isSelected ? AppColors.primary : Colors.transparent,
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
                    style: GoogleFonts.inter(
                      color:
                          isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (item.badgeText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : (item.badgeColor ?? AppColors.primary)
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white38
                            : (item.badgeColor ?? AppColors.primary)
                                .withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      item.badgeText!,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : (item.badgeColor ?? AppColors.primary),
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
    final admin = AdminAuthService().currentAdmin;
    final fullName = admin?.fullName ?? 'Executive Administrator';
    final roleName = admin?.roleDisplayName ?? 'Executive Super Administrator';
    final initial = admin?.avatarInitial ?? 'EA';

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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        roleName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  tooltip: 'Sign Out',
                  onPressed: onSignOut,
                ),
              ],
            ),
    );
  }
}
