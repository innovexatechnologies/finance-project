import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/services/escrow_lifecycle_service.dart';
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

  Future<void> _handleApproveAndRelease(ProjectModel project) async {
    final feedbackController = TextEditingController();
    final escrow = project.escrowAmount > 0 ? project.escrowAmount : 10000.0;
    final commission = double.parse((escrow * 0.10).toStringAsFixed(2));
    final studentPayout = double.parse((escrow - commission).toStringAsFixed(2));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.statusOpen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Approve & Release Payment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you satisfied with the deliverables submitted for "${project.title}"?',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.statusOpen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Escrow Funded Budget:', style: TextStyle(fontSize: 12)),
                        Text('PKR ${escrow.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platform Fee (10%):',
                            style: TextStyle(fontSize: 12, color: AppColors.grayText)),
                        Text('- PKR ${commission.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Student Payout (90%):',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14532D))),
                        Text('PKR ${studentPayout.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF14532D))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: feedbackController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Supervisor Feedback (Optional)',
                  hintText: 'Great work on deliverables...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Release'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await EscrowLifecycleService().approveAndReleasePayment(
        projectId: project.id,
        companyFeedback: feedbackController.text.trim().isEmpty ? null : feedbackController.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment approved! Admin notified to execute transfer to Student.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(EscrowLifecycleService().lastError ?? 'Unable to approve payout.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRaiseDispute(ProjectModel project) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Raise Escrow Dispute',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are deliverables for "${project.title}" incomplete or unsatisfactory? Raising a dispute halts auto-release and transfers the case to Skill Bridge Admin for mediation.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Dispute Reason / Details *',
                  hintText: 'Explain the issue with deliverables in detail...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please describe the reason for dispute.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Raise Dispute'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final caseId = await EscrowLifecycleService().raiseDispute(
        projectId: project.id,
        reason: reasonController.text.trim(),
        raisedByRole: 'Company (${project.companyName})',
      );

      if (!mounted) return;
      if (caseId != null) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Dispute Registered'),
              ],
            ),
            content: Text(
              'Dispute has been logged under Case $caseId.\n\nSkill Bridge Administrator has been alerted and will review project submissions, communication logs, and issue a binding resolution (100% Student, 100% Refund, or 50-50 Split).',
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(EscrowLifecycleService().lastError ?? 'Failed to raise dispute.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              if (project.isDelivered) ...[
                _buildDeliveryReviewCard(project),
                const SizedBox(height: 16),
              ] else if (project.isDisputed) ...[
                _buildDisputeStatusBanner(project),
                const SizedBox(height: 16),
              ] else if (project.isReadyForPayout) ...[
                _buildPayoutStatusBanner(project),
                const SizedBox(height: 16),
              ],
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
                            Text(
                              'Applications',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
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
                            Text(
                              'Assigned',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: hasAssigned
                                    ? AppColors.statusOpen
                                    : AppColors.grayText,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Milestone Execution Progress',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepNavy,
                ),
              ),
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
        if (project.isDelivered) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _handleApproveAndRelease(project),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Approve & Release Payment to Student'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _handleRaiseDispute(project),
              icon: const Icon(Icons.gavel_rounded, size: 18),
              label: const Text('Raise Dispute / Contest Deliverables'),
            ),
          ),
        ],
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
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.grayText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryReviewCard(ProjectModel project) {
    final remaining = project.autoReleaseRemaining;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Delivered Deliverables',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      '5-Day Auto-Release Window: $remaining remaining',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The assigned student has submitted completed deliverables. Please review the output. If accepted, approve the payment to trigger transfer. If no dispute or approval is registered within 5 days, Skill Bridge Admin will automatically release funds to the student.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF78350F),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Approve & Release'),
                  onPressed: () => _handleApproveAndRelease(project),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: const Text('Raise Dispute'),
                  onPressed: () => _handleRaiseDispute(project),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeStatusBanner(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispute Active [${project.disputeCaseId ?? "#SB-CASE"}]',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reason: "${project.disputeReason ?? "Deliverables under contention"}". Skill Bridge Admin is reviewing submissions and will issue a binding decision (100% Student, 100% Company, or 50-50 Split).',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFFB91C1C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutStatusBanner(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Color(0xFF059669),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for Payout',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Payout resolution applied (${project.payoutType ?? "full_student"}). Skill Bridge Admin will execute account transfer.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF047857),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
