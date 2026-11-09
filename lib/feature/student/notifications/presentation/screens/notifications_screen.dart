import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Your project is approved!',
        'subtitle': 'Barcode Scanning Mobile Utility final review passed.',
        'time': '2h ago',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.statusOpen,
        'isUnread': true,
      },
      {
        'title': 'New project available:',
        'subtitle': 'UI Design for Web App published by Microsoft.',
        'time': '3h ago',
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFFEF4444),
        'isUnread': true,
      },
      {
        'title': 'You earned 500 points!',
        'subtitle': 'Milestone bonus for on-time submission.',
        'time': '1d ago',
        'icon': Icons.stars_rounded,
        'color': const Color(0xFFF59E0B),
        'isUnread': false,
      },
      {
        'title': 'Your profile is verified',
        'subtitle': 'Academic identity confirmed with University portal.',
        'time': '2d ago',
        'icon': Icons.verified_user_rounded,
        'color': AppColors.teal,
        'isUnread': false,
      },
      {
        'title': 'Application Shortlisted',
        'subtitle': 'Google shortlisted your Market Research application.',
        'time': '3d ago',
        'icon': Icons.thumb_up_alt_rounded,
        'color': AppColors.primaryBlue,
        'isUnread': false,
      },
    ];

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = notifications[index];
          final color = item['color'] as Color;
          final isUnread = item['isUnread'] as bool;

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
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 22),
              ),
              title: Text(
                item['title'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.deepNavy,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item['subtitle'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ),
              ),
              trailing: Text(
                item['time'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.grayText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
