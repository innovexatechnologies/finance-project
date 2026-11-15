import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/company/payment_methods/services/company_payment_method_service.dart';

class CompanyPaymentMethodScreen extends StatefulWidget {
  const CompanyPaymentMethodScreen({super.key});

  @override
  State<CompanyPaymentMethodScreen> createState() =>
      _CompanyPaymentMethodScreenState();
}

class _CompanyPaymentMethodScreenState
    extends State<CompanyPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountTitleController = TextEditingController();
  final _service = CompanyPaymentMethodService();

  String _provider = CompanyPaymentMethodService.providers.first;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasSavedDetails = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethod();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethod() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final saved = await _service.loadForCurrentCompany();
      if (!mounted) return;
      setState(() {
        if (saved != null) {
          _provider =
              CompanyPaymentMethodService.providers.contains(saved.provider)
                  ? saved.provider
                  : CompanyPaymentMethodService.providers.first;
          _accountNumberController.text = saved.accountNumber;
          _accountTitleController.text = saved.accountTitle;
          _hasSavedDetails = true;
        } else {
          // Pre-fill company name if available
          final curName = AppDataService.instance.userName.trim();
          if (curName.isNotEmpty) {
            _accountTitleController.text = curName;
          }
          _hasSavedDetails = false;
        }
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Company payment method load failed: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError =
            'Could not load your corporate payment details. Please try again.';
      });
    }
  }

  Future<void> _savePaymentMethod() async {
    if (_isLoading || _loadError != null || _isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await _service.saveForCurrentCompany(
        provider: _provider,
        accountNumber: _accountNumberController.text.trim(),
        accountTitle: _accountTitleController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _hasSavedDetails = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corporate refund & payment details saved successfully.'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      debugPrint('Company payment method save failed: $error');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save details. Please check inputs and retry.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment & Refund Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.deepNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header card explaining purpose
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Escrow Refund Account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'In case of project cancellation or dispute resolution, SkillBridge Admin transfers refunded escrow funds directly to this verified account.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF1E40AF),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // If details saved, show active preview card
                      if (_hasSavedDetails) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _provider,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF047857),
                                      ),
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF10B981), size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active Refund Method',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Account Title: ${_accountTitleController.text.trim()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'A/C or IBAN: ${_accountNumberController.text.trim()}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 16, color: AppColors.primaryBlue),
                                    tooltip: 'Copy Number',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                        text: _accountNumberController.text.trim(),
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Account number copied'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Form to add/update
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.lightGray),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hasSavedDetails
                                    ? 'Update Payment / Refund Details'
                                    : 'Add Corporate Payment Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Provider dropdown
                              Text(
                                'Select Bank / Digital Wallet *',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _provider,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGray),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGray),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                items: CompanyPaymentMethodService.providers
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _provider = val);
                                },
                              ),
                              const SizedBox(height: 14),

                              // Account Title
                              Text(
                                'Account Title / Corporate Name *',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _accountTitleController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Systems Limited / Danish Ali',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGray),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGray),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter corporate account title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Account Number / IBAN
                              Text(
                                'Account Number / IBAN / Wallet Number *',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _accountNumberController,
                                decoration: InputDecoration(
                                  hintText: _provider == 'Bank Account'
                                      ? 'e.g. PK36MEZN0001234567890123'
                                      : 'e.g. 03001234567',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGray),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGray),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter account or IBAN number';
                                  }
                                  if (val.trim().length < 5) {
                                    return 'Please enter a valid account number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: _isSaving ? null : _savePaymentMethod,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_rounded, size: 20),
                                  label: Text(
                                    _isSaving
                                        ? 'Saving Details...'
                                        : 'Save Payment Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
