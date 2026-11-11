import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  ProjectModel? _findProject(String projectId) {
    for (final p in _projectService.allProjects) {
      if (p.id == projectId) return p;
    }
    return null;
  }

  Future<void> _openExternalUrl(String rawUrl, String label) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final normalized =
        (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
            ? trimmed
            : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: trimmed));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label link copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleShortlist(ApplicantModel applicant) async {
    setState(() => _isProcessingAction = true);
    final success = await _applicantService.updateApplicantStatus(
      applicantId: applicant.id,
      newStatus: 'Shortlisted',
    );
    if (mounted) setState(() => _isProcessingAction = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${applicant.name} has been shortlisted.'),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleAccept(ApplicantModel applicant) async {
    final project = _findProject(applicant.projectId);
    final openings = project?.openings ?? 1;
    final acceptedCount =
        _applicantService.getAcceptedCount(applicant.projectId);

    if (acceptedCount >= openings && applicant.status != 'Accepted') {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.statusPending),
              const SizedBox(width: 8),
              Text(
                'Openings Full',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'All $openings student opening(s) for "${project?.title ?? applicant.projectTitle}" are already filled.\n\nTo accept additional candidates, edit student openings in project settings.',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.statusOpen),
            const SizedBox(width: 8),
            Text(
              'Accept Applicant?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Confirm selection of "${applicant.name}" for "${project?.title ?? applicant.projectTitle}"?\n\nThe student will be assigned immediately and notified to begin project milestones.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
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
            child: const Text('Accept & Assign'),
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
      if (mounted) setState(() => _isProcessingAction = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${applicant.name} has been accepted and assigned to the project.',
            ),
            backgroundColor: AppColors.statusOpen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(ApplicantModel applicant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.statusClosed),
            const SizedBox(width: 8),
            Text(
              'Decline Application?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to decline the application from "${applicant.name}" for "${applicant.projectTitle}"?',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
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
            child: const Text('Decline'),
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
      if (mounted) setState(() => _isProcessingAction = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application from ${applicant.name} was declined.'),
            backgroundColor: AppColors.statusClosed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ApplicantModel>>(
      valueListenable: _applicantService.applicantsNotifier,
      builder: (context, _, _) {
        final applicant = _getLatestApplicant();
        if (applicant == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Applicant Profile')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: AppEmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Applicant Not Found',
                  subtitle:
                      'This application record is no longer available or could not be loaded.',
                  actionLabel: 'Go Back',
                  onAction: () => Navigator.pop(context),
                ),
              ),
            ),
          );
        }

        final bool canDecide =
            applicant.status != 'Accepted' && applicant.status != 'Rejected';
        final bool isShortlisted = applicant.status == 'Shortlisted';

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
              'Candidate Review',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(applicant),
                const SizedBox(height: 16),
                _buildProposalSection(applicant),
                const SizedBox(height: 16),
                _buildAcademicCard(applicant),
                if (applicant.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSkillsCard(applicant),
                ],
                if (applicant.portfolioUrl.trim().isNotEmpty ||
                    applicant.resumeFileName.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildLinksAndResumeCard(applicant),
                ],
                if (applicant.certificates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCertificatesCard(applicant),
                ],
                if (applicant.bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildBioCard(applicant),
                ],
                const SizedBox(height: 20),
                if (canDecide)
                  _buildDecisionBar(applicant, isShortlisted)
                else
                  _buildStatusFooter(applicant),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(ApplicantModel applicant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  applicant.avatarInitial,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            applicant.name,
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (applicant.isEducationVerified)
                          const Tooltip(
                            message: 'Academic Profile Verified',
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.lightAqua,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (applicant.email.isNotEmpty)
                      Text(
                        applicant.email,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.lightAqua,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(label: applicant.status),
                        if (applicant.rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  applicant.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline_rounded,
                    color: AppColors.lightAqua, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Applying for: ${applicant.projectTitle}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  applicant.appliedDate,
                  style: GoogleFonts.inter(
                    color: AppColors.lightAqua,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalSection(ApplicantModel applicant) {
    return _sectionCard(
      title: 'Cover Letter & Approach',
      icon: Icons.description_outlined,
      child: Text(
        applicant.proposalSummary,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          height: 1.55,
          color: AppColors.darkText,
        ),
      ),
    );
  }

  Widget _buildAcademicCard(ApplicantModel applicant) {
    final rows = <(String, String)>[
      if (applicant.university.trim().isNotEmpty)
        ('University / Institute', applicant.university),
      if (applicant.degree.trim().isNotEmpty) ('Degree Program', applicant.degree),
      if (applicant.department.trim().isNotEmpty)
        ('Department', applicant.department),
      if (applicant.semester.trim().isNotEmpty) ('Semester / Year', applicant.semester),
      if (applicant.cgpa > 0) ('CGPA', applicant.cgpa.toStringAsFixed(2)),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      title: 'Academic Background',
      icon: Icons.school_outlined,
      child: Column(
        children: rows.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    pair.$1,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.grayText,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    pair.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepNavy,
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

  Widget _buildSkillsCard(ApplicantModel applicant) {
    return _sectionCard(
      title: 'Verified Technical Skills',
      icon: Icons.code_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: applicant.skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightAqua.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              skill,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLinksAndResumeCard(ApplicantModel applicant) {
    final portfolio = applicant.portfolioUrl.trim();
    final resume = applicant.resumeFileName.trim();
    final isResumeUrl = resume.startsWith('http://') ||
        resume.startsWith('https://') ||
        resume.startsWith('www.');

    return _sectionCard(
      title: 'Portfolio & Credentials',
      icon: Icons.link_rounded,
      child: Column(
        children: [
          if (portfolio.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.lightAqua,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.public_rounded,
                    color: AppColors.primaryBlue, size: 20),
              ),
              title: Text(
                'Portfolio / GitHub Profile',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepNavy,
                ),
              ),
              subtitle: Text(
                portfolio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () => _openExternalUrl(portfolio, 'Portfolio'),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open'),
              ),
            ),
          if (resume.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.statusClosed, size: 20),
              ),
              title: Text(
                'Attached CV / Resume',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepNavy,
                ),
              ),
              subtitle: Text(
                resume,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () {
                  if (isResumeUrl) {
                    _openExternalUrl(resume, 'Resume');
                  } else {
                    Clipboard.setData(ClipboardData(text: resume));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resume reference copied to clipboard.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: Icon(
                  isResumeUrl ? Icons.open_in_new_rounded : Icons.copy_rounded,
                  size: 16,
                ),
                label: Text(isResumeUrl ? 'Open' : 'Copy'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCertificatesCard(ApplicantModel applicant) {
    return _sectionCard(
      title: 'Earned Certificates (${applicant.certificates.length})',
      icon: Icons.workspace_premium_outlined,
      child: Column(
        children: applicant.certificates.map((cert) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: AppColors.statusOpen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        '${cert.issuer} • Issued ${cert.issueDate}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
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
    );
  }

  Widget _buildBioCard(ApplicantModel applicant) {
    return _sectionCard(
      title: 'Candidate Bio',
      icon: Icons.person_outline_rounded,
      child: Text(
        applicant.bio,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          height: 1.5,
          color: AppColors.darkText,
        ),
      ),
    );
  }

  Widget _buildDecisionBar(ApplicantModel applicant, bool isShortlisted) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusClosed,
                  side: const BorderSide(color: AppColors.statusClosed),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed:
                    _isProcessingAction ? null : () => _handleReject(applicant),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Decline'),
              ),
            ),
            if (!isShortlisted) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: _isProcessingAction
                      ? null
                      : () => _handleShortlist(applicant),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Shortlist'),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusOpen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed:
                    _isProcessingAction ? null : () => _handleAccept(applicant),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Accept & Assign'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFooter(ApplicantModel applicant) {
    final isAccepted = applicant.status == 'Accepted';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isAccepted ? AppColors.statusOpen : AppColors.statusClosed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAccepted
                  ? '${applicant.name} has been accepted and assigned to "${applicant.projectTitle}".'
                  : 'This application was declined.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
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
