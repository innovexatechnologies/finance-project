import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/models/company_settings_model.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_profile_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_verification_screen.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_settings_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _profileService = CompanyProfileService();
  final _verificationService = CompanyVerificationService();
  final _settingsService = CompanySettingsService();

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
    );
  }

  void _openChangePasswordModal() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Change Password',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure your corporate account uses a strong password with at least 6 characters.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.grayText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.statusClosed.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.statusClosed,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.inter(
                                  color: AppColors.statusClosed,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: currentPassCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final current = currentPassCtrl.text.trim();
                                final newP = newPassCtrl.text.trim();
                                final confirmP = confirmPassCtrl.text.trim();

                                if (current.isEmpty) {
                                  setModalState(
                                    () => errorMessage =
                                        'Please enter your current password.',
                                  );
                                  return;
                                }
                                if (newP.length < 6) {
                                  setModalState(
                                    () => errorMessage = 'New password must be at least 6 characters.',
                                  );
                                  return;
                                }
                                if (newP != confirmP) {
                                  setModalState(
                                    () => errorMessage = 'New password and confirmation do not match.',
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                  errorMessage = null;
                                });

                                final success = await _settingsService
                                    .changePassword(
                                      currentPassword: current,
                                      newPassword: newP,
                                    );

                                if (!ctx.mounted) return;

                                if (success) {
                                  Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Corporate password updated successfully.',
                                        ),
                                        backgroundColor: AppColors.statusOpen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  setModalState(() {
                                    isSaving = false;
                                    errorMessage = _settingsService.lastError ?? 'Unable to update password. Verify your current password.';
                                  });
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openHelpAndSupportModal() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedCategory = 'Verification & Compliance';
    bool isSubmitting = false;

    const categories = [
      'Verification & Compliance',
      'Project Recruitment',
      'Student Deliverables & Certificates',
      'Account & Billing',
      'Technical Issue',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final tickets = AppDataService.instance.getSupportTickets();
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Partner Support Desk',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submit a support ticket directly to the CampusConnect Governance team.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.grayText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => selectedCategory = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        hintText: 'Brief summary of your inquiry',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Details *',
                        hintText: 'Provide relevant project or verification details...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (subjectCtrl.text.trim().isEmpty ||
                                    messageCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Subject and details are both required.',
                                      ),
                                      backgroundColor: AppColors.statusClosed,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                await AppDataService.instance
                                    .submitSupportTicket(
                                      category: selectedCategory,
                                      subject: subjectCtrl.text.trim(),
                                      message: messageCtrl.text.trim(),
                                    );
                                if (!ctx.mounted || !mounted) return;
                                subjectCtrl.clear();
                                messageCtrl.clear();
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Support ticket submitted to Governance Admin.',
                                    ),
                                    backgroundColor: AppColors.statusOpen,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Submit Support Ticket'),
                      ),
                    ),
                    if (tickets.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Your Recent Tickets',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tickets.take(3).map((t) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGray),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['subject']?.toString() ?? 'Ticket',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                    Text(
                                      '${t['id'] ?? ''} • ${t['category'] ?? ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: AppColors.grayText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: t['status']?.toString() ?? 'Open',
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.deepNavy,
          ),
        ),
        content: Text(
          'You will be signed out of your corporate session on this device.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusClosed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(initialRole: 'Company'),
        ),
        (route) => false,
      );
    }
  }

  String _verificationBadgeText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.notSubmitted:
        return 'Not Submitted';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Organization Settings',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ValueListenableBuilder<CompanyProfileModel>(
        valueListenable: _profileService.currentProfileNotifier,
        builder: (context, profile, _) {
          return ValueListenableBuilder<CompanyVerificationModel>(
            valueListenable: _verificationService.verificationNotifier,
            builder: (context, verification, _) {
              return ValueListenableBuilder<CompanySettingsModel>(
                valueListenable: _settingsService.settingsNotifier,
                builder: (context, settings, _) {
                  final orgName = profile.companyName.trim().isNotEmpty
                      ? profile.companyName.trim()
                      : 'Corporate Partner';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                child: Text(
                                  profile.logoInitial,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orgName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (profile.officialEmail.isNotEmpty)
                                      Text(
                                        profile.officialEmail,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.lightAqua,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: _verificationBadgeText(
                                  verification.status,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildSectionCard(
                          title: 'Account & Verification',
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.business_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              title: Text(
                                'Edit Organization Profile',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Update company info, domain website, and primary contact',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grayText,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: _navigateToEditProfile,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              title: Text(
                                'Company Verification Status',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: StatusBadge(
                                    label: _verificationBadgeText(
                                      verification.status,
                                    ),
                                  ),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CompanyVerificationScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.primaryBlue,
                              ),
                              title: Text(
                                'Change Password',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Update your Supabase authentication credentials',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grayText,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: _openChangePasswordModal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Privacy & Directory Visibility',
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: AppColors.primaryBlue,
                              title: const Text('Visible in Student Explore'),
                              subtitle: const Text(
                                'Allow verified students to discover your organization',
                              ),
                              value: settings.privacyDirectoryVisible,
                              onChanged: (v) => _settingsService.updateSettings(
                                settings.copyWith(privacyDirectoryVisible: v),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: AppColors.primaryBlue,
                              title: const Text('Display Primary Mentor Name'),
                              value: settings.privacyShowContactPerson,
                              onChanged: (v) => _settingsService.updateSettings(
                                settings.copyWith(privacyShowContactPerson: v),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: AppColors.primaryBlue,
                              title: const Text(
                                'Share Anonymous Impact Metrics',
                              ),
                              value: settings.privacyShareAnalytics,
                              onChanged: (v) => _settingsService.updateSettings(
                                settings.copyWith(privacyShareAnalytics: v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Support & Session',
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.support_agent_rounded,
                                color: AppColors.primaryBlue,
                              ),
                              title: Text(
                                'Partner Support & Tickets',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Contact Governance Admin or track submitted inquiries',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grayText,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: _openHelpAndSupportModal,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.statusClosed,
                              ),
                              title: Text(
                                'Sign Out',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.statusClosed,
                                ),
                              ),
                              onTap: _confirmLogout,
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
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
