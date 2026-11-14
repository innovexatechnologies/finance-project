import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_payment_methods_screen.dart';
import 'package:link_vibe/screens/admin/admin_project_approvals_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_verification_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';

/// Interactive Enterprise Quick Actions Bar
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  void _openManageStudents(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
    );
  }

  void _openManageCompanies(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
    );
  }

  void _openEscrowAccounts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPaymentMethodsScreen()),
    );
  }

  void _openPaymentApprovals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminProjectApprovalsScreen(),
      ),
    );
  }

  void _openReviewVerificationsModal(BuildContext context) {
    final pendingList = AdminVerificationService()
        .allVerifications
        .where((v) => v.status == VerificationStatus.pending)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.domain_verification_rounded,
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
                              'Corporate Verification Review Desk',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Authenticate submitted business & SECP documents',
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

            if (pendingList.isEmpty) ...[
              const AppEmptyState(
                compact: true,
                icon: Icons.verified_outlined,
                iconColor: AppColors.success,
                title: 'All Company Verifications Reviewed',
                subtitle:
                    'There are currently no pending corporate verification submissions awaiting sign-off.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompanyVerificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('Open Full Verification Desk'),
                ),
              ),
            ] else ...[
              Builder(
                builder: (_) {
                  final item = pendingList.first;
                  final reviewer = AdminAuthService().currentAdmin?.fullName ??
                      'Executive Administrator';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.companyName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PENDING REVIEW',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Official Email: ${item.officialEmail.isNotEmpty ? item.officialEmail : "Not provided"}',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                            Text(
                              'Website: ${item.websiteUrl.isNotEmpty ? item.websiteUrl : "Not provided"}',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                            Text(
                              'Attached Evidence: ${item.documentName.isNotEmpty ? item.documentName : "No evidence file attached"}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Reject with Comments'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _promptRejectFeedback(
                                  context,
                                  verificationId: item.id,
                                  companyName: item.companyName,
                                  reviewerName: reviewer,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Approve Partner'),
                              onPressed: () async {
                                final ok = await AdminVerificationService()
                                    .approveCompany(
                                  verificationId: item.id,
                                  reviewerName: reviewer,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? '${item.companyName} successfully verified!'
                                          : 'Unable to approve verification.',
                                    ),
                                    backgroundColor: ok
                                        ? AppColors.success
                                        : AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (pendingList.length > 1) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CompanyVerificationsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View all ${pendingList.length} pending verifications →',
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _promptRejectFeedback(
    BuildContext context, {
    required String verificationId,
    required String companyName,
    required String reviewerName,
  }) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Reject Verification: $companyName'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(
            hintText: 'Enter feedback for company to correct...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final feedback = feedbackController.text.trim();
              if (feedback.isEmpty) return;

              final ok = await AdminVerificationService().rejectCompany(
                verificationId: verificationId,
                feedback: feedback,
                reviewerName: reviewerName,
              );
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Verification rejected with feedback.'
                        : 'Unable to submit rejection.',
                  ),
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

  void _openManageProjects(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
    );
  }

  void _openViewReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administrative Governance Actions',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Direct access to platform registries, verification desks, and compliance logs',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                label: 'Manage Students',
                icon: Icons.school_outlined,
                color: AppColors.primary,
                bgColor: AppColors.lightIceBlue,
                onTap: () => _openManageStudents(context),
              ),
              _buildActionButton(
                label: 'Manage Companies',
                icon: Icons.domain_outlined,
                color: AppColors.accentTeal,
                bgColor: AppColors.accentTeal.withValues(alpha: 0.12),
                onTap: () => _openManageCompanies(context),
              ),
              _buildActionButton(
                label: 'Review Verifications',
                icon: Icons.domain_verification_outlined,
                color: AppColors.warning,
                bgColor: AppColors.warningBg,
                onTap: () => _openReviewVerificationsModal(context),
              ),
              _buildActionButton(
                label: 'Manage Projects',
                icon: Icons.assignment_outlined,
                color: AppColors.indigoAccent,
                bgColor: AppColors.indigoAccent.withValues(alpha: 0.12),
                onTap: () => _openManageProjects(context),
              ),
              _buildActionButton(
                label: 'View Reports',
                icon: Icons.analytics_outlined,
                color: AppColors.success,
                bgColor: AppColors.successBg,
                onTap: () => _openViewReports(context),
              ),
              _buildActionButton(
                label: 'Escrow Accounts',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                bgColor: AppColors.lightIceBlue,
                onTap: () => _openEscrowAccounts(context),
              ),
              _buildActionButton(
                label: 'Payment Approvals',
                icon: Icons.fact_check_outlined,
                color: AppColors.warning,
                bgColor: AppColors.warningBg,
                onTap: () => _openPaymentApprovals(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      icon: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.darkNavy,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
    );
  }
}
