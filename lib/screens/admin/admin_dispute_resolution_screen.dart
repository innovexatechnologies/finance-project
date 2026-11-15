import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
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
                    _buildExecutiveBanner(!isDesktop),
                    _buildUniqueTabBar(!isDesktop),
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
          return _buildUniqueDisputesEmptyState();
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
                  LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isMobileCard = cardConstraints.maxWidth < 460;
                      return SizedBox(
                        width: isMobileCard ? double.infinity : null,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.gavel_rounded, size: 17),
                          label: const Text(
                            'Resolve Dispute (3-Way Decision)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _openDisputeDecisionDialog(p),
                        ),
                      );
                    },
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
          return _buildUniquePayoutsEmptyState();
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
                  LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isMobileCard = cardConstraints.maxWidth < 460;
                      return SizedBox(
                        width: isMobileCard ? double.infinity : null,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text(
                            'Execute Transfer & Finalize',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _openCompletePayoutModal(p),
                        ),
                      );
                    },
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
          return _buildUniqueNotificationsEmptyState();
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

  // ===========================================================================
  // EXECUTIVE HEADER & SEGMENTED PILL TAB BAR (ZERO TRUNCATION)
  // ===========================================================================
  Widget _buildExecutiveBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 10 : 16,
        isMobile ? 12 : 24,
        0,
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custodial Escrow & Resolution Chamber',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Arbitrated 3-Way Decisions • 5-Day Auto-Release • 10% Platform Fee',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color: const Color(0xFF94A3B8), // Slate 400
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBannerStatPill(
                icon: Icons.gavel_rounded,
                label: 'Arbitration Chamber',
                color: const Color(0xFFEF4444),
              ),
              _buildBannerStatPill(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Guaranteed Payouts',
                color: const Color(0xFF10B981),
              ),
              _buildBannerStatPill(
                icon: Icons.timer_rounded,
                label: '5-Day Release Protocol',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueTabBar(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 10,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final activeIndex = _tabController.index;
            return Row(
              children: [
                Expanded(
                  child: _buildSegmentTab(
                    index: 0,
                    isActive: activeIndex == 0,
                    icon: Icons.gavel_rounded,
                    title: 'Disputes',
                    isMobile: isMobile,
                    countNotifier: _payoutService.disputedProjectsNotifier,
                    badgeColor: AppColors.error,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentTab(
                    index: 1,
                    isActive: activeIndex == 1,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Payouts',
                    isMobile: isMobile,
                    countNotifier: _payoutService.payoutReadyProjectsNotifier,
                    badgeColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildNotificationSegmentTab(
                    index: 2,
                    isActive: activeIndex == 2,
                    icon: Icons.notifications_active_rounded,
                    title: 'Alerts',
                    isMobile: isMobile,
                    badgeColor: AppColors.warning,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required bool isActive,
    required IconData icon,
    required String title,
    required bool isMobile,
    required ValueNotifier<List<ProjectModel>> countNotifier,
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 8 : 10,
          horizontal: isMobile ? 4 : 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 15 : 18,
                color: isActive ? AppColors.darkNavy : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 13.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.darkNavy : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<List<ProjectModel>>(
                valueListenable: countNotifier,
                builder: (context, list, _) {
                  final count = list.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? badgeColor.withValues(alpha: 0.14)
                          : (isActive ? Colors.grey.shade200 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? badgeColor : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSegmentTab({
    required int index,
    required bool isActive,
    required IconData icon,
    required String title,
    required bool isMobile,
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 8 : 10,
          horizontal: isMobile ? 4 : 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 15 : 18,
                color: isActive ? AppColors.darkNavy : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 13.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.darkNavy : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<List<AdminNotificationModel>>(
                valueListenable: _payoutService.notificationsNotifier,
                builder: (context, notifs, _) {
                  final unread = notifs.where((n) => !n.isRead).length;
                  final count = unread > 0 ? unread : notifs.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: unread > 0
                          ? badgeColor.withValues(alpha: 0.16)
                          : (isActive ? Colors.grey.shade200 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 0 ? '$unread' : '$count',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.bold,
                        color: unread > 0 ? badgeColor : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UNIQUE ILLUSTRATED EMPTY STATES
  // ===========================================================================
  Widget _buildUniqueDisputesEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Arbitration Chamber In Equilibrium',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Zero unresolved arbitration disputes. All student project deliverables and corporate specifications are progressing peacefully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              _buildTrustFeatureRow(
                Icons.check_circle_rounded,
                '100% Student Release upon approved deliverables',
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _buildTrustFeatureRow(
                Icons.check_circle_rounded,
                '100% Company Refund for unfulfilled milestone contracts',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _buildTrustFeatureRow(
                Icons.check_circle_rounded,
                '50/50 Fair Split with 10% platform commission retained',
                color: AppColors.warning,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Sync Dispute Ledger',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onPressed: _refreshAllData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniquePayoutsEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 38,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Escrow Disbursement Queue Settled',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All approved milestones and arbitrated funds have been successfully settled and transferred to student talent accounts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              _buildTrustFeatureRow(
                Icons.check_circle_rounded,
                'Automated 5-Day Auto-Release for uncontested deliveries',
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _buildTrustFeatureRow(
                Icons.check_circle_rounded,
                'Direct Bank Transfer & Mobile Wallet (JazzCash / EasyPaisa)',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _buildTrustFeatureRow(
                Icons.check_circle_rounded,
                'TID recording & verifiable payment receipt screenshot vault',
                color: AppColors.success,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Check Payout Queue',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onPressed: _refreshAllData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniqueNotificationsEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 38,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'All Escrow Feeds Quiet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No new dispute filings, auto-release timers running out, or escrow security alerts recorded.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Poll Escrow Alerts',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onPressed: _refreshAllData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustFeatureRow(IconData icon, String text, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

