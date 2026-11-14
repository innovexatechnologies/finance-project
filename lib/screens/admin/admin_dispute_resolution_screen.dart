import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_notification_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/services/admin_dispute_payout_service.dart';

/// Enterprise Admin Console for Dispute Resolution, Payout Execution, and Escrow Alerts.
/// Strictly uses [AdminDisputePayoutService] — NO direct Supabase calls.
class AdminDisputeResolutionScreen extends StatefulWidget {
  const AdminDisputeResolutionScreen({super.key});

  @override
  State<AdminDisputeResolutionScreen> createState() =>
      _AdminDisputeResolutionScreenState();
}

class _AdminDisputeResolutionScreenState
    extends State<AdminDisputeResolutionScreen>
    with SingleTickerProviderStateMixin {
  final AdminDisputePayoutService _payoutService = AdminDisputePayoutService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  String _searchQuery = '';
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _payoutService.loadNotifications(forceRefresh: true),
      _payoutService.loadDisputedProjects(forceRefresh: true),
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

  // ===========================================================================
  // 3-WAY DISPUTE DECISION MODAL
  // ===========================================================================
  Future<void> _openDisputeDecisionDialog(ProjectModel project) async {
    final escrow = project.escrowAmount > 0 ? project.escrowAmount : 10000.0;
    final commission10 = double.parse((escrow * 0.10).toStringAsFixed(2));
    final studentFull = double.parse((escrow - commission10).toStringAsFixed(2));
    final splitNet = double.parse(((escrow - commission10) / 2).toStringAsFixed(2));

    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin 3-Way Dispute Decision',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      'Case ID: ${project.disputeCaseId ?? "#SB-CASE"}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
                  'Project: ${project.title}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'Total Escrow Locked: PKR ${escrow.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (project.disputeReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Dispute Reason: "${project.disputeReason}"',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Select Binding Resolution Decision:',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 10),

                // Option 1: 100% Student
                _buildDecisionOptionCard(
                  title: '1. 100% Release to Student',
                  subtitle:
                      'Student: PKR $studentFull (10% platform fee: PKR $commission10). Company: PKR 0',
                  color: AppColors.success,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _executeDisputeDecision(
                      project.id,
                      'full_student',
                      notesCtrl.text,
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Option 2: 100% Refund to Company
                _buildDecisionOptionCard(
                  title: '2. 100% Refund to Company',
                  subtitle:
                      'Company refund: PKR ${escrow.toStringAsFixed(0)}. Student payout: PKR 0',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _executeDisputeDecision(
                      project.id,
                      'full_company_refund',
                      notesCtrl.text,
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Option 3: 50% Student / 50% Company Split
                _buildDecisionOptionCard(
                  title: '3. 50-50 Split (Student & Company)',
                  subtitle:
                      'Student: PKR $splitNet, Company Refund: PKR $splitNet (10% fee: PKR $commission10)',
                  color: AppColors.warning,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _executeDisputeDecision(
                      project.id,
                      'split_50_50',
                      notesCtrl.text,
                    );
                  },
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Optional Admin Notes / Decision Rationale',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionOptionCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.radio_button_checked_rounded, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _executeDisputeDecision(
    String projectId,
    String decisionType,
    String notes,
  ) async {
    final ok = await _payoutService.resolveDisputeDecision(
      projectId: projectId,
      decisionType: decisionType,
      adminNotes: notes,
    );

    if (ok) {
      _showFeedback(
        'Dispute decision applied successfully. Project moved to Payout Ready Queue.',
      );
      _tabController.animateTo(1); // Switch to Payout queue
    } else {
      _showFeedback(
        _payoutService.lastError ?? 'Failed to apply dispute decision.',
        isError: true,
      );
    }
  }

  // ===========================================================================
  // EXECUTE PAYOUT TRANSFER MODAL
  // ===========================================================================
  Future<void> _openCompletePayoutModal(ProjectModel project) async {
    final tidCtrl = TextEditingController();
    XFile? receiptFile;
    Uint8List? receiptBytes;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final viewInsets = MediaQuery.of(context).viewInsets;

          return Container(
            margin: EdgeInsets.only(top: 60, bottom: viewInsets.bottom),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: AppColors.success, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Execute Escrow Payout',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Project: ${project.title}',
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
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 14),

                  // Financial Breakdown Card
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
                          'Total Escrow Deposit',
                          'PKR ${project.escrowAmount.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownRow(
                          'Platform Commission (10%)',
                          'PKR ${(project.platformCommissionAmount ?? 0).toStringAsFixed(0)}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownRow(
                          'Net Student Payout',
                          'PKR ${(project.studentPayoutAmount ?? 0).toStringAsFixed(0)}',
                          color: AppColors.success,
                          isBold: true,
                        ),
                        if ((project.companyRefundAmount ?? 0) > 0) ...[
                          const SizedBox(height: 6),
                          _buildBreakdownRow(
                            'Company Refund Amount',
                            'PKR ${project.companyRefundAmount!.toStringAsFixed(0)}',
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

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

                  // Receipt Upload
                  Text(
                    'Transfer Receipt Screenshot (Optional)',
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
                            child: Image.memory(receiptBytes!,
                                width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              receiptFile?.name ?? 'receipt.jpg',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              setSheetState(() {
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
                          setSheetState(() {
                            receiptFile = img;
                            receiptBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Attach Transfer Slip / Receipt'),
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isSaving
                            ? 'Processing Payout...'
                            : 'Mark Payout Completed & Finalize Project',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final tid = tidCtrl.text.trim();
                              if (tid.isEmpty) {
                                _showFeedback('Please enter the payout TID',
                                    isError: true);
                                return;
                              }
                              setSheetState(() => isSaving = true);
                              final ok = await _payoutService.completePayout(
                                projectId: project.id,
                                transactionId: tid,
                                receiptUrl: receiptFile != null
                                    ? 'https://mock.storage/payouts/${project.id}/${receiptFile!.name}'
                                    : null,
                              );
                              if (ok && ctx.mounted) {
                                Navigator.pop(ctx);
                                _showFeedback(
                                    'Payout finalized! Project marked completed.');
                              } else {
                                setSheetState(() => isSaving = false);
                                _showFeedback(
                                  _payoutService.lastError ??
                                      'Failed to finalize payout.',
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

  // ===========================================================================
  // MAIN BUILD METHOD
  // ===========================================================================
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
                      pageTitle: 'Disputes & Escrow Payouts',
                      breadcrumb: 'Financial Governance',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (q) => setState(() => _searchQuery = q),
                    ),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        tabs: [
                          ValueListenableBuilder<List<ProjectModel>>(
                            valueListenable:
                                _payoutService.disputedProjectsNotifier,
                            builder: (context, list, child) => Tab(
                              icon: const Icon(Icons.gavel_rounded, size: 18),
                              text: 'Dispute Cases (${list.length})',
                            ),
                          ),
                          ValueListenableBuilder<List<ProjectModel>>(
                            valueListenable:
                                _payoutService.payoutReadyProjectsNotifier,
                            builder: (context, list, child) => Tab(
                              icon: const Icon(Icons.payment_rounded, size: 18),
                              text: 'Ready for Payout (${list.length})',
                            ),
                          ),
                          ValueListenableBuilder<List<AdminNotificationModel>>(
                            valueListenable:
                                _payoutService.notificationsNotifier,
                            builder: (context, list, child) {
                              final unread = list.where((n) => !n.isRead).length;
                              return Tab(
                                icon: const Icon(Icons.notifications_active_rounded,
                                    size: 18),
                                text: unread > 0
                                    ? 'Escrow Alerts ($unread New)'
                                    : 'Escrow Alerts',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshAllData,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDisputesTab(),
                            _buildPayoutQueueTab(),
                            _buildNotificationsTab(),
                          ],
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

  // TAB 1: DISPUTES
  Widget _buildDisputesTab() {
    return ValueListenableBuilder<List<ProjectModel>>(
      valueListenable: _payoutService.disputedProjectsNotifier,
      builder: (context, projects, _) {
        final filteredList = _searchQuery.trim().isEmpty
            ? projects
            : projects.where((p) {
                final q = _searchQuery.toLowerCase();
                return p.title.toLowerCase().contains(q) ||
                    (p.disputeCaseId ?? '').toLowerCase().contains(q) ||
                    p.companyName.toLowerCase().contains(q);
              }).toList();

        if (filteredList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: AppEmptyState(
              title: 'No Active Disputes',
              subtitle:
                  'All project deliverables are progressing peacefully without any active dispute cases.',
              icon: Icons.verified_rounded,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filteredList.length,
          itemBuilder: (context, idx) {
            final p = filteredList[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _copyToClipboard(
                            p.disputeCaseId ?? '#SB-DISPUTE', 'Dispute Case ID'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.disputeCaseId ?? '#SB-DISPUTE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'PKR ${p.escrowAmount.toStringAsFixed(0)} Locked',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Text(
                    'Company: ${p.companyName} • Assigned: ${p.assignedStudent ?? "Awarded Student"}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Dispute Claim: "${p.disputeReason ?? "Deliverable specifications mismatch"}"',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.gavel_rounded, size: 17),
                        label: const Text('Resolve Dispute (3-Way Decision)'),
                        onPressed: () => _openDisputeDecisionDialog(p),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: PAYOUT READY QUEUE
  Widget _buildPayoutQueueTab() {
    return ValueListenableBuilder<List<ProjectModel>>(
      valueListenable: _payoutService.payoutReadyProjectsNotifier,
      builder: (context, projects, _) {
        if (projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: AppEmptyState(
              title: 'Payout Queue Empty',
              subtitle:
                  'There are no approved or dispute-resolved projects awaiting payout transfer.',
              icon: Icons.done_all_rounded,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: projects.length,
          itemBuilder: (context, idx) {
            final p = projects[idx];
            final netStudent = p.studentPayoutAmount ?? (p.escrowAmount * 0.90);
            final fee = p.platformCommissionAmount ?? (p.escrowAmount * 0.10);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (p.payoutType ?? 'ready_for_payout')
                              .toUpperCase()
                              .replaceAll('_', ' '),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      Text(
                        'Payable: PKR ${netStudent.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Text(
                    'Recipient Student: ${p.assignedStudent ?? "Awarded Candidate"} • Platform Fee: PKR ${fee.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if ((p.companyRefundAmount ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Company Refund: PKR ${p.companyRefundAmount!.toStringAsFixed(0)} to ${p.companyName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Execute Transfer & Finalize'),
                        onPressed: () => _openCompletePayoutModal(p),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // TAB 3: NOTIFICATIONS / ALERTS
  Widget _buildNotificationsTab() {
    return ValueListenableBuilder<List<AdminNotificationModel>>(
      valueListenable: _payoutService.notificationsNotifier,
      builder: (context, notifs, _) {
        if (notifs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: AppEmptyState(
              title: 'No Escrow Alerts',
              subtitle: 'No pending alerts or notifications at this time.',
              icon: Icons.notifications_none_rounded,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: notifs.length,
          itemBuilder: (context, idx) {
            final n = notifs[idx];
            Color iconColor = AppColors.primary;
            IconData icon = Icons.info_outline_rounded;

            if (n.notificationType == 'dispute_raised') {
              iconColor = AppColors.error;
              icon = Icons.gavel_rounded;
            } else if (n.notificationType == 'auto_release_5_days') {
              iconColor = AppColors.warning;
              icon = Icons.hourglass_top_rounded;
            } else if (n.notificationType == 'company_approval') {
              iconColor = AppColors.success;
              icon = Icons.check_circle_outline_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: n.isRead ? Colors.white : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: n.isRead
                      ? AppColors.border
                      : iconColor.withValues(alpha: 0.4),
                  width: n.isRead ? 1 : 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.message,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.createdAt,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!n.isRead)
                    TextButton(
                      onPressed: () =>
                          _payoutService.markNotificationAsRead(n.id),
                      child: const Text('Mark Read'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

