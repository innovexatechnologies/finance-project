import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/services/admin_project_approval_service.dart';

/// Admin Screen for Reviewing and Approving Company Upfront Escrow Deposits.
/// Strictly uses [AdminProjectApprovalService] — NO direct Supabase calls.
class AdminProjectApprovalsScreen extends StatefulWidget {
  const AdminProjectApprovalsScreen({super.key});

  @override
  State<AdminProjectApprovalsScreen> createState() =>
      _AdminProjectApprovalsScreenState();
}

class _AdminProjectApprovalsScreenState
    extends State<AdminProjectApprovalsScreen> {
  final AdminProjectApprovalService _approvalService =
      AdminProjectApprovalService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _approvalService.loadPendingApprovals();
    });
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
        content: Text(
          'Confirm receipt of PKR ${project.escrowAmount.toStringAsFixed(0)} (TID: ${project.transactionId ?? 'N/A'})?\n\nOnce approved, this project will automatically go live on the Student Portal with a "Verified & Escrow Funded" badge.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
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
      if (ok) {
        _showFeedback('Project verified and published live to students!');
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
                      breadcrumb: 'Escrow Verification Queue',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (q) => setState(() => _searchQuery = q),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            _approvalService.loadPendingApprovals(
                          forceRefresh: true,
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _approvalService.isLoadingNotifier,
                          builder: (context, isLoading, _) {
                            return ValueListenableBuilder<List<ProjectModel>>(
                              valueListenable:
                                  _approvalService.pendingApprovalsNotifier,
                              builder: (context, pendingProjects, _) {
                                final filtered = pendingProjects.where((p) {
                                  if (_searchQuery.trim().isEmpty) return true;
                                  final q = _searchQuery.toLowerCase();
                                  return p.title.toLowerCase().contains(q) ||
                                      p.companyName.toLowerCase().contains(q) ||
                                      (p.transactionId
                                              ?.toLowerCase()
                                              .contains(q) ??
                                          false);
                                }).toList();

                                return ListView(
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    _buildQueueBanner(
                                      pendingProjects.length,
                                      isDesktop,
                                    ),
                                    const SizedBox(height: 20),
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
                                      ...filtered.map((p) =>
                                          _buildPendingProjectCard(p)),
                                  ],
                                );
                              },
                            );
                          },
                        ),
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

  Widget _buildQueueBanner(int count, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Escrow Verification Queue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Text(
                    'Verify company deposit slips against bank statements before publishing live',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: count > 0 ? AppColors.warning : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Pending',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingProjectCard(ProjectModel project) {
    final amountText = 'PKR ${project.escrowAmount.toStringAsFixed(0)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      'Posted by: ${project.companyName} • ${project.category}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  amountText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Escrow Details Row
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildMetaItem(
                label: 'Payment Method',
                value: project.paymentMethodUsed ?? 'Bank / Wallet',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildMetaItem(
                label: 'Transaction ID (TID)',
                value: project.transactionId ?? 'N/A',
                icon: Icons.numbers_rounded,
                isMonospace: true,
                onCopy: project.transactionId != null
                    ? () => _copyToClipboard(project.transactionId!, 'TID')
                    : null,
              ),
              _buildMetaItem(
                label: 'Submission Date',
                value: project.createdAt,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        project.paymentReceiptUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.receipt_long_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Click to Inspect Receipt Screenshot',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Tap for full-size interactive zoom',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.fullscreen_rounded,
                        size: 20, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  'Mark as Paid & Publish',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _confirmApprove(project),
              ),
            ],
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

