import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/admin/models/admin_settings_model.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';

class _AdminAlertItem {
  final String title;
  final String description;
  final String time;
  final Color color;
  final IconData icon;

  const _AdminAlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.color,
    required this.icon,
  });
}

/// Clean Enterprise Top Navigation Bar with Live DB Alert Counts & Admin Session Badge
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
  Size get preferredSize => const Size.fromHeight(65);

  List<_AdminAlertItem> _collectLiveAlerts() {
    final alerts = <_AdminAlertItem>[];

    for (final v in AdminVerificationService()
        .allVerifications
        .where((v) => v.status == VerificationStatus.pending)) {
      alerts.add(
        _AdminAlertItem(
          title: 'Pending Company Verification',
          description: '${v.companyName} (${v.industry}) awaits review.',
          time: v.submittedAt,
          color: AppColors.warning,
          icon: Icons.domain_verification_rounded,
        ),
      );
    }

    for (final s in AdminStudentService()
        .allStudents
        .where((s) => s.verificationStatus == StudentVerificationStatus.pending)) {
      alerts.add(
        _AdminAlertItem(
          title: 'Pending Student Credential',
          description:
              '${s.name}${s.university.isNotEmpty ? " (${s.university})" : ""} is awaiting academic verification.',
          time: s.registrationDate,
          color: AppColors.primary,
          icon: Icons.school_rounded,
        ),
      );
    }

    for (final a in AdminApplicationMonitoringService()
        .allApplications
        .where((a) =>
            a.reportStatus == ApplicationReportStatus.reported ||
            a.reportStatus == ApplicationReportStatus.underInvestigation)) {
      alerts.add(
        _AdminAlertItem(
          title: 'Flagged Application (${a.reportStatusDisplay})',
          description: '${a.studentName} — ${a.projectTitle}',
          time: a.submissionDate,
          color: AppColors.error,
          icon: Icons.shield_outlined,
        ),
      );
    }

    for (final t in AdminSettingsService()
        .helpRequestsNotifier
        .value
        .where((t) => t.status != HelpRequestStatus.resolved)) {
      alerts.add(
        _AdminAlertItem(
          title: 'Open Support Ticket',
          description: '${t.senderName}: ${t.subject}',
          time: '${t.submittedAt.year}-${t.submittedAt.month.toString().padLeft(2, '0')}-${t.submittedAt.day.toString().padLeft(2, '0')}',
          color: AppColors.accentTeal,
          icon: Icons.support_agent_rounded,
        ),
      );
    }

    return alerts;
  }

  void _showNotificationsSheet(BuildContext context) {
    final alerts = _collectLiveAlerts();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Administrative Alerts (${alerts.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
            const Divider(),
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: AppEmptyState(
                  compact: true,
                  icon: Icons.notifications_none_rounded,
                  title: 'No Pending Governance Alerts',
                  subtitle:
                      'All company verifications, student approvals, compliance flags, and support tickets are up to date.',
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) => _buildNotificationItem(alerts[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(_AdminAlertItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.time,
                  style: GoogleFonts.inter(
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
    final listenable = Listenable.merge([
      AdminAuthService().currentAdminNotifier,
      AdminVerificationService().verificationsNotifier,
      AdminStudentService().studentsNotifier,
      AdminApplicationMonitoringService().applicationsNotifier,
      AdminSettingsService().helpRequestsNotifier,
    ]);

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final admin = AdminAuthService().currentAdmin ??
            const AdminUserModel(
              id: 'adm_root',
              fullName: 'Executive Administrator',
              email: 'admin@campusconnect.edu.pk',
              role: 'SUPER_ADMIN',
              roleDisplayName: 'Executive Super Administrator',
              department: 'CampusConnect Governance Council',
              avatarInitial: 'EA',
              permissions: ['all'],
              lastLoginAt: 'Active Session',
            );
        final alertCount = _collectLiveAlerts().length;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 12,
                ),
                child: Row(
                  children: [
                    if (!isDesktop) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.hub_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CampusConnect',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepNavy,
                                height: 1.15,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              pageTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.grayText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
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

              const SizedBox(width: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(38, 38),
                      fixedSize: const Size(38, 38),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.darkNavy,
                      size: 22,
                    ),
                    tooltip: 'Alerts',
                    onPressed: () => _showNotificationsSheet(context),
                  ),
                  if (alertCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          alertCount > 99 ? '99+' : '$alertCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),

              PopupMenuButton<String>(
                tooltip: 'Administrator Account',
                offset: const Offset(0, 48),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
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
                    radius: isDesktop ? 17 : 15,
                    backgroundColor: AppColors.darkNavy,
                    child: Text(
                      admin.avatarInitial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 12 : 11,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Open Navigation Menu',
                  child: Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: onOpenDrawer,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          size: 20,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
                    ],
                  ),
                ),
              ),
            ),
          );
      },
    );
  }
}
