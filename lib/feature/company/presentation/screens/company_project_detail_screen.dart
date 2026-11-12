import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
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
  bool _isMarkingPaymentSent = false;

  ProjectModel? _resolveProject(List<ProjectModel> projects) {
    final targetId =
        widget.project?.id ?? widget.initialProject?.id ?? widget.projectId;
    if (targetId != null && targetId.isNotEmpty) {
      for (final p in projects) {
        if (p.id == targetId) return p;
      }
    }
    return widget.project ?? widget.initialProject;
  }

  bool _isAuthorized(ProjectModel project) {
    final company = _profileService.currentProfile;
    if (company.id.isEmpty || project.companyId.isEmpty) return true;
    return project.companyId == company.id ||
        project.companyName == company.companyName;
  }

  void _navigateToApplicants(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicantsScreen(projectId: project.id),
      ),
    );
  }

  void _navigateToAssignedStudents(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignedProjectsScreen(
          filterProjectId: project.id,
        ),
      ),
    );
  }

  Future<void> _markPaymentSent(ProjectModel project) async {
    if (_isMarkingPaymentSent || project.paymentSent) return;
    setState(() => _isMarkingPaymentSent = true);
    try {
      await _projectService.markProjectPaymentSent(project.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project payment marked as sent.'),
          backgroundColor: AppColors.statusOpen,
        ),
      );
    } catch (error) {
      debugPrint('Company project payment status update failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update payment status. Please try again.'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMarkingPaymentSent = false);
    }
  }

  Future<void> _confirmDeleteProject(ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to permanently delete "${project.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusClosed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Project'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _projectService.deleteProject(project.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project deleted successfully.'),
          backgroundColor: AppColors.deepNavy,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleEditProject(ProjectModel project) async {
    final hasAssignedStudent = project.assignedStudent != null &&
        project.assignedStudent!.trim().isNotEmpty;

    if (hasAssignedStudent) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: AppColors.statusPending),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scope Locked',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'A student is already assigned to "${project.title}". Core deliverables and requirements are locked to keep evaluation criteria consistent.',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostProjectScreen(existingProject: project),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project details updated.'),
          backgroundColor: AppColors.statusOpen,
        ),
      );
    }
  }

  Future<void> _confirmStatusTransition(
      ProjectModel project, String newStatus) async {
    final isClose = newStatus == 'Closed';
    final actionName = isClose ? 'Close Project' : 'Cancel Project';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isClose ? Icons.lock_outline : Icons.cancel_outlined,
                color: isClose ? AppColors.deepNavy : AppColors.statusClosed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$actionName?',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isClose
                ? 'Mark "${project.title}" as Closed? Students will no longer be able to submit new applications.'
                : 'Cancel "${project.title}"? This will end recruitment and mark the listing as cancelled.',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isClose ? AppColors.deepNavy : AppColors.statusClosed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirm $actionName'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _projectService.updateProjectStatus(project.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project status updated to "$newStatus".'),
          backgroundColor:
              isClose ? AppColors.deepNavy : AppColors.statusClosed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ProjectModel>>(
      valueListenable: _projectService.projectsNotifier,
      builder: (context, projects, _) {
        final project = _resolveProject(projects);

        if (project == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Project Details')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.folder_off_outlined,
                  title: 'Project Not Found',
                  subtitle:
                      'This project listing could not be located in your corporate workspace.',
                  actionLabel: 'Back to Projects',
                  onAction: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        }

        if (!_isAuthorized(project)) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Access Restricted')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.statusClosed,
                  title: 'Unauthorized Access',
                  subtitle:
                      'You can only manage projects belonging to your authenticated organization.',
                  actionLabel: 'Return',
                  onAction: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        }

        final canCloseOrCancel =
            project.status == 'Open' || project.status == 'In Progress';
        final isDraft = project.status == 'Draft';
        final hasAssignedStudents = project.assignedStudent != null &&
            project.assignedStudent!.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Project Management'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.deepNavy),
                tooltip: 'Project Actions',
                onSelected: (val) {
                  if (val == 'Edit') {
                    _handleEditProject(project);
                  } else if (val == 'Close') {
                    _confirmStatusTransition(project, 'Closed');
                  } else if (val == 'Cancel') {
                    _confirmStatusTransition(project, 'Cancelled');
                  } else if (val == 'ReviewApplicants') {
                    _navigateToApplicants(project);
                  } else if (val == 'AssignedStudents') {
                    _navigateToAssignedStudents(project);
                  } else if (val == 'Delete') {
                    _confirmDeleteProject(project);
                  } else if (val == 'PublishDraft') {
                    _projectService.updateProjectStatus(project.id, 'Open');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Draft listing is now published.'),
                        backgroundColor: AppColors.statusOpen,
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
                        Text('Review Applicants'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'AssignedStudents',
                    child: Row(
                      children: [
                        Icon(Icons.school_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Assigned Students'),
                      ],
                    ),
                  ),
                  if (isDraft || project.status == 'Open')
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
                              size: 18, color: AppColors.primaryBlue),
                          SizedBox(width: 8),
                          Text('Publish Listing'),
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
                              size: 18, color: AppColors.statusClosed),
                          SizedBox(width: 8),
                          Text(
                            'Cancel Project',
                            style: TextStyle(color: AppColors.statusClosed),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'Delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.statusClosed),
                        SizedBox(width: 8),
                        Text(
                          'Delete Project',
                          style: TextStyle(
                            color: AppColors.statusClosed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              if (hasAssignedStudents)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.statusPending, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Students are assigned to this project. Core deliverables and requirements are locked.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildHeroCard(project),
              const SizedBox(height: 16),
              _buildMetricsSection(project),
              const SizedBox(height: 16),
              _buildPaymentSection(project),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Project Description & Scope',
                icon: Icons.description_outlined,
                content: Text(
                  project.description.isNotEmpty
                      ? project.description
                      : 'No project description specified.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.darkText,
                    height: 1.5,
                  ),
                ),
              ),
              if (project.requirements.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Prerequisites & Eligibility',
                  icon: Icons.checklist_rtl_rounded,
                  content: Text(
                    project.requirements,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.darkText,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (project.skillsRequired.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Required Skills & Tech Stack',
                  icon: Icons.code_rounded,
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: project.skillsRequired
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.lightAqua,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: GoogleFonts.inter(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (project.deliverables.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Expected Deliverables',
                  icon: Icons.inventory_2_outlined,
                  content: Text(
                    project.deliverables,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.darkText,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildTimelineAndParametersSection(project),
              const SizedBox(height: 24),
              _buildManagementActionButtons(
                project,
                canCloseOrCancel,
                isDraft,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightAqua,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.category,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.primaryBlue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: project.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.title,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  project.companyName.isNotEmpty
                      ? project.companyName
                      : 'Corporate Partner',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(ProjectModel project) {
    final hasAssigned = project.assignedStudent != null &&
        project.assignedStudent!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToApplicants(project),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightAqua,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined,
                                size: 17, color: AppColors.primaryBlue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Applications',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${project.applicantsCount} Candidate(s)',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review pipeline →',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToAssignedStudents(project),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasAssigned
                          ? AppColors.successBg
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasAssigned
                                  ? Icons.school_rounded
                                  : Icons.person_search_rounded,
                              size: 17,
                              color: hasAssigned
                                  ? AppColors.statusOpen
                                  : AppColors.grayText,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Assigned',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: hasAssigned
                                      ? AppColors.statusOpen
                                      : AppColors.grayText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasAssigned ? project.assignedStudent! : 'Unassigned',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: hasAssigned
                                ? const Color(0xFF14532D)
                                : AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasAssigned ? 'View workspace →' : 'Open for hiring',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: hasAssigned
                                ? AppColors.statusOpen
                                : AppColors.grayText,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Milestone Execution Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(project.progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: project.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(ProjectModel project) {
    final hasAssignedStudent =
        project.assignedStudent != null &&
        project.assignedStudent!.trim().isNotEmpty;
    final statusColor = project.paymentSent
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);
    final statusBackground = project.paymentSent
        ? AppColors.successBg
        : AppColors.warningBg;

    return _buildSectionCard(
      title: 'Payment Status',
      icon: Icons.account_balance_wallet_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Project payment',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  project.paymentSent ? 'Paid' : 'Payment Pending',
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  !hasAssignedStudent ||
                      project.paymentSent ||
                      _isMarkingPaymentSent
                  ? null
                  : () => _markPaymentSent(project),
              icon: _isMarkingPaymentSent
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Payment Sent'),
            ),
          ),
          if (!hasAssignedStudent) ...[
            const SizedBox(height: 8),
            Text(
              'Assign a student before marking payment as sent.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grayText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineAndParametersSection(ProjectModel project) {
    return _buildSectionCard(
      title: 'Timeline & Parameters',
      icon: Icons.calendar_today_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Submission Deadline',
            value: project.deadline,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Collaboration Mode',
            value: project.projectType,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.group_outlined,
            label: 'Student Openings',
            value: '${project.openings} Open Seat(s)',
          ),
          if (project.additionalInstructions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Additional Instructions',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              project.additionalInstructions,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.grayText,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManagementActionButtons(
    ProjectModel project,
    bool canCloseOrCancel,
    bool isDraft,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToApplicants(project),
                icon: const Icon(Icons.people_outline, size: 18),
                label: Text('Applicants (${project.applicantsCount})'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _navigateToAssignedStudents(project),
                icon: const Icon(Icons.school_outlined, size: 18),
                label: const Text('Assigned Work'),
              ),
            ),
          ],
        ),
        if (isDraft) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusOpen,
              ),
              onPressed: () {
                _projectService.updateProjectStatus(project.id, 'Open');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Draft listing is now published.'),
                    backgroundColor: AppColors.statusOpen,
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Publish Draft Listing'),
            ),
          ),
        ],
        if (canCloseOrCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusClosed,
              ),
              onPressed: () => _confirmStatusTransition(project, 'Closed'),
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Close Project Applications'),
            ),
          ),
        ],
      ],
    );
  }

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
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 12),
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
        Icon(icon, size: 17, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
