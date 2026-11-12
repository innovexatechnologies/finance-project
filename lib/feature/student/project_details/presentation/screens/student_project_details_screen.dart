import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/apply/presentation/screens/apply_project_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final id = project['projectId']?.toString() ??
        project['id']?.toString() ??
        '';
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
    final stipend = (project['stipend']?.toString().trim().isNotEmpty == true)
        ? project['stipend'].toString().trim()
        : (project['budget']?.toString().trim() ?? '');
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

    final requirementBullets = _splitLines(requirementsRaw);
    final deliverableBullets = _splitLines(deliverablesRaw);

    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final isSaved = AppDataService.instance.isProjectSaved(id);
        final hasApplied = AppDataService.instance.hasApplied(id);
        final currentApplication = _findCurrentApplication(id);
        final paymentProject = currentApplication ?? project;
        final isAssignedProject =
            paymentProject['isAssignedProject'] == true;
        final paymentStatusAvailable =
            paymentProject['paymentStatusAvailable'] == true;
        final paymentSent = paymentProject['paymentSent'] == true;
        final paymentConfirmationStatus =
            _savedPaymentConfirmationStatus ??
                paymentProject['paymentConfirmationStatus']?.toString();
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
                              StatusBadge(label: status),
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
                              if (stipend.isNotEmpty)
                                _buildMetaBadge(
                                  Icons.workspace_premium_outlined,
                                  stipend,
                                  AppColors.statusOpen,
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

                          if (isAssignedProject) ...[
                            _buildPaymentConfirmationSection(
                              projectId: id,
                              statusAvailable: paymentStatusAvailable,
                              paymentSent: paymentSent,
                              confirmationStatus:
                                  paymentConfirmationStatus,
                            ),
                            const SizedBox(height: 18),
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
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isAssignedProject
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.cardWhite,
                      border: Border(
                        top: BorderSide(color: AppColors.lightGray),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: isSaved ? 'Remove Bookmark' : 'Save Project',
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color:
                                isSaved ? AppColors.teal : AppColors.grayText,
                          ),
                          onPressed: () {
                            AppDataService.instance.toggleSaveProject(project);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                                ApplyProjectScreen(
                                              project: project,
                                            ),
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
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                    ),
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

  Widget _buildPaymentConfirmationSection({
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
