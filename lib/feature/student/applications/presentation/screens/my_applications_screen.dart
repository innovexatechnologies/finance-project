import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Pending',
    'Shortlisted',
    'Accepted',
    'In Progress',
    'Under Review',
    'Revision Requested',
    'Completed',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ExecutiveAppBar(
        title: 'My Applications',
        subtitle: 'Track Review & Approval Stages',
        actions: [
          ExecutiveHeaderIconButton(
            tooltip: 'Sync Applications',
            icon: Icons.refresh_rounded,
            onPressed: () =>
                AppDataService.instance.syncFromSupabase(forceRefresh: true),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final allApps = AppDataService.instance.getApplications();

          final filteredApps = allApps.where((app) {
            if (_selectedFilter == 'All') return true;
            return app['status']?.toString().toLowerCase() ==
                _selectedFilter.toLowerCase();
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFilter = filter);
                              }
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: AppColors.cardWhite,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkText,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.lightGray,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryBlue,
                      onRefresh: () => AppDataService.instance
                          .syncFromSupabase(forceRefresh: true),
                      child: filteredApps.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 40),
                                AppEmptyState(
                                  icon: Icons.assignment_late_outlined,
                                  title: 'No Applications Found',
                                  subtitle: _selectedFilter == 'All'
                                      ? 'Apply for live corporate opportunities in Explore to track every review milestone here.'
                                      : 'You have no applications currently in "$_selectedFilter" status.',
                                  actionLabel: _selectedFilter == 'All'
                                      ? null
                                      : 'Show All Applications',
                                  onAction: _selectedFilter == 'All'
                                      ? null
                                      : () => setState(
                                          () => _selectedFilter = 'All'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredApps.length,
                              itemBuilder: (context, index) {
                                return _buildApplicationCard(
                                  context,
                                  filteredApps[index],
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, Map<String, dynamic> app) {
    final status = app['status']?.toString() ?? 'Pending';
    final timelineStep = (app['timelineStep'] as int?) ?? 1;
    final company = (app['company']?.toString().trim().isNotEmpty == true)
        ? app['company'].toString().trim()
        : 'Partner Company';
    final title = app['title']?.toString() ?? 'Project';
    final appliedDate = app['appliedDate']?.toString().trim() ?? 'Recently';
    final feedback = app['companyFeedback']?.toString().trim() ?? '';
    final canWork = status == 'Accepted' ||
        status == 'In Progress' ||
        status == 'Under Review' ||
        status == 'Revision Requested';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lightAqua,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      SupabaseHelper.initialsFor(company, fallback: 'CO'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                StatusBadge(label: status),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied: $appliedDate',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.grayText,
                  ),
                ),
                Text(
                  'Stage $timelineStep of 3',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTimelineBar(timelineStep, status),

            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Company Feedback: $feedback',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ),
            ],

            if (canWork) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                    ),
                    onPressed: () {
                      if (status == 'Revision Requested') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeedbackScreen(project: app),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmitWorkScreen(project: app),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      status == 'Revision Requested'
                          ? Icons.rate_review_rounded
                          : Icons.upload_file_rounded,
                      size: 16,
                    ),
                    label: Text(
                      status == 'Revision Requested'
                          ? 'Review & Resubmit'
                          : 'Submit Deliverable',
                      style: GoogleFonts.poppins(fontSize: 12.5),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                    ),
                    onPressed: () async {
                      await AppDataService.instance.openOrCreateConversation(
                        companyName: company,
                        peerUserId: app['companyUserId']?.toString(),
                        projectTitle: title,
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChatListScreen()),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15),
                    label: const Text('Message', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineBar(int step, String status) {
    final isRejected = status == 'Rejected';

    return Row(
      children: [
        _buildTimelineStep('Submitted', step >= 1, isRejected && step == 1),
        Expanded(
          child: Container(
            height: 3,
            color: step >= 2 ? AppColors.primaryBlue : AppColors.lightGray,
          ),
        ),
        _buildTimelineStep('Review', step >= 2, isRejected && step == 2),
        Expanded(
          child: Container(
            height: 3,
            color: step >= 3 ? AppColors.primaryBlue : AppColors.lightGray,
          ),
        ),
        _buildTimelineStep(
          isRejected
              ? 'Rejected'
              : (status == 'Completed' ? 'Completed' : 'Accepted'),
          step >= 3,
          isRejected,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String label, bool isDone, bool isAlert) {
    Color dotColor = AppColors.lightGray;
    if (isAlert) {
      dotColor = AppColors.statusClosed;
    } else if (isDone) {
      dotColor = AppColors.primaryBlue;
    }

    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppColors.deepNavy : AppColors.grayText,
          ),
        ),
      ],
    );
  }
}
