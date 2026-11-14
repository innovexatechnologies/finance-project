import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/platform_payment_method_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/services/company_escrow_service.dart';

/// Company Screen for Upfront Escrow Deposit & Receipt Proof Submission.
/// Strictly uses [CompanyEscrowService] — NO direct Supabase calls.
class CompanyEscrowPaymentScreen extends StatefulWidget {
  final ProjectModel project;

  const CompanyEscrowPaymentScreen({
    super.key,
    required this.project,
  });

  @override
  State<CompanyEscrowPaymentScreen> createState() =>
      _CompanyEscrowPaymentScreenState();
}

class _CompanyEscrowPaymentScreenState
    extends State<CompanyEscrowPaymentScreen> {
  final CompanyEscrowService _escrowService = CompanyEscrowService();
  final _formKey = GlobalKey<FormState>();
  final _tidController = TextEditingController();

  List<PlatformPaymentMethodModel> _paymentMethods = [];
  PlatformPaymentMethodModel? _selectedMethod;
  bool _isLoadingMethods = true;
  bool _isSubmitting = false;

  XFile? _receiptImage;
  Uint8List? _receiptBytes;

  @override
  void initState() {
    super.initState();
    _loadAdminPaymentMethods();
  }

  @override
  void dispose() {
    _tidController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminPaymentMethods() async {
    setState(() => _isLoadingMethods = true);
    final methods = await _escrowService.getActivePlatformPaymentMethods();
    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
      if (methods.isNotEmpty) {
        _selectedMethod = methods.first;
      }
      _isLoadingMethods = false;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _receiptImage = picked;
          _receiptBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select receipt image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleSubmitProof() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Escrow Payment Account.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_receiptBytes == null || _receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your payment receipt screenshot.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload receipt to Supabase Storage via Service
      final receiptUrl = await _escrowService.uploadReceiptImage(
        projectId: widget.project.id,
        imageBytes: _receiptBytes!,
        fileName: _receiptImage!.name,
      );

      if (receiptUrl == null) {
        throw Exception(
          _escrowService.lastError ?? 'Failed to upload receipt screenshot.',
        );
      }

      // 2. Submit payment proof via Service
      final success = await _escrowService.submitPaymentProof(
        projectId: widget.project.id,
        transactionId: _tidController.text.trim(),
        paymentMethodUsed: _selectedMethod!.bankOrWalletName,
        receiptUrl: receiptUrl,
      );

      if (!success) {
        throw Exception(
          _escrowService.lastError ?? 'Failed to submit payment details.',
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // 3. Show Success Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Proof Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your deposit of PKR ${widget.project.escrowAmount.toStringAsFixed(0)} has been sent for verification with TID ${_tidController.text.trim()}.\n\nYour project will go live on the Student Portal with a "Verified & Escrow Funded" badge once Admin confirms the transfer.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context, true); // Pop payment screen
                  },
                  child: const Text('Return to Projects'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.project.escrowAmount > 0
        ? 'PKR ${widget.project.escrowAmount.toStringAsFixed(0)}'
        : 'PKR 10,000';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.darkNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project Escrow Deposit',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Escrow Protection Header Banner
              _buildEscrowBanner(amountText),
              const SizedBox(height: 24),

              // Step 1: Select Admin Account
              _buildStepTitle(
                step: '1',
                title: 'Transfer Funds to Admin Escrow',
                subtitle:
                    'Select an account and transfer the project budget via your banking app.',
              ),
              const SizedBox(height: 12),
              if (_isLoadingMethods)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_paymentMethods.isEmpty)
                _buildNoAccountsAlert()
              else
                ..._paymentMethods.map((m) => _buildAccountCard(m)),

              const SizedBox(height: 24),

              // Step 2: Enter Transaction ID
              _buildStepTitle(
                step: '2',
                title: 'Enter Transaction ID (TID)',
                subtitle:
                    'Input the reference or transaction ID provided by your bank/wallet.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tidController,
                decoration: InputDecoration(
                  hintText: 'e.g. 123456789012 or TRX-998822',
                  prefixIcon: const Icon(Icons.numbers_rounded,
                      color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter the transaction ID';
                  }
                  if (v.trim().length < 4) {
                    return 'Please enter a valid transaction ID';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Step 3: Attach Payment Receipt Screenshot
              _buildStepTitle(
                step: '3',
                title: 'Upload Payment Receipt Screenshot',
                subtitle:
                    'Attach a clear screenshot or photo of the completed transfer slip.',
              ),
              const SizedBox(height: 12),
              _buildReceiptUploadBox(),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shield_outlined),
                  label: Text(
                    _isSubmitting
                        ? 'Verifying & Submitting...'
                        : 'Submit Proof & Request Escrow Verification',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmitProof,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEscrowBanner(String amountText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.project.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Escrow Required',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      amountText,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your deposit remains 100% locked in SkillBridge custodial escrow until the project is delivered and approved.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(PlatformPaymentMethodModel method) {
    final isSelected = _selectedMethod?.id == method.id;
    final brandColor = method.brandColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? brandColor : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? AppColors.softShadow : null,
      ),
      child: RadioListTile<PlatformPaymentMethodModel>(
        value: method,
        groupValue: _selectedMethod,
        activeColor: brandColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onChanged: (val) {
          setState(() => _selectedMethod = val);
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(method.icon, color: brandColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  method.bankOrWalletName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                method.methodType,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: brandColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${method.accountTitle}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'A/C: ${method.accountNumber}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(
                      method.accountNumber,
                      'Account Number',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 11,
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
              if (method.iban != null && method.iban!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'IBAN: ${method.iban}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _copyToClipboard(method.iban!, 'IBAN'),
                      child: const Icon(Icons.copy_rounded,
                          size: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
              if (method.instructions != null &&
                  method.instructions!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Note: ${method.instructions}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAccountsAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: const Text(
        'No active platform accounts currently configured by Admin. Please contact Admin support.',
        style: TextStyle(color: AppColors.darkNavy, fontSize: 13),
      ),
    );
  }

  Widget _buildReceiptUploadBox() {
    if (_receiptBytes != null && _receiptImage != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _receiptBytes!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _receiptImage!.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_receiptBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB — Ready to upload',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: () {
                setState(() {
                  _receiptImage = null;
                  _receiptBytes = null;
                });
              },
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickReceiptImage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightAqua,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Click to Upload Receipt Screenshot',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PNG, JPG, or WEBP up to 10MB',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

