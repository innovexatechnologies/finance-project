import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_dashboard_model.dart';

/// Live Platform Activity Feed with category filter tabs and clean empty states
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
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-Time Platform Activity Audit',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live streaming of registrations, verification actions, and project milestones',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3.5, backgroundColor: AppColors.success),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Live Event Stream',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _activeFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          if (filteredActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AppEmptyState(
                compact: true,
                icon: Icons.history_toggle_off_rounded,
                title: widget.activities.isEmpty
                    ? 'No Platform Activity Yet'
                    : 'No Activities Match Filter',
                subtitle: widget.activities.isEmpty
                    ? 'Registrations, verification submissions, project launches, and compliance logs from the database will appear here.'
                    : 'Switch filters back to "All" to inspect the complete audit log stream.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredActivities.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildActivityTile(filteredActivities[index]);
              },
            ),
        ],
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
        color = AppColors.indigoAccent;
        bgColor = AppColors.indigoAccent.withValues(alpha: 0.12);
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
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${item.actorName} (${item.actorRole})',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.badgeText,
                        style: GoogleFonts.inter(
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
