import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';

import 'change_password_screen.dart';
import 'notification_preferences_screen.dart';
import 'privacy_settings_screen.dart';
import 'help_center_screen.dart';
import 'contact_support_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AppDataService.instance.clearAuthSession();
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Help'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Section
          Text(
            'Account Preferences',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            Icons.lock_outline_rounded,
            'Change Password',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            Icons.notifications_outlined,
            'Notification Preferences',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            Icons.shield_outlined,
            'Privacy & Visibility Settings',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Support Section
          Text(
            'Support & Legal',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            Icons.help_outline_rounded,
            'Help Center & FAQs',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            Icons.mail_outline_rounded,
            'Contact Support',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactSupportScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            Icons.description_outlined,
            'Terms & Conditions',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsConditionsScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            Icons.policy_outlined,
            'Privacy Policy',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Log Out',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue, size: 22),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.darkText,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.grayText,
        ),
        onTap: onTap,
      ),
    );
  }
}
