import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_certificate_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';

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
/// Dynamically computes live badge counts from Supabase-backed services.
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

  List<AdminNavItem> _buildLiveNavItems() {
    final pendingCompanyVerifs = AdminVerificationService()
        .allVerifications
        .where((v) => v.status == VerificationStatus.pending)
        .length;

    final pendingStudents = AdminStudentService()
        .allStudents
        .where((s) => s.verificationStatus == StudentVerificationStatus.pending)
        .length;

    final activeProjects = AdminProjectService()
        .allProjects
        .where((p) =>
            p.status == AdminProjectStatus.published ||
            p.status == AdminProjectStatus.active)
        .length;

    final flaggedApps = AdminApplicationMonitoringService()
        .allApplications
        .where((a) =>
            a.reportStatus == ApplicationReportStatus.reported ||
            a.reportStatus == ApplicationReportStatus.underInvestigation)
        .length;

    final mintedCertificates =
        AdminCertificateService().allCertificates.length;

    return [
      const AdminNavItem(
        title: 'Platform Overview',
        icon: Icons.dashboard_outlined,
        routeId: 'dashboard',
      ),
      AdminNavItem(
        title: 'Company Verifications',
        icon: Icons.domain_verification_outlined,
        routeId: 'company_verifications',
        badgeText: pendingCompanyVerifs > 0
            ? '$pendingCompanyVerifs Pending'
            : null,
        badgeColor: AppColors.warning,
      ),
      AdminNavItem(
        title: 'Student Credentials',
        icon: Icons.school_outlined,
        routeId: 'student_verifications',
        badgeText: pendingStudents > 0 ? '$pendingStudents Pending' : null,
        badgeColor: AppColors.accentTeal,
      ),
      AdminNavItem(
        title: 'Projects & Sprints',
        icon: Icons.assignment_outlined,
        routeId: 'projects_audit',
        badgeText: activeProjects > 0 ? '$activeProjects Active' : null,
        badgeColor: AppColors.primary,
      ),
      AdminNavItem(
        title: 'Application Monitoring',
        icon: Icons.shield_outlined,
        routeId: 'compliance',
        badgeText: flaggedApps > 0
            ? '$flaggedApps Flag${flaggedApps == 1 ? '' : 's'}'
            : null,
        badgeColor: AppColors.error,
      ),
      AdminNavItem(
        title: 'Audit Logs & Vault',
        icon: Icons.history_edu_outlined,
        routeId: 'audit_logs',
        badgeText:
            mintedCertificates > 0 ? '$mintedCertificates Minted' : null,
      ),
      const AdminNavItem(
        title: 'Reports & Analytics',
        icon: Icons.insights_outlined,
        routeId: 'analytics',
        badgeText: 'Live BI',
        badgeColor: AppColors.accentTeal,
      ),
      const AdminNavItem(
        title: 'Platform Settings',
        icon: Icons.settings_outlined,
        routeId: 'settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([
      AdminAuthService().currentAdminNotifier,
      AdminVerificationService().verificationsNotifier,
      AdminStudentService().studentsNotifier,
      AdminProjectService().projectsNotifier,
      AdminApplicationMonitoringService().applicationsNotifier,
      AdminCertificateService().certificatesNotifier,
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
          child: Column(
            children: [
              _buildBrandHeader(),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.routeId == activeRouteId;
                    return _buildNavItemTile(item, isSelected);
                  },
                ),
              ),
              _buildFooterSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
      child: Row(
        mainAxisAlignment: isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (isCollapsed)
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
            )
          else
            Expanded(
              child: Row(
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
                      child:
                          Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAMPUSCONNECT',
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
