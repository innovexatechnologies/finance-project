import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/services/helpdesk_service.dart';

/// Modular Student Project Detail Help Section (Layer 3)
/// Enforces the 48-Hour (2-Day) submission review window and allows the student
/// to escalate an unresponsive submission to the Admin HelpDesk.
class StudentProjectDetailHelpSection extends StatefulWidget {
  final Map<String, dynamic> project;
  final VoidCallback? onHelpRequested;

  const StudentProjectDetailHelpSection({
    super.key,
    required this.project,
    this.onHelpRequested,
  });

  @override
  State<StudentProjectDetailHelpSection> createState() =>
      _StudentProjectDetailHelpSectionState();
}

class _StudentProjectDetailHelpSectionState
    extends State<StudentProjectDetailHelpSection> {
  bool _isSubmittingTicket = false;

  DateTime? _resolveSubmissionDate() {
    final raw = widget.project['submitted_at'] ??
        widget.project['submittedAt'] ??
        widget.project['delivered_at'] ??
        widget.project['deliveredAt'] ??
        widget.project['work_submitted_at'];

    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  bool _isSubmitted() {
    final status = (widget.project['status'] ?? '').toString().toLowerCase();
    final isDeliveredFlag = widget.project['isDelivered'] == true ||
        widget.project['isSubmitted'] == true;
    return status == 'submitted' ||
        status == 'delivered' ||
        status == 'under review' ||
        status == 'under_review' ||
        isDeliveredFlag;
  }

  bool _hasHelpRequest() {
    return widget.project['has_help_request'] == true ||
        widget.project['hasHelpRequest'] == true ||
        HelpdeskService.instance.hasActiveTicket(
          widget.project['projectId']?.toString() ??
              widget.project['id']?.toString() ??
              '',
        );
  }

  bool _isAlreadyResolvedOrDisputed() {
    final status = (widget.project['status'] ?? '').toString().toLowerCase();
    return status == 'completed' ||
        status == 'paid' ||
        status == 'disputed' ||
        status == 'rejected' ||
        status == 'cancelled';
  }

  Duration _timeUntil48Hours(DateTime submittedAt) {
    final diff = DateTime.now().difference(submittedAt);
    const twoDays = Duration(hours: 48);
    if (diff >= twoDays) return Duration.zero;
    return twoDays - diff;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Future<void> _openHelpRequestModal(BuildContext context) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Escalate to Admin HelpDesk',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                                Text(
                                  '48 Hours Review Window Expired',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The company has not responded within 48 hours. Submitting this request sends an urgent 24-hour final notice to the company. If they do not approve or reject within 24 hours, Admin will release the escrow payment directly to your account.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF1E40AF),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Reason for HelpDesk Escalation *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Describe the deliverables submitted and your attempt to contact the company...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.grayText,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 10) {
                            return 'Please provide at least 10 characters detailing the issue.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSubmittingTicket
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _isSubmittingTicket
                                ? 'Escalating to Admin...'
                                : 'Send to Admin HelpDesk',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _isSubmittingTicket
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final messenger = ScaffoldMessenger.of(context);
                                  final nav = Navigator.of(modalCtx);

                                  setModalState(() => _isSubmittingTicket = true);

                                  final pId = widget.project['projectId']?.toString() ??
                                      widget.project['id']?.toString() ??
                                      '';

                                  final ok = await HelpdeskService.instance
                                      .createHelpdeskTicket(
                                    projectId: pId,
                                    reason: reasonController.text.trim(),
                                    projectTitle: widget.project['title']?.toString(),
                                    companyName: widget.project['company']?.toString(),
                                  );

                                  setModalState(() => _isSubmittingTicket = false);
                                  nav.pop();

                                  if (ok && mounted) {
                                    setState(() {});
                                    widget.onHelpRequested?.call();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Ticket escalated to Admin HelpDesk. Company has been sent a 24-hour final notice.'),
                                        backgroundColor: Color(0xFF059669),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAlreadyResolvedOrDisputed()) {
      return const SizedBox.shrink();
    }

    if (!_isSubmitted()) {
      return const SizedBox.shrink();
    }

    final hasTicket = _hasHelpRequest();

    // State A: Already escalated to HelpDesk
    if (hasTicket) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Escalated to Admin HelpDesk',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '24H NOTICE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Admin has sent an automated 24-hour final notice to the company. If they do not approve or reject within this window, Admin will disburse the payment directly to your bank account.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFFB45309),
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

    // Check 48 hours submission window
    final submissionDate = _resolveSubmissionDate();
    final remainingTime = submissionDate != null
        ? _timeUntil48Hours(submissionDate)
        : Duration.zero;

    final isEligibleForHelp = submissionDate != null && remainingTime == Duration.zero;

    // State B: 48 Hours have elapsed -> Show "Request Admin Help" button
    if (isEligibleForHelp) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.alarm_on_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Company Has Not Responded in 48 Hours',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your work was submitted over 2 days ago. You are now eligible to request Admin HelpDesk escalation to trigger the final 24-hour notice.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFFB91C1C),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.support_agent_rounded, size: 16),
                label: const Text(
                  'Request Admin Help',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _openHelpRequestModal(context),
              ),
            ),
          ],
        ),
      );
    }

    // State C: Under 48 hours -> Subtle informational note
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 16,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Company has 48 hours to review your submission (${_formatDuration(remainingTime)} remaining for Help button).',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
