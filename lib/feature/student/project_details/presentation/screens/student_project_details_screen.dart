import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/apply/presentation/screens/apply_project_screen.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/widgets/student_project_detail_help_section.dart';

class StudentProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const StudentProjectDetailsScreen({super.key, required this.project});

  @override
  State<StudentProjectDetailsScreen> createState() =>
      _StudentProjectDetailsScreenState();
}

class _StudentProjectDetailsScreenState
    extends State<StudentProjectDetailsScreen> {
  bool _isSubmittingPaymentConfirmation = false;
  String? _savedPaymentConfirmationStatus;

  @override
  void initState() {
    super.initState();
    final id = widget.project['id']?.toString() ??
        widget.project['projectId']?.toString() ??
        '';
    if (id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppDataService.instance.refreshProjectApplicantsCount(id);
        }
      });
    }
  }

  Map<String, dynamic>? _findCurrentApplication(String projectId) {
    final applications = AppDataService.instance.getApplications();
    final applicationId =
        widget.project['applicationId']?.toString() ?? '';
    for (final application in applications) {
      if (applicationId.isNotEmpty &&
          (application['applicationId']?.toString() ??
                  application['id']?.toString()) ==
              applicationId) {
        return application;
      }
    }
    for (final application in applications) {
      if (application['projectId']?.toString() == projectId &&
          application['isAssignedProject'] == true) {
        return application;
      }
    }
    for (final application in applications) {
      if (application['projectId']?.toString() == projectId) {
        return application;
      }
    }
    return null;
  }

  Future<void> _submitPaymentConfirmation({
    required String projectId,
    required bool received,
  }) async {
    if (_isSubmittingPaymentConfirmation) return;
    setState(() => _isSubmittingPaymentConfirmation = true);
    try {
      final response = await AppDataService.instance.confirmProjectPayment(
        projectId: projectId,
        received: received,
      );
      if (!mounted) return;
      setState(() => _savedPaymentConfirmationStatus = response);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Payment response saved: $response.'),
            backgroundColor: AppColors.statusOpen,
          ),
        );
    } catch (error) {
      debugPrint('Student payment confirmation failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save your payment response. Try again.'),
            backgroundColor: AppColors.statusClosed,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmittingPaymentConfirmation = false);
    }
  }

  List<String> _splitLines(String raw) {
    return raw
        .split(RegExp(r'[\n;]'))
        .map((e) => e.replaceFirst(RegExp(r'^[\-\•\*\d\.\)\s]+'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _openAttachment(BuildContext context, String urlStr) async {
    String normalized = urlStr.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open project attachment link.')),
      );
    }
  }

  Widget _buildReceiptImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final b64 = url.substring(commaIdx + 1);
          final bytes = base64Decode(b64);
          return Image.memory(bytes, width: width, height: height, fit: fit);
        }
      } catch (_) {}
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.receipt_long_rounded,
        size: 32,
        color: AppColors.primaryBlue,
      ),
    );
  }

  void _openReceiptViewer(BuildContext context, String imageUrl, String projectTitle) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              backgroundColor: AppColors.deepNavy,
              title: Text(
                'Admin Transfer Slip: $projectTitle',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520, maxWidth: 600),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: _buildReceiptImage(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final id = project['id']?.toString() ??
        project['projectId']?.toString() ??
        '';
    final currentApplication = _findCurrentApplication(id);

    final assignedStudentRaw = (project['assigned_student'] ??
            project['assignedStudent'] ??
            currentApplication?['assigned_student'] ??
            currentApplication?['assignedStudent'] ??
            '')
        .toString()
        .trim();

    final curUid = SupabaseHelper.currentUser?.id.trim().toLowerCase() ?? '';
    final curName = AppDataService.instance.userName.trim().toLowerCase();
    final curEmail = AppDataService.instance.userEmail.trim().toLowerCase();

    final isAssignedDirectly = assignedStudentRaw.isNotEmpty &&
        (assignedStudentRaw.toLowerCase() == curUid ||
            (curName.isNotEmpty &&
                assignedStudentRaw.toLowerCase() == curName) ||
            (curEmail.isNotEmpty &&
                assignedStudentRaw.toLowerCase() == curEmail));

    final appStatus =
        (currentApplication?['status'] ?? '').toString().trim().toLowerCase();
    final isAppAwarded = appStatus == 'accepted' ||
        appStatus == 'in progress' ||
        appStatus == 'in_progress' ||
        appStatus == 'delivered' ||
        appStatus == 'revision requested' ||
        appStatus == 'revision_requested' ||
        appStatus == 'ready_for_payout' ||
        appStatus == 'disputed' ||
        appStatus == 'rejected' ||
        appStatus == 'completed';

    final isAssignedProject = project['isAssignedProject'] == true ||
        currentApplication?['isAssignedProject'] == true ||
        isAppAwarded ||
        isAssignedDirectly;
    final statusAvailable =
        project['paymentStatusAvailable'] == true ||
            currentApplication?['paymentStatusAvailable'] == true;
    final paymentSent = project['paymentSent'] == true ||
        currentApplication?['paymentSent'] == true;
    final confirmationStatus = _savedPaymentConfirmationStatus ??
        project['paymentConfirmationStatus']?.toString() ??
        currentApplication?['paymentConfirmationStatus']?.toString();
    final title = (project['title']?.toString().trim().isNotEmpty == true)
        ? project['title'].toString().trim()
        : 'Untitled Project';
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    final category = project['category']?.toString().trim() ?? '';
    final duration =
        (project['duration']?.toString().trim().isNotEmpty == true)
            ? project['duration'].toString().trim()
            : 'Flexible';
    final workMode =
        (project['workMode']?.toString().trim().isNotEmpty == true)
            ? project['workMode'].toString().trim()
            : 'Remote';
    final deadline = project['deadline']?.toString().trim() ?? '';
    final openings = project['openings']?.toString().trim() ?? '';
    final description =
        (project['description']?.toString().trim().isNotEmpty == true)
            ? project['description'].toString().trim()
            : 'No detailed project summary was provided by the company.';
    final requirementsRaw = project['requirements']?.toString().trim() ?? '';
    final deliverablesRaw = project['deliverables']?.toString().trim() ?? '';
    final instructionsRaw =
        project['additionalInstructions']?.toString().trim() ?? '';
    final attachmentUrl = project['attachmentUrl']?.toString().trim() ?? '';
    final skills = SupabaseHelper.parseStringList(project['skills']);
    final isVerified = project['isVerified'] == true;
    final status = project['status']?.toString().trim() ?? 'Open';
    final rawBudget = project['budgetAmount'] ??
        project['budget'] ??
        project['escrow_amount'] ??
        project['escrowAmount'] ??
        15000;
    final budgetNum = (rawBudget is num)
        ? rawBudget
        : double.tryParse(rawBudget.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 15000;
    final escrowFormatted = budgetNum.toStringAsFixed(0);
    final statusLower = status.toLowerCase();
    final payoutTid = (project['payout_transaction_id'] ??
            project['payoutTransactionId'] ??
            currentApplication?['payout_transaction_id'] ??
            currentApplication?['payoutTransactionId'] ??
            '')
        .toString()
        .trim();
    final hasDisbursalTid = payoutTid.isNotEmpty;
    final pStatus = (project['payment_status'] ??
            project['paymentStatus'] ??
            currentApplication?['payment_status'] ??
            currentApplication?['paymentStatus'] ??
            '')
        .toString()
        .toLowerCase();
    final isPaid = statusLower == 'paid' ||
        pStatus == 'paid' ||
        project['isPaid'] == true ||
        project['is_paid'] == true ||
        currentApplication?['isPaid'] == true ||
        currentApplication?['is_paid'] == true ||
        ((statusLower == 'completed' || statusLower == 'paid') &&
            (hasDisbursalTid ||
                project['isPaidByAdmin'] == true ||
                currentApplication?['isPaidByAdmin'] == true ||
                pStatus == 'paid'));
    final isReadyForPayout = statusLower == 'ready_for_payout';
    final hasDeliveredFlag = project['isDelivered'] == true ||
        currentApplication?['isDelivered'] == true ||
        (currentApplication?['submissionUrl'] != null &&
            currentApplication!['submissionUrl'].toString().isNotEmpty) ||
        (project['submissionUrl'] != null &&
            project['submissionUrl'].toString().isNotEmpty) ||
        (project['delivered_at'] != null &&
            project['delivered_at'].toString().isNotEmpty) ||
        AppDataService.instance.getSubmission(id) != null;
    final isDelivered = statusLower == 'delivered' ||
        statusLower == 'under review' ||
        statusLower == 'under_review' ||
        hasDeliveredFlag;
    final isRevisionRequested = statusLower == 'revision_requested' || statusLower == 'revision requested';
    final isDisputed = statusLower == 'disputed' ||
        statusLower == 'rejected' ||
        project['isDisputed'] == true ||
        currentApplication?['isDisputed'] == true ||
        appStatus == 'rejected' ||
        appStatus == 'disputed';
    final isCancelled = statusLower == 'cancelled' ||
        project['isCancelled'] == true ||
        currentApplication?['isCancelled'] == true;
    final payoutReceiptUrl = (project['payout_receipt_url'] ??
            project['paymentReceiptUrl'] ??
            currentApplication?['payout_receipt_url'] ??
            currentApplication?['paymentReceiptUrl'] ??
            '')
        .toString()
        .trim();
    final revisionDeadline = (project['revision_deadline'] ??
            project['revisionDeadline'] ??
            currentApplication?['revision_deadline'] ??
            currentApplication?['revisionDeadline'] ??
            '')
        .toString()
        .trim();
    final revisionNotes =
        (project['revision_notes'] ?? project['revisionNotes'] ?? '')
            .toString()
            .trim();

    final requirementBullets = _splitLines(requirementsRaw);
    final deliverableBullets = _splitLines(deliverablesRaw);

    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final isSaved = AppDataService.instance.isProjectSaved(id);
        final hasApplied = AppDataService.instance.hasApplied(id);
        final isClosed = status.toLowerCase() == 'closed' ||
            status.toLowerCase() == 'completed';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 190,
                pinned: true,
                backgroundColor: AppColors.deepNavy,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      ShareService.shareProject(
                        context: context,
                        project: project,
                      );
                    },
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: isSaved ? AppColors.teal : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      AppDataService.instance.toggleSaveProject(project);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? 'Project removed from bookmarks'
                                : 'Project saved to bookmarks!',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.deepNavy,
                          AppColors.primaryBlue,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.business_center_rounded,
                            size: 72,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Center(
                              child: Text(
                                SupabaseHelper.initialsFor(
                                  company,
                                  fallback: 'CO',
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: isCancelled
                                    ? 'Cancelled'
                                    : (isDisputed
                                        ? 'Rejected'
                                        : (isPaid
                                            ? 'Paid'
                                            : (isReadyForPayout
                                                ? 'Approved'
                                                : status))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                company,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grayText,
                                ),
                              ),
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightAqua,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: AppColors.teal,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified Partner',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.deepNavy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Overflow-safe Meta Chips Wrap
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (category.isNotEmpty)
                                _buildMetaBadge(
                                  Icons.category_outlined,
                                  category,
                                  AppColors.indigoAccent,
                                ),
                              _buildMetaBadge(
                                Icons.schedule_rounded,
                                duration,
                                AppColors.deepNavy,
                              ),
                              _buildMetaBadge(
                                Icons.public_rounded,
                                workMode,
                                AppColors.primaryBlue,
                              ),
                              if (deadline.isNotEmpty)
                                _buildMetaBadge(
                                  Icons.event_outlined,
                                  'Deadline: $deadline',
                                  const Color(0xFFD97706),
                                ),
                              if (openings.isNotEmpty)
                                _buildMetaBadge(
                                  Icons.groups_outlined,
                                  '$openings seat${openings == '1' ? '' : 's'}',
                                  AppColors.teal,
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Escrow & Lifecycle Status Banners (Strictly for Awarded/Assigned Student ONLY)
                          if (isAssignedProject) ...[
                            if (isCancelled) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cancel_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Project Cancelled (Refunded)',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF991B1B),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'SkillBridge administration payment refund to company. Project Cancelled.',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFFB91C1C),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (isPaid) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
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
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF059669),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Payment Disbursed by Admin (Paid) ✓',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF065F46),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Company approved your deliverables and SkillBridge Executive Administrator has disbursed your payment.',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: const Color(0xFF047857),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (payoutTid.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFD1FAE5)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.numbers_rounded, size: 16, color: Color(0xFF059669)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Transfer TID: $payoutTid',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF065F46),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: payoutTid));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('TID copied to clipboard'),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF059669)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (payoutReceiptUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () => _openReceiptViewer(context, payoutReceiptUrl, title),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFD1FAE5)),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: _buildReceiptImage(
                                                payoutReceiptUrl,
                                                width: 44,
                                                height: 44,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Admin Bank Transfer Slip',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF065F46),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Tap for full-size interactive zoom',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: const Color(0xFF047857),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.fullscreen_rounded,
                                              size: 20,
                                              color: Color(0xFF059669),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else if (isDisputed) ...[
                            Container(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cancel_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Project Deliverables Rejected by Company',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF991B1B),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Company has rejected the submitted deliverables. SkillBridge Admin is mediating this dispute (Case: ${project['dispute_case_id'] ?? project['disputeCaseId'] ?? '#SB-DISPUTE'}).',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFFB91C1C),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.email_rounded,
                                            size: 16, color: Color(0xFFDC2626)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Share evidence on our official Gmail:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF7F1D1D),
                                                ),
                                              ),
                                              Text(
                                                AppDataService.skillBridgeOfficialGmail,
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(const ClipboardData(
                                                text: AppDataService.skillBridgeOfficialGmail));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('SkillBridge official Gmail copied to clipboard!'),
                                                duration: Duration(seconds: 2),
                                                backgroundColor: Color(0xFFDC2626),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFCA5A5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.copy_rounded,
                                                    size: 12, color: Color(0xFFDC2626)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Copy',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFDC2626),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isRevisionRequested) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.rate_review_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Improvement Requested (Only 1 Review Allowed)',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E40AF),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              revisionDeadline.isNotEmpty
                                                  ? '⚠️ You have strictly 2 Days (48 Hours) to re-deliver revised deliverables (Deadline: $revisionDeadline).'
                                                  : '⚠️ You have strictly 2 Days (48 Hours) to re-deliver revised deliverables based on supervisor notes.',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1D4ED8),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (revisionNotes.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFBFDBFE),
                                        ),
                                      ),
                                      child: Text(
                                        'Company Feedback: "$revisionNotes"',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: const Color(0xFF1E3A8A),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else if (isReadyForPayout) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Deliverables Approved by Company!',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E40AF),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Company has approved your work. Platform payout has been sent to Admin queue for disbursal to your account.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: const Color(0xFF1D4ED8),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Real Escrow Funded Protection Notice
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      color: Color(0xFF059669),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Company Sent Your Pay to Admin\'s Account (Escrow Funded)',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF065F46),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isDelivered
                                              ? 'Deliverables submitted. Payout releases upon company approval or after 5-day review window.'
                                              : 'PKR $escrowFormatted is safely held in SkillBridge platform custody. Your payout is 100% guaranteed upon deliverable approval.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: const Color(0xFF047857),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          StudentProjectDetailHelpSection(
                            project: project,
                            onHelpRequested: () {
                              if (mounted) setState(() {});
                            },
                          ),
                        ],

                          _buildSectionCard(
                            title: 'About this Project',
                            child: Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.darkText,
                                height: 1.55,
                              ),
                            ),
                          ),

                          if (requirementBullets.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSectionCard(
                              title: 'Requirements & Scope',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: requirementBullets
                                    .map(_buildBulletItem)
                                    .toList(),
                              ),
                            ),
                          ],

                          if (deliverableBullets.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSectionCard(
                              title: 'Expected Deliverables',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: deliverableBullets
                                    .map(_buildBulletItem)
                                    .toList(),
                              ),
                            ),
                          ],

                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSectionCard(
                              title: 'Skills Required',
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: skills.map((s) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.lightGray),
                                    ),
                                    child: Text(
                                      s,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          if (instructionsRaw.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSectionCard(
                              title: 'Additional Instructions',
                              child: Text(
                                instructionsRaw,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: AppColors.darkText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],

                          if (attachmentUrl.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () =>
                                  _openAttachment(context, attachmentUrl),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attachment_rounded,
                                        color: AppColors.primaryBlue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Open Attached Project Specification',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 16,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (isAssignedProject) ...[
                            const SizedBox(height: 14),
                            _buildPaymentConfirmationCard(
                              projectId: id,
                              statusAvailable: statusAvailable,
                              paymentSent: paymentSent,
                              confirmationStatus: confirmationStatus,
                            ),
                          ],
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.cardWhite,
                border: Border(top: BorderSide(color: AppColors.lightGray)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: isSaved ? 'Remove Bookmark' : 'Save Project',
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isSaved ? AppColors.teal : AppColors.grayText,
                    ),
                    onPressed: () {
                      AppDataService.instance.toggleSaveProject(project);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: isAssignedProject
                          ? (isCancelled
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.statusClosed,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.cancel_outlined, size: 18),
                                  label: Text(
                                    'Project Cancelled',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : isPaid
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.verified_rounded, size: 18),
                                  label: Text(
                                    'Payment Disbursed (Paid) ✓',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : isReadyForPayout
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                                  label: Text(
                                    'Approved (Awaiting Disbursal)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : isDelivered
                              ? Opacity(
                                  opacity: 0.55,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.grayText,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: null,
                                    icon: const Icon(Icons.hourglass_top_rounded, size: 18),
                                    label: Text(
                                      'Submitted (Under Review)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : isDisputed
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.gavel_rounded, size: 18),
                                  label: Text(
                                    'Disputed (In Mediation)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubmitWorkScreen(project: project),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                                  label: Text(
                                    'Submit Project',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ))
                          : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasApplied
                                            ? AppColors.statusOpen
                                            : (isClosed
                                                ? AppColors.grayText
                                                : AppColors.primaryBlue),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: isClosed && !hasApplied
                                          ? null
                                          : () {
                                              if (hasApplied) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'You have already applied! Check status in My Applications.',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ApplyProjectScreen(project: project),
                                                  ),
                                                );
                                              }
                                            },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            hasApplied
                                                ? 'Applied ✓'
                                                : (isClosed ? 'Closed' : 'Apply Now'),
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (!hasApplied && !isClosed) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_forward_rounded, size: 16),
                                          ],
                                        ],
                                      ),
                                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConfirmationCard({
    required String projectId,
    required bool statusAvailable,
    required bool paymentSent,
    required String? confirmationStatus,
  }) {
    final hasConfirmation = confirmationStatus == 'Received' ||
        confirmationStatus == 'Not Received';
    final statusLabel = hasConfirmation
        ? confirmationStatus!
        : !statusAvailable
            ? 'Payment status unavailable'
            : paymentSent
                ? 'Payment Sent'
                : 'Payment Pending';
    final statusColor = switch (statusLabel) {
      'Received' => const Color(0xFF166534),
      'Not Received' => AppColors.statusClosed,
      'Payment Sent' => AppColors.primaryBlue,
      'Payment Pending' => const Color(0xFF92400E),
      _ => AppColors.grayText,
    };
    final statusBackground = switch (statusLabel) {
      'Received' => AppColors.successBg,
      'Not Received' => AppColors.errorBg,
      'Payment Sent' => AppColors.lightAqua,
      'Payment Pending' => AppColors.warningBg,
      _ => AppColors.surfaceAlt,
    };
    final canRespond =
        statusAvailable && paymentSent && !hasConfirmation;

    return _buildSectionCard(
      title: 'Payment Confirmation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (canRespond) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusOpen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onPressed: _isSubmittingPaymentConfirmation
                    ? null
                    : () => _submitPaymentConfirmation(
                          projectId: projectId,
                          received: true,
                        ),
                icon: _isSubmittingPaymentConfirmation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Yes, Payment Received',
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusClosed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: AppColors.statusClosed),
                ),
                onPressed: _isSubmittingPaymentConfirmation
                    ? null
                    : () => _submitPaymentConfirmation(
                          projectId: projectId,
                          received: false,
                        ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text(
                  'No, Payment Not Received',
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 5, color: AppColors.primaryBlue),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.darkText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
