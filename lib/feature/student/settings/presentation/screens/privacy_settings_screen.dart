import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Visibility'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final privacy = AppDataService.instance.getPrivacySettings();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.teal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Data & Visibility Control',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Control which profile information is visible to partner companies.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Profile Visibility',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              _buildPrivacySwitch(
                context: context,
                icon: Icons.visibility_outlined,
                title: 'Company Profile Discovery',
                subtitle: 'Allow verified hiring companies to discover and invite your profile',
                keyName: 'profileVisibility',
                value: privacy['profileVisibility'] ?? true,
              ),
              _buildPrivacySwitch(
                context: context,
                icon: Icons.folder_shared_outlined,
                title: 'Public Portfolio & Skills',
                subtitle: 'Showcase your completed projects and skills on your public profile',
                keyName: 'publicPortfolio',
                value: privacy['publicPortfolio'] ?? true,
              ),
              const SizedBox(height: 24),

              Text(
                'Contact Details Privacy',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              _buildPrivacySwitch(
                context: context,
                icon: Icons.email_outlined,
                title: 'Show Email Address',
                subtitle: 'Display your university email to companies you apply to',
                keyName: 'showEmail',
                value: privacy['showEmail'] ?? true,
              ),
              _buildPrivacySwitch(
                context: context,
                icon: Icons.phone_outlined,
                title: 'Show Contact Number',
                subtitle: 'Include phone number on submitted project applications',
                keyName: 'showPhone',
                value: privacy['showPhone'] ?? false,
              ),
              _buildPrivacySwitch(
                context: context,
                icon: Icons.message_outlined,
                title: 'Allow Direct Company Messaging',
                subtitle: 'Permit companies to message you regarding assigned projects',
                keyName: 'allowCompanyMessages',
                value: privacy['allowCompanyMessages'] ?? true,
              ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacySwitch({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String keyName,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightGray),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : AppColors.lightGray.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? AppColors.teal : AppColors.grayText,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepNavy,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.grayText,
            ),
          ),
          activeTrackColor: AppColors.teal.withValues(alpha: 0.5),
          activeThumbColor: AppColors.teal,
          value: value,
          onChanged: (newValue) async {
            await AppDataService.instance
                .updatePrivacySetting(keyName, newValue);
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('$title ${newValue ? "allowed" : "restricted"}'),
                  duration: const Duration(milliseconds: 1200),
                  backgroundColor:
                      newValue ? AppColors.teal : AppColors.deepNavy,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
