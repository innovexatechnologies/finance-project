import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/cloud_storage_service.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

class CompanyVerificationScreen extends StatefulWidget {
  const CompanyVerificationScreen({super.key});

  @override
  State<CompanyVerificationScreen> createState() =>
      _CompanyVerificationScreenState();
}

class _CompanyVerificationScreenState extends State<CompanyVerificationScreen> {
  final _verificationService = CompanyVerificationService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _evidenceNameController;
  late TextEditingController _evidenceUrlController;
  late TextEditingController _websiteController;

  bool _isConfirmingEmail = false;
  bool _isSubmitting = false;
  bool _isUploadingEvidence = false;
  String? _evidenceFileSize;

  String _selectedEvidenceType = 'SECP / Company Registration';

  static const List<String> _evidenceTypes = [
    'SECP / Company Registration',
    'NTN / FBR Tax Certificate',
    'Chamber of Commerce License',
    'Trade License / Incorporation Certificate',
  ];

  Future<void> _pickAndUploadEvidence() async {
    if (_isUploadingEvidence) return;
    setState(() => _isUploadingEvidence = true);
    try {
      final res = await CloudStorageService.pickAndUploadFile(
        bucket: 'company-assets',
        folder: 'evidence',
        dialogTitle: 'Select Registration Evidence (PDF, PNG, JPG)',
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );
      if (res != null && mounted) {
        setState(() {
          _evidenceNameController.text = res.fileName;
          _evidenceUrlController.text = res.url;
          _evidenceFileSize = res.sizeLabel;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Uploaded evidence document: ${res.fileName} (${res.sizeLabel})',
            ),
            backgroundColor: AppColors.statusOpen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not upload evidence document: $e'),
          backgroundColor: AppColors.statusClosed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingEvidence = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final profile = CompanyProfileService().currentProfile;
    final current = _verificationService.currentVerification;

    _emailController = TextEditingController(
      text: current.officialEmail.isNotEmpty
          ? current.officialEmail
          : profile.officialEmail,
    );
    _evidenceNameController = TextEditingController(
      text: current.businessEvidenceFileName ?? '',
    );
    _evidenceUrlController = TextEditingController(
      text: current.businessEvidenceUrl ?? '',
    );
    _websiteController = TextEditingController(
      text: (current.websiteUrl != null && current.websiteUrl!.isNotEmpty)
          ? current.websiteUrl
          : profile.websiteUrl,
    );

    if (current.businessEvidenceType != null &&
        _evidenceTypes.contains(current.businessEvidenceType)) {
      _selectedEvidenceType = current.businessEvidenceType!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _evidenceNameController.dispose();
    _evidenceUrlController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    await CompanyProfileService().loadFromSupabase();
    await _verificationService.loadFromSupabase();
    if (!mounted) return;
    final current = _verificationService.currentVerification;
    if (current.officialEmail.isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = current.officialEmail;
    }
  }

  Future<void> _handleConfirmEmail() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid corporate email address.'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
      return;
    }

    setState(() => _isConfirmingEmail = true);
    final ok = await _verificationService.confirmOfficialEmail(email);
    if (!mounted) return;
    setState(() => _isConfirmingEmail = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Official corporate email confirmed.'
              : 'Could not confirm email. Please check your connection.',
        ),
        backgroundColor: ok ? AppColors.statusOpen : AppColors.statusClosed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final current = _verificationService.currentVerification;
    if (!current.isEmailVerified) {
      final emailOk = await _verificationService
          .confirmOfficialEmail(_emailController.text.trim());
      if (!emailOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please confirm a valid corporate email before submitting.'),
            backgroundColor: AppColors.statusPending,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      if (current.status == VerificationStatus.rejected) {
        await _verificationService.resubmitVerificationRequest(
          businessEvidenceFileName: _evidenceNameController.text.trim(),
          businessEvidenceType: _selectedEvidenceType,
          businessEvidenceFileSize: _evidenceFileSize ?? current.businessEvidenceFileSize,
          businessEvidenceUrl: _evidenceUrlController.text.trim(),
          websiteUrl: _websiteController.text.trim(),
          officialEmail: _emailController.text.trim(),
        );
      } else {
        await _verificationService.submitVerificationRequest(
          businessEvidenceFileName: _evidenceNameController.text.trim(),
          businessEvidenceType: _selectedEvidenceType,
          businessEvidenceFileSize: _evidenceFileSize ?? current.businessEvidenceFileSize,
          businessEvidenceUrl: _evidenceUrlController.text.trim(),
          websiteUrl: _websiteController.text.trim(),
          officialEmail: _emailController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification documents submitted to SkillBridge Governance Admin.',
          ),
          backgroundColor: AppColors.statusOpen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: AppColors.statusClosed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _statusLabel(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.notSubmitted:
        return 'Not Submitted';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Company Verification',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Verification Status',
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: ValueListenableBuilder<CompanyVerificationModel>(
        valueListenable: _verificationService.verificationNotifier,
        builder: (context, verification, _) {
          final isVerified = verification.status == VerificationStatus.verified;
          final isPending = verification.status == VerificationStatus.pending;
          final isEditable = !isVerified && !isPending;

          return RefreshIndicator(
            onRefresh: _refreshStatus,
            color: AppColors.primaryBlue,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(verification),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      stepNumber: '1',
                      title: 'Official Corporate Email',
                      subtitle:
                          'Confirm your corporate domain address for institutional trust.',
                      completed: verification.isEmailVerified,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            enabled: isEditable && !verification.isEmailVerified,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Corporate Email *',
                              hintText: 'hr@yourcompany.com',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Corporate email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          if (verification.isEmailVerified)
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.statusOpen, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Confirmed corporate email',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusOpen,
                                  ),
                                ),
                              ],
                            )
                          else if (isEditable)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isConfirmingEmail
                                    ? null
                                    : _handleConfirmEmail,
                                icon: _isConfirmingEmail
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.mark_email_read_outlined,
                                        size: 18),
                                label: const Text('Confirm Corporate Email'),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStepCard(
                      stepNumber: '2',
                      title: 'Business Registration Evidence',
                      subtitle:
                          'Provide your SECP, NTN, Chamber license reference and optional verification document link.',
                      completed: (verification.businessEvidenceFileName ?? '')
                          .trim()
                          .isNotEmpty,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedEvidenceType,
                            decoration: const InputDecoration(
                              labelText: 'Document Classification',
                            ),
                            items: _evidenceTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: isEditable
                                ? (val) {
                                    if (val != null) {
                                      setState(() => _selectedEvidenceType = val);
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _evidenceNameController,
                            enabled: isEditable,
                            decoration: const InputDecoration(
                              labelText: 'Registration No. or Document Name *',
                              hintText: 'e.g. SECP-REG-2026-8812 or Company_NTN.pdf',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Registration reference or document title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _evidenceUrlController,
                            enabled: isEditable,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Document Verification Link (Optional)',
                              hintText: 'https://drive.google.com/...',
                            ),
                              validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final t = v.trim();
                                if (!t.startsWith('http://') &&
                                    !t.startsWith('https://')) {
                                  return 'Enter a valid http:// or https:// URL';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (isEditable)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isUploadingEvidence
                                    ? null
                                    : _pickAndUploadEvidence,
                                icon: _isUploadingEvidence
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.upload_file_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  _evidenceUrlController.text.trim().isNotEmpty
                                      ? 'Replace Uploaded Document (PDF / Image)'
                                      : 'Upload Evidence Document (PDF / Image)',
                                ),
                              ),
                            ),
                          if (_evidenceUrlController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => CloudStorageService.openUrl(
                                  context,
                                  _evidenceUrlController.text.trim(),
                                  label: 'Registration Evidence',
                                ),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'Preview Attached Document${_evidenceFileSize != null ? ' ($_evidenceFileSize)' : ''}',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStepCard(
                      stepNumber: '3',
                      title: 'Corporate Web Presence',
                      subtitle:
                          'Add your official website for governance inspection.',
                      completed: (verification.websiteUrl ?? '').trim().isNotEmpty,
                      child: TextFormField(
                        controller: _websiteController,
                        enabled: isEditable,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Official Website URL *',
                          hintText: 'https://yourcompany.com',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Official website URL is required';
                          }
                          final t = v.trim();
                          if (!t.contains('.')) {
                            return 'Enter a valid domain URL';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (isEditable) ...[
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _isSubmitting ? null : _handleSubmitRequest,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_user_outlined),
                          label: Text(
                            verification.status == VerificationStatus.rejected
                                ? 'Resubmit Verification Request'
                                : 'Submit Verification Request',
                          ),
                        ),
                      ),
                    ],
                  ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(CompanyVerificationModel verification) {
    final label = _statusLabel(verification.status);
    IconData icon;
    String detail;
    switch (verification.status) {
      case VerificationStatus.verified:
        icon = Icons.verified_rounded;
        detail =
            'Your organization has passed SkillBridge governance verification and is trusted across student talent feeds.';
        break;
      case VerificationStatus.pending:
        icon = Icons.hourglass_top_rounded;
        detail =
            'Your documents were submitted ${verification.submittedAt ?? 'recently'} and are queued for Admin review.';
        break;
      case VerificationStatus.rejected:
        icon = Icons.error_outline_rounded;
        detail = verification.adminFeedback?.isNotEmpty == true
            ? 'Admin Feedback: ${verification.adminFeedback}'
            : 'Please update your registration details and resubmit for review.';
        break;
      case VerificationStatus.notSubmitted:
        icon = Icons.shield_outlined;
        detail =
            'Complete the 3 steps below to receive a Verified Corporate Partner badge on all your project listings.';
        break;
    }

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trust & Governance Status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.lightAqua,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StatusBadge(label: label),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (verification.reviewedAt != null &&
              verification.reviewedAt!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reviewed ${verification.reviewedAt}${verification.reviewerName != null ? ' • ${verification.reviewerName}' : ''}',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.lightAqua,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool completed,
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
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    completed ? AppColors.statusOpen : AppColors.deepNavy,
                child: completed
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : Text(
                        stepNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
