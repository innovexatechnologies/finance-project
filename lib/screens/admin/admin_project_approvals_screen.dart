import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/services/admin_dispute_payout_service.dart';
import 'package:link_vibe/services/admin_project_approval_service.dart';

/// Admin Screen for Reviewing and Approving Company Upfront Escrow Deposits & Student Payouts.
/// Strictly uses pure service layers — NO direct Supabase calls.
class AdminProjectApprovalsScreen extends StatefulWidget {
  const AdminProjectApprovalsScreen({super.key});

  @override
  State<AdminProjectApprovalsScreen> createState() =>
      _AdminProjectApprovalsScreenState();
}

class _AdminProjectApprovalsScreenState
    extends State<AdminProjectApprovalsScreen>
    with SingleTickerProviderStateMixin {
  final AdminProjectApprovalService _approvalService =
      AdminProjectApprovalService();
  final AdminDisputePayoutService _payoutService = AdminDisputePayoutService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  String _searchQuery = '';
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging ||
          _tabController.animation?.value == _tabController.index) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _approvalService.loadPendingApprovals(forceRefresh: true),
      _payoutService.loadPayoutReadyProjects(forceRefresh: true),
    ]);
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showFeedback('$label copied to clipboard');
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out Console'),
        content: const Text('Are you sure you want to end your active session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  void _onRouteSelected(String routeId) {
    AdminSidebar.navigateToRoute(
      context,
      scaffoldKey: _scaffoldKey,
      currentRouteId: 'projects_audit',
      targetRouteId: routeId,
    );
  }

  void _viewReceiptImage(String imageUrl, String projectTitle) {
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
              backgroundColor: AppColors.darkNavy,
              title: Text(
                'Receipt Proof: $projectTitle',
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
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load receipt image: $error',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApprove(ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Approve & Publish Project?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Builder(
          builder: (context) {
            final base = project.escrowAmount > 0 ? project.escrowAmount : 15000.0;
            final comm = (base * 0.10).roundToDouble();
            final total = base + comm;
            return Text(
              'Confirm receipt of total PKR ${total.toStringAsFixed(0)} (PKR ${base.toStringAsFixed(0)} Project Budget + PKR ${comm.toStringAsFixed(0)} [10%] Admin Commission) (TID: ${project.transactionId ?? 'N/A'})?\n\nOnce approved, this project will automatically go live on the Student Portal with a "Verified & Escrow Funded" badge.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark as Paid & Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await _approvalService.markAsPaidAndPublish(
        projectId: project.id,
      );
      if (!mounted) return;
      if (ok) {
        _showFeedback('Project verified and published live to students!');
        await _approvalService.loadPendingApprovals(forceRefresh: true);
        if (mounted) setState(() {});
      } else {
        _showFeedback(
          _approvalService.lastError ?? 'Failed to approve payment.',
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmReject(ProjectModel project) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Payment Proof'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please specify why this payment proof is invalid or rejected (e.g. TID mismatch, incorrect amount):',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a rejection reason';
                  }
                  return null;
                },
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject Payment'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await _approvalService.rejectPayment(
        projectId: project.id,
        rejectionReason: reasonController.text.trim(),
      );
      if (ok) {
        _showFeedback('Project payment marked rejected.');
      } else {
        _showFeedback(
          _approvalService.lastError ?? 'Failed to reject payment.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: 'projects_audit',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'projects_audit',
                  onRouteSelected: _onRouteSelected,
                  onSignOut: _handleSignOut,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopNavbar(
                      pageTitle: 'Project Payment Approvals',
                      breadcrumb: 'Escrow Verification & Disbursals',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (q) => setState(() => _searchQuery = q),
                    ),
                    _buildTabsBar(isDesktop),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCompanyDepositsTab(isDesktop),
                          _buildStudentPayoutsTab(isDesktop),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatSubmissionDate(String raw) {
    if (raw.trim().isEmpty) return 'N/A';
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final local = parsed.toLocal();
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = monthNames[local.month - 1];
      final day = local.day;
      final year = local.year;
      final hour = local.hour == 0
          ? 12
          : (local.hour > 12 ? local.hour - 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$month $day, $year • $hour:$minute $period';
    }
    if (raw.contains('T')) {
      final parts = raw.split('T');
      final date = parts[0];
      final time = parts[1].split('.')[0];
      return '$date • $time';
    }
    return raw;
  }

  Widget _buildQueueBanner(int count, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Escrow Verification Queue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 16 : 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verify company deposit slips against bank statements before publishing live',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: count > 0 ? AppColors.warning : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$count Pending',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingProjectCard(ProjectModel project, {bool isMobile = false}) {
    final baseAmount = project.escrowAmount > 0 ? project.escrowAmount : 15000.0;
    final commission10 = (baseAmount * 0.10).roundToDouble();
    final totalDeposit = baseAmount + commission10;
    final amountText = 'PKR ${totalDeposit.toStringAsFixed(0)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Posted by: ${project.companyName} • ${project.category}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      amountText,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'incl. 10% fee (PKR ${commission10.toStringAsFixed(0)})',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Escrow Details Row with 10% Platform Fee breakdown
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildMetaItem(
                label: 'Project Budget',
                value: 'PKR ${baseAmount.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
              ),
              _buildMetaItem(
                label: 'Admin Fee (10%)',
                value: 'PKR ${commission10.toStringAsFixed(0)}',
                icon: Icons.percent_rounded,
              ),
              _buildMetaItem(
                label: 'Total Deposit',
                value: 'PKR ${totalDeposit.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
              ),
              _buildMetaItem(
                label: 'Payment Method',
                value: project.paymentMethodUsed?.isNotEmpty == true
                    ? project.paymentMethodUsed!
                    : 'Bank / Wallet',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildMetaItem(
                label: 'Transaction ID (TID)',
                value: project.transactionId?.isNotEmpty == true
                    ? project.transactionId!
                    : 'N/A',
                icon: Icons.numbers_rounded,
                isMonospace: true,
                onCopy: project.transactionId != null &&
                        project.transactionId!.isNotEmpty
                    ? () => _copyToClipboard(project.transactionId!, 'TID')
                    : null,
              ),
              _buildMetaItem(
                label: 'Submission Date',
                value: _formatSubmissionDate(project.createdAt),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Receipt Screenshot Preview
          if (project.paymentReceiptUrl != null &&
              project.paymentReceiptUrl!.isNotEmpty) ...[
            Text(
              'Payment Receipt Proof:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _viewReceiptImage(
                project.paymentReceiptUrl!,
                project.title,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        project.paymentReceiptUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.receipt_long_rounded,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Click to Inspect Receipt Screenshot',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap for full-size interactive zoom',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.fullscreen_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Action Buttons: 100% Overflow Proof with Responsive LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 480;
              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject Payment'),
                      onPressed: () => _confirmReject(project),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Mark as Paid & Publish',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _confirmApprove(project),
                    ),
                  ],
                );
              }

              // Mobile Layout: Two Expanded buttons perfectly proportioned to never overflow
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: Text(
                        'Reject Payment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _confirmReject(project),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Mark as Paid',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _confirmApprove(project),
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

  Widget _buildMetaItem({
    required String label,
    required String value,
    required IconData icon,
    bool isMonospace = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: isMonospace
                      ? GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        )
                      : GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNavy,
                        ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onCopy,
                    child: const Icon(Icons.copy_rounded,
                        size: 13, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabsBar(bool isDesktop) {
    return ValueListenableBuilder<List<ProjectModel>>(
      valueListenable: _approvalService.pendingApprovalsNotifier,
      builder: (context, pendingCompany, _) {
        return ValueListenableBuilder<List<ProjectModel>>(
          valueListenable: _payoutService.payoutReadyProjectsNotifier,
          builder: (context, pendingPayouts, _) {
            final companyCount = pendingCompany.length;
            final payoutCount = pendingPayouts.length;

            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 14,
                vertical: 10,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text('Company Deposits'),
                        if (companyCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$companyCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payments_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text('Student Payouts'),
                        if (payoutCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$payoutCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompanyDepositsTab(bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ValueListenableBuilder<bool>(
        valueListenable: _approvalService.isLoadingNotifier,
        builder: (context, isLoading, _) {
          return ValueListenableBuilder<List<ProjectModel>>(
            valueListenable: _approvalService.pendingApprovalsNotifier,
            builder: (context, pendingProjects, _) {
              final filtered = pendingProjects.where((p) {
                if (_searchQuery.trim().isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return p.title.toLowerCase().contains(q) ||
                    p.companyName.toLowerCase().contains(q) ||
                    (p.transactionId?.toLowerCase().contains(q) ?? false);
              }).toList();

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 14,
                  vertical: isDesktop ? 16 : 12,
                ),
                children: [
                  _buildQueueBanner(
                    pendingProjects.length,
                    isDesktop,
                  ),
                  const SizedBox(height: 16),
                  if (isLoading && pendingProjects.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map(
                      (p) => _buildPendingProjectCard(
                        p,
                        isMobile: !isDesktop,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentPayoutsTab(bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ValueListenableBuilder<bool>(
        valueListenable: _payoutService.isLoadingNotifier,
        builder: (context, isLoading, _) {
          return ValueListenableBuilder<List<ProjectModel>>(
            valueListenable: _payoutService.payoutReadyProjectsNotifier,
            builder: (context, payoutProjects, _) {
              final filtered = payoutProjects.where((p) {
                if (_searchQuery.trim().isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return p.title.toLowerCase().contains(q) ||
                    p.companyName.toLowerCase().contains(q) ||
                    (p.assignedStudent?.toLowerCase().contains(q) ?? false);
              }).toList();

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 14,
                  vertical: isDesktop ? 16 : 12,
                ),
                children: [
                  _buildPayoutQueueBanner(
                    payoutProjects.length,
                    isDesktop,
                  ),
                  const SizedBox(height: 16),
                  if (isLoading && payoutProjects.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filtered.isEmpty)
                    _buildStudentPayoutEmptyState()
                  else
                    ...filtered.map(
                      (p) => _buildStudentPayoutCard(
                        p,
                        isMobile: !isDesktop,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPayoutQueueBanner(int count, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
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
                  'Student Escrow Disbursal Queue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 16 : 14.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Company approved deliverables. Review student bank details and send payout.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF047857),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: count > 0 ? const Color(0xFF059669) : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$count Pending',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPayoutCard(ProjectModel project, {required bool isMobile}) {
    final escrow = project.escrowAmount > 0 ? project.escrowAmount : 25000.0;
    final fee = double.parse((escrow * 0.10).toStringAsFixed(2));
    final netStudent = double.parse((escrow * 0.90).toStringAsFixed(2));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openStudentPayoutModal(project),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'COMPANY APPROVED • READY FOR DISBURSAL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ),
                    Text(
                      'PKR ${netStudent.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Company: ${project.companyName} • Category: ${project.category}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Awarded Student: ${project.assignedStudent ?? "Candidate"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ),
                      Text(
                        'Fee: PKR ${fee.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.account_balance_rounded, size: 16),
                    label: const Text(
                      'Review Student Bank Details & Send Payment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _openStudentPayoutModal(project),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentPayoutEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const AppEmptyState(
        title: 'No Pending Student Payouts',
        subtitle:
            'Projects approved by companies will appear here for you to inspect the awarded student\'s bank details and disburse payout.',
        icon: Icons.payments_rounded,
      ),
    );
  }

  Future<void> _openStudentPayoutModal(ProjectModel project) async {
    final escrow = project.escrowAmount > 0 ? project.escrowAmount : 25000.0;
    final commission10 = double.parse((escrow * 0.10).toStringAsFixed(2));
    final netStudent = double.parse((escrow * 0.90).toStringAsFixed(2));

    final tidCtrl = TextEditingController();
    XFile? receiptFile;
    Uint8List? receiptBytes;
    bool isSaving = false;
    StudentDisbursalDetails? studentDetails;
    bool isLoadingDetails = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isLoadingDetails) {
            _payoutService.getStudentDisbursalDetails(project).then((details) {
              if (ctx.mounted) {
                setModalState(() {
                  studentDetails = details;
                  isLoadingDetails = false;
                });
              }
            });
          }

          final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboardInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
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
                              'Disburse Payout to Student',
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Project: ${project.title} • ${project.companyName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // 1. AWARDED STUDENT BANK & WALLET DESTINATION CARD
                  if (isLoadingDetails)
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Color(0xFF059669),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Awarded Student Bank Account Details',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                    Text(
                                      '${studentDetails?.studentName ?? project.assignedStudent ?? "Awarded Student"} • ${studentDetails?.studentEmail ?? ""}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Color(0xFFD1FAE5), height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Method',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      studentDetails?.paymentMethod ?? 'Bank Account',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkNavy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Title',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      studentDetails?.accountTitle ?? (studentDetails?.studentName ?? 'Student Account'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkNavy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Number / IBAN',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      studentDetails?.accountNumber ?? '0300-1234567',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy Account Number',
                                icon: const Icon(Icons.copy_rounded,
                                    size: 18, color: Color(0xFF059669)),
                                onPressed: () {
                                  _copyToClipboard(
                                    studentDetails?.accountNumber ?? '',
                                    'Student Account Number',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // 2. FINANCIAL BREAKDOWN CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildBreakdownRow(
                          'Total Escrow Funded',
                          'PKR ${escrow.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownRow(
                          'Platform Fee (10%)',
                          '- PKR ${commission10.toStringAsFixed(0)}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownRow(
                          'Net Payable to Student (90%)',
                          'PKR ${netStudent.toStringAsFixed(0)}',
                          color: AppColors.success,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. TID INPUT
                  Text(
                    'Bank Transfer TID / Reference Number *',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tidCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 109822998877 or TRX-0099',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. RECEIPT PROOF
                  Text(
                    'Transfer Receipt Screenshot Proof *',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (receiptBytes != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              receiptBytes!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              receiptFile?.name ?? 'receipt.jpg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              setModalState(() {
                                receiptFile = null;
                                receiptBytes = null;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setModalState(() {
                            receiptFile = img;
                            receiptBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Attach Transfer Slip / Receipt Screenshot'),
                    ),

                  const SizedBox(height: 24),

                  // 5. SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isSaving
                            ? 'Executing Transfer...'
                            : 'Send Payment & Mark as Paid (PKR ${netStudent.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final tid = tidCtrl.text.trim();
                              if (tid.isEmpty) {
                                _showFeedback('Please enter Bank Transfer TID', isError: true);
                                return;
                              }
                              if (receiptBytes == null) {
                                _showFeedback('Please attach transfer receipt screenshot proof', isError: true);
                                return;
                              }

                              setModalState(() => isSaving = true);

                              final receiptUrl = await _payoutService.uploadPayoutReceipt(
                                projectId: project.id,
                                bytes: receiptBytes!,
                                fileName: receiptFile?.name ?? 'receipt.jpg',
                              );

                              final ok = await _payoutService.completePayout(
                                projectId: project.id,
                                transactionId: tid,
                                receiptUrl: receiptUrl,
                              );

                              if (!ctx.mounted) return;
                              if (ok) {
                                Navigator.pop(ctx);
                                _showFeedback(
                                  'Payment of PKR ${netStudent.toStringAsFixed(0)} disbursed to ${studentDetails?.studentName ?? "Student"}! Project marked as Paid.',
                                );
                                await _refreshAllData();
                                if (mounted) setState(() {});
                              } else {
                                setModalState(() => isSaving = false);
                                _showFeedback(
                                  _payoutService.lastError ?? 'Failed to complete payout.',
                                  isError: true,
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: color ?? AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: color ?? AppColors.darkNavy,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const AppEmptyState(
        title: 'All Clear — No Pending Approvals',
        subtitle:
            'There are currently no company projects waiting for upfront payment verification. All active projects have been funded and published.',
        icon: Icons.task_alt_rounded,
      ),
    );
  }
}

