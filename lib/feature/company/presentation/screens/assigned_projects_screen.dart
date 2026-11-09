import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicant_detail_screen.dart';
import 'company_project_detail_screen.dart';

class AssignedProjectsScreen extends StatefulWidget {
  final String? filterProjectId;

  const AssignedProjectsScreen({
    super.key,
    this.filterProjectId,
  });

  @override
  State<AssignedProjectsScreen> createState() => _AssignedProjectsScreenState();
}

class _AssignedProjectsScreenState extends State<AssignedProjectsScreen> {
  final _assignmentService = CompanyAssignmentService();
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  late String? _selectedProjectId;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final List<String> _statusFilters = [
    'All',
    'In Progress',
    'Under Review',
    'Submitted',
    'Approved',
    'Pending Work',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.filterProjectId;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => _isLoading = false);
  }

  // Action: Open Student Profile (Screen 29)
  void _navigateToStudentProfile(AssignmentModel assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantDetailScreen(
          applicantId: assignment.applicantId,
          projectId: assignment.projectId,
        ),
      ),
    );
  }

  // Action: Open Project Details (Screen 27)
  void _navigateToProjectDetails(AssignmentModel assignment) {
    ProjectModel? targetProject;
    try {
      targetProject = _projectService.allProjects.firstWhere(
        (p) => p.id == assignment.projectId,
      );
    } catch (_) {
      targetProject = null;
    }

    if (targetProject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyProjectDetailScreen(
            projectId: targetProject!.id,
            initialProject: targetProject,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project details for "${assignment.projectTitle}" unavailable.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Action: Open Submission Modal (Requirement 10)
  void _openSubmissionModal(AssignmentModel assignment) {
    final submission = assignment.latestSubmission;
    if (submission == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lightIceBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fact_check_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Student Work Submission',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Status & Submission Date Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Assigned: ${assignment.studentName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              _buildSubmissionBadge(submission.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Project: ${assignment.projectTitle}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Submitted: ${submission.submittedDate}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deliverable Title
                    const Text(
                      'Milestone Deliverable Title',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      submission.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student Notes & Changelog
                    const Text(
                      'Student Delivery Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        submission.notes,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Code Repository URL
                    if (submission.repositoryUrl.isNotEmpty) ...[
                      const Text(
                        'Verified Source Code Repository',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.code_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                submission.repositoryUrl,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: submission.repositoryUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Repository URL copied: ${submission.repositoryUrl}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Live Demo Link
                    if (submission.liveDemoUrl != null) ...[
                      const Text(
                        'Live Demo & Staging Preview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.rocket_launch_rounded,
                                color: AppColors.success, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                submission.liveDemoUrl!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Opening staging preview: ${submission.liveDemoUrl!}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Attached Files
                    if (submission.attachmentFiles.isNotEmpty) ...[
                      const Text(
                        'Attached Work Deliverables',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: submission.attachmentFiles.map((file) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file_rounded,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(60, 24),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Downloading $file...'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.download_rounded,
                                      size: 14),
                                  label: const Text('Download',
                                      style: TextStyle(fontSize: 11.5)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Company Feedback (if revision requested or approved)
                    if (submission.companyFeedback != null &&
                        submission.companyFeedback!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: submission.status == 'Approved'
                              ? AppColors.successBg
                              : AppColors.warningBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: submission.status == 'Approved'
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  submission.status == 'Approved'
                                      ? Icons.check_circle_rounded
                                      : Icons.feedback_outlined,
                                  size: 16,
                                  color: submission.status == 'Approved'
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  submission.status == 'Approved'
                                      ? 'Corporate Approval Notes'
                                      : 'Corporate Revision Feedback',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: submission.status == 'Approved'
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              submission.companyFeedback!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Actions: Request Revision vs Approve Milestone
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Request Revision button
                    if (submission.status != 'Approved') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _promptRequestRevision(assignment);
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Request Revision',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Approve Deliverable button
                    if (submission.status != 'Approved') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmApproveSubmission(assignment);
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 18),
                          label: const Text('Approve Work',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    // If already approved, show completed notice
                    if (submission.status == 'Approved') ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: AppColors.success, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Milestone Deliverable Approved',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action: Request Revision Dialog
  void _promptRequestRevision(AssignmentModel assignment) {
    final feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Request Revision',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify adjustments required from ${assignment.studentName} for "${assignment.projectTitle}":',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Please add error handling for network timeouts and update README.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
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
              final text = feedbackCtrl.text.trim();
              if (text.isEmpty) return;

              Navigator.pop(ctx);
              final success = await _assignmentService.reviewSubmission(
                assignmentId: assignment.id,
                newStatus: 'Revision Requested',
                feedback: text,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Revision requested from ${assignment.studentName}.'),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  // Action: Confirm Approve Submission
  void _confirmApproveSubmission(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Approve Deliverable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Confirm approval of submitted work by ${assignment.studentName} for "${assignment.projectTitle}"?\n\nThis will mark milestone progress as completed and update platform records.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
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
              Navigator.pop(ctx);
              final success = await _assignmentService.reviewSubmission(
                assignmentId: assignment.id,
                newStatus: 'Approved',
                feedback:
                    'Excellent work! All milestone acceptance criteria successfully satisfied.',
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '🎉 Deliverable from ${assignment.studentName} approved! Project completed.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Approve Deliverable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = _profileService.currentProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Projects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Selected Students • ${company.companyName}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.lightIceBlue,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Assignments',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AssignmentModel>>(
        valueListenable: _assignmentService.assignmentsNotifier,
        builder: (context, allAssignments, _) {
          // Strictly filter assignments belonging to the logged-in company
          final companyAssignments = allAssignments
              .where((a) => a.companyId == company.id)
              .toList();

          // Optional filter by specific project if opened from Screen 27
          final projectFiltered = _selectedProjectId != null
              ? companyAssignments
                  .where((a) => a.projectId == _selectedProjectId)
                  .toList()
              : companyAssignments;

          // Apply Status Tabs
          List<AssignmentModel> statusFiltered;
          if (_selectedFilter == 'In Progress') {
            statusFiltered = projectFiltered
                .where((a) => a.projectStatus == 'In Progress')
                .toList();
          } else if (_selectedFilter == 'Under Review') {
            statusFiltered = projectFiltered
                .where((a) => a.submissionStatus == 'Under Review')
                .toList();
          } else if (_selectedFilter == 'Submitted') {
            statusFiltered = projectFiltered
                .where((a) => a.submissionStatus == 'Submitted')
                .toList();
          } else if (_selectedFilter == 'Approved') {
            statusFiltered = projectFiltered
                .where((a) =>
                    a.submissionStatus == 'Approved' ||
                    a.projectStatus == 'Completed')
                .toList();
          } else if (_selectedFilter == 'Pending Work') {
            statusFiltered = projectFiltered
                .where((a) => !a.hasSubmission)
                .toList();
          } else {
            statusFiltered = projectFiltered;
          }

          // Apply Live Search Query
          final displayList = _searchQuery.isEmpty
              ? statusFiltered
              : statusFiltered.where((a) {
                  return a.studentName.toLowerCase().contains(_searchQuery) ||
                      a.projectTitle.toLowerCase().contains(_searchQuery) ||
                      a.studentUniversity.toLowerCase().contains(_searchQuery) ||
                      a.projectCategory.toLowerCase().contains(_searchQuery);
                }).toList();

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                // Project Scope Banner (if opened for a specific project)
                if (_selectedProjectId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: AppColors.lightIceBlue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.filter_list_rounded,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Filtered by selected project',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedProjectId = null;
                            });
                          },
                          child: const Text('Show All',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search by student name, university, or project...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedFilter == filter;

                      // Count for this filter
                      int count = 0;
                      if (filter == 'All') {
                        count = projectFiltered.length;
                      } else if (filter == 'In Progress') {
                        count = projectFiltered
                            .where((a) => a.projectStatus == 'In Progress')
                            .length;
                      } else if (filter == 'Under Review') {
                        count = projectFiltered
                            .where((a) => a.submissionStatus == 'Under Review')
                            .length;
                      } else if (filter == 'Submitted') {
                        count = projectFiltered
                            .where((a) => a.submissionStatus == 'Submitted')
                            .length;
                      } else if (filter == 'Approved') {
                        count = projectFiltered
                            .where((a) =>
                                a.submissionStatus == 'Approved' ||
                                a.projectStatus == 'Completed')
                            .length;
                      } else if (filter == 'Pending Work') {
                        count = projectFiltered
                            .where((a) => !a.hasSubmission)
                            .length;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text('$filter ($count)'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Content List or Empty State
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : displayList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                return _buildAssignmentCard(displayList[index]);
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 1-10. Complete Assignment Card (All 10 UI requirements)
  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final hasSubmission = assignment.hasSubmission;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Student Profile Image, Student Name, University, Project Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. Student Profile Image / Avatar Initial
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary,
                child: Text(
                  assignment.studentAvatarInitial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 1. Selected Student Name & Degree
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assignment.studentUniversity,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      assignment.studentDegree,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Current Project Status Badge
              _buildProjectStatusBadge(assignment.projectStatus),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // 3. Assigned Project Title & Category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assignment.projectCategory,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            assignment.projectTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 8),

          // 4 & 5. Project Start Date & Project Deadline
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Started: ${assignment.startDate}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Row(
                children: [
                  const Icon(Icons.alarm_rounded,
                      size: 13, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${assignment.deadline}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: assignment.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      assignment.progress >= 1.0
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(assignment.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 7. Submission Status Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      hasSubmission
                          ? Icons.task_alt_rounded
                          : Icons.pending_actions_rounded,
                      size: 16,
                      color: hasSubmission
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasSubmission
                          ? 'Work Submitted for Review'
                          : 'Student working on milestone',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasSubmission
                            ? AppColors.darkNavy
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildSubmissionBadge(assignment.submissionStatus),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: 8 (View Profile), 9 (View Project), 10 (Open Submission)
          Row(
            children: [
              // 8. View Student Profile button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _navigateToStudentProfile(assignment),
                child: const Text('Student Profile',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),

              // 9. View Project button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _navigateToProjectDetails(assignment),
                child: const Text('View Project',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),

              // 10. Open Submission button (when work is available)
              if (hasSubmission) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _openSubmissionModal(assignment),
                  icon: const Icon(Icons.file_open_rounded, size: 14),
                  label: const Text('Open Work',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Awaiting Work',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 6. Project Status Badge Widget
  Widget _buildProjectStatusBadge(String status) {
    Color bg;
    Color textColor;

    switch (status) {
      case 'Completed':
        bg = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'In Progress':
        bg = AppColors.lightIceBlue;
        textColor = AppColors.primary;
        break;
      default:
        bg = AppColors.warningBg;
        textColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 7. Submission Status Badge Widget
  Widget _buildSubmissionBadge(String status) {
    Color bg;
    Color textColor;

    switch (status) {
      case 'Approved':
        bg = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'Submitted':
        bg = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'Under Review':
        bg = AppColors.infoBg;
        textColor = AppColors.info;
        break;
      case 'Revision Requested':
        bg = AppColors.warningBg;
        textColor = AppColors.warning;
        break;
      default:
        bg = AppColors.background;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightIceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_ind_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Assigned Students Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you accept student applicants from Screen 28, their assigned projects and milestone submissions will be managed right here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (_selectedFilter != 'All' || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'All';
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

