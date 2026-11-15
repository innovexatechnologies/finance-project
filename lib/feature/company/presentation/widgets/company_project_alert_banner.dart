import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/services/helpdesk_service.dart';

/// Modular Company Project Alert Banner (Layer 3)
/// Automatically triggers an urgent notice when 2 days have passed since student submission
/// and the student escalates to Admin HelpDesk. Displays the 24-hour countdown window.
class CompanyProjectAlertBanner extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const CompanyProjectAlertBanner({
    super.key,
    required this.project,
    this.onApprove,
    this.onReject,
  });

  @override
  State<CompanyProjectAlertBanner> createState() =>
      _CompanyProjectAlertBannerState();
}

class _CompanyProjectAlertBannerState extends State<CompanyProjectAlertBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    // Check if HelpDesk escalation is active on this project
    final hasHelp = p.hasHelpRequest ||
        HelpdeskService.instance.hasActiveTicket(p.id);

    if (!hasHelp) {
      return const SizedBox.shrink();
    }

    // Do not show banner if already completed, disputed, or cancelled
    if (p.isCompleted || p.isDisputed || p.isCancelled) {
      return const SizedBox.shrink();
    }

    final ticket = HelpdeskService.instance.getTicketForProject(p.id);
    final isExpired = ticket?.is24HoursPassed ?? false;
    final remainingFormatted = ticket?.remainingFormatted ?? '24h 0m remaining';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDC2626),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '⚠️ URGENT: Action Required Within 24h',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? const Color(0xFF7F1D1D)
                                : const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isExpired ? 'EXPIRED' : remainingFormatted,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '⚠️ Urgent: 2 days have passed since submission. Please Approve or Reject the student\'s work within 24 hours, otherwise Admin will release payment directly.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB91C1C),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (ticket != null && ticket.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student HelpDesk Note:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '"${ticket.reason}"',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

