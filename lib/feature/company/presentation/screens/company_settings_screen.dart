import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/models/company_settings_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_profile_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_verification_screen.dart';
import 'package:link_vibe/feature/company/presentation/widgets/company_executive_app_bar.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_settings_service.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _profileService = CompanyProfileService();
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
    String selectedCategory = 'Project Recruitment';
    bool isSubmitting = false;

    const categories = [
      'Project Recruitment',
      'Student Deliverables & Certificates',
      'Account & Security',
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
                      'Submit a support ticket directly to the SkillBridge Governance team.',
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
                        hintText: 'Provide relevant project or account details...',
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
                                      'Support ticket submitted to SkillBridge Governance Admin.',
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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.statusClosed,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account?',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete your company profile, posted projects, and messages from this workspace. This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.darkText,
          ),
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
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await _settingsService.deleteAccount();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _settingsService.lastError ?? 'Could not delete account right now.',
          ),
          backgroundColor: AppColors.statusClosed,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(initialRole: 'Company'),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CompanyExecutiveAppBar(
        title: 'Organization Settings',
        subtitle: 'Account, verification & privacy',
      ),
      body: ValueListenableBuilder<CompanyProfileModel>(
        valueListenable: _profileService.currentProfileNotifier,
        builder: (context, profile, _) {
          return ValueListenableBuilder<CompanySettingsModel>(
            valueListenable: _settingsService.settingsNotifier,
            builder: (context, settings, _) {
              final orgName = profile.companyName.trim().isNotEmpty
                  ? profile.companyName.trim()
                  : 'Corporate Partner';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompanyHeroBanner(
                          initial: profile.logoInitial,
                          title: orgName,
                          subtitle: profile.industry.isNotEmpty
                              ? profile.industry
                              : 'Corporate Partner',
                          secondaryLine: profile.officialEmail.isNotEmpty
                              ? profile.officialEmail
                              : null,
                          trailingAction: Tooltip(
                            message: 'Edit Company Profile',
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _navigateToEditProfile,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.26),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        CompanySectionCard(
                          title: 'Account & Verification',
                          icon: Icons.manage_accounts_outlined,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          child: Column(
                            children: [
                              _buildActionTile(
                                icon: Icons.business_outlined,
                                title: 'Edit Organization Profile',
                                subtitle:
                                    'Update company info, domain website, and primary contact',
                                onTap: _navigateToEditProfile,
                              ),
                              _buildRowDivider(),
                              _buildActionTile(
                                icon: Icons.verified_user_outlined,
                                title: 'Company Verification Status',
                                subtitle:
                                    'Review institutional verification & SECP documents',
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
                              _buildRowDivider(),
                              _buildActionTile(
                                icon: Icons.lock_outline_rounded,
                                title: 'Change Password',
                                subtitle:
                                    'Update your sign-in password and account security',
                                onTap: _openChangePasswordModal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CompanySectionCard(
                          title: 'Privacy & Directory Visibility',
                          icon: Icons.visibility_outlined,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          child: Column(
                            children: [
                              _buildToggleTile(
                                icon: Icons.public_rounded,
                                title: 'Visible in Student Explore',
                                subtitle:
                                    'Allow university students to discover your organization',
                                value: settings.privacyDirectoryVisible,
                                onChanged: (v) => _settingsService.updateSettings(
                                  settings.copyWith(privacyDirectoryVisible: v),
                                ),
                              ),
                              _buildRowDivider(),
                              _buildToggleTile(
                                icon: Icons.badge_outlined,
                                title: 'Display Primary Mentor Name',
                                subtitle:
                                    'Show lead mentor details on public project listings',
                                value: settings.privacyShowContactPerson,
                                onChanged: (v) => _settingsService.updateSettings(
                                  settings.copyWith(
                                    privacyShowContactPerson: v,
                                  ),
                                ),
                              ),
                              _buildRowDivider(),
                              _buildToggleTile(
                                icon: Icons.analytics_outlined,
                                title: 'Share Anonymous Impact Metrics',
                                subtitle:
                                    'Contribute anonymized metrics to platform insights',
                                value: settings.privacyShareAnalytics,
                                onChanged: (v) => _settingsService.updateSettings(
                                  settings.copyWith(privacyShareAnalytics: v),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CompanySectionCard(
                          title: 'Support & Session',
                          icon: Icons.support_agent_rounded,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          child: Column(
                            children: [
                              _buildActionTile(
                                icon: Icons.support_agent_rounded,
                                title: 'Partner Support & Tickets',
                                subtitle:
                                    'Reach support desk or track submitted inquiries',
                                onTap: _openHelpAndSupportModal,
                              ),
                              _buildRowDivider(),
                              _buildActionTile(
                                icon: Icons.logout_rounded,
                                iconColor: AppColors.deepNavy,
                                titleColor: AppColors.deepNavy,
                                showChevron: false,
                                title: 'Sign Out',
                                subtitle:
                                    'End your current session on this device',
                                onTap: _confirmLogout,
                              ),
                              _buildRowDivider(),
                              _buildActionTile(
                                icon: Icons.delete_forever_rounded,
                                iconColor: AppColors.statusClosed,
                                titleColor: AppColors.statusClosed,
                                showChevron: false,
                                title: 'Delete Account',
                                subtitle:
                                    'Permanently remove your company account and workspace data',
                                onTap: _confirmDeleteAccount,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRowDivider() {
    return const Divider(
      height: 1,
      indent: 50,
      color: AppColors.borderLight,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primaryBlue,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return _buildSettingRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      titleColor: titleColor,
      subtitle: subtitle,
      onTap: onTap,
      trailing: showChevron
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingRow(
      icon: icon,
      iconColor: AppColors.primaryBlue,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: AppColors.primaryBlue,
        activeThumbColor: Colors.white,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}
