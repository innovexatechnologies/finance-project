import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/models/company_settings_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_profile_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_verification_screen.dart';
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

  // 2. Action: Edit Company Profile (Screen 23)
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompanyProfileScreen(),
      ),
    );
  }

  // 3. Action: Change Password Dialog / Modal
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_reset_rounded,
                                color: AppColors.primary, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ensure your corporate account uses a strong password with at least 6 characters.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Current Password
                    TextField(
                      controller: currentPassCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // New Password
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm New Password
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final current = currentPassCtrl.text.trim();
                                final newP = newPassCtrl.text.trim();
                                final confirmP = confirmPassCtrl.text.trim();

                                if (current.isEmpty) {
                                  setModalState(() {
                                    errorMessage =
                                        'Please enter your current password.';
                                  });
                                  return;
                                }
                                if (newP.length < 6) {
                                  setModalState(() {
                                    errorMessage =
                                        'New password must be at least 6 characters.';
                                  });
                                  return;
                                }
                                if (newP != confirmP) {
                                  setModalState(() {
                                    errorMessage =
                                        'New password and confirmation do not match.';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                  errorMessage = null;
                                });

                                final success =
                                    await _settingsService.changePassword(
                                  currentPassword: current,
                                  newPassword: newP,
                                );

                                if (success && mounted && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '✅ Corporate password changed successfully.'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
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
                            : const Text('Update Password',
                                style: TextStyle(fontWeight: FontWeight.bold)),
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

  // 6. Terms & Conditions Modal
  void _openTermsAndConditionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gavel_rounded,
                            color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    Text(
                      'CAMPUSCONNECT Corporate Partner Agreement',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Last updated: November 2026\n\n'
                      '1. Sponsoring Real-World Projects\n'
                      'By registering as a company partner on CAMPUSCONNECT, you agree to sponsor genuine academic-corporate projects that provide verified practical experience for enrolled university students.\n\n'
                      '2. Student Intellectual Property & Deliverables\n'
                      'All source code, design assets, and research deliverables created by assigned students remain subject to institutional academic integrity standards and corporate partnership guidelines agreed upon during project assignment.\n\n'
                      '3. Non-Financial Platform Guarantee\n'
                      'CAMPUSCONNECT operates strictly as a skill-building, student-corporate bridge. Direct financial transactions, stipends, and commission payments are not managed through this software interface.\n\n'
                      '4. Corporate Conduct & Ethical Review\n'
                      'Companies must provide timely, professional feedback for student submissions and uphold university registrar code-of-conduct policies at all times.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('I Acknowledge & Agree'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 7. Privacy Policy Modal
  void _openPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    Text(
                      'Enterprise Data Protection & Student Privacy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Student Information Privacy\n'
                      'Companies are strictly prohibited from harvesting, exporting, or redistributing students’ private contact data, national identifiers, or internal university records outside project evaluation purposes.\n\n'
                      '2. Corporate Credentials & Security\n'
                      'Your organization’s official registration certificates, tax filings, and company passwords are cryptographically salted and securely processed in compliance with data privacy regulations.\n\n'
                      '3. Communication & Deliverable Storage\n'
                      'Uploaded milestone files and evaluation feedback are encrypted in transit and accessible solely to authorized company members and assigned student teams.\n\n'
                      '4. Data Retention & Deletion\n'
                      'Upon account closure, corporate project listings are safely archived or purged in accordance with our institutional compliance schedule.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Understood'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 8. Help & Support Modal
  void _openHelpSupportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.headset_mic_rounded,
                            color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Help & Corporate Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Corporate Partner Assistance Desk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Need help with student applications, verification documents, or milestone reviews? Our university liaison team is here to assist.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Official Helpline
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.lightIceBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Partner Helpline Desk',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                Text('+92 (51) 111-CAMPUS (226787)',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Official Support Email
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.email_outlined,
                                color: AppColors.success, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Direct Email Support',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                Text('partnerships@campusconnect.edu.pk',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildFaqItem(
                      'How long does company verification take?',
                      'Official email verification is instantaneous. SECP / Chamber business evidence is evaluated by university administrators within 24 to 48 hours.',
                    ),
                    _buildFaqItem(
                      'How are student openings tracked?',
                      'When posting a project, you set student openings. When reviewing applicants on Screen 28, the platform ensures you cannot exceed available openings.',
                    ),
                    _buildFaqItem(
                      'What happens after I approve a milestone?',
                      'The milestone progress updates to 100%, and the project marks as Completed in corporate records.',
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

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy)),
          const SizedBox(height: 4),
          Text(answer,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
        ],
      ),
    );
  }

  // 9. Action: Logout with Confirmation Dialog & Navigation to LoginScreen
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Log Out?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of CAMPUSCONNECT? Your active session will be securely terminated.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AppDataService.instance.clearAuthSession();
      await _settingsService.logout();

      if (mounted) {
        // Clear navigation stack and navigate safely to LoginScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Company Profile & Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder<CompanyProfileModel>(
        valueListenable: _profileService.currentProfileNotifier,
        builder: (context, profile, _) {
          return ValueListenableBuilder<CompanySettingsModel>(
            valueListenable: _settingsService.settingsNotifier,
            builder: (context, settings, child) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. COMPANY PROFILE INFORMATION HEADER CARD
                  _buildProfileHeaderCard(profile),
                  const SizedBox(height: 16),

                  // ACCOUNT SETTINGS SECTION
                  _buildSectionHeader('Account Management'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // 2. Edit Company Profile
                        _buildSettingsTile(
                          icon: Icons.business_rounded,
                          title: 'Edit Company Profile',
                          subtitle: 'Name, logo, industry, contact & address',
                          onTap: _navigateToEditProfile,
                        ),
                        const Divider(height: 1),
                        // Company Verification Status
                        _buildSettingsTile(
                          icon: Icons.verified_user_rounded,
                          iconColor: profile.isVerified
                              ? AppColors.success
                              : AppColors.warning,
                          title: 'Verification Status',
                          subtitle: profile.isVerified
                              ? 'Verified Corporate Partner'
                              : 'Verification Pending Review',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: profile.isVerified
                                  ? AppColors.successBg
                                  : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              profile.isVerified ? 'Verified' : 'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: profile.isVerified
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
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
                        // 3. Change Password
                        _buildSettingsTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          subtitle: 'Update your corporate account password',
                          onTap: _openChangePasswordModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. NOTIFICATION PREFERENCES SECTION
                  _buildSectionHeader('Notification Preferences'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'New Student Applications',
                          subtitle:
                              'Receive alerts when candidates apply to your projects',
                          value: settings.notifyNewApplications,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(notifyNewApplications: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.assignment_turned_in_rounded,
                          title: 'Milestone Work Submissions',
                          subtitle:
                              'Get notified when students deliver milestone work',
                          value: settings.notifyMilestoneSubmissions,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(notifyMilestoneSubmissions: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Project Status Updates',
                          subtitle:
                              'Alerts when projects are closed or approved',
                          value: settings.notifyStatusChanges,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(notifyStatusChanges: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.mail_outline_rounded,
                          title: 'Weekly Performance Digest',
                          subtitle:
                              'Weekly overview of project metrics and candidate talent',
                          value: settings.notifyWeeklyDigest,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(notifyWeeklyDigest: val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. PRIVACY SETTINGS SECTION
                  _buildSectionHeader('Privacy & Directory Visibility'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.public_rounded,
                          title: 'Public Corporate Directory',
                          subtitle:
                              'Show company profile on campus exploration feeds',
                          value: settings.privacyDirectoryVisible,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(privacyDirectoryVisible: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.badge_outlined,
                          title: 'Show Contact Person to Candidates',
                          subtitle:
                              'Display contact representative name to applicants',
                          value: settings.privacyShowContactPerson,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(
                                  privacyShowContactPerson: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.insights_rounded,
                          title: 'Platform Analytics Sharing',
                          subtitle:
                              'Share aggregated talent statistics with university registrars',
                          value: settings.privacyShareAnalytics,
                          onChanged: (val) {
                            _settingsService.updateSettings(
                              settings.copyWith(privacyShareAnalytics: val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 6, 7, 8. LEGAL, POLICY & SUPPORT SECTION
                  _buildSectionHeader('Support & Legal Guidelines'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // 8. Help & Support
                        _buildSettingsTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Help & Corporate Support',
                          subtitle:
                              'Liaison desk, partner helpline & FAQs',
                          onTap: _openHelpSupportModal,
                        ),
                        const Divider(height: 1),
                        // 6. Terms & Conditions
                        _buildSettingsTile(
                          icon: Icons.gavel_rounded,
                          title: 'Terms & Conditions',
                          subtitle:
                              'Partner agreements & intellectual property rules',
                          onTap: _openTermsAndConditionsModal,
                        ),
                        const Divider(height: 1),
                        // 7. Privacy Policy
                        _buildSettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle:
                              'Student data security & corporate compliance',
                          onTap: _openPrivacyPolicyModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 9. LOGOUT BUTTON
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 22),
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Securely end active corporate session',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.error),
                      onTap: _handleLogout,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Version Footer
                  const Center(
                    child: Text(
                      'CAMPUSCONNECT v1.0.0 • Student–Corporate Bridge Platform\nProtected under university academic partner network',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // 1. Company Profile Information Header Card
  Widget _buildProfileHeaderCard(CompanyProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              // Logo Monogram
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.darkNavy, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile.logoInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name, Industry, and Verified badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.companyName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.verified_rounded,
                                color: AppColors.success, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.industry,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.city} • Contact: ${profile.contactPersonName}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Official Email & Website row
          Row(
            children: [
              const Icon(Icons.email_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  profile.officialEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Updated: ${profile.lastUpdated}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.darkNavy,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.darkNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
      ),
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: AppColors.darkNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
