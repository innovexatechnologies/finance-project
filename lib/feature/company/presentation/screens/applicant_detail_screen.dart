import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class ApplicantDetailScreen extends StatefulWidget {
  final String applicantId;
  final String? projectId;
  final ApplicantModel? initialApplicant;

  const ApplicantDetailScreen({
    super.key,
    required this.applicantId,
    this.projectId,
    this.initialApplicant,
  });

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  final _applicantService = CompanyApplicantService();
  final _projectService = CompanyProjectService();
  bool _isProcessingAction = false;

  ApplicantModel? _getLatestApplicant() {
    return _applicantService.getApplicantById(widget.applicantId) ??
        widget.initialApplicant;
  }

  // Action: Shortlist Applicant
  Future<void> _handleShortlist(ApplicantModel applicant) async {
    setState(() => _isProcessingAction = true);
    final success = await _applicantService.updateApplicantStatus(
      applicantId: applicant.id,
      newStatus: 'Shortlisted',
    );
    setState(() => _isProcessingAction = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${applicant.name} has been added to Shortlist.'),
          backgroundColor: const Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Action: Accept Applicant with Openings Limit Check & Project Assignment
  Future<void> _handleAccept(ApplicantModel applicant) async {
    final project = _projectService.allProjects.firstWhere(
      (p) => p.id == applicant.projectId,
      orElse: () => _projectService.allProjects.first,
    );

    final acceptedCount =
        _applicantService.getAcceptedCount(applicant.projectId);

    // Guard: Validate student openings limit
    if (acceptedCount >= project.openings) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Openings Full',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'All ${project.openings} student opening(s) for "${project.title}" are already filled.\n\nTo accept additional candidates, increase student openings in project settings.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Accept Applicant?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Confirm selection of "${applicant.name}" for "${project.title}"?\n\nThe student will be assigned to this project and notified to start work milestones.',
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
            child: const Text('Accept & Hire'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isProcessingAction = true);
      final success = await _applicantService.updateApplicantStatus(
        applicantId: applicant.id,
        newStatus: 'Accepted',
      );
      setState(() => _isProcessingAction = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ${applicant.name} has been accepted and assigned to the project!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Action: Reject Applicant
  Future<void> _handleReject(ApplicantModel applicant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Reject Application?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reject the application submitted by "${applicant.name}" for "${applicant.projectTitle}"?',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
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
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isProcessingAction = true);
      final success = await _applicantService.updateApplicantStatus(
        applicantId: applicant.id,
        newStatus: 'Rejected',
      );
      setState(() => _isProcessingAction = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application from ${applicant.name} was rejected.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Modal: View Portfolio Item Details & Links
  void _openPortfolioItemModal(StudentPortfolioItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                  width: 40,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_special_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        if (item.attachmentType != null)
                          Text(
                            'Type: ${item.attachmentType}',
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
              const SizedBox(height: 14),
              const Text(
                'Project Overview',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Technologies & Tools',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.techStack.map((tech) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tech,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (item.attachmentName != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Portfolio Attachment File',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
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
                          item.attachmentName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.projectUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.projectUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Project URL copied: ${item.projectUrl}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.link_rounded,
                        color: AppColors.primary),
                    label: Text(
                      'Copy Repository URL (${item.projectUrl})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Modal: View Student Resume / CV Preview
  void _openResumePreviewModal(ApplicantModel applicant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
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
                        const Icon(Icons.picture_as_pdf_rounded,
                            color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          applicant.resumeFileName,
                          style: const TextStyle(
                            fontSize: 16,
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
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView(
                    children: [
                      Center(
                        child: Text(
                          applicant.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          '${applicant.degree} • ${applicant.university}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Official Student Email: ${applicant.email}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'EXECUTIVE BIOGRAPHY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        applicant.bio,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CORE COMPETENCIES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: applicant.skills.map((s) {
                          return Chip(
                            label: Text(s),
                            backgroundColor: AppColors.lightIceBlue,
                            labelStyle: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'VERIFIED ACADEMIC PROFILE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Department: ${applicant.department}\nSemester: ${applicant.semester}\nCumulative GPA: ${applicant.cgpa.toStringAsFixed(2)} / 4.00\nUniversity Status: Confirmed Full-Time Enrollment',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Downloading verified student resume (${applicant.resumeFileName})...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download Official CV PDF'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modal: Verified Education Credential Details
  void _openVerificationDetailsModal(ApplicantModel applicant) {
    showModalBottomSheet(
      context: context,
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
                  width: 40,
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
                      color: applicant.isEducationVerified
                          ? AppColors.successBg
                          : AppColors.warningBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      applicant.isEducationVerified
                          ? Icons.verified_user_rounded
                          : Icons.gpp_maybe_rounded,
                      color: applicant.isEducationVerified
                          ? AppColors.success
                          : AppColors.warning,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant.isEducationVerified
                              ? 'Verified Academic Student'
                              : 'Pending University Verification',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        Text(
                          applicant.isEducationVerified
                              ? 'Confirmed by CampusConnect Partner Network'
                              : 'Institutional records awaiting registrar validation',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildVerificationRow(
                        'Institution', applicant.university),
                    const Divider(height: 14),
                    _buildVerificationRow(
                        'Student ID', applicant.studentId),
                    const Divider(height: 14),
                    _buildVerificationRow(
                        'Program', applicant.degree),
                    const Divider(height: 14),
                    _buildVerificationRow(
                        'Department', applicant.department),
                    const Divider(height: 14),
                    _buildVerificationRow(
                        'Current Semester', applicant.semester),
                    const Divider(height: 14),
                    _buildVerificationRow(
                      'Official Edu Email',
                      applicant.email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ApplicantModel>>(
      valueListenable: _applicantService.applicantsNotifier,
      builder: (context, _, __) {
        final applicant = _getLatestApplicant();

        if (applicant == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Applicant Profile'),
              backgroundColor: AppColors.darkNavy,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'Applicant record not found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final isPending = applicant.status == 'Pending';
        final isUnderReview = applicant.status == 'Under Review';
        final isAccepted = applicant.status == 'Accepted';
        final isRejected = applicant.status == 'Rejected';

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
              'Applicant Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              // Project Context pill
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      applicant.projectTitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
                children: [
                  // HEADER CARD: Profile Picture, Name, University, Verified Badge
                  _buildHeaderCard(applicant),
                  const SizedBox(height: 16),

                  // 12. APPLICATION PROPOSAL FOR THIS PROJECT
                  _buildProposalSection(applicant),
                  const SizedBox(height: 16),

                  // 4, 5, 6, 7. VERIFIED EDUCATION & ACADEMIC CREDENTIALS
                  _buildEducationSection(applicant),
                  const SizedBox(height: 16),

                  // 8. SKILLS SECTION
                  _buildSkillsSection(applicant),
                  const SizedBox(height: 16),

                  // 9. PORTFOLIO PROJECTS
                  _buildPortfolioSection(applicant),
                  const SizedBox(height: 16),

                  // 10. PREVIOUS PROJECT RECORDS
                  _buildPreviousProjectsSection(applicant),
                  const SizedBox(height: 16),

                  // 11. CERTIFICATES
                  _buildCertificatesSection(applicant),
                ],
              ),

              // Bottom Sticky Action Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(
                  applicant: applicant,
                  isPending: isPending,
                  isUnderReview: isUnderReview,
                  isAccepted: isAccepted,
                  isRejected: isRejected,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1, 2, 3, 4. Header Card with Profile Picture, Name, University, Verified Education
  Widget _buildHeaderCard(ApplicantModel applicant) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Picture / Avatar Initial
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      applicant.avatarInitial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (applicant.isEducationVerified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // 2. Student Name & Academic Tagline
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // 3. University Name
                    Row(
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            applicant.university,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      applicant.degree,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Rating & CGPA
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightIceBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CGPA: ${applicant.cgpa.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              applicant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // 4. VERIFIED EDUCATION INDICATOR (Requirement 4)
          InkWell(
            onTap: () => _openVerificationDetailsModal(applicant),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: applicant.isEducationVerified
                    ? AppColors.successBg
                    : AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: applicant.isEducationVerified
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    applicant.isEducationVerified
                        ? Icons.verified_user_rounded
                        : Icons.gpp_maybe_rounded,
                    color: applicant.isEducationVerified
                        ? AppColors.success
                        : AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      applicant.isEducationVerified
                          ? 'Verified Student • Confirmed University Enrollment'
                          : 'Education Verification Pending Institutional Review',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: applicant.isEducationVerified
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 12. Application Proposal Submitted for the Selected Project
  Widget _buildProposalSection(ApplicantModel applicant) {
    return _buildSectionCard(
      title: 'Project Application Proposal',
      icon: Icons.assignment_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _getStatusBgColor(applicant.status),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          applicant.status,
          style: TextStyle(
            color: _getStatusTextColor(applicant.status),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Submitted on: ${applicant.appliedDate}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              applicant.proposalSummary,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Attached Student Resume tile
          InkWell(
            onTap: () => _openResumePreviewModal(applicant),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant.resumeFileName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const Text(
                          'Verified Academic Resume • PDF Document',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Preview CV',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4, 5, 6, 7. Verified Education Details
  Widget _buildEducationSection(ApplicantModel applicant) {
    return _buildSectionCard(
      title: 'Academic Education & Standing',
      icon: Icons.account_balance_rounded,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.school_rounded,
            title: 'University / Institution',
            value: applicant.university,
          ),
          const Divider(height: 16),
          // 5. Degree / Program
          _buildInfoRow(
            icon: Icons.workspace_premium_rounded,
            title: 'Degree / Program',
            value: applicant.degree,
          ),
          const Divider(height: 16),
          // 6. Department
          _buildInfoRow(
            icon: Icons.apartment_rounded,
            title: 'Department',
            value: applicant.department,
          ),
          const Divider(height: 16),
          // 7. Semester
          _buildInfoRow(
            icon: Icons.timeline_rounded,
            title: 'Current Semester',
            value: applicant.semester,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            title: 'Student ID Reference',
            value: applicant.studentId,
          ),
        ],
      ),
    );
  }

  // 8. Skills Section
  Widget _buildSkillsSection(ApplicantModel applicant) {
    return _buildSectionCard(
      title: 'Verified Skills & Proficiencies',
      icon: Icons.code_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: applicant.skills.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (applicant.portfolioUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: applicant.portfolioUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Portfolio URL copied: ${applicant.portfolioUrl}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      applicant.portfolioUrl,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 9. Portfolio Projects & Attachments
  Widget _buildPortfolioSection(ApplicantModel applicant) {
    return _buildSectionCard(
      title: 'Portfolio Projects (${applicant.portfolioProjects.length})',
      icon: Icons.work_history_rounded,
      child: applicant.portfolioProjects.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No portfolio projects attached yet.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: applicant.portfolioProjects.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                          if (item.attachmentType != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lightIceBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.attachmentType!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Wrap(
                            spacing: 4,
                            children: item.techStack.take(3).map((t) {
                              return Text(
                                '#$t',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _openPortfolioItemModal(item),
                            child: const Row(
                              children: [
                                Text('View Project',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 3),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // 10. Previous Project Records
  Widget _buildPreviousProjectsSection(ApplicantModel applicant) {
    return _buildSectionCard(
      title: 'Previous Project Records (${applicant.previousProjects.length})',
      icon: Icons.history_edu_rounded,
      child: applicant.previousProjects.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No previous industry/capstone project records recorded yet.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: applicant.previousProjects.map((rec) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                          Expanded(
                            child: Text(
                              rec.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                rec.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rec.organization} • ${rec.role} • ${rec.completionDate}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '"${rec.clientFeedback}"',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // 11. Certificates Section
  Widget _buildCertificatesSection(ApplicantModel applicant) {
    return _buildSectionCard(
      title: 'Certificates & Credentials (${applicant.certificates.length})',
      icon: Icons.military_tech_rounded,
      child: applicant.certificates.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No professional certificates listed yet.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: applicant.certificates.map((cert) {
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
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cert.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              '${cert.issuer} • Issued: ${cert.issueDate}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'ID: ${cert.credentialId}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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
    );
  }

  // Section Card Wrapper
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Bottom Sticky Action Bar
  Widget _buildBottomActionBar({
    required ApplicantModel applicant,
    required bool isPending,
    required bool isUnderReview,
    required bool isAccepted,
    required bool isRejected,
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
        child: _isProcessingAction
            ? const Center(
                heightFactor: 1.5,
                child: CircularProgressIndicator(),
              )
            : Row(
                children: [
                  // Shortlist button (if pending / under review)
                  if (isPending || isUnderReview) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _handleShortlist(applicant),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Shortlist',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Reject button (if not already rejected or accepted)
                  if (!isRejected && !isAccepted) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _handleReject(applicant),
                      child: const Text('Reject',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Accept button (if not accepted)
                  if (!isAccepted) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleAccept(applicant),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Accept & Assign',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  // Accepted Indicator State
                  if (isAccepted) ...[
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
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Applicant Accepted & Assigned to Project',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Rejected Indicator State
                  if (isRejected) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_rounded,
                                color: AppColors.error, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Application has been Rejected',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Accepted':
        return AppColors.successBg;
      case 'Rejected':
        return AppColors.errorBg;
      case 'Shortlisted':
        return const Color(0xFFF3E8FF);
      case 'Under Review':
        return AppColors.infoBg;
      default:
        return AppColors.warningBg;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Accepted':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      case 'Shortlisted':
        return const Color(0xFF7C3AED);
      case 'Under Review':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }
}

