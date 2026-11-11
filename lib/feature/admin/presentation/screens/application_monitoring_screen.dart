import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enterprise Application Monitoring & Investigation Desk for SkillBridge Admin Panel.
/// Surfaced for auditing suspicious, reported, or problematic project applications,
/// maintaining privacy boundaries, forensic investigation notes, and authorized case resolutions.
class ApplicationMonitoringScreen extends StatefulWidget {
  const ApplicationMonitoringScreen({super.key});

  @override
  State<ApplicationMonitoringScreen> createState() =>
      _ApplicationMonitoringScreenState();
}

class _ApplicationMonitoringScreenState
    extends State<ApplicationMonitoringScreen>
    with SingleTickerProviderStateMixin {
  final AdminAuthService _authService = AdminAuthService();
  final AdminApplicationMonitoringService _monitoringService =
      AdminApplicationMonitoringService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedWorkflowStatus = 'All Statuses';
  String _selectedReportStatus = 'All Reports';
  String _selectedDateFilter = 'All Time';
  String _sortBy = 'Newest Submission';

  bool _isSidebarCollapsed = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _monitoringService.loadFromSupabase();
    });
  }

  void _showActionResult(
    bool ok,
    String successMessage, {
    Color successColor = AppColors.success,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? successMessage
              : 'Unable to persist investigation update to Supabase.',
        ),
        backgroundColor: ok ? successColor : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _workflowStatusFilters = [
    'All Statuses',
    'Pending',
    'Accepted',
    'Rejected',
    'Withdrawn',
  ];

  final List<String> _reportStatusFilters = [
    'All Reports',
    'Reported / Flagged',
    'Under Investigation',
    'Clear / No Flags',
    'Resolved',
    'Dismissed',
  ];

  final List<String> _dateFilters = [
    'All Time',
    'Today',
    'Last 7 Days',
    'Last 30 Days',
  ];

  final List<String> _sortOptions = [
    'Newest Submission',
    'Oldest Submission',
    'High Severity First',
    'Student Name (A-Z)',
  ];

  Future<void> _refreshApplications() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _monitoringService.loadFromSupabase();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applications synchronized with Supabase.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchExternalUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or incomplete document URL.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open attached document link.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to launch attached URL on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign Out Console',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to end your active administrative session? Session credentials will be invalidated securely.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  void _onRouteSelected(String routeId) {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (routeId == 'compliance' || routeId == 'application_monitoring') {
      return;
    }
    if (routeId == 'dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (routeId == 'student_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
      );
    } else if (routeId == 'company_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyVerificationsScreen()),
      );
    } else if (routeId == 'company_management') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
      );
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
      );
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CertificateManagementScreen()),
      );
    } else if (routeId == 'analytics' || routeId == 'reports') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
      );
    } else if (routeId == 'settings') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
      );
    }
  }

  List<AdminApplicationModel> _getFilteredApplications(
    List<AdminApplicationModel> applications,
  ) {
    return applications.where((a) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = a.id.toLowerCase().contains(query);
        final matchesStudent = a.studentName.toLowerCase().contains(query);
        final matchesCompany = a.companyName.toLowerCase().contains(query);
        final matchesProject = a.projectTitle.toLowerCase().contains(query);
        if (!matchesId &&
            !matchesStudent &&
            !matchesCompany &&
            !matchesProject) {
          return false;
        }
      }

      if (_selectedWorkflowStatus != 'All Statuses' &&
          a.workflowStatusDisplay != _selectedWorkflowStatus) {
        return false;
      }

      if (_selectedReportStatus != 'All Reports') {
        if (_selectedReportStatus == 'Reported / Flagged' &&
            a.reportStatus != ApplicationReportStatus.reported) {
          return false;
        }
        if (_selectedReportStatus == 'Under Investigation' &&
            a.reportStatus != ApplicationReportStatus.underInvestigation) {
          return false;
        }
        if (_selectedReportStatus == 'Clear / No Flags' &&
            a.reportStatus != ApplicationReportStatus.clear) {
          return false;
        }
        if (_selectedReportStatus == 'Resolved' &&
            a.reportStatus != ApplicationReportStatus.resolved) {
          return false;
        }
        if (_selectedReportStatus == 'Dismissed' &&
            a.reportStatus != ApplicationReportStatus.dismissed) {
          return false;
        }
      }

      if (_selectedDateFilter != 'All Time') {
        final now = DateTime.now();
        if (_selectedDateFilter == 'Today') {
          if (a.submissionDateTime.day != now.day ||
              a.submissionDateTime.month != now.month ||
              a.submissionDateTime.year != now.year) {
            return false;
          }
        } else if (_selectedDateFilter == 'Last 7 Days') {
          if (now.difference(a.submissionDateTime).inDays > 7) {
            return false;
          }
        } else if (_selectedDateFilter == 'Last 30 Days') {
          if (now.difference(a.submissionDateTime).inDays > 30) {
            return false;
          }
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'Newest Submission') {
          return b.submissionDateTime.compareTo(a.submissionDateTime);
        } else if (_sortBy == 'Oldest Submission') {
          return a.submissionDateTime.compareTo(b.submissionDateTime);
        } else if (_sortBy == 'High Severity First') {
          final aScore = _getSeverityWeight(a.reportDetail?.severity);
          final bScore = _getSeverityWeight(b.reportDetail?.severity);
          return bScore.compareTo(aScore);
        } else {
          return a.studentName.compareTo(b.studentName);
        }
      });
  }

  int _getSeverityWeight(String? severity) {
    if (severity == 'Critical') return 4;
    if (severity == 'High') return 3;
    if (severity == 'Medium') return 2;
    if (severity == 'Low') return 1;
    return 0;
  }

  void _openApplicationDetailsDrawer(AdminApplicationModel app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 3,
        child: DraggableScrollableSheet(
          initialChildSize: 0.90,
          maxChildSize: 0.96,
          minChildSize: 0.50,
          expand: false,
          builder: (_, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getReportStatusColor(app.reportStatus)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getReportStatusIcon(app.reportStatus),
                        color: _getReportStatusColor(app.reportStatus),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investigation Desk: ${app.id}',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Applicant: ${app.studentName} • Sponsor: ${app.companyName}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),

                // Privacy Notice
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Administrative Investigation Channel • Protected by SkillBridge Academic Privacy Governance',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.darkNavy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Status Badges Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusPill(
                      label: 'Status: ${app.workflowStatusDisplay}',
                      color: _getWorkflowColor(app.workflowStatus),
                      bgColor: _getWorkflowBgColor(app.workflowStatus),
                    ),
                    _buildStatusPill(
                      label: 'Report: ${app.reportStatusDisplay}',
                      color: _getReportStatusColor(app.reportStatus),
                      bgColor: _getReportStatusBgColor(app.reportStatus),
                    ),
                    if (app.flagType != SuspiciousFlagType.none)
                      _buildStatusPill(
                        label: app.flagTypeDisplay,
                        color: AppColors.error,
                        bgColor: AppColors.errorBg,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                TabBar(
                  isScrollable: MediaQuery.of(ctx).size.width < 520,
                  labelColor: AppColors.darkNavy,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.badge_outlined, size: 18),
                      text: 'Application Info',
                    ),
                    Tab(
                      icon: Icon(Icons.flag_outlined, size: 18),
                      text: 'Report & Evidence',
                    ),
                    Tab(
                      icon: Icon(Icons.history_edu_outlined, size: 18),
                      text: 'Investigation Audit',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 460,
                  child: TabBarView(
                    children: [
                      _buildTab1ApplicationInfo(app),
                      _buildTab2ReportAndEvidence(app),
                      _buildTab3InvestigationAudit(app),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                _buildDrawerActionButtons(ctx, app),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab1ApplicationInfo(AdminApplicationModel app) {
    final hasResume = (app.resumeUrl?.isNotEmpty == true);
    final hasWork = (app.submittedWorkUrl?.isNotEmpty == true);

    return ListView(
      children: [
        _buildSectionHeader('1. Project Target & Scope'),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.assignment_outlined,
          'Project Title',
          app.projectTitle,
        ),
        _buildInfoRow(
          Icons.category_outlined,
          'Domain Vertical',
          app.projectCategory,
        ),
        _buildInfoRow(
          Icons.apartment_outlined,
          'Sponsoring Corporate',
          app.companyName,
        ),
        _buildInfoRow(
          Icons.person_outline_rounded,
          'Company Liaison',
          app.companyLiaison,
        ),
        _buildInfoRow(
          Icons.calendar_today_rounded,
          'Submitted Date',
          app.submissionDate,
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('2. Applicant Academic Credentials'),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.person_rounded,
          'Full Student Name',
          app.studentName,
        ),
        _buildInfoRow(
          Icons.email_outlined,
          'Academic Email',
          app.studentEmail.isNotEmpty ? app.studentEmail : 'Not provided',
        ),
        _buildInfoRow(
          Icons.school_rounded,
          'University Institution',
          app.university.isNotEmpty ? app.university : 'Not specified',
        ),
        _buildInfoRow(
          Icons.workspace_premium_rounded,
          'Enrolled Degree',
          app.degree,
        ),
        _buildInfoRow(Icons.domain_rounded, 'Department', app.department),
        if (app.semester.isNotEmpty)
          _buildInfoRow(
            Icons.timeline_rounded,
            'Current Semester',
            app.semester,
          ),
        _buildInfoRow(
          Icons.grade_rounded,
          'Cumulative GPA',
          '${app.cgpa > 0 ? app.cgpa.toStringAsFixed(2) : "Not listed"} ${app.isEducationVerified ? "(Verified)" : "(Pending Verification)"}',
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('3. Submitted Proposal Narrative'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            app.proposalSummary.trim().isNotEmpty
                ? app.proposalSummary
                : 'No proposal summary provided by applicant.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('4. Declared Technical Skills'),
        const SizedBox(height: 8),
        if (app.skills.isEmpty)
          Text(
            'No specific technical skills listed on this application.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: app.skills.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),

        _buildSectionHeader('5. Attached Documents & Deliverables'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: hasResume ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.resumeFileName.isNotEmpty
                              ? app.resumeFileName
                              : (hasResume
                                  ? 'Submitted Resume Attachment'
                                  : 'No resume document attached'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (hasResume)
                          Text(
                            app.resumeUrl!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasResume)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('Open'),
                      onPressed: () => _launchExternalUrl(app.resumeUrl!),
                    ),
                ],
              ),
              if (hasWork) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.folder_zip_outlined,
                      color: AppColors.accentTeal,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Submitted Deliverable Work URL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            app.submittedWorkUrl!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('Inspect'),
                      onPressed: () =>
                          _launchExternalUrl(app.submittedWorkUrl!),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab2ReportAndEvidence(AdminApplicationModel app) {
    if (app.reportDetail == null) {
      return const Center(
        child: AppEmptyState(
          compact: true,
          icon: Icons.verified_user_rounded,
          iconColor: AppColors.success,
          title: 'No Reports or Flags Registered',
          subtitle:
              'This application maintains clean standing across compliance checks.',
        ),
      );
    }

    final rep = app.reportDetail!;

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: rep.severity == 'Critical'
                ? const Color(0xFFFEF2F2)
                : AppColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rep.severity == 'Critical'
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: rep.severity == 'Critical'
                            ? AppColors.error
                            : const Color(0xFF92400E),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'REPORT FILED: ${rep.reportCategory.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: rep.severity == 'Critical'
                                ? AppColors.error
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: rep.severity == 'Critical'
                          ? AppColors.error
                          : AppColors.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SEVERITY: ${rep.severity.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Report Reference: ${rep.reportId} • Filed On: ${rep.reportedDate}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Filed by: ${rep.reportedBy} (${rep.reporterRole})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('Reporter Narrative & Grievance'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            rep.reportExplanation,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (rep.evidenceSnippet != null) ...[
          _buildSectionHeader('Extracted Evidence Snippet'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rep.evidenceSnippet!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTab3InvestigationAudit(AdminApplicationModel app) {
    return ListView(
      children: [
        _buildSectionHeader('Investigation Notes & Forensic Log'),
        const SizedBox(height: 8),
        if (app.investigationNotes.isEmpty)
          const Text(
            'No investigation notes recorded yet.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else
          ...app.investigationNotes.map((note) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.darkNavy,
                ),
              ),
            );
          }),
        const SizedBox(height: 20),

        _buildSectionHeader('Administrative Audit Trail'),
        const SizedBox(height: 8),
        if (app.investigationHistory.isEmpty)
          const Text(
            'No audit events registered.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else
          ...app.investigationHistory.map((audit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          audit.action,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppColors.darkNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        audit.timestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recorded by: ${audit.adminName}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (audit.findings != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Findings: "${audit.findings}"',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDrawerActionButtons(
    BuildContext ctx,
    AdminApplicationModel app,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.note_add_outlined, size: 16),
          label: const Text('Add Note'),
          onPressed: () {
            Navigator.pop(ctx);
            _promptAddInvestigationNote(app);
          },
        ),
        if (app.reportStatus == ApplicationReportStatus.reported)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Mark Under Review'),
            onPressed: () {
              Navigator.pop(ctx);
              _promptMarkUnderInvestigation(app);
            },
          ),
        if (app.reportStatus == ApplicationReportStatus.reported ||
            app.reportStatus == ApplicationReportStatus.underInvestigation)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Dismiss Report'),
            onPressed: () {
              Navigator.pop(ctx);
              _promptDismissReport(app);
            },
          ),
        if (app.reportStatus == ApplicationReportStatus.reported ||
            app.reportStatus == ApplicationReportStatus.underInvestigation)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: const Icon(Icons.gavel_rounded, size: 16),
            label: const Text('Resolve Case'),
            onPressed: () {
              Navigator.pop(ctx);
              _promptResolveReport(app);
            },
          ),
      ],
    );
  }

  void _promptMarkUnderInvestigation(AdminApplicationModel app) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mark Under Active Review: ${app.id}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Initiate forensic investigation on this flagged submission. Provide initial observations.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Initial Investigation Focus *',
                  hintText: 'Describe initial compliance observations...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isEmpty) return;

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              final ok = await _monitoringService.markCaseUnderInvestigation(
                applicationId: app.id,
                adminName: admin,
                initialNote: note,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              _showActionResult(
                ok,
                '${app.id} marked under active investigation.',
                successColor: AppColors.warning,
              );
            },
            child: const Text('Initiate Review'),
          ),
        ],
      ),
    );
  }

  void _promptAddInvestigationNote(AdminApplicationModel app) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.note_add_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Record Investigation Note: ${app.id}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log administrative observations, verification checks, or sponsor feedback.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Investigation Note *',
                  hintText: 'Enter investigation details...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isEmpty) return;

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              final ok = await _monitoringService.recordInvestigationNote(
                applicationId: app.id,
                adminName: admin,
                note: note,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              _showActionResult(
                ok,
                'Investigation note securely logged into audit vault.',
                successColor: AppColors.primary,
              );
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _promptDismissReport(AdminApplicationModel app) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dismiss Report: ${app.id}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dismissing this report marks the flag as unfounded. Enter dismissal findings below.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Dismissal Findings *',
                  hintText: 'State why the compliance report was dismissed...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              final ok = await _monitoringService.dismissReport(
                applicationId: app.id,
                adminName: admin,
                reason: reason,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              _showActionResult(
                ok,
                'Report dismissed and student standing cleared.',
              );
            },
            child: const Text('Confirm Dismissal'),
          ),
        ],
      ),
    );
  }

  void _promptResolveReport(AdminApplicationModel app) {
    final summaryController = TextEditingController();
    bool revokeApplication = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Resolve Investigation: ${app.id}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record formal administrative resolution findings to conclude this compliance case.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Resolution Summary *',
                    hintText: 'Summarize investigation conclusion and action taken...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: revokeApplication,
                    activeColor: AppColors.error,
                    title: const Text(
                      'Authorize Decision Modification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Administratively revoke this application and sync rejection across student and company panels.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() => revokeApplication = val ?? false);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final summary = summaryController.text.trim();
                if (summary.isEmpty) return;

                final admin =
                    _authService.currentAdmin?.fullName ?? 'Executive Administrator';
                final ok = await _monitoringService.resolveReportWithAction(
                  applicationId: app.id,
                  adminName: admin,
                  resolutionSummary: summary,
                  revokeApplication: revokeApplication,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                _showActionResult(
                  ok,
                  'Case resolved.${revokeApplication ? " Application administratively revoked." : ""}',
                );
              },
              child: const Text('Conclude Investigation'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsvRecords(List<AdminApplicationModel> applications) {
    final csv = _monitoringService.exportApplicationsCsv(applications);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.file_download_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Export Application Registry (CSV)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The authorized application and compliance surveillance records have been compiled into CSV format:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application CSV records copied to clipboard!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getWorkflowColor(ApplicationWorkflowStatus status) {
    switch (status) {
      case ApplicationWorkflowStatus.pending:
        return const Color(0xFFD97706);
      case ApplicationWorkflowStatus.accepted:
        return AppColors.success;
      case ApplicationWorkflowStatus.rejected:
        return AppColors.error;
      case ApplicationWorkflowStatus.withdrawn:
        return const Color(0xFF64748B);
    }
  }

  Color _getWorkflowBgColor(ApplicationWorkflowStatus status) {
    switch (status) {
      case ApplicationWorkflowStatus.pending:
        return AppColors.warningBg;
      case ApplicationWorkflowStatus.accepted:
        return AppColors.successBg;
      case ApplicationWorkflowStatus.rejected:
        return AppColors.errorBg;
      case ApplicationWorkflowStatus.withdrawn:
        return AppColors.background;
    }
  }

  Color _getReportStatusColor(ApplicationReportStatus status) {
    switch (status) {
      case ApplicationReportStatus.clear:
        return AppColors.success;
      case ApplicationReportStatus.reported:
        return AppColors.error;
      case ApplicationReportStatus.underInvestigation:
        return const Color(0xFFD97706);
      case ApplicationReportStatus.resolved:
        return AppColors.primary;
      case ApplicationReportStatus.dismissed:
        return const Color(0xFF64748B);
    }
  }

  Color _getReportStatusBgColor(ApplicationReportStatus status) {
    switch (status) {
      case ApplicationReportStatus.clear:
        return AppColors.successBg;
      case ApplicationReportStatus.reported:
        return AppColors.errorBg;
      case ApplicationReportStatus.underInvestigation:
        return AppColors.warningBg;
      case ApplicationReportStatus.resolved:
        return AppColors.lightIceBlue;
      case ApplicationReportStatus.dismissed:
        return AppColors.background;
    }
  }

  IconData _getReportStatusIcon(ApplicationReportStatus status) {
    switch (status) {
      case ApplicationReportStatus.clear:
        return Icons.verified_rounded;
      case ApplicationReportStatus.reported:
        return Icons.flag_rounded;
      case ApplicationReportStatus.underInvestigation:
        return Icons.search_rounded;
      case ApplicationReportStatus.resolved:
        return Icons.gavel_rounded;
      case ApplicationReportStatus.dismissed:
        return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.darkNavy,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: 'compliance',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'compliance',
                  onRouteSelected: _onRouteSelected,
                  onSignOut: _handleSignOut,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopNavbar(
                      pageTitle: 'Application Monitoring & Investigations',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (query) {
                        setState(() {
                          _searchQuery = query;
                          _currentPage = 1;
                        });
                      },
                    ),
                    Expanded(
                      child: ValueListenableBuilder<List<AdminApplicationModel>>(
                        valueListenable: _monitoringService.applicationsNotifier,
                        builder: (context, applications, _) {
                          final filtered = _getFilteredApplications(applications);
                          final totalPages = (filtered.length / _itemsPerPage)
                              .ceil()
                              .clamp(1, 999);
                          final safePage = _currentPage.clamp(1, totalPages);
                          final startIndex = (safePage - 1) * _itemsPerPage;
                          final pageItems = filtered
                              .skip(startIndex)
                              .take(_itemsPerPage)
                              .toList();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildApplicationOverviewMetrics(),
                                const SizedBox(height: 20),
                                _buildFilterAndActionCard(filtered),
                                const SizedBox(height: 20),
                                _buildApplicationTableCard(
                                  pageItems,
                                  filtered.length,
                                  totalPages,
                                  safePage,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApplicationOverviewMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 4;
        if (constraints.maxWidth < 600) {
          count = 1;
        } else if (constraints.maxWidth < 1050) {
          count = 2;
        }

        final cards = [
          _buildMetricTile(
            title: 'Total Applications',
            value: '${_monitoringService.totalCount}',
            subtitle: 'Cumulative project submissions',
            icon: Icons.assignment_turned_in_rounded,
            color: AppColors.primary,
            bgColor: AppColors.lightIceBlue,
          ),
          _buildMetricTile(
            title: 'Pending Applications',
            value: '${_monitoringService.pendingCount}',
            subtitle: 'Under corporate consideration',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFD97706),
            bgColor: AppColors.warningBg,
          ),
          _buildMetricTile(
            title: 'Accepted Applications',
            value: '${_monitoringService.acceptedCount}',
            subtitle: 'Matched and sprint-assigned',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            bgColor: AppColors.successBg,
          ),
          _buildMetricTile(
            title: 'Rejected Applications',
            value: '${_monitoringService.rejectedCount}',
            subtitle: 'Declined or prerequisite mismatch',
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            bgColor: AppColors.errorBg,
          ),
          _buildMetricTile(
            title: 'Withdrawn Applications',
            value: '${_monitoringService.withdrawnCount}',
            subtitle: 'Voluntarily pulled by students',
            icon: Icons.remove_circle_outline_rounded,
            color: const Color(0xFF64748B),
            bgColor: AppColors.background,
          ),
          _buildMetricTile(
            title: 'Reported Applications',
            value: '${_monitoringService.reportedCount}',
            subtitle: 'Grievance / infraction filed',
            icon: Icons.flag_rounded,
            color: AppColors.error,
            bgColor: AppColors.errorBg,
          ),
          _buildMetricTile(
            title: 'Under Active Review',
            value: '${_monitoringService.requiringInvestigationCount}',
            subtitle: 'Formal administrative inquiry',
            icon: Icons.gavel_rounded,
            color: const Color(0xFF9333EA),
            bgColor: const Color(0xFFF3E8FF),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: count == 1 ? 2.8 : 1.75,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndActionCard(
    List<AdminApplicationModel> filteredApplications,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Surveillance & Investigation Desk',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Audit flagged applications, review submissions, and investigate integrity infractions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh'),
                    onPressed: _isRefreshing ? null : _refreshApplications,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkNavy,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Records (CSV)'),
                    onPressed: () => _exportCsvRecords(filteredApplications),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final fieldWidth = compact ? constraints.maxWidth : 200.0;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (compact)
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Applications',
                        hintText: 'Student, company, project, ID...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (q) => setState(() {
                        _searchQuery = q;
                        _currentPage = 1;
                      }),
                    ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedWorkflowStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Application Status',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _workflowStatusFilters
                          .map((st) => DropdownMenuItem(
                                value: st,
                                child: Text(
                                  st,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedWorkflowStatus = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedReportStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Report / Investigation Status',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _reportStatusFilters
                          .map((rst) => DropdownMenuItem(
                                value: rst,
                                child: Text(
                                  rst,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedReportStatus = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 170,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDateFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Submission Date',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _dateFilters
                          .map((df) => DropdownMenuItem(
                                value: df,
                                child: Text(
                                  df,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDateFilter = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _sortOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationTableCard(
    List<AdminApplicationModel> pageApplications,
    int totalCount,
    int totalPages,
    int safePage,
  ) {
    if (pageApplications.isEmpty) {
      return AppEmptyState(
        icon: Icons.find_in_page_outlined,
        title: 'No Applications Found',
        subtitle: _monitoringService.totalCount == 0
            ? 'No student applications have been submitted in Supabase yet.'
            : 'Try adjusting the search query, workflow status, or investigation filter.',
        actionLabel: _monitoringService.totalCount == 0
            ? 'Refresh Applications'
            : 'Reset Filters',
        actionIcon: _monitoringService.totalCount == 0
            ? Icons.refresh_rounded
            : Icons.filter_alt_off_rounded,
        onAction: _monitoringService.totalCount == 0
            ? _refreshApplications
            : () {
                setState(() {
                  _searchQuery = '';
                  _selectedWorkflowStatus = 'All Statuses';
                  _selectedReportStatus = 'All Reports';
                  _selectedDateFilter = 'All Time';
                  _currentPage = 1;
                });
              },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final useMobileCards = constraints.maxWidth < 900;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageApplications.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final app = pageApplications[index];
                  if (useMobileCards) {
                    return _buildMobileApplicationCard(app);
                  }
                  return _buildDesktopApplicationRow(app);
                },
              );
            },
          ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Showing ${pageApplications.length} of $totalCount applications (Page $safePage of $totalPages)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: safePage > 1
                          ? () => setState(() => _currentPage = safePage - 1)
                          : null,
                    ),
                    Text(
                      '$safePage',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: safePage < totalPages
                          ? () => setState(() => _currentPage = safePage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopApplicationRow(AdminApplicationModel app) {
    final isFlagged = app.reportStatus == ApplicationReportStatus.reported ||
        app.reportStatus == ApplicationReportStatus.underInvestigation;
    final shortId = app.id.length > 10 ? '${app.id.substring(0, 8)}...' : app.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              shortId,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.darkNavy,
                  child: Text(
                    app.studentName.isNotEmpty
                        ? app.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              app.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.darkNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (app.isEducationVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.accentTeal,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${app.university.isNotEmpty ? app.university : "University"} • ${app.degree}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.projectTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.darkNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  app.projectCategory,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.companyName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Liaison: ${app.companyLiaison}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              app.submissionDate,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getWorkflowBgColor(app.workflowStatus),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              app.workflowStatusDisplay,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getWorkflowColor(app.workflowStatus),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getReportStatusBgColor(app.reportStatus),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getReportStatusIcon(app.reportStatus),
                  size: 13,
                  color: _getReportStatusColor(app.reportStatus),
                ),
                const SizedBox(width: 4),
                Text(
                  app.reportStatusDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getReportStatusColor(app.reportStatus),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFlagged ? AppColors.error : AppColors.darkNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: Icon(
              isFlagged ? Icons.search_rounded : Icons.assignment_outlined,
              size: 15,
            ),
            label: Text(
              isFlagged ? 'Investigate' : 'View Details',
              style: const TextStyle(fontSize: 11.5),
            ),
            onPressed: () => _openApplicationDetailsDrawer(app),
          ),
          const SizedBox(width: 4),
          _buildContextMenu(app),
        ],
      ),
    );
  }

  Widget _buildMobileApplicationCard(AdminApplicationModel app) {
    final isFlagged = app.reportStatus == ApplicationReportStatus.reported ||
        app.reportStatus == ApplicationReportStatus.underInvestigation;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.darkNavy,
                child: Text(
                  app.studentName.isNotEmpty
                      ? app.studentName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.studentName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      '${app.projectTitle} • ${app.companyName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildContextMenu(app),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStatusPill(
                label: app.workflowStatusDisplay,
                color: _getWorkflowColor(app.workflowStatus),
                bgColor: _getWorkflowBgColor(app.workflowStatus),
              ),
              _buildStatusPill(
                label: app.reportStatusDisplay,
                color: _getReportStatusColor(app.reportStatus),
                bgColor: _getReportStatusBgColor(app.reportStatus),
              ),
              _buildStatusPill(
                label: app.submissionDate,
                color: AppColors.textSecondary,
                bgColor: AppColors.background,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFlagged ? AppColors.error : AppColors.darkNavy,
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                isFlagged ? Icons.search_rounded : Icons.assignment_outlined,
                size: 16,
              ),
              label: Text(
                isFlagged ? 'Investigate Case' : 'View Application Details',
              ),
              onPressed: () => _openApplicationDetailsDrawer(app),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenu(AdminApplicationModel app) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (val) {
        if (val == 'details') {
          _openApplicationDetailsDrawer(app);
        } else if (val == 'review') {
          _promptMarkUnderInvestigation(app);
        } else if (val == 'note') {
          _promptAddInvestigationNote(app);
        } else if (val == 'dismiss') {
          _promptDismissReport(app);
        } else if (val == 'resolve') {
          _promptResolveReport(app);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16),
              SizedBox(width: 8),
              Text('Open Investigation Drawer', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'note',
          child: Row(
            children: [
              Icon(Icons.note_add_outlined, size: 16),
              SizedBox(width: 8),
              Text('Add Investigation Note', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        if (app.reportStatus == ApplicationReportStatus.reported)
          const PopupMenuItem(
            value: 'review',
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  'Mark Under Active Review',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ],
            ),
          ),
        if (app.reportStatus == ApplicationReportStatus.reported ||
            app.reportStatus == ApplicationReportStatus.underInvestigation) ...[
          const PopupMenuItem(
            value: 'dismiss',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('Dismiss False Report', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'resolve',
            child: Row(
              children: [
                Icon(Icons.gavel_rounded, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Resolve Investigation',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
