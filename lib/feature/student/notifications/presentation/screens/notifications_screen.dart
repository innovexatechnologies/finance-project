import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppDataService.instance.markNotificationsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All notifications marked as read')),
              );
            },
            child: Text(
              'Mark Read',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final notifications = AppDataService.instance.getNotifications();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined,
                      size: 52, color: AppColors.grayText),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final isUnread = !(item['isRead'] as bool? ?? false);
              final type = item['type']?.toString() ?? 'default';

              Color color = AppColors.primaryBlue;
              IconData icon = Icons.notifications_rounded;

              if (type == 'shortlisted') {
                color = const Color(0xFFD97706);
                icon = Icons.thumb_up_alt_rounded;
              } else if (type == 'assigned') {
                color = const Color(0xFF7C3AED);
                icon = Icons.assignment_ind_rounded;
              } else if (type == 'approved' || type == 'submitted') {
                color = AppColors.statusOpen;
                icon = Icons.check_circle_rounded;
              } else if (type == 'certificate') {
                color = AppColors.teal;
                icon = Icons.military_tech_rounded;
              } else if (type == 'chat') {
                color = AppColors.primaryBlue;
                icon = Icons.chat_bubble_outline_rounded;
              }

              return Card(
                elevation: isUnread ? 1 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isUnread
                        ? AppColors.primaryBlue.withValues(alpha: 0.3)
                        : AppColors.lightGray,
                  ),
                ),
                color: isUnread ? Colors.white : AppColors.cardWhite,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (isUnread) {
                      AppDataService.instance.markNotificationRead(item['id']);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'Notification',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grayText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['time'] ?? 'Recent',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.grayText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
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
}
