import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/services/company_payment_details_service.dart';

class AssignedStudentPaymentDetailsCard extends StatefulWidget {
  final String applicationId;

  const AssignedStudentPaymentDetailsCard({
    super.key,
    required this.applicationId,
  });

  @override
  State<AssignedStudentPaymentDetailsCard> createState() =>
      _AssignedStudentPaymentDetailsCardState();
}

class _AssignedStudentPaymentDetailsCardState
    extends State<AssignedStudentPaymentDetailsCard> {
  final _service = CompanyPaymentDetailsService();
  late Future<CompanyStudentPaymentDetails?> _detailsFuture;
  bool _isConfirmingAssignment = false;
  String? _confirmationError;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<CompanyStudentPaymentDetails?> _loadDetails() {
    return _service.loadForAssignment(widget.applicationId);
  }

  void _retry() {
    setState(() => _detailsFuture = _loadDetails());
  }

  Future<void> _confirmAssignment() async {
    setState(() {
      _isConfirmingAssignment = true;
      _confirmationError = null;
    });
    try {
      await _service.confirmAssignment(widget.applicationId);
      if (!mounted) return;
      setState(() {
        _isConfirmingAssignment = false;
        _detailsFuture = _loadDetails();
      });
    } catch (error) {
      debugPrint('Company assignment confirmation failed: $error');
      if (!mounted) return;
      setState(() {
        _isConfirmingAssignment = false;
        _confirmationError =
            'Could not confirm this assignment. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assigned student payment details',
                  style: GoogleFonts.poppins(
                    color: AppColors.deepNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<CompanyStudentPaymentDetails?>(
            future: _detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildMessage(
                  'Payment details could not be loaded. Please try again.',
                  action: TextButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                );
              }

              final details = snapshot.data;
              if (details == null) {
                return _buildMessage(
                  _confirmationError ??
                      "Confirm this student's assignment to securely access "
                          'their payment details.',
                  action: _isConfirmingAssignment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _confirmAssignment,
                          child: const Text('Confirm assignment'),
                        ),
                );
              }

              final accountNumber = details.accountNumber;
              if (accountNumber == null || accountNumber.isEmpty) {
                return _buildMessage(
                  'The student has not added payment details yet.',
                );
              }
              final provider = details.provider?.trim();
              final providerLabel = provider == null || provider.isEmpty
                  ? 'Payment account'
                  : provider;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerLabel,
                    style: GoogleFonts.inter(
                      color: AppColors.grayText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    accountNumber,
                    style: GoogleFonts.inter(
                      color: AppColors.deepNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, {Widget? action}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.grayText,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
