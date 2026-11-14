import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';
import 'package:link_vibe/services/escrow_lifecycle_service.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshProjects({bool showFeedback = true}) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final hasClient = SupabaseHelper.clientOrNull != null;
      if (hasClient) {
        await AppDataService.instance.syncFromSupabase(forceRefresh: true);
      } else {
        await AppDataService.instance.init();
      }
      if (!mounted || !showFeedback) return;
      final syncError = AppDataService.instance.lastSyncError;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              syncError != null
                  ? SupabaseHelper.friendlyError(syncError)
                  : hasClient
                      ? 'Projects and statuses refreshed.'
                      : 'Refreshed local projects.',
            ),
            backgroundColor:
                syncError != null ? AppColors.statusClosed : AppColors.statusOpen,
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(SupabaseHelper.friendlyError(e)),
              backgroundColor: AppColors.statusClosed,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
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
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                'Submit deliverables for "$title"? The company has 5 days to inspect work or funds will automatically release to you.',
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
                  hintText: 'Summary of completed work...',
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
        _refreshProjects(showFeedback: false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project delivered successfully! 5-day review period started.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final allApps = AppDataService.instance.getApplications();

        final activeList = allApps
            .where((a) {
              final s = (a['status'] ?? '').toString().toLowerCase();
              return s == 'in progress' ||
                  s == 'in_progress' ||
                  s == 'under review' ||
                  s == 'revision requested' ||
                  s == 'accepted' ||
                  s == 'shortlisted' ||
                  s == 'delivered' ||
                  s == 'disputed' ||
                  s == 'ready_for_payout';
            })
            .toList();

        final completedList = allApps
            .where((a) => (a['status'] ?? '').toString().toLowerCase() == 'completed')
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ExecutiveAppBar(
            title: 'My Projects',
            subtitle: 'Active Engagements & Deliverables',
            showLeading: Navigator.canPop(context),
            leadingBadge: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business_center_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            actions: [
              ExecutiveHeaderIconButton(
                tooltip:
                    _isRefreshing ? 'Syncing Projects...' : 'Refresh Projects',
                icon: Icons.refresh_rounded,
                onPressed: _isRefreshing ? null : _refreshProjects,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.grayText,
              indicatorColor: AppColors.primaryBlue,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Active (${activeList.length})'),
                Tab(text: 'Completed (${completedList.length})'),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: _refreshProjects,
                    child: activeList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 40),
                              AppEmptyState(
                                icon: Icons.folder_shared_outlined,
                                title: 'No Active Projects',
                                subtitle:
                                    'Apply for open projects from Explore and once a partner company shortlists or assigns you, it will appear here.',
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: activeList.length,
                            itemBuilder: (_, index) =>
                                _buildProjectItem(activeList[index], false),
                          ),
                  ),
                  RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: _refreshProjects,
                    child: completedList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 40),
                              AppEmptyState(
                                icon: Icons.verified_outlined,
                                title: 'No Completed Projects Yet',
                                subtitle:
                                    'Finished projects approved by your company supervisor will appear here alongside your verified certificates.',
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: completedList.length,
                            itemBuilder: (_, index) =>
                                _buildProjectItem(completedList[index], true),
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

  Widget _buildProjectItem(Map<String, dynamic> project, bool isCompleted) {
    final status = project['status']?.toString() ?? 'In Progress';
    final statusLower = status.toLowerCase();
    final isInProgress = statusLower == 'in progress' || statusLower == 'in_progress';
    final isDelivered = statusLower == 'delivered';
    final isDisputed = statusLower == 'disputed';
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    final pId = project['projectId']?.toString() ??
        project['id']?.toString() ??
        '';
    final hasSubmission = AppDataService.instance.getSubmission(pId) != null;
    final assignedDate = project['appliedDate']?.toString().trim() ?? 'Recently';
    final feedback = project['companyFeedback']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lightAqua,
                        AppColors.primaryBlue.withValues(alpha: 0.14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      SupabaseHelper.initialsFor(company, fallback: 'CO'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title']?.toString() ?? 'Untitled Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                StatusBadge(label: status),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.grayText),
                    const SizedBox(width: 4),
                    Text(
                      'Updated: $assignedDate',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
                if (hasSubmission)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.statusOpen),
                      const SizedBox(width: 4),
                      Text(
                        'Work Uploaded',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusOpen,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (isInProgress) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Escrow Protected: Funds securely held by Skill Bridge Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isDelivered) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Delivered: Awaiting Company Review (5-day auto-release window)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isDisputed) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_rounded,
                        size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Disputed: Skill Bridge Admin is mediating settlement',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Supervisor Note: $feedback',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentProjectDetailsScreen(project: project),
                      ),
                    );
                  },
                  child: const Text('Details'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onPressed: () {
                    ShareService.shareProject(
                      context: context,
                      project: project,
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 15),
                  label: const Text('Share'),
                ),
                if (!isCompleted && isInProgress)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () => _handleDeliverProject(
                      context,
                      pId,
                      project['title']?.toString() ?? 'Project',
                    ),
                    icon: const Icon(Icons.send_rounded, size: 15),
                    label: Text(
                      'Deliver Project',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!isCompleted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'Revision Requested'
                          ? const Color(0xFFD97706)
                          : AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => status == 'Revision Requested'
                              ? FeedbackScreen(project: project)
                              : SubmitWorkScreen(project: project),
                        ),
                      );
                    },
                    icon: Icon(
                      status == 'Revision Requested'
                          ? Icons.rate_review_rounded
                          : Icons.upload_file_rounded,
                      size: 16,
                    ),
                    label: Text(
                      status == 'Revision Requested'
                          ? 'Feedback'
                          : hasSubmission
                              ? 'Update Work'
                              : 'Submit Work',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CertificatesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                    label: const Text('Certificate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
