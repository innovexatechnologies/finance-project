import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';

/// Enterprise Project Management & Moderation Screen for CampusConnect Admin Panel (Screen 37)
/// Features project listing grid, multi-parameter filtering, full project inspection drawer,
/// moderation workflows (publish, unpublish, close, remove), and policy retention controls.
class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminProjectService _projectService = AdminProjectService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  String _selectedProjectStatus = 'All Statuses';
  String _selectedPublicationStatus = 'All Publications';
  String _sortBy = 'Newest First';

  bool _isSidebarCollapsed = false;
  final Set<String> _selectedProjectIds = {};

  // Pagination controls
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _categories = [
    'All Categories',
    'Mobile App Development',
    'Web Development',
    'AI / Machine Learning & Data',
    'Cloud Infrastructure & DevOps',
    'IoT & Embedded Systems',
    'Blockchain & Distributed Systems',
  ];

  final List<String> _projectStatusFilters = [
    'All Statuses',
    'Draft',
    'Pending Review',
    'Published',
    'Active',
    'Completed',
    'Closed',
    'Rejected',
    'Removed',
  ];

  final List<String> _publicationStatusFilters = [
    'All Publications',
    'Published',
    'Unpublished',
    'Pending Moderation',
    'Rejected',
    'Removed Listing',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Most Applicants',
    'Title (A-Z)',
    'Deadline (Nearest)',
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
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ApplicationMonitoringScreen()),
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
    // If routeId is 'projects_audit', we are already on this screen.
  }

  // Filter & Sort Logic
  List<AdminProjectModel> _getFilteredProjects(List<AdminProjectModel> projects) {
    return projects.where((p) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = p.title.toLowerCase().contains(query);
        final matchesCompany = p.companyName.toLowerCase().contains(query);
        final matchesCategory = p.category.toLowerCase().contains(query);
        final matchesId = p.id.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCompany && !matchesCategory && !matchesId) {
          return false;
        }
      }

      // 2. Category Filter
      if (_selectedCategory != 'All Categories' && p.category != _selectedCategory) {
        return false;
      }

      // 3. Project Status Filter
      if (_selectedProjectStatus != 'All Statuses' &&
          p.statusDisplay != _selectedProjectStatus) {
        return false;
      }

      // 4. Publication Status Filter
      if (_selectedPublicationStatus != 'All Publications' &&
          p.publicationStatusDisplay != _selectedPublicationStatus) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'Newest First') {
          return b.createdDateTime.compareTo(a.createdDateTime);
        } else if (_sortBy == 'Oldest First') {
          return a.createdDateTime.compareTo(b.createdDateTime);
        } else if (_sortBy == 'Most Applicants') {
          return b.applicantsCount.compareTo(a.applicantsCount);
        } else if (_sortBy == 'Title (A-Z)') {
          return a.title.compareTo(b.title);
        } else {
          return a.deadlineDateTime.compareTo(b.deadlineDateTime);
        }
      });
  }

  // 4. Detailed Project Information Drawer
  void _openProjectDetailsDrawer(AdminProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
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
                          color: _getStatusColor(project.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(project.status),
                          color: _getStatusColor(project.status),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          Text(
                            'Sponsored by: ${project.companyName} • ID: ${project.id}',
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
              const SizedBox(height: 12),

              // Status Summary Badges
              Row(
                children: [
                  _buildStatusPill(
                    label: project.statusDisplay,
                    color: _getStatusColor(project.status),
                    bgColor: _getStatusBgColor(project.status),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(
                    label: 'Pub: ${project.publicationStatusDisplay}',
                    color: project.publicationStatus == AdminPublicationStatus.published
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    bgColor: project.publicationStatus == AdminPublicationStatus.published
                        ? AppColors.lightIceBlue
                        : AppColors.background,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(
                    label: '${project.applicantsCount} Applicants',
                    color: AppColors.darkNavy,
                    bgColor: AppColors.background,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(
                    label: project.projectType,
                    color: AppColors.darkNavy,
                    bgColor: AppColors.background,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Narrative Description
              _buildSectionHeader('1. Project Title & Detailed Description'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  project.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Company Information
              _buildSectionHeader('2. Corporate Sponsor & Organizational Liaison'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.domain_rounded, 'Company Name', project.companyName),
              _buildInfoRow(Icons.numbers_rounded, 'Company Identifier', project.companyId),
              _buildInfoRow(Icons.category_rounded, 'Category Vertical', project.category),
              _buildInfoRow(Icons.schedule_rounded, 'Listing Created On', project.createdAt),
              const SizedBox(height: 20),

              // 3. Required Skills
              _buildSectionHeader('3. Required Technical Skillset'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.skillsRequired.map((skill) {
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
              const SizedBox(height: 20),

              // 4. Expected Deliverables & Requirements
              _buildSectionHeader('4. Expected Deliverables & Prerequisites'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.checklist_rounded, 'Deliverables', project.deliverables),
              _buildInfoRow(Icons.fact_check_outlined, 'Academic Requirements', project.requirements),
              if (project.additionalInstructions.isNotEmpty)
                _buildInfoRow(
                  Icons.info_outline_rounded,
                  'Sprint Instructions',
                  project.additionalInstructions,
                ),
              const SizedBox(height: 20),

              // 5. Application Parameters & Participation
              _buildSectionHeader('5. Sprint Parameters & Application Deadlines'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.hourglass_bottom_rounded, 'Estimated Duration', project.duration),
              _buildInfoRow(Icons.event_available_rounded, 'Application Deadline', project.deadline),
              _buildInfoRow(Icons.group_outlined, 'Available Student Openings', '${project.openings} Seat(s)'),
              _buildInfoRow(Icons.people_outline_rounded, 'Received Applications', '${project.applicantsCount} student(s) applied'),
              if (project.assignedStudent != null)
                _buildInfoRow(Icons.person_pin_rounded, 'Assigned Student', project.assignedStudent!),
              _buildInfoRow(Icons.trending_up_rounded, 'Milestone Progress', '${(project.progress * 100).toInt()}% delivered'),
              const SizedBox(height: 20),

              // 6. Moderation / Policy Removal Alert Box
              if (project.moderationReason != null) ...[
                _buildSectionHeader('Policy / Moderation Notice'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: project.status == AdminProjectStatus.removed
                        ? AppColors.errorBg
                        : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: project.status == AdminProjectStatus.removed
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            project.status == AdminProjectStatus.removed
                                ? Icons.warning_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: project.status == AdminProjectStatus.removed
                                ? AppColors.error
                                : const Color(0xFF92400E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            project.status == AdminProjectStatus.removed
                                ? 'POLICY COMPLIANCE DE-LISTING'
                                : 'MODERATION REMARKS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: project.status == AdminProjectStatus.removed
                                  ? AppColors.error
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project.moderationReason!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: project.status == AdminProjectStatus.removed
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF78350F),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 7. Moderation History & Audit Trail
              _buildSectionHeader('6. Moderation & Compliance Audit Trail'),
              const SizedBox(height: 8),
              if (project.moderationHistory.isEmpty)
                const Text(
                  'No prior moderation events recorded.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                )
              else
                ...project.moderationHistory.map((audit) {
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
                          'Moderator: ${audit.moderatorName}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        if (audit.reason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: "${audit.reason}"',
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
              const SizedBox(height: 24),

              // Primary Action Buttons
              Row(
                children: [
                  // Review Pending Project
                  if (project.status == AdminProjectStatus.pendingReview) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Reject Submission'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _promptRejectProject(project);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Approve & Publish'),
                        onPressed: () async {
                          final admin =
                              _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
                          await _projectService.publishProject(
                            projectId: project.id,
                            moderatorName: admin,
                          );
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${project.title}" has been published for students!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ] else if (project.status == AdminProjectStatus.published ||
                      project.status == AdminProjectStatus.active) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.lock_clock_outlined, size: 16),
                        label: const Text('Close Project'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _promptCloseProject(project);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.visibility_off_outlined, size: 16),
                        label: const Text('Unpublish'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _promptUnpublishProject(project);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_forever_outlined, size: 16),
                        label: const Text('Remove (Policy)'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _promptRemoveProject(project);
                        },
                      ),
                    ),
                  ] else if (project.status == AdminProjectStatus.removed) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                        label: const Text('Restore Removed Listing'),
                        onPressed: () async {
                          final admin =
                              _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
                          await _projectService.restoreRemovedProject(
                            projectId: project.id,
                            moderatorName: admin,
                          );
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${project.title}" listing has been restored.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Rejection Reason Prompt
  void _promptRejectProject(AdminProjectModel project) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reject Submission: ${project.title}',
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
              'A mandatory reason is required so corporate liaisons can rectify project prerequisites.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Mandatory Rejection Reason *',
                hintText: 'e.g. Scope missing academic learning deliverables or requirements vague...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _projectService.rejectProject(
                projectId: project.id,
                reason: reason,
                moderatorName: admin,
              );

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Project rejected. Reason logged in audit vault.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Submit Rejection'),
          ),
        ],
      ),
    );
  }

  // 5. Policy Removal Reason Prompt
  void _promptRemoveProject(AdminProjectModel project) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_outlined, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'De-list Listing: ${project.title}',
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
              'De-listing soft-archives this project per platform retention policy. It will be removed from student discovery.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Policy Infraction / Removal Reason *',
                hintText: 'e.g. Commercial crypto speculation or prohibited financial activity...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _projectService.removePolicyViolatingProject(
                projectId: project.id,
                reason: reason,
                moderatorName: admin,
              );

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Project de-listed and archived for retention compliance.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm De-listing'),
          ),
        ],
      ),
    );
  }

  // 5. Unpublish Project Prompt
  void _promptUnpublishProject(AdminProjectModel project) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.visibility_off_outlined, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unpublish: ${project.title}',
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
              'Unpublishing hides the project from student feeds while allowing the company to revise parameters.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Unpublish Reason *',
                hintText: 'e.g. Prerequisite clarification requested by company sponsor...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _projectService.unpublishProject(
                projectId: project.id,
                reason: reason,
                moderatorName: admin,
              );

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Project unpublished from public discovery.'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Unpublish Listing'),
          ),
        ],
      ),
    );
  }

  // 5. Close Project Prompt
  void _promptCloseProject(AdminProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Close Project: ${project.title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Closing this project concludes the application window. No new student applications will be permitted.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _projectService.closeProject(
                projectId: project.id,
                moderatorName: admin,
              );

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Project closed successfully.'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Close'),
          ),
        ],
      ),
    );
  }

  // 7. Bulk Moderation Handling
  void _handleBulkModerate(AdminProjectStatus newStatus) async {
    if (_selectedProjectIds.isEmpty) return;

    final count = _selectedProjectIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bulk ${newStatus.name.toUpperCase()} $count Projects?'),
        content: Text(
          'This batch operation will update status for all $count selected projects simultaneously across all panels.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == AdminProjectStatus.published
                  ? AppColors.success
                  : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm Bulk ${newStatus.name.toUpperCase()}'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
      await _projectService.bulkModerateProjects(
        projectIds: _selectedProjectIds.toList(),
        newStatus: newStatus,
        moderatorName: admin,
      );
      setState(() => _selectedProjectIds.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully executed batch moderation across $count projects!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 7. Export Records to CSV Dialog
  void _exportCsvRecords(List<AdminProjectModel> projects) {
    final csv = _projectService.exportProjectsCsv(projects);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Export Project Roster (CSV)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The authorized project moderation registry has been generated in CSV format per platform retention standards:',
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
                  content: Text('Project CSV records copied to clipboard!'),
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

  // Color & Icon Helpers for 8 Project Statuses
  Color _getStatusColor(AdminProjectStatus status) {
    switch (status) {
      case AdminProjectStatus.draft:
        return const Color(0xFF64748B);
      case AdminProjectStatus.pendingReview:
        return AppColors.warning;
      case AdminProjectStatus.published:
        return AppColors.primary;
      case AdminProjectStatus.active:
        return const Color(0xFF0284C7); // Sky blue
      case AdminProjectStatus.completed:
        return AppColors.success;
      case AdminProjectStatus.closed:
        return const Color(0xFF475569);
      case AdminProjectStatus.rejected:
        return AppColors.error;
      case AdminProjectStatus.removed:
        return const Color(0xFFDC2626);
    }
  }

  Color _getStatusBgColor(AdminProjectStatus status) {
    switch (status) {
      case AdminProjectStatus.draft:
        return AppColors.background;
      case AdminProjectStatus.pendingReview:
        return AppColors.warningBg;
      case AdminProjectStatus.published:
        return AppColors.lightIceBlue;
      case AdminProjectStatus.active:
        return const Color(0xFFE0F2FE);
      case AdminProjectStatus.completed:
        return AppColors.successBg;
      case AdminProjectStatus.closed:
        return AppColors.background;
      case AdminProjectStatus.rejected:
      case AdminProjectStatus.removed:
        return AppColors.errorBg;
    }
  }

  IconData _getStatusIcon(AdminProjectStatus status) {
    switch (status) {
      case AdminProjectStatus.draft:
        return Icons.edit_note_rounded;
      case AdminProjectStatus.pendingReview:
        return Icons.hourglass_top_rounded;
      case AdminProjectStatus.published:
        return Icons.public_rounded;
      case AdminProjectStatus.active:
        return Icons.pending_actions_rounded;
      case AdminProjectStatus.completed:
        return Icons.verified_rounded;
      case AdminProjectStatus.closed:
        return Icons.lock_clock_outlined;
      case AdminProjectStatus.rejected:
        return Icons.cancel_outlined;
      case AdminProjectStatus.removed:
        return Icons.delete_forever_outlined;
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
                    activeRouteId: 'projects_audit',
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
                  activeRouteId: 'projects_audit',
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
                      pageTitle: 'Project Moderation & Sprints',
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
                      child: ValueListenableBuilder<List<AdminProjectModel>>(
                        valueListenable: _projectService.projectsNotifier,
                        builder: (context, projects, _) {
                          final filtered = _getFilteredProjects(projects);

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
                                // 1. 7 Overview Metric Cards
                                _buildProjectOverviewMetrics(),
                                const SizedBox(height: 20),

                                // 2. Search, Multi-Filter & Action Bar
                                _buildFilterAndActionCard(filtered),
                                const SizedBox(height: 20),

                                // 3. Project Data Table Card with Pagination
                                _buildProjectTableCard(pageItems, filtered.length, totalPages),
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

  // 1. 7 Project Overview Metric Cards
  Widget _buildProjectOverviewMetrics() {
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
            title: 'Total Projects',
            value: '${_projectService.totalCount}',
            subtitle: 'All created collaboration sprints',
            icon: Icons.assignment_outlined,
            color: AppColors.primary,
            bgColor: AppColors.lightIceBlue,
          ),
          _buildMetricTile(
            title: 'Pending Review',
            value: '${_projectService.pendingReviewCount}',
            subtitle: 'Moderation queue awaiting review',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warning,
            bgColor: AppColors.warningBg,
          ),
          _buildMetricTile(
            title: 'Published Projects',
            value: '${_projectService.publishedCount}',
            subtitle: 'Open for student applications',
            icon: Icons.public_rounded,
            color: AppColors.accentTeal,
            bgColor: AppColors.accentTeal.withValues(alpha: 0.12),
          ),
          _buildMetricTile(
            title: 'Active Projects',
            value: '${_projectService.activeCount}',
            subtitle: 'Assigned & in-progress sprints',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
          ),
          _buildMetricTile(
            title: 'Completed Projects',
            value: '${_projectService.completedCount}',
            subtitle: 'Successfully delivered sprints',
            icon: Icons.verified_rounded,
            color: AppColors.success,
            bgColor: AppColors.successBg,
          ),
          _buildMetricTile(
            title: 'Closed Projects',
            value: '${_projectService.closedCount}',
            subtitle: 'Application windows concluded',
            icon: Icons.lock_clock_outlined,
            color: const Color(0xFF64748B),
            bgColor: AppColors.background,
          ),
          _buildMetricTile(
            title: 'Removed Projects',
            value: '${_projectService.removedCount}',
            subtitle: 'De-listed for policy non-compliance',
            icon: Icons.delete_forever_outlined,
            color: AppColors.error,
            bgColor: AppColors.errorBg,
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
  Widget _buildFilterAndActionCard(List<AdminProjectModel> filteredProjects) {
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
          // Top Row: Title, Bulk Actions & CSV Export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Moderation & Sprints Governance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Review newly submitted sprints, regulate publication status, and enforce academic compliance',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (_selectedProjectIds.isNotEmpty) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text('Bulk Publish (${_selectedProjectIds.length})'),
                      onPressed: () => _handleBulkModerate(AdminProjectStatus.published),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.lock_clock_outlined, size: 16),
                      label: Text('Bulk Close (${_selectedProjectIds.length})'),
                      onPressed: () => _handleBulkModerate(AdminProjectStatus.closed),
                    ),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkNavy,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Records (CSV)'),
                    onPressed: () => _exportCsvRecords(filteredProjects),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Filters Row 1: Category, Status, Publication, and Sort
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Category Dropdown
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category Vertical',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),

              // Project Status Dropdown
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedProjectStatus,
                  decoration: InputDecoration(
                    labelText: 'Project Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _projectStatusFilters
                      .map((st) => DropdownMenuItem(
                            value: st,
                            child: Text(st, style: const TextStyle(fontSize: 12.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProjectStatus = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),

              // Publication Status Dropdown
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPublicationStatus,
                  decoration: InputDecoration(
                    labelText: 'Publication Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _publicationStatusFilters
                      .map((pub) => DropdownMenuItem(
                            value: pub,
                            child: Text(pub, style: const TextStyle(fontSize: 12.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPublicationStatus = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),

              // Sort Dropdown
              SizedBox(
                width: 190,
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

  // 3. Project Data Table Card with Pagination
  Widget _buildProjectTableCard(
    List<AdminProjectModel> pageProjects,
    int totalCount,
    int totalPages,
  ) {
    if (pageProjects.isEmpty) {
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
              Icon(Icons.assignment_late_outlined, size: 44, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No projects match the active criteria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try adjusting the search query, category, or project status filter.',
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
            itemCount: pageProjects.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final project = pageProjects[index];
              final isChecked = _selectedProjectIds.contains(project.id);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: isChecked,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedProjectIds.add(project.id);
                          } else {
                            _selectedProjectIds.remove(project.id);
                          }
                        });
                      },
                    ),

                    // Project Title & ID
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppColors.darkNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${project.category} • ${project.openings} Opening(s) • ${project.id}',
                            style: const TextStyle(
                              fontSize: 11.5,
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
                            project.companyName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Created: ${project.createdAt}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skills Required Preview (First 2 pills)
                    Expanded(
                      flex: 2,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: project.skillsRequired.take(2).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lightIceBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Project Type & Duration
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${project.projectType} • ${project.duration}',
                            style: const TextStyle(fontSize: 12, color: AppColors.darkNavy),
                          ),
                          Text(
                            'Deadline: ${project.deadline}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Project Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(project.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(project.status),
                            size: 13,
                            color: _getStatusColor(project.status),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            project.statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(project.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Publication Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: project.publicationStatus == AdminPublicationStatus.published
                            ? AppColors.lightIceBlue
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: project.publicationStatus == AdminPublicationStatus.published
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        project.publicationStatusDisplay,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: project.publicationStatus == AdminPublicationStatus.published
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Action: View Details
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.assignment_outlined, size: 15),
                      label: const Text('View Details', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => _openProjectDetailsDrawer(project),
                    ),
                    const SizedBox(width: 6),

                    // Action: Context Popup Menu for Quick Moderation
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (val) {
                        if (val == 'details') {
                          _openProjectDetailsDrawer(project);
                        } else if (val == 'publish') {
                          final admin =
                              _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
                          _projectService.publishProject(
                            projectId: project.id,
                            moderatorName: admin,
                          );
                        } else if (val == 'unpublish') {
                          _promptUnpublishProject(project);
                        } else if (val == 'reject') {
                          _promptRejectProject(project);
                        } else if (val == 'close') {
                          _promptCloseProject(project);
                        } else if (val == 'remove') {
                          _promptRemoveProject(project);
                        } else if (val == 'restore') {
                          final admin =
                              _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
                          _projectService.restoreRemovedProject(
                            projectId: project.id,
                            moderatorName: admin,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('View Full Details', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        if (project.status == AdminProjectStatus.pendingReview) ...[
                          const PopupMenuItem(
                            value: 'publish',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 16, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Approve & Publish',
                                    style: TextStyle(fontSize: 12, color: AppColors.success)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reject',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 16, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Reject Submission',
                                    style: TextStyle(fontSize: 12, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                        if (project.status == AdminProjectStatus.published) ...[
                          const PopupMenuItem(
                            value: 'unpublish',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_off_outlined,
                                    size: 16, color: AppColors.warning),
                                SizedBox(width: 8),
                                Text('Unpublish Listing',
                                    style: TextStyle(fontSize: 12, color: AppColors.warning)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'close',
                            child: Row(
                              children: [
                                Icon(Icons.lock_clock_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Close Project', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever_outlined,
                                    size: 16, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Remove (Policy Non-Compliance)',
                                    style: TextStyle(fontSize: 12, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                        if (project.status == AdminProjectStatus.removed) ...[
                          const PopupMenuItem(
                            value: 'restore',
                            child: Row(
                              children: [
                                Icon(Icons.restore_from_trash_rounded,
                                    size: 16, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Restore Listing',
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
                  'Showing ${pageProjects.length} of $totalCount projects (Page $_currentPage of $totalPages)',
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

