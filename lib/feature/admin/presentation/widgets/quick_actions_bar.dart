import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/services/admin_dashboard_service.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Interactive Enterprise Quick Actions Bar
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  void _openManageStudentsModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
    );
  }

  void _openManageCompaniesModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
    );
  }

  void _openReviewVerificationsModal(BuildContext context) {
    final verif = CompanyVerificationService().currentVerification;
    final company = CompanyProfileService().currentProfile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.domain_verification_rounded, color: AppColors.warning, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Corporate Verification Review Desk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Authenticate submitted SECP & NTN documents',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

                // Company Card
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
                          Text(
                            company.companyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: verif.status == VerificationStatus.verified
                                  ? AppColors.successBg
                                  : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              verif.status == VerificationStatus.verified ? 'VERIFIED' : 'PENDING REVIEW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: verif.status == VerificationStatus.verified
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Official Email: ${verif.officialEmail}', style: const TextStyle(fontSize: 12)),
                      Text('Website: ${verif.websiteUrl ?? 'https://techvistainnovations.com'}', style: const TextStyle(fontSize: 12)),
                      Text('Attached Evidence: ${verif.businessEvidenceFileName ?? 'SECP_Certificate_2026.pdf'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Direct Action Buttons
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
                        label: const Text('Reject with Comments'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          _promptRejectFeedback(context);
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
                        label: const Text('Approve & Verify Partner'),
                        onPressed: () async {
                          await AdminDashboardService().quickApproveCompanyVerification();
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Company successfully verified! Updated in platform directory.'),
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
          );
        },
      ),
    );
  }

  void _promptRejectFeedback(BuildContext context) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Provide Rejection Reason'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final feedback = feedbackController.text.trim();
              if (feedback.isEmpty) return;

              await AdminDashboardService().quickRejectCompanyVerification(feedback);
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification rejected with feedback.'),
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

  void _openManageProjectsModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
    );
  }

  void _openViewReportsModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApplicationMonitoringScreen()),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administrative Governance Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Direct access to platform registries, verification desks, and compliance logs',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // 5 Quick Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                label: 'Manage Students',
                icon: Icons.school_outlined,
                color: AppColors.primary,
                bgColor: AppColors.lightIceBlue,
                onTap: () => _openManageStudentsModal(context),
              ),
              _buildActionButton(
                label: 'Manage Companies',
                icon: Icons.domain_outlined,
                color: AppColors.accentTeal,
                bgColor: AppColors.accentTeal.withValues(alpha: 0.12),
                onTap: () => _openManageCompaniesModal(context),
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
                color: const Color(0xFF6366F1), // Indigo
                bgColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                onTap: () => _openManageProjectsModal(context),
              ),
              _buildActionButton(
                label: 'View Reports',
                icon: Icons.analytics_outlined,
                color: AppColors.success,
                bgColor: AppColors.successBg,
                onTap: () => _openViewReportsModal(context),
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
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: color),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.darkNavy,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
    );
  }
}
