import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicants_screen.dart';
import 'assigned_projects_screen.dart';
import 'post_project_screen.dart';

class CompanyProjectDetailScreen extends StatefulWidget {
  final ProjectModel? project;
  final String? projectId;
  final ProjectModel? initialProject;

  const CompanyProjectDetailScreen({
    super.key,
    this.project,
    this.projectId,
    this.initialProject,
  }) : assert(project != null || projectId != null || initialProject != null);

  @override
  State<CompanyProjectDetailScreen> createState() =>
      _CompanyProjectDetailScreenState();
}

class _CompanyProjectDetailScreenState
    extends State<CompanyProjectDetailScreen> {
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  late ProjectModel _project;
  bool _isAuthorized = true;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _project = widget.project!;
    } else if (widget.initialProject != null) {
      _project = widget.initialProject!;
    } else {
      _project = _projectService.allProjects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => _projectService.allProjects.first,
      );
    }
    _verifyCompanyOwnership();
  }

  // Functional Requirement: Verify that the project belongs to the logged-in company
  void _verifyCompanyOwnership() {
    final company = _profileService.currentProfile;
    if (_project.companyId != company.id &&
        _project.companyName != company.companyName) {
      setState(() {
        _isAuthorized = false;
      });
    }
  }

  // Navigate to Screen 28 (View / Review Applicants)
  void _navigateToApplicants() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicantsScreen(),
      ),
    );
  }

  // Navigate to Screen 30 (View Selected / Assigned Students)
  void _navigateToAssignedStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignedProjectsScreen(
          filterProjectId: _project.id,
        ),
      ),
    );
  }

  // Edit Project Scope (Restricted after student assignment)
  Future<void> _handleEditProject() async {
    final hasAssignedStudent = _project.assignedStudent != null;

    if (hasAssignedStudent) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Sensitive Edits Locked',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Students have already been assigned to "${_project.title}".\n\nCore deliverables and project requirements cannot be modified to protect student evaluation agreements.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Understand'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostProjectScreen(),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project listing refreshed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Confirmation before closing or cancelling project
  Future<void> _confirmStatusTransition(String newStatus) async {
    final isClose = newStatus == 'Closed';
    final actionName = isClose ? 'Close Project' : 'Cancel Project';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isClose ? Icons.lock_outline : Icons.cancel_outlined,
                color: isClose ? AppColors.darkNavy : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                '$actionName?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          content: Text(
            isClose
                ? 'Are you sure you want to mark "${_project.title}" as Closed?\n\nStudents will no longer be able to submit new applications.'
                : 'Are you sure you want to Cancel "${_project.title}"?\n\nThis will terminate project activity and mark it as cancelled.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isClose ? AppColors.darkNavy : AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirm $actionName'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _projectService.updateProjectStatus(_project.id, newStatus);
      if (!mounted) return;
      setState(() {
        _project = _project.copyWith(status: newStatus);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project status transitioned to "$newStatus"!'),
          backgroundColor: isClose ? AppColors.darkNavy : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Access Restricted'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Unauthorized Project Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can only manage projects belonging to your authenticated company.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to My Projects'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canCloseOrCancel =
        _project.status == 'Open' || _project.status == 'In Progress';
    final isDraft = _project.status == 'Draft';
    final hasAssignedStudents = _project.assignedStudent != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Manage Project (Screen 27)'),
        actions: [
          // Project Management Options (Dropdown Actions)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.darkNavy),
            tooltip: 'Management Actions (Requirement 14)',
            onSelected: (val) {
              if (val == 'Edit') {
                _handleEditProject();
              } else if (val == 'Close') {
                _confirmStatusTransition('Closed');
              } else if (val == 'Cancel') {
                _confirmStatusTransition('Cancelled');
              } else if (val == 'ReviewApplicants') {
                _navigateToApplicants();
              } else if (val == 'AssignedStudents') {
                _navigateToAssignedStudents();
              } else if (val == 'PublishDraft') {
                _projectService.updateProjectStatus(_project.id, 'Open');
                setState(() {
                  _project = _project.copyWith(status: 'Open');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Draft project is now live for students!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'ReviewApplicants',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Review Applicants (Screen 28)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'AssignedStudents',
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Assigned Students (Screen 30)'),
                  ],
                ),
              ),
              if (isDraft || _project.status == 'Open')
                const PopupMenuItem(
                  value: 'Edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Project Scope'),
                    ],
                  ),
                ),
              if (isDraft)
                const PopupMenuItem(
                  value: 'PublishDraft',
                  child: Row(
                    children: [
                      Icon(Icons.rocket_launch_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Publish Draft Listing'),
                    ],
                  ),
                ),
              if (canCloseOrCancel) ...[
                const PopupMenuItem(
                  value: 'Close',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Mark as Closed'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Project',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Sensitive edit restriction notice if student is assigned
          if (hasAssignedStudents)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Students are assigned to this project. Core deliverables & evaluation criteria are locked.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 1 & 2 & 11. Project Title, Category, and Publication Status Hero
          _buildHeroCard(),
          const SizedBox(height: 18),

          // 12 & 13. Total Applications & Assigned Students Metrics
          _buildMetricsSection(),
          const SizedBox(height: 18),

          // 3. Project Description
          _buildSectionCard(
            title: '3. Project Description & Scope',
            icon: Icons.description_outlined,
            content: Text(
              _project.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Project Requirements
          if (_project.requirements.isNotEmpty) ...[
            _buildSectionCard(
              title: '4. Student Prerequisites & Requirements',
              icon: Icons.checklist_rtl_rounded,
              content: Text(
                _project.requirements,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 5. Required Skills
          _buildSectionCard(
            title: '5. Required Skills & Tech Stack',
            icon: Icons.code_rounded,
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _project.skillsRequired
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: AppColors.lightIceBlue,
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 0.8,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),

          // 6. Project Deliverables
          if (_project.deliverables.isNotEmpty) ...[
            _buildSectionCard(
              title: '6. Expected Project Deliverables',
              icon: Icons.inventory_2_outlined,
              content: Text(
                _project.deliverables,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 7, 8, 9, 10. Deadline, Type, Openings, Instructions
          _buildTimelineAndParametersSection(),
          const SizedBox(height: 26),

          // 14. Project Management Action Bar
          _buildManagementActionButtons(canCloseOrCancel, isDraft),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Hero Card: Requirements 1, 2, 11
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _project.category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPublicationStatusBadge(_project.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _project.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.darkNavy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Sponsoring Company: ${_project.companyName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Metrics Section: Requirements 12 & 13
  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 12. Total Applications (Navigates to Screen 28)
              Expanded(
                child: InkWell(
                  onTap: _navigateToApplicants,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.people_alt_outlined,
                                size: 18, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Applications',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_project.applicantsCount} Students',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Review in Screen 28 >',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 13. Assigned Students (Navigates to Screen 30)
              Expanded(
                child: InkWell(
                  onTap: _navigateToAssignedStudents,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _project.assignedStudent != null
                          ? AppColors.successBg
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _project.assignedStudent != null
                                  ? Icons.school_rounded
                                  : Icons.person_search_rounded,
                              size: 18,
                              color: _project.assignedStudent != null
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Assigned Student',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _project.assignedStudent != null
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _project.assignedStudent ?? 'Unassigned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _project.assignedStudent != null
                                ? const Color(0xFF14532D)
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _project.assignedStudent != null
                              ? 'Manage in Screen 30 >'
                              : 'Open for hiring',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _project.assignedStudent != null
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Project Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Milestone Execution Progress:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              Text(
                '${(_project.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _project.progress,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  // Requirements 7, 8, 9, 10
  Widget _buildTimelineAndParametersSection() {
    return _buildSectionCard(
      title: 'Timeline & Project Parameters',
      icon: Icons.calendar_today_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.calendar_month,
            label: '7. Project Deadline',
            value: _project.deadline,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.apartment,
            label: '8. Project Type',
            value: _project.projectType,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.group,
            label: '9. Student Openings',
            value: '${_project.openings} Open Seat(s)',
          ),
          if (_project.additionalInstructions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            const Text(
              '10. Additional Instructions:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _project.additionalInstructions,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 14. Project Management Action Bar
  Widget _buildManagementActionButtons(bool canCloseOrCancel, bool isDraft) {
    return Column(
      children: [
        Row(
          children: [
            // Review Applicants Button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToApplicants,
                icon: const Icon(Icons.people_outline, size: 18),
                label: Text('Review Applicants (${_project.applicantsCount})'),
              ),
            ),
            const SizedBox(width: 10),

            // Assigned Students Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToAssignedStudents,
                icon: const Icon(Icons.school_outlined,
                    color: AppColors.primary, size: 18),
                label: const Text(
                  'Assigned Work',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (canCloseOrCancel) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              onPressed: () => _confirmStatusTransition('Closed'),
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Close Project Applications'),
            ),
          ),
        ],
      ],
    );
  }

  // Section Card Wrapper
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // 11. Project Publication Status Badge
  Widget _buildPublicationStatusBadge(String status) {
    Color bg;
    Color text;

    switch (status) {
      case 'Open':
        bg = AppColors.infoBg;
        text = AppColors.info;
        break;
      case 'In Progress':
        bg = const Color(0xFFE0F7FA);
        text = AppColors.accentTeal;
        break;
      case 'Completed':
        bg = AppColors.successBg;
        text = AppColors.success;
        break;
      case 'Draft':
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        break;
      case 'Closed':
        bg = const Color(0xFFE2E8F0);
        text = AppColors.darkNavy;
        break;
      case 'Cancelled':
        bg = AppColors.errorBg;
        text = AppColors.error;
        break;
      default:
        bg = AppColors.background;
        text = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
