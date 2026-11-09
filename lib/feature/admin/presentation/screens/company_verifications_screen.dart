import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_company_verification_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';

/// Enterprise Company Verification Management & Review Desk (Screen 34)
/// Provides a comprehensive audit data grid, evidence inspection drawer,
/// and live cross-panel synchronization with company accounts.
class CompanyVerificationsScreen extends StatefulWidget {
  const CompanyVerificationsScreen({super.key});

  @override
  State<CompanyVerificationsScreen> createState() =>
      _CompanyVerificationsScreenState();
}

class _CompanyVerificationsScreenState
    extends State<CompanyVerificationsScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminVerificationService _verificationService =
      AdminVerificationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Verified', 'Rejected'
  bool _isSidebarCollapsed = false;

  final List<String> _filters = ['All', 'Pending', 'Verified', 'Rejected'];

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out Console'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your active administrative session? Session credentials will be invalidated securely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
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
    if (routeId == 'dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (routeId == 'student_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
      );
    }
  }

  void _openDossierModal(AdminCompanyVerificationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.darkNavy,
                        child: Text(
                          item.logoInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.companyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          Text(
                            '${item.industry} • ${item.city}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Status Card
              _buildDossierStatusBanner(item),
              const SizedBox(height: 16),

              // SECP & Corporate Identity Details
              _buildSectionTitle('1. Corporate Identity & Registration'),
              const SizedBox(height: 8),
              _buildDetailInfoTile(
                icon: Icons.badge_outlined,
                title: 'SECP / NTN Registration Number',
                value: item.registrationNumber,
              ),
              _buildDetailInfoTile(
                icon: Icons.verified_outlined,
                title: 'Official Corporate Email',
                value: item.officialEmail,
                badge: item.isEmailVerified ? 'Email Verified' : 'Unverified Email',
                badgeColor: item.isEmailVerified ? AppColors.success : AppColors.error,
              ),
              _buildDetailInfoTile(
                icon: Icons.language_rounded,
                title: 'Corporate Website',
                value: item.websiteUrl,
              ),
              const SizedBox(height: 20),

              // Submitted Evidence Document
              _buildSectionTitle('2. Submitted Business Evidence Document'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.documentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.documentType} • ${item.documentSize}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Inspect Document', style: TextStyle(fontSize: 11.5)),
                          onPressed: () => _openDocumentPreviewModal(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Admin Feedback or Rejection Reason if any
              if (item.adminFeedback != null) ...[
                _buildSectionTitle('3. Previous Review Comments'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '"${item.adminFeedback}"',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Decision Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Reject Verification'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptRejectReason(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Grant Verified Status'),
                      onPressed: () async {
                        final admin = _authService.currentAdmin?.fullName ??
                            'Executive SuperAdmin';
                        await _verificationService.approveCompany(
                          verificationId: item.id,
                          reviewerName: admin,
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.companyName} has been verified and authorized across CampusConnect.',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openDocumentPreviewModal(AdminCompanyVerificationItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(item.documentName, style: const TextStyle(fontSize: 15)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
        content: Container(
          width: 500,
          height: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                item.documentType,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Registration Authority: SECP Pakistan\nEntity: ${item.companyName}\nCertificate ID: ${item.registrationNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'SECP Digital Seal Verified (TLS Checksum OK)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Done Inspection'),
          ),
        ],
      ),
    );
  }

  void _promptRejectReason(AdminCompanyVerificationItem item) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.feedback_outlined, color: AppColors.error),
            const SizedBox(width: 10),
            Text('Reject Verification: ${item.companyName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify mandatory audit feedback so the corporate sponsor can correct discrepancies and resubmit credentials.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason / Feedback *',
                hintText: 'e.g. Uploaded SECP certificate is expired or illegible...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = feedbackController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback is strictly mandatory.')),
                );
                return;
              }

              final admin = _authService.currentAdmin?.fullName ??
                  'Executive SuperAdmin';
              await _verificationService.rejectCompany(
                verificationId: item.id,
                feedback: text,
                reviewerName: admin,
              );

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification rejected for ${item.companyName}. Feedback logged.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Submit Rejection'),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierStatusBanner(AdminCompanyVerificationItem item) {
    Color cardBg;
    Color borderColor;
    Color textColor;
    String title;
    IconData icon;

    switch (item.status) {
      case VerificationStatus.pending:
        cardBg = AppColors.warningBg;
        borderColor = AppColors.warning.withValues(alpha: 0.4);
        textColor = const Color(0xFF92400E);
        title = 'Pending Administrative Review';
        icon = Icons.hourglass_top_rounded;
        break;
      case VerificationStatus.verified:
        cardBg = AppColors.successBg;
        borderColor = AppColors.success.withValues(alpha: 0.4);
        textColor = const Color(0xFF166534);
        title = 'Verified Partner Organization';
        icon = Icons.verified_rounded;
        break;
      case VerificationStatus.rejected:
        cardBg = AppColors.errorBg;
        borderColor = AppColors.error.withValues(alpha: 0.4);
        textColor = const Color(0xFF991B1B);
        title = 'Verification Rejected';
        icon = Icons.cancel_outlined;
        break;
      case VerificationStatus.notSubmitted:
        cardBg = AppColors.lightIceBlue;
        borderColor = AppColors.primary.withValues(alpha: 0.3);
        textColor = AppColors.darkNavy;
        title = 'Not Yet Submitted';
        icon = Icons.shield_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title • Submitted: ${item.submittedAt}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.darkNavy,
      ),
    );
  }

  Widget _buildDetailInfoTile({
    required IconData icon,
    required String title,
    required String value,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: badgeColor ?? AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: isDesktop
              ? null
              : Drawer(
                  child: AdminSidebar(
                    activeRouteId: 'company_verifications',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'company_verifications',
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
                      pageTitle: 'Company Verifications',
                      breadcrumb: 'Governance',
                      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (q) => setState(() => _searchQuery = q),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<
                          List<AdminCompanyVerificationItem>>(
                        valueListenable: _verificationService.verificationsNotifier,
                        builder: (context, verifications, _) {
                          // Filter by status & search
                          final filtered = verifications.where((item) {
                            if (_selectedStatusFilter == 'Pending' &&
                                item.status != VerificationStatus.pending) {
                              return false;
                            }
                            if (_selectedStatusFilter == 'Verified' &&
                                item.status != VerificationStatus.verified) {
                              return false;
                            }
                            if (_selectedStatusFilter == 'Rejected' &&
                                item.status != VerificationStatus.rejected) {
                              return false;
                            }

                            if (_searchQuery.isNotEmpty) {
                              final query = _searchQuery.toLowerCase();
                              return item.companyName.toLowerCase().contains(query) ||
                                  item.registrationNumber.toLowerCase().contains(query) ||
                                  item.officialEmail.toLowerCase().contains(query) ||
                                  item.industry.toLowerCase().contains(query);
                            }
                            return true;
                          }).toList();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderActionsBar(verifications),
                                const SizedBox(height: 20),
                                _buildVerificationsTableCard(filtered),
                              ],
                            ),
                          );
                        },
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

  Widget _buildHeaderActionsBar(List<AdminCompanyVerificationItem> allItems) {
    final pendingCount = allItems
        .where((i) => i.status == VerificationStatus.pending)
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Corporate Verification Review Desk',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pendingCount pending verification${pendingCount == 1 ? '' : 's'} awaiting administrative sign-off',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingCount > 0 ? AppColors.warningBg : AppColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: pendingCount > 0
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  pendingCount > 0 ? '$pendingCount Action Required' : 'All Clear',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: pendingCount > 0 ? const Color(0xFF92400E) : const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          // Filter Chips
          Wrap(
            spacing: 8,
            children: _filters.map((filter) {
              final isSelected = _selectedStatusFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                selectedColor: AppColors.darkNavy,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (val) {
                  if (val) setState(() => _selectedStatusFilter = filter);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsTableCard(List<AdminCompanyVerificationItem> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No verification records match your filter criteria',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
              ),
              SizedBox(height: 4),
              Text(
                'Try selecting "All" or clearing the search query to see full list.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final isPending = item.status == VerificationStatus.pending;
          final isVerified = item.status == VerificationStatus.verified;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.darkNavy,
                  child: Text(
                    item.logoInitial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.companyName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.industry} • Reg: ${item.registrationNumber}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.isEmailVerified ? Icons.check_circle : Icons.warning_amber_rounded,
                            size: 14,
                            color: item.isEmailVerified ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.officialEmail,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        'Doc: ${item.documentName}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.warningBg
                        : isVerified
                            ? AppColors.successBg
                            : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending
                        ? 'Pending Review'
                        : isVerified
                            ? 'Verified'
                            : 'Rejected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? const Color(0xFF92400E)
                          : isVerified
                              ? const Color(0xFF166534)
                              : const Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _openDossierModal(item),
                  child: const Text('Review Dossier', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
