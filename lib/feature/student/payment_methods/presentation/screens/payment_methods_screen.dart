import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/student/payment_methods/services/student_payment_method_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _service = StudentPaymentMethodService();

  String _provider = StudentPaymentMethodService.providers.first;
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
    super.dispose();
  }

  Future<void> _loadPaymentMethod() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final saved = await _service.loadForCurrentUser();
      if (!mounted) return;
      setState(() {
        if (saved != null) {
          _provider =
              StudentPaymentMethodService.providers.contains(saved.provider)
              ? saved.provider
              : StudentPaymentMethodService.providers.first;
          _accountNumberController.text = saved.accountNumber;
          _hasSavedDetails = true;
        } else {
          _hasSavedDetails = false;
        }
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Payment method load failed: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load your payment details. Please try again.';
      });
    }
  }

  Future<void> _savePaymentMethod() async {
    if (_isLoading || _loadError != null || _isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await _service.saveForCurrentUser(
        provider: _provider,
        accountNumber: _accountNumberController.text,
      );
      if (!mounted) return;
      setState(() {
        _hasSavedDetails = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment details saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      debugPrint('Payment method save failed: $error');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save payment details. Please try again.'),
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
          'Payment Methods',
          style: GoogleFonts.poppins(
            color: AppColors.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.deepNavy),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusClosed,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.darkText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadPaymentMethod,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add the account where you want to receive payments. '
                    'Only you and authorized administrators can access these details. '
                    'A company can view them only after assigning you to its project.',
                    style: GoogleFonts.inter(
                      color: AppColors.darkText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Payment provider',
            style: GoogleFonts.poppins(
              color: AppColors.deepNavy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            items: StudentPaymentMethodService.providers
                .map(
                  (provider) =>
                      DropdownMenuItem(value: provider, child: Text(provider)),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (provider) {
                    if (provider != null) setState(() => _provider = provider);
                  },
          ),
          const SizedBox(height: 18),
          Text(
            'Account number',
            style: GoogleFonts.poppins(
              color: AppColors.deepNavy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountNumberController,
            enabled: !_isSaving,
            textInputAction: TextInputAction.done,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: 'Enter your account number',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
            validator: (value) {
              final accountNumber = value?.trim() ?? '';
              if (accountNumber.isEmpty) {
                return 'Enter your account number.';
              }
              if (accountNumber.length > 50) {
                return 'Account number must be 50 characters or fewer.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePaymentMethod,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _hasSavedDetails
                          ? 'Update payment details'
                          : 'Save payment details',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
