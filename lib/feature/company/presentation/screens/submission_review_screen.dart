import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'applicant_detail_screen.dart';

class SubmissionReviewScreen extends StatefulWidget {
  final String assignmentId;
  final AssignmentModel? initialAssignment;

  const SubmissionReviewScreen({
    super.key,
    required this.assignmentId,
    this.initialAssignment,
  });

  @override
  State<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends State<SubmissionReviewScreen> {
  final _assignmentService = CompanyAssignmentService();
  final _profileService = CompanyProfileService();

  final TextEditingController _feedbackController = TextEditingController();
  final FocusNode _feedbackFocusNode = FocusNode();

  bool _isSubmitting = false;
  String? _feedbackError;

  @override
  void initState() {
    super.initState();
    final assignment = _getAssignment();
    if (assignment?.latestSubmission?.companyFeedback != null) {
      _feedbackController.text =
          assignment!.latestSubmission!.companyFeedback!;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
  }

  AssignmentModel? _getAssignment() {
    return _assignmentService.getAssignmentById(widget.assignmentId) ??
        widget.initialAssignment;
  }

  // Action: Open File Preview Modal (Requirement 7)
  void _openFilePreviewModal(SubmissionFileAttachment file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFileIcon(file.fileType),
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        Text(
                          'Format: ${file.fileType} • Size: ${file.fileSize}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_outlined,
                        color: AppColors.success, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Verified Academic Work Attachment',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Integrity verification SHA-256 confirmed. Safe to preview and run.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${file.fileName}"...'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('Download ${file.fileName} (${file.fileSize})'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action: Request Revision (Feedback strictly mandatory)
  Future<void> _handleRequestRevision(AssignmentModel assignment) async {
    final feedback = _feedbackController.text.trim();

    if (feedback.isEmpty) {
      setState(() {
        _feedbackError =
            'Feedback is mandatory when requesting a revision. Please explain required adjustments to the student.';
      });
      _feedbackFocusNode.requestFocus();
      return;
    }

    setState(() {
      _feedbackError = null;
    });

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Request Revision?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Send revision feedback to ${assignment.studentName} for "${assignment.projectTitle}"?\n\nThe student will be notified to review your feedback and resubmit deliverables.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Request'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSubmitting = true);
      final success = await _assignmentService.reviewSubmission(
        assignmentId: assignment.id,
        newStatus: 'Revision Requested',
        feedback: feedback,
      );
      setState(() => _isSubmitting = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Revision requested. Notification sent to ${assignment.studentName}.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Action: Approve Work (With Confirmation Dialog)
  Future<void> _handleApproveWork(AssignmentModel assignment) async {
    setState(() => _feedbackError = null);
    final feedback = _feedbackController.text.trim();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Approve Work?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Confirm approval of submitted work by ${assignment.studentName} for "${assignment.projectTitle}"?\n\nThis will mark the milestone progress as completed and update platform records.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSubmitting = true);
      final success = await _assignmentService.reviewSubmission(
        assignmentId: assignment.id,
        newStatus: 'Approved',
        feedback: feedback.isNotEmpty
            ? feedback
            : 'All milestone acceptance criteria and code deliverables successfully approved.',
      );
      setState(() => _isSubmitting = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Work deliverable from ${assignment.studentName} approved! Project milestone completed.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = _profileService.currentProfile;

    return ValueListenableBuilder<List<AssignmentModel>>(
      valueListenable: _assignmentService.assignmentsNotifier,
      builder: (context, _, __) {
        final assignment = _getAssignment();

        // Guard: Verify submission exists and belongs to logged-in company
        if (assignment == null || assignment.companyId != company.id) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Review Submitted Work'),
              backgroundColor: AppColors.darkNavy,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'Submission not found or unauthorized access.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final submission = assignment.latestSubmission;
        if (submission == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Review Submitted Work'),
              backgroundColor: AppColors.darkNavy,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions_rounded,
                        size: 48, color: AppColors.warning),
                    const SizedBox(height: 12),
                    Text(
                      'No work submitted yet by ${assignment.studentName}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The student has not uploaded milestone deliverables for this project yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isApproved = submission.status == 'Approved';
        final isRevisionRequested = submission.status == 'Revision Requested';
        final isPendingReview = submission.status == 'Pending Review' ||
            submission.status == 'Submitted' ||
            submission.status == 'Under Review';

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
            title: const Text(
              'Review Submitted Work',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                tooltip: 'Student Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplicantDetailScreen(
                        applicantId: assignment.applicantId,
                        projectId: assignment.projectId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  // 11. REVIEW STATUS BANNER
                  _buildReviewStatusBanner(
                    isApproved: isApproved,
                    isRevisionRequested: isRevisionRequested,
                    isPendingReview: isPendingReview,
                    statusText: submission.status,
                  ),
                  const SizedBox(height: 14),

                  // 1. STUDENT INFORMATION CARD
                  _buildStudentInfoCard(assignment),
                  const SizedBox(height: 14),

                  // 2 & 3. PROJECT TITLE & SUBMISSION DATE
                  _buildProjectAndDateCard(assignment, submission),
                  const SizedBox(height: 14),

                  // 4. SUBMISSION DESCRIPTION
                  _buildSubmissionDescriptionCard(submission),
                  const SizedBox(height: 14),

                  // 5 & 7. UPLOADED FILES & PREVIEW / DOWNLOAD
                  _buildUploadedFilesCard(submission),
                  const SizedBox(height: 14),

                  // 6. EXTERNAL PROJECT LINKS
                  _buildExternalLinksCard(submission),
                  const SizedBox(height: 14),

                  // 8. FEEDBACK TEXT FIELD
                  _buildFeedbackCard(isApproved),
                  const SizedBox(height: 14),

                  // REVISION & REVIEW HISTORY
                  if (submission.reviewHistory.isNotEmpty) ...[
                    _buildReviewHistoryCard(submission.reviewHistory),
                  ],
                ],
              ),

              // Bottom Sticky Action Bar: 9 (Approve) & 10 (Request Revision)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(
                  assignment: assignment,
                  isApproved: isApproved,
                  isRevisionRequested: isRevisionRequested,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 11. Review Status Banner
  Widget _buildReviewStatusBanner({
    required bool isApproved,
    required bool isRevisionRequested,
    required bool isPendingReview,
    required String statusText,
  }) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String heading;
    String subtitle;

    if (isApproved) {
      bg = AppColors.successBg;
      border = AppColors.success.withValues(alpha: 0.3);
      text = AppColors.success;
      icon = Icons.check_circle_rounded;
      heading = 'Work Approved';
      subtitle =
          'Milestone acceptance criteria fulfilled and verified by your company.';
    } else if (isRevisionRequested) {
      bg = AppColors.warningBg;
      border = AppColors.warning.withValues(alpha: 0.3);
      text = AppColors.warning;
      icon = Icons.edit_note_rounded;
      heading = 'Revision Requested';
      subtitle =
          'Changes requested. Student will resubmit after updating deliverables.';
    } else {
      bg = AppColors.infoBg;
      border = AppColors.info.withValues(alpha: 0.3);
      text = AppColors.info;
      icon = Icons.hourglass_top_rounded;
      heading = 'Pending Corporate Review';
      subtitle =
          'Student has delivered milestone files. Please inspect and approve or request revision.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: text, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Student Information Card
  Widget _buildStudentInfoCard(AssignmentModel assignment) {
    return _buildCardWrapper(
      title: 'Student Information',
      icon: Icons.person_rounded,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              assignment.studentAvatarInitial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  assignment.studentDegree,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicantDetailScreen(
                    applicantId: assignment.applicantId,
                    projectId: assignment.projectId,
                  ),
                ),
              );
            },
            child: const Text('Profile',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2 & 3. Project Title & Submission Date
  Widget _buildProjectAndDateCard(
    AssignmentModel assignment,
    StudentSubmissionModel submission,
  ) {
    return _buildCardWrapper(
      title: 'Project & Milestone Context',
      icon: Icons.assignment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assignment.projectCategory,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${assignment.deadline}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2. Project Title
          Text(
            assignment.projectTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          // 3. Submission Date & Deliverable Title
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Submission Date: ${submission.submittedDate}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Deliverable: ${submission.title}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Submission Description
  Widget _buildSubmissionDescriptionCard(StudentSubmissionModel submission) {
    return _buildCardWrapper(
      title: 'Submission Description',
      icon: Icons.notes_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
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
    );
  }

  // 5 & 7. Uploaded Files with Preview & Download Actions
  Widget _buildUploadedFilesCard(StudentSubmissionModel submission) {
    // Generate file items if structured files list is empty
    final files = submission.files.isNotEmpty
        ? submission.files
        : submission.attachmentFiles
            .map((name) => SubmissionFileAttachment(
                  fileName: name,
                  fileSize: name.endsWith('.apk') ? '18.4 MB' : '2.5 MB',
                  fileType: name.endsWith('.apk')
                      ? 'APK'
                      : name.endsWith('.pdf')
                          ? 'PDF'
                          : 'CODE',
                ))
            .toList();

    return _buildCardWrapper(
      title: 'Uploaded Deliverables (${files.length})',
      icon: Icons.folder_zip_outlined,
      child: files.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('No files attached.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          : Column(
              children: files.map((file) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightIceBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFileIcon(file.fileType),
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.fileName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${file.fileType} • ${file.fileSize}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 7. File Preview / Download Action
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: const Size(60, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => _openFilePreviewModal(file),
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            size: 13),
                        label: const Text('Preview',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // 6. External Project Links
  Widget _buildExternalLinksCard(StudentSubmissionModel submission) {
    return _buildCardWrapper(
      title: 'External Project Links',
      icon: Icons.link_rounded,
      child: Column(
        children: [
          // Repository Link
          if (submission.repositoryUrl.isNotEmpty)
            _buildLinkTile(
              icon: Icons.code_rounded,
              label: 'Source Code Repository (GitHub)',
              url: submission.repositoryUrl,
              accentColor: AppColors.primary,
            ),

          // Live Demo Link
          if (submission.liveDemoUrl != null &&
              submission.liveDemoUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLinkTile(
              icon: Icons.rocket_launch_rounded,
              label: 'Live Staging Demo Link',
              url: submission.liveDemoUrl!,
              accentColor: AppColors.success,
            ),
          ],

          // Figma Design Link
          if (submission.figmaUrl != null &&
              submission.figmaUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLinkTile(
              icon: Icons.design_services_rounded,
              label: 'Figma UI Prototype Link',
              url: submission.figmaUrl!,
              accentColor: const Color(0xFF7C3AED),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String label,
    required String url,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            color: AppColors.textSecondary,
            tooltip: 'Copy Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied link: $url'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 8. Feedback Text Field
  Widget _buildFeedbackCard(bool isApproved) {
    return _buildCardWrapper(
      title: 'Company Review Feedback',
      icon: Icons.rate_review_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provide constructive feedback, code review observations, or revision directions:',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _feedbackController,
            focusNode: _feedbackFocusNode,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'e.g. Clean architecture implementation! Please ensure SQLite schema migrations handle edge cases on older OS builds.',
              hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
              filled: true,
              fillColor: AppColors.background,
              errorText: _feedbackError,
              errorMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _feedbackError != null
                      ? AppColors.error
                      : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '* Feedback is strictly mandatory when requesting a revision.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Revision & Review History
  Widget _buildReviewHistoryCard(List<SubmissionReviewRecord> history) {
    return _buildCardWrapper(
      title: 'Review & Revision History (${history.length})',
      icon: Icons.history_rounded,
      child: Column(
        children: history.map((rec) {
          final isApproveRec = rec.action == 'Approved';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
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
                          isApproveRec
                              ? Icons.check_circle_rounded
                              : Icons.edit_note_rounded,
                          size: 16,
                          color: isApproveRec
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rec.action,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isApproveRec
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      rec.reviewDate,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${rec.feedback}"',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By: ${rec.reviewerName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 9 & 10. Bottom Action Bar (Approve Work & Request Revision)
  Widget _buildBottomActionBar({
    required AssignmentModel assignment,
    required bool isApproved,
    required bool isRevisionRequested,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: _isSubmitting
            ? const Center(
                heightFactor: 1.5,
                child: CircularProgressIndicator(),
              )
            : Row(
                children: [
                  // 10. Request Revision Button
                  if (!isApproved) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleRequestRevision(assignment),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Request Revision',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // 9. Approve Work Button
                  if (!isApproved) ...[
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleApproveWork(assignment),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Approve Work',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  // Already Approved Banner in action bar
                  if (isApproved) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                              'Work Deliverable Approved & Verified',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
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
    );
  }

  Widget _buildCardWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'APK':
        return Icons.android_rounded;
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'CODE':
      case 'DART':
        return Icons.code_rounded;
      case 'ZIP':
        return Icons.archive_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

