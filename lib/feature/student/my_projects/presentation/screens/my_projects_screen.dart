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
    _tabController = TabController(length: 3, vsync: this);
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
            backgroundColor: syncError != null
                ? AppColors.statusClosed
                : AppColors.statusOpen,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final allApps = AppDataService.instance.getApplications();

        final myProjects = allApps
            .where(
              (a) =>
                  a['status'] == 'In Progress' ||
                  a['status'] == 'Under Review' ||
                  a['status'] == 'Revision Requested' ||
                  a['status'] == 'Accepted' ||
                  a['status'] == 'Shortlisted' ||
                  a['status'] == 'Completed' ||
                  a['isAssignedProject'] == true,
            )
            .toList();

        final awaitingConfirmation = myProjects
            .where(
              (project) =>
                  _paymentStatusLabel(project) != 'Received' &&
                  _paymentStatusLabel(project) != 'Not Received',
            )
            .toList();
        final receivedProjects = myProjects
            .where((project) => _paymentStatusLabel(project) == 'Received')
            .toList();
        final notReceivedProjects = myProjects
            .where((project) => _paymentStatusLabel(project) == 'Not Received')
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
                tooltip: _isRefreshing
                    ? 'Syncing Projects...'
                    : 'Refresh Projects',
                icon: Icons.refresh_rounded,
                onPressed: _isRefreshing ? null : _refreshProjects,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.grayText,
              indicatorColor: AppColors.primaryBlue,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Awaiting Confirmation'),
                Tab(text: 'Received'),
                Tab(text: 'Not Received'),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProjectsTab(
                    projects: awaitingConfirmation,
                    emptyIcon: Icons.hourglass_empty_rounded,
                    emptyTitle: 'No Projects Awaiting Confirmation',
                    emptySubtitle: 'Unassigned projects appear here with an Unassigned status. Assigned projects remain here until you confirm payment.',
                  ),
                  _buildProjectsTab(
                    projects: receivedProjects,
                    emptyIcon: Icons.check_circle_outline_rounded,
                    emptyTitle: 'No Payments Confirmed as Received',
                    emptySubtitle:
                        'Projects you confirm as received will appear here.',
                  ),
                  _buildProjectsTab(
                    projects: notReceivedProjects,
                    emptyIcon: Icons.error_outline_rounded,
                    emptyTitle: 'No Payments Marked Not Received',
                    emptySubtitle:
                        'Projects you report as not received will appear here.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectsTab({
    required List<Map<String, dynamic>> projects,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _refreshProjects,
      child: projects.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                AppEmptyState(
                  icon: emptyIcon,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (_, index) => _buildProjectItem(
                projects[index],
                projects[index]['status'] == 'Completed',
              ),
            ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project, bool isCompleted) {
    final status = project['status']?.toString() ?? 'In Progress';
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    final pId =
        project['projectId']?.toString() ?? project['id']?.toString() ?? '';
    final hasSubmission = AppDataService.instance.getSubmission(pId) != null;
    final assignedDate =
        project['appliedDate']?.toString().trim() ?? 'Recently';
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
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.grayText,
                    ),
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
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.statusOpen,
                      ),
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
                _buildPaymentStatusChip(_paymentStatusLabel(project)),
              ],
            ),

            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.statusPending.withValues(alpha: 0.4),
                  ),
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
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                if (!isCompleted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'Revision Requested'
                          ? const Color(0xFFD97706)
                          : AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                        horizontal: 14,
                        vertical: 10,
                      ),
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

  String _paymentStatusLabel(Map<String, dynamic> project) {
    if (project['paymentStatusAvailable'] != true) {
      return 'Payment status unavailable';
    }
    if (project['isAssignedProject'] != true) return 'Unassigned';

    final confirmation = project['paymentConfirmationStatus']?.toString();
    if (confirmation == 'Received' || confirmation == 'Not Received') {
      return confirmation!;
    }
    return 'Awaiting Confirmation';
  }

  Widget _buildPaymentStatusChip(String label) {
    final color = switch (label) {
      'Received' => const Color(0xFF166534),
      'Not Received' => AppColors.statusClosed,
      'Awaiting Confirmation' => const Color(0xFF92400E),
      'Unassigned' => AppColors.grayText,
      _ => AppColors.grayText,
    };
    final background = switch (label) {
      'Received' => AppColors.successBg,
      'Not Received' => AppColors.errorBg,
      'Awaiting Confirmation' => AppColors.warningBg,
      'Unassigned' => AppColors.surfaceAlt,
      _ => AppColors.surfaceAlt,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
