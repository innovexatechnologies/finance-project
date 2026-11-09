import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
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
  late TextEditingController _otpController;
  late TextEditingController _websiteController;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isSubmitting = false;
  bool _otpSent = false;
  String? _otpSentCode;

  String _selectedEvidenceType = 'SECP / Company Registration';
  String? _selectedFileName;
  String? _selectedFileSize;

  final List<String> _evidenceTypes = [
    'SECP / Company Registration',
    'NTN / FBR Tax Certificate',
    'Chamber of Commerce License',
    'Trade License / Incorporation Certificate',
  ];

  final List<Map<String, String>> _sampleDocuments = [
    {
      'name': 'TechVista_SECP_Registration.pdf',
      'size': '1.8 MB',
    },
    {
      'name': 'FBR_NTN_Tax_Certificate_2026.pdf',
      'size': '940 KB',
    },
    {
      'name': 'Chamber_Of_Commerce_Membership.pdf',
      'size': '1.2 MB',
    },
  ];

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
    _otpController = TextEditingController();
    _websiteController = TextEditingController(
      text: current.websiteUrl ?? profile.websiteUrl,
    );

    _selectedEvidenceType = current.businessEvidenceType ?? _evidenceTypes.first;
    _selectedFileName = current.businessEvidenceFileName;
    _selectedFileSize = current.businessEvidenceFileSize;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // 1. Send OTP logic
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid corporate email address first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final code = await _verificationService.sendEmailOtp(email);

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
      _otpSent = true;
      _otpSentCode = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code sent to $email (Test Code: $code)'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // 2. Verify OTP logic
  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit verification code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final success = await _verificationService.verifyEmailOtp(code);

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Official email successfully verified!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Please enter the correct 6-digit OTP.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 3. Document selection
  void _openDocumentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Business Evidence File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Attach an official document confirming organization validity:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ..._sampleDocuments.map((doc) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.error,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    doc['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  subtitle: Text('File size: ${doc['size']} • PDF format'),
                  trailing: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedFileName = doc['name'];
                      _selectedFileSize = doc['size'];
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 4. Submit Verification Request
  Future<void> _handleSubmitRequest() async {
    final current = _verificationService.currentVerification;

    if (!current.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please complete official email verification before submitting.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Optional website validation if entered
    final website = _websiteController.text.trim();
    if (website.isNotEmpty &&
        (!website.contains('.') || website.length < 5)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid website URL or leave it blank.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    if (current.status == VerificationStatus.rejected) {
      await _verificationService.resubmitVerificationRequest(
        businessEvidenceFileName: _selectedFileName,
        businessEvidenceType: _selectedEvidenceType,
        websiteUrl: website.isNotEmpty ? website : null,
      );
    } else {
      await _verificationService.submitVerificationRequest(
        businessEvidenceFileName: _selectedFileName,
        businessEvidenceType: _selectedEvidenceType,
        businessEvidenceFileSize: _selectedFileSize,
        websiteUrl: website.isNotEmpty ? website : null,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification request successfully submitted for Admin Review!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CompanyVerificationModel>(
      valueListenable: _verificationService.verificationNotifier,
      builder: (context, verification, _) {
        final isPending = verification.status == VerificationStatus.pending;
        final isVerified = verification.status == VerificationStatus.verified;
        final isRejected = verification.status == VerificationStatus.rejected;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text('Company Verification (Screen 24)'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                // 1. Heading & Header Explanation
                _buildHeaderSection(),
                const SizedBox(height: 18),

                // 2. Verification Status Card
                _buildStatusCard(verification),
                const SizedBox(height: 18),

                // 3. Admin Feedback Section (Shows if Rejected or Feedback exists)
                if (isRejected || verification.adminFeedback != null)
                  _buildAdminFeedbackSection(verification),
                if (isRejected || verification.adminFeedback != null)
                  const SizedBox(height: 18),

                // 4. Official Email Verification Section
                _buildEmailVerificationSection(verification),
                const SizedBox(height: 20),

                // 5. Optional Business Evidence Upload Section
                _buildBusinessEvidenceSection(isPending, isVerified),
                const SizedBox(height: 20),

                // 6. Optional Website Details Section
                _buildWebsiteDetailsSection(isPending, isVerified),
                const SizedBox(height: 28),

                // 7. Submit Action Button
                _buildSubmitButton(verification, isPending, isVerified),
                const SizedBox(height: 28),

                // 8. Admin Simulation Testing Panel (For Review Testing)
                _buildTestingControlPanel(verification),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Header Section
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization Verification',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verify your corporate credentials to receive the verified partner badge, post real student challenges, and hire campus talent.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 2. Status Card
  Widget _buildStatusCard(CompanyVerificationModel verification) {
    Color cardBg;
    Color borderColor;
    Color pillColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String statusDescription;

    switch (verification.status) {
      case VerificationStatus.pending:
        cardBg = AppColors.warningBg;
        borderColor = AppColors.warning.withOpacity(0.4);
        pillColor = AppColors.warning;
        textColor = const Color(0xFF92400E);
        icon = Icons.hourglass_top_rounded;
        statusTitle = 'Pending Admin Review';
        statusDescription =
            'Your verification request was submitted on ${verification.submittedAt ?? 'recently'}. The CampusConnect Admin Council will review credentials within 24 to 48 hours.';
        break;

      case VerificationStatus.verified:
        cardBg = AppColors.successBg;
        borderColor = AppColors.success.withOpacity(0.4);
        pillColor = AppColors.success;
        textColor = const Color(0xFF166534);
        icon = Icons.verified_rounded;
        statusTitle = 'Verified Corporate Partner';
        statusDescription =
            'Congratulations! Your organization was verified by ${verification.reviewerName ?? 'CampusConnect Admin'} on ${verification.reviewedAt ?? 'today'}.';
        break;

      case VerificationStatus.rejected:
        cardBg = AppColors.errorBg;
        borderColor = AppColors.error.withOpacity(0.4);
        pillColor = AppColors.error;
        textColor = const Color(0xFF991B1B);
        icon = Icons.highlight_off_rounded;
        statusTitle = 'Verification Request Rejected';
        statusDescription =
            'Your previous request was reviewed and rejected. Please review admin comments below, correct the discrepancies, and resubmit.';
        break;

      case VerificationStatus.notSubmitted:
        cardBg = AppColors.lightIceBlue;
        borderColor = AppColors.primary.withOpacity(0.3);
        pillColor = AppColors.primary;
        textColor = AppColors.darkNavy;
        icon = Icons.shield_outlined;
        statusTitle = 'Verification Action Required';
        statusDescription =
            'Please verify your corporate email and upload supporting business evidence to initiate the admin authorization process.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, color: pillColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textColor.withOpacity(0.9),
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

  // 3. Admin Feedback Section
  Widget _buildAdminFeedbackSection(CompanyVerificationModel verification) {
    final feedback = verification.adminFeedback ??
        'The submitted business registration copy was illegible or expired. Please attach an updated SECP/FBR document with the active registration number clearly visible.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.feedback_outlined,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Admin Council Feedback & Rejection Reason',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"$feedback"',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF7F1D1D),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Action needed: Re-upload the required document in Section 2 below and tap "Resubmit Verification Request".',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Official Email Verification Section
  Widget _buildEmailVerificationSection(
      CompanyVerificationModel verification) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Step 1: Official Email Verification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
              if (verification.isEmailVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'We send a 6-digit verification code to confirm you own this company domain email address.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Email Input Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  enabled: !verification.isEmailVerified,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Company Official Email',
                    hintText: 'e.g. contact@company.com',
                    prefixIcon: const Icon(Icons.alternate_email, size: 18),
                    filled: true,
                    fillColor: verification.isEmailVerified
                        ? const Color(0xFFF1F5F9)
                        : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              if (!verification.isEmailVerified) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSendingOtp ? null : _handleSendOtp,
                  child: _isSendingOtp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_otpSent ? 'Resend' : 'Send Code'),
                ),
              ],
            ],
          ),

          // OTP Code Verification Box (Appears when code is sent)
          if (_otpSent && !verification.isEmailVerified) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightIceBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enter 6-Digit Verification Code:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      if (_otpSentCode != null)
                        Text(
                          'Test OTP: $_otpSentCode',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            letterSpacing: 4,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _isVerifyingOtp ? null : _handleVerifyOtp,
                        child: _isVerifyingOtp
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verify Code'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 5. Optional Business Evidence Upload Section
  Widget _buildBusinessEvidenceSection(bool isPending, bool isVerified) {
    final isLocked = isPending || isVerified;

    return Container(
      padding: const EdgeInsets.all(18),
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
              const Row(
                children: [
                  Icon(Icons.attachment_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Step 2: Business Evidence (Optional)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload your legal registration document (SECP, NTN, or Chamber Certificate) for faster approval.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Document Type Selector
          DropdownButtonFormField<String>(
            value: _selectedEvidenceType,
            decoration: InputDecoration(
              labelText: 'Evidence Document Type',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: _evidenceTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: isLocked
                ? null
                : (val) {
                    if (val != null) {
                      setState(() {
                        _selectedEvidenceType = val;
                      });
                    }
                  },
          ),
          const SizedBox(height: 14),

          // Upload Area or Attached Document Card
          if (_selectedFileName != null)
            Container(
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
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Size: ${_selectedFileSize ?? '1.5 MB'} • Ready for review',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLocked)
                    IconButton(
                      icon: const Icon(Icons.change_circle_outlined,
                          color: AppColors.primary),
                      tooltip: 'Change Document',
                      onPressed: _openDocumentPicker,
                    ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: isLocked ? null : _openDocumentPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: isLocked ? AppColors.textMuted : AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLocked
                          ? 'Document attached under review'
                          : 'Tap to select document (PDF, PNG, JPG)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isLocked ? AppColors.textMuted : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Max file size: 10MB',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 6. Optional Website Details Section
  Widget _buildWebsiteDetailsSection(bool isPending, bool isVerified) {
    final isLocked = isPending || isVerified;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.language_rounded,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Step 3: Website Details (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Official company website URL helps verify corporate web presence against your domain email.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _websiteController,
            enabled: !isLocked,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Company Website URL',
              hintText: 'e.g. https://techvistainnovations.com',
              prefixIcon: const Icon(Icons.link, size: 18),
              filled: true,
              fillColor: isLocked
                  ? const Color(0xFFF1F5F9)
                  : AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Submit Action Button
  Widget _buildSubmitButton(CompanyVerificationModel verification,
      bool isPending, bool isVerified) {
    String buttonText = 'Submit Verification Request';
    IconData buttonIcon = Icons.send_rounded;
    Color buttonColor = AppColors.primary;
    VoidCallback? onTap = _handleSubmitRequest;

    if (isPending) {
      buttonText = 'Request Under Admin Review';
      buttonIcon = Icons.hourglass_top_rounded;
      buttonColor = AppColors.warning;
      onTap = null;
    } else if (isVerified) {
      buttonText = 'Organization Verified';
      buttonIcon = Icons.verified;
      buttonColor = AppColors.success;
      onTap = null;
    } else if (verification.status == VerificationStatus.rejected) {
      buttonText = 'Resubmit Verification Request';
      buttonIcon = Icons.refresh_rounded;
      buttonColor = AppColors.primary;
      onTap = _handleSubmitRequest;
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _isSubmitting ? null : onTap,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(buttonIcon, size: 18),
        label: Text(
          _isSubmitting ? 'Submitting Request...' : buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 8. Admin Simulation Testing Panel (For Testing All 3 Required Statuses)
  Widget _buildTestingControlPanel(CompanyVerificationModel verification) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
            SizedBox(width: 8),
            Text(
              'Admin Review Simulation (Tester Controls)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: const Text(
          'Simulate admin actions to test Pending, Verified, and Rejected states without automatic bypass.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.verified,
                    color: AppColors.success, size: 16),
                label: const Text('Simulate Admin Approval'),
                onPressed: () {
                  _verificationService.simulateAdminApproval();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulated: Admin approved verification!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel,
                    color: AppColors.error, size: 16),
                label: const Text('Simulate Admin Rejection'),
                onPressed: () {
                  _verificationService.simulateAdminRejection(
                    'The SECP incorporation certificate provided was expired. Please re-upload an active valid document.',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Simulated: Admin rejected request with feedback.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt,
                    color: AppColors.textSecondary, size: 16),
                label: const Text('Reset to Draft'),
                onPressed: () {
                  _verificationService.resetToDraft();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

