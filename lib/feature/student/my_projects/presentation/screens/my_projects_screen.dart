import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
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
            .where((a) {
              final s = (a['status'] ?? '').toString().toLowerCase();
              return s == 'in progress' ||
                  s == 'in_progress' ||
                  s == 'under review' ||
                  s == 'revision requested' ||
                  s == 'accepted' ||
                  s == 'shortlisted' ||
                  s == 'completed' ||
                  s == 'delivered' ||
                  s == 'disputed' ||
                  s == 'rejected' ||
                  s == 'ready_for_payout' ||
                  s == 'cancelled' ||
                  a['isCancelled'] == true ||
                  a['isDisputed'] == true ||
                  a['isAssignedProject'] == true;
            })
            .toList();

        final paidProjects = myProjects.where((p) {
          final s = (p['status'] ?? '').toString().toLowerCase();
          final pStatus = (p['payment_status'] ?? p['paymentStatus'] ?? '')
              .toString()
              .toLowerCase();
          final hasDisbursalTid = (p['payout_transaction_id'] ??
                  p['payoutTransactionId'] ??
                  '')
              .toString()
              .trim()
              .isNotEmpty;
          final isDisbursed = s == 'completed' ||
              s == 'paid' ||
              pStatus == 'paid' ||
              p['isPaid'] == true ||
              p['is_paid'] == true ||
              p['isPaidByAdmin'] == true ||
              hasDisbursalTid;
          return isDisbursed;
        }).toList();

        final activeProjects = myProjects.where((p) {
          final s = (p['status'] ?? '').toString().toLowerCase();
          final pStatus = (p['payment_status'] ?? p['paymentStatus'] ?? '')
              .toString()
              .toLowerCase();
          final hasDisbursalTid = (p['payout_transaction_id'] ??
                  p['payoutTransactionId'] ??
                  '')
              .toString()
              .trim()
              .isNotEmpty;
          final isDisbursed = s == 'completed' ||
              s == 'paid' ||
              pStatus == 'paid' ||
              p['isPaid'] == true ||
              p['is_paid'] == true ||
              p['isPaidByAdmin'] == true ||
              hasDisbursalTid;
          final isCancelled = s == 'cancelled' || p['isCancelled'] == true;
          return !isDisbursed && !isCancelled;
        }).toList();

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
              isScrollable: false,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.grayText,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Active (${activeProjects.length})'),
                Tab(text: 'Completed / Paid (${paidProjects.length})'),
                Tab(text: 'All (${myProjects.length})'),
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
                    projects: activeProjects,
                    emptyIcon: Icons.hourglass_empty_rounded,
                    emptyTitle: 'No Active Projects in Progress',
                    emptySubtitle:
                        'Projects assigned to you will appear here with company-funded escrow protection and delivery tracking.',
                  ),
                  _buildProjectsTab(
                    projects: paidProjects,
                    emptyIcon: Icons.check_circle_outline_rounded,
                    emptyTitle: 'No Paid Deliverables Yet',
                    emptySubtitle:
                        'Projects completed with verified Admin payout transfers and receipts will appear here.',
                  ),
                  _buildProjectsTab(
                    projects: myProjects,
                    emptyIcon: Icons.business_center_outlined,
                    emptyTitle: 'No Projects Found',
                    emptySubtitle:
                        'Explore verified projects and apply to start working on paid company challenges.',
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
    final statusLower = status.toLowerCase();
    final hasDisbursalTid = (project['payout_transaction_id'] ??
            project['payoutTransactionId'] ??
            '')
        .toString()
        .trim()
        .isNotEmpty;
    final pStatus = (project['payment_status'] ?? project['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();
    final isDisbursed = statusLower == 'completed' ||
        statusLower == 'paid' ||
        pStatus == 'paid' ||
        project['isPaid'] == true ||
        project['is_paid'] == true ||
        project['isPaidByAdmin'] == true ||
        hasDisbursalTid;
    final isCompleted = isDisbursed;
    final isReadyForPayout = statusLower == 'ready_for_payout';
    final isDelivered = statusLower == 'delivered';
    final isRevisionRequested = statusLower == 'revision_requested' || statusLower == 'revision requested';
    final isDisputed = statusLower == 'disputed' ||
        statusLower == 'rejected' ||
        project['isDisputed'] == true ||
        project['applicationStatus']?.toString().toLowerCase() == 'rejected' ||
        project['application_status']?.toString().toLowerCase() == 'rejected';
    final isCancelled = statusLower == 'cancelled' || project['isCancelled'] == true;
    final bool isAssigned = project['isAssignedProject'] == true;
    final payoutTid = (project['payout_transaction_id'] ??
            project['payoutTransactionId'] ??
            project['transactionId'] ??
            '')
        .toString()
        .trim();
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    final pId =
        project['projectId']?.toString() ?? project['id']?.toString() ?? '';
    final hasSubmission = AppDataService.instance.getSubmission(pId) != null;
    final assignedDate =
        project['appliedDate']?.toString().trim() ?? 'Recently';
    final feedback = project['companyFeedback']?.toString().trim() ?? '';
    final revisionNotes =
        (project['revision_notes'] ?? project['revisionNotes'] ?? feedback)
            .toString()
            .trim();

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
                StatusBadge(
                  label: isCancelled
                      ? 'Cancelled'
                      : (isDisputed
                      ? 'Rejected'
                      : (isReadyForPayout
                          ? 'Approved'
                          : (isDisbursed ? 'Paid' : status))),
                ),
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

            if (isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        payoutTid.isNotEmpty
                            ? 'Paid: Disbursed by Admin (TID: $payoutTid)'
                            : 'Paid: Payout disbursed by Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isReadyForPayout) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Company Approved Work! Admin Disbursal in progress.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isRevisionRequested) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rate_review_rounded,
                            size: 15, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Improvement Requested (1 Review Allowed • 2 Days)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (revisionNotes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Notes: $revisionNotes',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E3A8A),
                          height: 1.35,
                        ),
                      ),
                    ],
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
            ] else if (isCancelled) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_rounded,
                        size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SkillBridge administration payment refund to company. Project Cancelled.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isDisbursed) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payoutTid.isNotEmpty
                            ? 'SkillBridge administration sent payment to student (TID: $payoutTid)'
                            : 'SkillBridge administration sent payment to student',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF065F46),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel_rounded,
                            size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Project Deliverables Rejected by Company',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please share your work evidence on our official Gmail: ${AppDataService.skillBridgeOfficialGmail}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB91C1C),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(
                            text: AppDataService.skillBridgeOfficialGmail));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SkillBridge official Gmail copied!'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                              'Copy Gmail',
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
            ] else if (isAssigned) ...[
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
                        'Company Sent Your Pay to Admin\'s Account (Escrow Funded)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                if (isCancelled) ...[
                  Opacity(
                    opacity: 0.75,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusClosed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.cancel_outlined, size: 15),
                      label: Text(
                        'Project Cancelled',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else if (!isCompleted) ...[
                  if (isReadyForPayout) ...[
                    Opacity(
                      opacity: 0.75,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        onPressed: null,
                        icon: const Icon(Icons.task_alt_rounded, size: 15),
                        label: Text(
                          'Approved (Awaiting Disbursal)',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else if (isDisputed) ...[
                    Opacity(
                      opacity: 0.75,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        onPressed: null,
                        icon: const Icon(Icons.gavel_rounded, size: 15),
                        label: Text(
                          'Rejected • Dispute Mediation',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else if (isDelivered ||
                      hasSubmission ||
                      statusLower == 'under review' ||
                      statusLower == 'under_review' ||
                      statusLower == 'delivered') ...[
                    Opacity(
                      opacity: 0.55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grayText,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        onPressed: null,
                        icon: const Icon(Icons.hourglass_top_rounded, size: 15),
                        label: Text(
                          'Submitted (Under Review)',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
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
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: Text(
                        'Submit Project',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ]
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
