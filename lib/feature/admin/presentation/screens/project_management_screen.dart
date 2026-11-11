import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';

/// Enterprise Project Management & Moderation Screen for SkillBridge Admin Panel (Screen 37)
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
  final AdminSettingsService _settingsService = AdminSettingsService();
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

  List<String> _buildCategoryOptions(List<AdminProjectModel> projects) {
    final set = <String>{'All Categories'};
    for (final cat in _settingsService.categoriesNotifier.value) {
      final name = cat.name.trim();
      if (name.isNotEmpty) set.add(name);
    }
    for (final p in projects) {
      final cat = p.category.trim();
      if (cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }

  Future<void> _refreshProjects() async {
    await _projectService.loadFromSupabase();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project catalog synced from Supabase.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (routeId == 'projects_audit' || routeId == 'projects') return;

    Widget? target;
    if (routeId == 'dashboard') {
      target = const AdminDashboardScreen();
    } else if (routeId == 'student_verifications') {
      target = const StudentManagementScreen();
    } else if (routeId == 'company_verifications') {
      target = const CompanyVerificationsScreen();
    } else if (routeId == 'company_management') {
      target = const CompanyManagementScreen();
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      target = const ApplicationMonitoringScreen();
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      target = const CertificateManagementScreen();
    } else if (routeId == 'analytics' || routeId == 'reports') {
      target = const ReportsAnalyticsScreen();
    } else if (routeId == 'settings') {
      target = const AdminSettingsScreen();
    }

    if (target != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target!),
      );
    }
  }

  // Filter & Sort Logic
  List<AdminProjectModel> _getFilteredProjects(
    List<AdminProjectModel> projects, {
    required String effectiveCategory,
  }) {
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
      if (effectiveCategory != 'All Categories' && p.category != effectiveCategory) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Sponsored by: ${project.companyName} • ID: ${project.id}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusPill(
                    label: project.statusDisplay,
                    color: _getStatusColor(project.status),
                    bgColor: _getStatusBgColor(project.status),
                  ),
                  _buildStatusPill(
                    label: 'Pub: ${project.publicationStatusDisplay}',
                    color: project.publicationStatus == AdminPublicationStatus.published
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    bgColor: project.publicationStatus == AdminPublicationStatus.published
                        ? AppColors.lightIceBlue
                        : AppColors.background,
                  ),
                  _buildStatusPill(
                    label: '${project.applicantsCount} Applicants',
                    color: AppColors.darkNavy,
                    bgColor: AppColors.background,
                  ),
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
                  project.description.isEmpty
                      ? 'No project description provided.'
                      : project.description,
                  style: GoogleFonts.inter(
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
              if (project.skillsRequired.isEmpty)
                Text(
                  'No specific skills listed.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                )
              else
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
                        style: GoogleFonts.inter(
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
                            Expanded(
                              child: Text(
                                audit.action,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: AppColors.darkNavy,
                                ),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (project.status == AdminProjectStatus.pendingReview) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject Submission'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptRejectProject(project);
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Approve & Publish'),
                      onPressed: () async {
                        final admin =
                            _authService.currentAdmin?.fullName ?? 'Executive Administrator';
                        await _projectService.publishProject(
                          projectId: project.id,
                          moderatorName: admin,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${project.title}" has been published for students!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ] else if (project.status == AdminProjectStatus.published ||
                      project.status == AdminProjectStatus.active) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.lock_clock_outlined, size: 16),
                      label: const Text('Close Project'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptCloseProject(project);
                      },
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.visibility_off_outlined, size: 16),
                      label: const Text('Unpublish'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptUnpublishProject(project);
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_forever_outlined, size: 16),
                      label: const Text('Remove (Policy)'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptRemoveProject(project);
                      },
                    ),
                  ] else if (project.status == AdminProjectStatus.removed) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                      label: const Text('Restore Removed Listing'),
                      onPressed: () async {
                        final admin =
                            _authService.currentAdmin?.fullName ?? 'Executive Administrator';
                        await _projectService.restoreRemovedProject(
                          projectId: project.id,
                          moderatorName: admin,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${project.title}" listing has been restored.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _projectService.rejectProject(
                projectId: project.id,
                reason: reason,
                moderatorName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
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
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _projectService.removePolicyViolatingProject(
                projectId: project.id,
                reason: reason,
                moderatorName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
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
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _projectService.unpublishProject(
                projectId: project.id,
                reason: reason,
                moderatorName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
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
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _projectService.closeProject(
                projectId: project.id,
                moderatorName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
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
      final admin = _authService.currentAdmin?.fullName ?? 'Executive Administrator';
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
            Expanded(
              child: Text(
                'Export Project Roster (CSV)',
                overflow: TextOverflow.ellipsis,
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
                'The authorized project moderation registry has been generated in CSV format per platform retention standards:',
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
                          final categories = _buildCategoryOptions(projects);
                          final effectiveCategory =
                              categories.contains(_selectedCategory)
                                  ? _selectedCategory
                                  : 'All Categories';

                          final filtered = _getFilteredProjects(
                            projects,
                            effectiveCategory: effectiveCategory,
                          );

                          // Pagination slice
                          final totalPages =
                              (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
                          final safePage = _currentPage.clamp(1, totalPages);
                          final startIndex = (safePage - 1) * _itemsPerPage;
                          final pageItems = filtered
                              .skip(startIndex)
                              .take(_itemsPerPage)
                              .toList();

                          return SingleChildScrollView(
                            padding: EdgeInsets.all(isDesktop ? 24 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProjectOverviewMetrics(),
                                const SizedBox(height: 20),
                                _buildFilterAndActionCard(
                                  categories: categories,
                                  selectedCategory: effectiveCategory,
                                  filteredProjects: filtered,
                                ),
                                const SizedBox(height: 20),
                                _buildProjectTableCard(
                                  pageProjects: pageItems,
                                  totalCount: filtered.length,
                                  safePage: safePage,
                                  totalPages: totalPages,
                                  hasAnyProjects: projects.isNotEmpty,
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
            childAspectRatio: count == 1 ? 2.7 : 1.6,
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
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. Search, Multi-Filter & Action Bar
  Widget _buildFilterAndActionCard({
    required List<String> categories,
    required String selectedCategory,
    required List<AdminProjectModel> filteredProjects,
  }) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 720
                          ? constraints.maxWidth - 460
                          : constraints.maxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Moderation & Sprints Governance',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review newly submitted sprints, regulate publication status, and enforce academic compliance',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh'),
                        onPressed: _refreshProjects,
                      ),
                      if (_selectedProjectIds.isNotEmpty) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label:
                              Text('Bulk Publish (${_selectedProjectIds.length})'),
                          onPressed: () =>
                              _handleBulkModerate(AdminProjectStatus.published),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64748B),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.lock_clock_outlined, size: 16),
                          label:
                              Text('Bulk Close (${_selectedProjectIds.length})'),
                          onPressed: () =>
                              _handleBulkModerate(AdminProjectStatus.closed),
                        ),
                      ],
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkNavy,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export CSV'),
                        onPressed: () => _exportCsvRecords(filteredProjects),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Filters Row 1: Category, Status, Publication, and Sort
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: compact ? constraints.maxWidth : 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category Vertical',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: categories
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
                  SizedBox(
                    width: compact ? constraints.maxWidth : 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedProjectStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Project Status',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _projectStatusFilters
                          .map((st) => DropdownMenuItem(
                                value: st,
                                child: Text(
                                  st,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                  SizedBox(
                    width: compact ? constraints.maxWidth : 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPublicationStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Publication Status',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _publicationStatusFilters
                          .map((pub) => DropdownMenuItem(
                                value: pub,
                                child: Text(
                                  pub,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                  SizedBox(
                    width: compact ? constraints.maxWidth : 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _sortOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
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

  Widget _buildProjectStatusBadge(AdminProjectModel project) {
    return Container(
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
    );
  }

  Widget _buildPublicationBadge(AdminProjectModel project) {
    final isPub = project.publicationStatus == AdminPublicationStatus.published;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPub ? AppColors.lightIceBlue : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPub ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Text(
        project.publicationStatusDisplay,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isPub ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProjectActionMenu(AdminProjectModel project) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (val) {
        if (val == 'details') {
          _openProjectDetailsDrawer(project);
        } else if (val == 'publish') {
          final admin =
              _authService.currentAdmin?.fullName ?? 'Executive Administrator';
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
              _authService.currentAdmin?.fullName ?? 'Executive Administrator';
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
                Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
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
    );
  }

  // 3. Project Data Table Card with Pagination
  Widget _buildProjectTableCard({
    required List<AdminProjectModel> pageProjects,
    required int totalCount,
    required int safePage,
    required int totalPages,
    required bool hasAnyProjects,
  }) {
    if (pageProjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: AppEmptyState(
          icon: Icons.assignment_late_outlined,
          title: hasAnyProjects
              ? 'No projects match the active criteria'
              : 'No company projects submitted yet',
          subtitle: hasAnyProjects
              ? 'Try adjusting the search query, category, or project status filter.'
              : 'Company sprint listings submitted in Supabase will appear here automatically.',
          actionLabel: hasAnyProjects ? 'Reset Filters' : 'Refresh',
          onAction: hasAnyProjects
              ? () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'All Categories';
                    _selectedProjectStatus = 'All Statuses';
                    _selectedPublicationStatus = 'All Publications';
                    _currentPage = 1;
                  });
                }
              : _refreshProjects,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;

          return Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageProjects.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final project = pageProjects[index];
                  final isChecked = _selectedProjectIds.contains(project.id);

                  if (isCompact) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.title,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.darkNavy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${project.companyName} • ${project.category}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              _buildProjectActionMenu(project),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${project.projectType} • ${project.duration} • Deadline: ${project.deadline}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (project.skillsRequired.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: project.skillsRequired.take(3).map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
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
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildProjectStatusBadge(project),
                              _buildPublicationBadge(project),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.assignment_outlined,
                                    size: 15),
                                label: const Text('View Details',
                                    style: TextStyle(fontSize: 11.5)),
                                onPressed: () =>
                                    _openProjectDetailsDrawer(project),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
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
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${project.category} • ${project.openings} Opening(s) • ${project.id}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
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
                                project.companyName,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Created: ${project.createdAt}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: project.skillsRequired.take(2).map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
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
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${project.projectType} • ${project.duration}',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.darkNavy),
                              ),
                              Text(
                                'Deadline: ${project.deadline}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        _buildProjectStatusBadge(project),
                        const SizedBox(width: 10),
                        _buildPublicationBadge(project),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.assignment_outlined, size: 15),
                          label: const Text('View Details',
                              style: TextStyle(fontSize: 11.5)),
                          onPressed: () => _openProjectDetailsDrawer(project),
                        ),
                        const SizedBox(width: 6),
                        _buildProjectActionMenu(project),
                      ],
                    ),
                  );
                },
              ),

              // Pagination Bar
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      'Showing ${pageProjects.length} of $totalCount projects (Page $safePage of $totalPages)',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
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
                          style: GoogleFonts.poppins(
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
          );
        },
      ),
    );
  }
}

