import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/core/services/cloud_storage_service.dart';
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

  static const List<String> _certificateTitles = [
    'Certificate of Project Completion',
    'Certificate of Excellence',
    'Outstanding Engineering Distinction',
  ];

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

  Future<void> _openExternalUrl(String rawUrl, String label) async {
    await CloudStorageService.openUrl(
      context,
      rawUrl,
      label: label,
      copyFallback: true,
    );
  }

  void _openAttachmentSheet(SubmissionFileAttachment file) {
    final assignment = _getAssignment();
    final repoUrl = assignment?.latestSubmission?.repositoryUrl.trim() ?? '';
    final isFileAUrl = file.fileName.startsWith('http://') ||
        file.fileName.startsWith('https://') ||
        file.fileName.startsWith('www.');
    final targetUrl = isFileAUrl
        ? file.fileName
        : (repoUrl.startsWith('http://') || repoUrl.startsWith('https://')
            ? repoUrl
            : '');
    final hasUrl = targetUrl.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightAqua,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFileIcon(file.fileType),
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        Text(
                          '${file.fileType} • ${file.fileSize}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grayText,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (hasUrl) {
                      _openExternalUrl(targetUrl, 'Attachment');
                    } else {
                      Clipboard.setData(ClipboardData(text: file.fileName));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied "${file.fileName}" to clipboard.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    hasUrl ? Icons.open_in_new_rounded : Icons.copy_rounded,
                    size: 18,
                  ),
                  label: Text(
                    hasUrl ? 'Open Deliverable' : 'Copy Attachment Name',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRequestRevision(AssignmentModel assignment) async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      setState(() {
        _feedbackError =
            'Feedback is required when requesting revisions. Describe the exact changes needed.';
      });
      _feedbackFocusNode.requestFocus();
      return;
    }

    setState(() => _feedbackError = null);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.statusPending),
            const SizedBox(width: 8),
            Text(
              'Request Revision?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Send revision notes to ${assignment.studentName} for "${assignment.projectTitle}"?',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusPending,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final success = await _assignmentService.reviewSubmission(
      assignmentId: assignment.id,
      newStatus: 'Revision Requested',
      feedback: feedback,
    );
    if (mounted) setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revision request sent to the student.'),
          backgroundColor: AppColors.statusPending,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleApproveWork(AssignmentModel assignment) async {
    double rating = 5.0;
    String selectedCertTitle = _certificateTitles.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.statusOpen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Approve & Issue Certificate',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
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
                  'Approving ${assignment.studentName}\'s deliverable marks "${assignment.projectTitle}" Completed and issues a verifiable digital certificate.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 16),
                Text(
                  'Performance Rating: ${rating.toStringAsFixed(1)} / 5.0',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                Slider(
                  value: rating,
                  min: 3.0,
                  max: 5.0,
                  divisions: 4,
                  activeColor: AppColors.statusOpen,
                  label: rating.toStringAsFixed(1),
                  onChanged: (v) => setDialogState(() => rating = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'Certificate Honor Title',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCertTitle,
                  isExpanded: true,
                  items: _certificateTitles
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCertTitle = val);
                    }
                  },
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
                backgroundColor: AppColors.statusOpen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approve & Certify'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _feedbackError = null;
      _isSubmitting = true;
    });

    final success = await _assignmentService.reviewSubmission(
      assignmentId: assignment.id,
      newStatus: 'Approved',
      feedback: _feedbackController.text.trim(),
      overallRating: rating,
      certificateTitle: selectedCertTitle,
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Work approved and $selectedCertTitle issued to ${assignment.studentName}!',
          ),
          backgroundColor: AppColors.statusOpen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'APK':
        return Icons.android_rounded;
      case 'ZIP':
        return Icons.folder_zip_rounded;
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AssignmentModel>>(
      valueListenable: _assignmentService.assignmentsNotifier,
      builder: (context, _, _) {
        final assignment = _getAssignment();
        final company = _profileService.currentProfile;

        if (assignment == null ||
            (company.id.isNotEmpty &&
                assignment.companyId.isNotEmpty &&
                assignment.companyId != company.id)) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Submission Review')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: AppEmptyState(
                  icon: Icons.assignment_late_outlined,
                  title: 'Submission Not Available',
                  subtitle:
                      'This deliverable cannot be accessed or has not been submitted yet.',
                  actionLabel: 'Back',
                  onAction: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        }

        final submission = assignment.latestSubmission;
        if (submission == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Submission Review')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: AppEmptyState(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'No Deliverable Uploaded Yet',
                  subtitle:
                      '${assignment.studentName} has not submitted deliverables for "${assignment.projectTitle}" yet.',
                  actionLabel: 'Back',
                  onAction: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        }

        final isApproved = submission.status == 'Approved';
        final hasAnyLink = submission.repositoryUrl.trim().isNotEmpty ||
            (submission.liveDemoUrl?.trim().isNotEmpty ?? false) ||
            (submission.figmaUrl?.trim().isNotEmpty ?? false);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.deepNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Deliverable Review',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              TextButton.icon(
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
                icon: const Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  'Profile',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            child: Text(
                              assignment.studentAvatarInitial,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment.studentName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  assignment.projectTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppColors.lightAqua,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: submission.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        submission.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted ${submission.submittedDate}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.lightAqua,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Deliverable Notes',
                  icon: Icons.notes_rounded,
                  child: Text(
                    submission.notes,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.55,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                if (hasAnyLink) ...[
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Submitted Links',
                    icon: Icons.link_rounded,
                    child: Column(
                      children: [
                        if (submission.repositoryUrl.trim().isNotEmpty)
                          _buildLinkTile(
                            'Deliverable / Repository URL',
                            submission.repositoryUrl,
                            Icons.code_rounded,
                          ),
                        if (submission.liveDemoUrl != null &&
                            submission.liveDemoUrl!.trim().isNotEmpty)
                          _buildLinkTile(
                            'Live Demo URL',
                            submission.liveDemoUrl!,
                            Icons.rocket_launch_outlined,
                          ),
                        if (submission.figmaUrl != null &&
                            submission.figmaUrl!.trim().isNotEmpty)
                          _buildLinkTile(
                            'Design / Prototype URL',
                            submission.figmaUrl!,
                            Icons.design_services_outlined,
                          ),
                      ],
                    ),
                  ),
                ],
                if (submission.files.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Attached Deliverables (${submission.files.length})',
                    icon: Icons.attach_file_rounded,
                    child: Column(
                      children: submission.files.map((file) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.lightAqua,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getFileIcon(file.fileType),
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            file.fileName,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          subtitle: Text(
                            '${file.fileType} • ${file.fileSize}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new_rounded,
                                color: AppColors.primaryBlue),
                            onPressed: () => _openAttachmentSheet(file),
                          ),
                          onTap: () => _openAttachmentSheet(file),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildCard(
                  title: isApproved
                      ? 'Evaluation Completed'
                      : 'Corporate Evaluation & Feedback',
                  icon: isApproved
                      ? Icons.verified_rounded
                      : Icons.rate_review_outlined,
                  child: isApproved
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.workspace_premium_rounded,
                                      color: AppColors.statusOpen),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Approved and verifiable certificate issued to ${assignment.studentName}.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (submission.companyFeedback != null &&
                                submission.companyFeedback!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                submission.companyFeedback!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leave commendation remarks before approving, or provide specific revision feedback.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.grayText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _feedbackController,
                              focusNode: _feedbackFocusNode,
                              maxLines: 4,
                              onChanged: (_) {
                                if (_feedbackError != null) {
                                  setState(() => _feedbackError = null);
                                }
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Write technical evaluation or revision points...',
                                errorText: _feedbackError,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.statusPending,
                                      side: const BorderSide(
                                          color: AppColors.statusPending),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                    ),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () =>
                                            _handleRequestRevision(assignment),
                                    icon: const Icon(Icons.edit_note_rounded,
                                        size: 18),
                                    label: const Text('Request Revision'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.statusOpen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                    ),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => _handleApproveWork(assignment),
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18),
                                    label: const Text('Approve Work'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                if (submission.reviewHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Review History',
                    icon: Icons.history_rounded,
                    child: Column(
                      children: submission.reviewHistory.map((rec) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusBadge(label: rec.action),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${rec.reviewerName} • ${rec.reviewDate}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      rec.feedback,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinkTile(String title, String url, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.lightAqua,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 19),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.deepNavy,
        ),
      ),
      subtitle: Text(
        url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.primaryBlue,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded,
                size: 18, color: AppColors.primaryBlue),
            onPressed: () => _openExternalUrl(url, title),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
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
}
