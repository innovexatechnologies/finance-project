import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/apply/presentation/screens/apply_project_screen.dart';
import 'package:link_vibe/services/escrow_lifecycle_service.dart';

class StudentProjectDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> project;

  const StudentProjectDetailsScreen({super.key, required this.project});

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

  Future<void> _handleDeliverProject(
    BuildContext context,
    String projectId,
    String title,
  ) async {
    final notesController = TextEditingController();
    final urlController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF059669)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Deliver Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to submit completed deliverables for "$title"? Skill Bridge will notify the company. They have 5 days to review, after which payment is automatically released.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Deliverables Link / GitHub / Drive (Optional)',
                  hintText: 'https://github.com/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Delivery Notes (Optional)',
                  hintText: 'Summary of completed work and notes for the supervisor...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await EscrowLifecycleService().deliverProject(
        projectId: projectId,
        workUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
        summary: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project delivered successfully! 5-day review period started.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(EscrowLifecycleService().lastError ?? 'Failed to deliver project.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReDeliverProject(
    BuildContext context,
    String projectId,
    String title,
  ) async {
    final notesController = TextEditingController();
    final urlController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Re-Deliver Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit revised deliverables for "$title"? The 5-day review timer will reset and restart from 0 for company inspection.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Updated Work Link / GitHub / Drive (Optional)',
                  hintText: 'https://github.com/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Revision Changelog / Notes (Optional)',
                  hintText: 'Summary of fixes applied based on supervisor notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Re-Deliver Work'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await EscrowLifecycleService().reDeliverProject(
        projectId: projectId,
        workUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
        summary: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revised work submitted! 5-day review countdown restarted.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(EscrowLifecycleService().lastError ?? 'Failed to re-deliver project.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = project['id']?.toString() ??
        project['projectId']?.toString() ??
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
    final isInProgress = statusLower == 'in_progress' || statusLower == 'in progress';
    final isDelivered = statusLower == 'delivered';
    final isRevisionRequested = statusLower == 'revision_requested' || statusLower == 'revision requested';
    final isDisputed = statusLower == 'disputed';
    final revisionCount = (project['revision_count'] as num?)?.toInt() ??
        (project['revisionCount'] as num?)?.toInt() ??
        1;
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

                          // Escrow Trust Banner for Awarded/In Progress/Delivered/Disputed Projects
                          if (isInProgress || isDelivered) ...[
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
                                          'Escrow Protected: PKR $escrowFormatted is securely held by Skill Bridge Admin',
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
                                              : 'Your payout is pre-funded and held in platform custody. Submit deliverables to trigger release.',
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
                                              'Revision $revisionCount of 2 Requested by Company',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E40AF),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            const Text(
                                              '5-day auto-release timer is paused. Review requested improvements and click Re-Deliver when ready.',
                                              style: TextStyle(
                                                fontSize: 11.5,
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
                                        'Supervisor Feedback: "$revisionNotes"',
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.gavel_rounded,
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
                                          'Dispute Under Review: Case ${project['dispute_case_id'] ?? project['disputeCaseId'] ?? '#SB-PENDING'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF991B1B),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          'Skill Bridge Admin is mediating this project to decide 100% student, refund, or 50-50 split.',
                                          style: TextStyle(
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
                      child: isRevisionRequested
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () =>
                                  _handleReDeliverProject(context, id, title),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(
                                'Re-Deliver Project (Revision $revisionCount/2)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : isInProgress
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => _handleDeliverProject(context, id, title),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                'Deliver Project',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : isDelivered
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.hourglass_top_rounded, size: 18),
                                  label: Text(
                                    'Delivered (Under Review)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
