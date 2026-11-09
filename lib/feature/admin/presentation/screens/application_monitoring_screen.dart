import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_application_monitoring_service.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';

/// Enterprise Application Monitoring & Investigation Desk for CampusConnect Admin Panel (Screen 38)
/// Surfaced for auditing suspicious, reported, or problematic project applications,
/// maintaining privacy boundaries, forensic investigation notes, and authorized case resolutions.
class ApplicationMonitoringScreen extends StatefulWidget {
  const ApplicationMonitoringScreen({super.key});

  @override
  State<ApplicationMonitoringScreen> createState() =>
      _ApplicationMonitoringScreenState();
}

class _ApplicationMonitoringScreenState
    extends State<ApplicationMonitoringScreen> with SingleTickerProviderStateMixin {
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

  // Pagination controls
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

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out Console'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your active administrative session? Session credentials will be invalidated securely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
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
    } else if (routeId == 'company_verifications' || routeId == 'company_management') {
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
    // If routeId is 'compliance' or 'application_monitoring', we are already on this screen.
  }

  // Filter & Sort Logic
  List<AdminApplicationModel> _getFilteredApplications(
      List<AdminApplicationModel> applications) {
    return applications.where((a) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = a.id.toLowerCase().contains(query);
        final matchesStudent = a.studentName.toLowerCase().contains(query);
        final matchesCompany = a.companyName.toLowerCase().contains(query);
        final matchesProject = a.projectTitle.toLowerCase().contains(query);
        if (!matchesId && !matchesStudent && !matchesCompany && !matchesProject) {
          return false;
        }
      }

      // 2. Workflow Status Filter
      if (_selectedWorkflowStatus != 'All Statuses' &&
          a.workflowStatusDisplay != _selectedWorkflowStatus) {
        return false;
      }

      // 3. Report Status Filter
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

      // 4. Date Filter
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

  // 4. Application Details & Investigation Drawer
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
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Investigation Desk: ${app.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Applicant: ${app.studentName} • Sponsor: ${app.companyName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Privacy & Confidentiality Notice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Administrative Investigation Channel • Protected by CampusConnect Academic Privacy Governance • Zero access to unauthorized student messaging',
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

                // Status Badges Row
                Row(
                  children: [
                    _buildStatusPill(
                      label: 'Status: ${app.workflowStatusDisplay}',
                      color: _getWorkflowColor(app.workflowStatus),
                      bgColor: _getWorkflowBgColor(app.workflowStatus),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      label: 'Report: ${app.reportStatusDisplay}',
                      color: _getReportStatusColor(app.reportStatus),
                      bgColor: _getReportStatusBgColor(app.reportStatus),
                    ),
                    if (app.flagType != SuspiciousFlagType.none) ...[
                      const SizedBox(width: 8),
                      _buildStatusPill(
                        label: app.flagTypeDisplay,
                        color: AppColors.error,
                        bgColor: AppColors.errorBg,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 3 Organized Tabs
                const TabBar(
                  labelColor: AppColors.darkNavy,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Application Info'),
                    Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Report & Evidence'),
                    Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: 'Investigation Audit'),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab View Content (Fixed Height Section)
                SizedBox(
                  height: 480,
                  child: TabBarView(
                    children: [
                      // Tab 1: Application Information
                      _buildTab1ApplicationInfo(app),

                      // Tab 2: Report & Evidence
                      _buildTab2ReportAndEvidence(app),

                      // Tab 3: Investigation Desk & Audit Trail
                      _buildTab3InvestigationAudit(app),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 14),

                // Primary Moderation Action Buttons
                _buildDrawerActionButtons(ctx, app),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drawer Tab 1: Application Information
  Widget _buildTab1ApplicationInfo(AdminApplicationModel app) {
    return ListView(
      children: [
        _buildSectionHeader('1. Project Target & Scope'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.assignment_outlined, 'Project Title', app.projectTitle),
        _buildInfoRow(Icons.category_outlined, 'Domain Vertical', app.projectCategory),
        _buildInfoRow(Icons.apartment_outlined, 'Sponsoring Corporate', app.companyName),
        _buildInfoRow(Icons.person_outline_rounded, 'Company Liaison', app.companyLiaison),
        _buildInfoRow(Icons.calendar_today_rounded, 'Submitted Date', app.submissionDate),
        const SizedBox(height: 16),

        _buildSectionHeader('2. Applicant Academic Credentials (FERPA Protected)'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.person_rounded, 'Full Student Name', app.studentName),
        _buildInfoRow(Icons.email_outlined, 'Academic Email', app.studentEmail),
        _buildInfoRow(Icons.school_rounded, 'University Institution', app.university),
        _buildInfoRow(Icons.workspace_premium_rounded, 'Enrolled Degree', app.degree),
        _buildInfoRow(Icons.domain_rounded, 'Department', app.department),
        _buildInfoRow(Icons.timeline_rounded, 'Current Semester', app.semester),
        _buildInfoRow(
          Icons.grade_rounded,
          'Cumulative GPA',
          '${app.cgpa} ${app.isEducationVerified ? "(Registrar Verified)" : "(Unverified Flag)"}',
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
            app.proposalSummary,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('4. Declared Technical Skills'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: app.skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightIceBlue,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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

        _buildSectionHeader('5. Attached Application Document'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  app.resumeFileName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Verified PDF', style: TextStyle(fontSize: 11, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Drawer Tab 2: Report & Evidence Details
  Widget _buildTab2ReportAndEvidence(AdminApplicationModel app) {
    if (app.reportDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            const Text(
              'No Reports or Flags Registered',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 4),
            const Text(
              'This application maintains clean standing across academic proctor checks.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final rep = app.reportDetail!;

    return ListView(
      children: [
        // Severity Alert Card
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: rep.severity == 'Critical'
                            ? AppColors.error
                            : const Color(0xFF92400E),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REPORT FILED: ${rep.reportCategory.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: rep.severity == 'Critical'
                              ? AppColors.error
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              Text(
                'Filed by: ${rep.reportedBy} (${rep.reporterRole})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
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
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
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
              color: const Color(0xFF1E293B), // Dark slate
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rep.evidenceSnippet!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF38BDF8), // Light cyan
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Drawer Tab 3: Investigation Desk & Audit Trail
  Widget _buildTab3InvestigationAudit(AdminApplicationModel app) {
    return ListView(
      children: [
        _buildSectionHeader('Investigation Notes & Forensic Log'),
        const SizedBox(height: 8),
        if (app.investigationNotes.isEmpty)
          const Text('No investigation notes recorded yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
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
                style: const TextStyle(fontSize: 12.5, color: AppColors.darkNavy),
              ),
            );
          }),
        const SizedBox(height: 20),

        _buildSectionHeader('Administrative Audit Trail'),
        const SizedBox(height: 8),
        if (app.investigationHistory.isEmpty)
          const Text('No audit events registered.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
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
                      Text(
                        audit.action,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      Text(
                        audit.timestamp,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recorded by: ${audit.adminName}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  if (audit.findings != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Findings: "${audit.findings}"',
                      style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.darkNavy),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // Drawer Action Buttons
  Widget _buildDrawerActionButtons(BuildContext ctx, AdminApplicationModel app) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        // Add Investigation Note
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

        // Mark Under Investigation if reported
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

        // Dismiss Report (False Flag)
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

        // Resolve Report with Action
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

  // Investigation Dialogs
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Initiate forensic investigation on this flagged submission. Provide initial proctoring observations.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Initial Investigation Focus *',
                hintText: 'e.g. Initiating transcript verification cross-check with registrar...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _monitoringService.markCaseUnderInvestigation(
                applicationId: app.id,
                adminName: admin,
                initialNote: note,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${app.id} marked under active investigation.'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log forensic observations, registrar verification responses, or sponsor feedback.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Investigation Note *',
                hintText: 'e.g. Telephoned registrar office; confirmed candidate credentials match...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _monitoringService.recordInvestigationNote(
                applicationId: app.id,
                adminName: admin,
                note: note,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Investigation note securely logged into audit vault.'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dismissing this report designates the flag as a false positive or unfounded grievance. Enter dismissal findings.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Mandatory Dismissal Findings *',
                hintText: 'e.g. Technical terminology validated; no misconduct or policy violation committed...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _monitoringService.dismissReport(
                applicationId: app.id,
                adminName: admin,
                reason: reason,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report dismissed and student standing cleared.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record the formal administrative resolution findings to conclude this compliance case.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Summary *',
                  hintText: 'e.g. Infraction confirmed; candidate sanctioned under academic code of conduct...',
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
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: revokeApplication,
                  activeColor: AppColors.error,
                  title: const Text(
                    'Authorize Decision Modification',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
                  ),
                  subtitle: const Text(
                    'Administratively revoke this application and synchronize rejection across student and company panels.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) {
                    setDialogState(() => revokeApplication = val ?? false);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final summary = summaryController.text.trim();
                if (summary.isEmpty) return;

                final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
                await _monitoringService.resolveReportWithAction(
                  applicationId: app.id,
                  adminName: admin,
                  resolutionSummary: summary,
                  revokeApplication: revokeApplication,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Case resolved.${revokeApplication ? " Application administratively revoked." : ""}',
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Conclude Investigation'),
            ),
          ],
        ),
      ),
    );
  }

  // CSV Export Dialog
  void _exportCsvRecords(List<AdminApplicationModel> applications) {
    final csv = _monitoringService.exportApplicationsCsv(applications);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Export Application Registry (CSV)'),
          ],
        ),
        content: Column(
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
      style: const TextStyle(
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
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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
          drawer: isDesktop
              ? null
              : Drawer(
                  child: AdminSidebar(
                    activeRouteId: 'compliance',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              // Persistent Sidebar on Desktop
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

              // Main Work Area
              Expanded(
                child: Column(
                  children: [
                    // Top Navigation Bar
                    AdminTopNavbar(
                      pageTitle: 'Application Monitoring & Investigations',
                      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (query) {
                        setState(() {
                          _searchQuery = query;
                          _currentPage = 1;
                        });
                      },
                    ),

                    // Content Scroll Area
                    Expanded(
                      child: ValueListenableBuilder<List<AdminApplicationModel>>(
                        valueListenable: _monitoringService.applicationsNotifier,
                        builder: (context, applications, _) {
                          final filtered = _getFilteredApplications(applications);

                          // Pagination slice
                          final totalPages =
                              (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
                          final startIndex = (_currentPage - 1) * _itemsPerPage;
                          final pageItems =
                              filtered.skip(startIndex).take(_itemsPerPage).toList();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. 7 Application Overview Metric Cards
                                _buildApplicationOverviewMetrics(),
                                const SizedBox(height: 20),

                                // 2. Search, Multi-Filter & Action Bar
                                _buildFilterAndActionCard(filtered),
                                const SizedBox(height: 20),

                                // 3. Application Data Table Card with Pagination
                                _buildApplicationTableCard(pageItems, filtered.length, totalPages),
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

  // 1. 7 Application Overview Metric Cards
  Widget _buildApplicationOverviewMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 4;
        if (constraints.maxWidth < 650) {
          count = 1;
        } else if (constraints.maxWidth < 1100) {
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
            color: const Color(0xFF9333EA), // Purple
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
            childAspectRatio: count == 1 ? 3.0 : 1.75,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
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
            style: const TextStyle(
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

  // 2. Search, Multi-Filter & Action Bar
  Widget _buildFilterAndActionCard(List<AdminApplicationModel> filteredApplications) {
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
          // Top Row: Title, Summary & CSV Export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Surveillance & Investigation Desk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Audit flagged applications, review suspicious submissions, and investigate integrity infractions',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
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
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Filters Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Workflow Status Filter
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedWorkflowStatus,
                  decoration: InputDecoration(
                    labelText: 'Application Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _workflowStatusFilters
                      .map((st) => DropdownMenuItem(
                            value: st,
                            child: Text(st, style: const TextStyle(fontSize: 12.5)),
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

              // Report / Investigation Status Filter
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedReportStatus,
                  decoration: InputDecoration(
                    labelText: 'Report / Investigation Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _reportStatusFilters
                      .map((rst) => DropdownMenuItem(
                            value: rst,
                            child: Text(rst, style: const TextStyle(fontSize: 12.5)),
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

              // Date Filter
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDateFilter,
                  decoration: InputDecoration(
                    labelText: 'Submission Date',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _dateFilters
                      .map((df) => DropdownMenuItem(
                            value: df,
                            child: Text(df, style: const TextStyle(fontSize: 12.5)),
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

              // Sort Dropdown
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _sortOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 12.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Application Data Table Card with Pagination
  Widget _buildApplicationTableCard(
    List<AdminApplicationModel> pageApplications,
    int totalCount,
    int totalPages,
  ) {
    if (pageApplications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.find_in_page_outlined, size: 44, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No applications match the active criteria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try adjusting the search query, workflow status, or investigation filter.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
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
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageApplications.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final app = pageApplications[index];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Application ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        app.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Student Information
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.darkNavy,
                            child: Text(
                              app.studentName.isNotEmpty ? app.studentName[0] : 'S',
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
                                  '${app.university} • ${app.degree}',
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

                    // Project Title & Category
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

                    // Company Name
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

                    // Submission Date
                    SizedBox(
                      width: 90,
                      child: Text(
                        app.submissionDate,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),

                    // Workflow Status Badge
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
                    const SizedBox(width: 10),

                    // Report / Investigation Badge
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
                    const SizedBox(width: 14),

                    // Action: Investigate / View Details
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app.reportStatus == ApplicationReportStatus.reported ||
                                app.reportStatus == ApplicationReportStatus.underInvestigation
                            ? AppColors.error
                            : AppColors.darkNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: Icon(
                        app.reportStatus == ApplicationReportStatus.reported ||
                                app.reportStatus == ApplicationReportStatus.underInvestigation
                            ? Icons.search_rounded
                            : Icons.assignment_outlined,
                        size: 15,
                      ),
                      label: Text(
                        app.reportStatus == ApplicationReportStatus.reported ||
                                app.reportStatus == ApplicationReportStatus.underInvestigation
                            ? 'Investigate'
                            : 'View Details',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      onPressed: () => _openApplicationDetailsDrawer(app),
                    ),
                    const SizedBox(width: 6),

                    // Context Menu for Quick Operations
                    PopupMenuButton<String>(
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
                                Text('Mark Under Active Review',
                                    style: TextStyle(fontSize: 12, color: AppColors.warning)),
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
                                Text('Resolve Investigation',
                                    style: TextStyle(fontSize: 12, color: AppColors.success)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${pageApplications.length} of $totalCount applications (Page $_currentPage of $totalPages)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      '$_currentPage',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
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
}

