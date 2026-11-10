import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
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
          final prefs = AppDataService.instance.getNotificationPreferences();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
              // Header Card
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
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Notification Channels',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customize how and when CampusConnect sends you alerts and updates.',
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
                'Delivery Channels',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              _buildPreferenceSwitch(
                context: context,
                icon: Icons.phone_android_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive real-time push alerts on your mobile device',
                keyName: 'pushNotifications',
                value: prefs['pushNotifications'] ?? true,
              ),
              _buildPreferenceSwitch(
                context: context,
                icon: Icons.mark_email_unread_rounded,
                title: 'Email Notifications',
                subtitle: 'Receive important project announcements via email',
                keyName: 'emailAlerts',
                value: prefs['emailAlerts'] ?? true,
              ),
              const SizedBox(height: 24),

              Text(
                'Activity & Work Alerts',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              _buildPreferenceSwitch(
                context: context,
                icon: Icons.work_outline_rounded,
                title: 'New Project Recommendations',
                subtitle: 'Get alerts when companies post projects matching your skills',
                keyName: 'newProjectsAlert',
                value: prefs['newProjectsAlert'] ?? true,
              ),
              _buildPreferenceSwitch(
                context: context,
                icon: Icons.task_alt_rounded,
                title: 'Application Status Updates',
                subtitle: 'Instant alerts when shortlisted, accepted, or under review',
                keyName: 'applicationUpdates',
                value: prefs['applicationUpdates'] ?? true,
              ),
              _buildPreferenceSwitch(
                context: context,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Company Messages & Chat',
                subtitle: 'Alerts when project supervisors send you direct messages',
                keyName: 'chatMessages',
                value: prefs['chatMessages'] ?? true,
              ),
              _buildPreferenceSwitch(
                context: context,
                icon: Icons.alarm_rounded,
                title: 'Milestone & Deadline Reminders',
                subtitle: 'Reminders 24 hours prior to assignment submission deadlines',
                keyName: 'deadlineReminders',
                value: prefs['deadlineReminders'] ?? true,
              ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreferenceSwitch({
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
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : AppColors.lightGray.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primaryBlue : AppColors.grayText,
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
          activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
          activeThumbColor: AppColors.primaryBlue,
          value: value,
          onChanged: (newValue) async {
            await AppDataService.instance
                .updateNotificationPreference(keyName, newValue);
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('$title ${newValue ? "enabled" : "disabled"}'),
                  duration: const Duration(milliseconds: 1200),
                  backgroundColor:
                      newValue ? AppColors.primaryBlue : AppColors.deepNavy,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
