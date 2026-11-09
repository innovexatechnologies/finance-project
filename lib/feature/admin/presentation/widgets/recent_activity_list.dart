import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';

/// Live Platform Activity Feed with category filter tabs and empty states
class RecentActivityList extends StatefulWidget {
  final List<AdminActivityItem> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  State<RecentActivityList> createState() => _RecentActivityListState();
}

class _RecentActivityListState extends State<RecentActivityList> {
  String _activeFilter = 'All';

  final List<String> _filters = [
    'All',
    'Verifications',
    'Registrations',
    'Projects',
    'Reports',
  ];

  @override
  Widget build(BuildContext context) {
    // Filter activities according to selected tab
    final filteredActivities = widget.activities.where((act) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Verifications') {
        return act.type == ActivityType.verificationSubmission;
      }
      if (_activeFilter == 'Registrations') {
        return act.type == ActivityType.studentRegistration ||
            act.type == ActivityType.companyRegistration;
      }
      if (_activeFilter == 'Projects') {
        return act.type == ActivityType.newProject ||
            act.type == ActivityType.projectCompletion;
      }
      if (_activeFilter == 'Reports') {
        return act.type == ActivityType.reportSubmission;
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(22),
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
          // Header & Live indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-Time Platform Activity Audit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Live streaming of registrations, verification actions, and project milestones',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3.5, backgroundColor: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Live Event Stream',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppColors.darkNavy,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    showCheckmark: false,
                    onSelected: (val) {
                      setState(() => _activeFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Activity Items or Empty State
          if (filteredActivities.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredActivities.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = filteredActivities[index];
                return _buildActivityTile(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightIceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'No activities match this filter criteria',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try switching filters to "All" to inspect the complete audit log stream.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(AdminActivityItem item) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (item.type) {
      case ActivityType.verificationSubmission:
        icon = Icons.domain_verification_rounded;
        color = AppColors.warning;
        bgColor = AppColors.warningBg;
        break;
      case ActivityType.newProject:
        icon = Icons.assignment_outlined;
        color = const Color(0xFF6366F1);
        bgColor = const Color(0xFF6366F1).withValues(alpha: 0.12);
        break;
      case ActivityType.studentRegistration:
        icon = Icons.school_outlined;
        color = AppColors.primary;
        bgColor = AppColors.lightIceBlue;
        break;
      case ActivityType.projectCompletion:
        icon = Icons.verified_outlined;
        color = AppColors.success;
        bgColor = AppColors.successBg;
        break;
      case ActivityType.reportSubmission:
        icon = Icons.analytics_outlined;
        color = AppColors.accentTeal;
        bgColor = AppColors.accentTeal.withValues(alpha: 0.12);
        break;
      case ActivityType.companyRegistration:
        icon = Icons.domain_outlined;
        color = AppColors.darkNavy;
        bgColor = AppColors.lightIceBlue;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${item.actorName} (${item.actorRole})',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

