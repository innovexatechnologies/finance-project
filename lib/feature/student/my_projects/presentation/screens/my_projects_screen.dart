import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final allApps = AppDataService.instance.getApplications();

        // Separate into active and completed
        final activeList = allApps
            .where((a) =>
                a['status'] == 'In Progress' ||
                a['status'] == 'Under Review' ||
                a['status'] == 'Revision Requested' ||
                a['status'] == 'Accepted' ||
                a['status'] == 'Shortlisted')
            .toList();

        final completedList =
            allApps.where((a) => a['status'] == 'Completed').toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Projects'),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.grayText,
              indicatorColor: AppColors.primaryBlue,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: 'Active (${activeList.length})'),
                Tab(text: 'Completed (${completedList.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Active Projects Tab
              activeList.isEmpty
                  ? _buildEmptyState(
                      'No Active Projects',
                      'Apply for projects and get assigned to start working!',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: activeList.length,
                      itemBuilder: (context, index) {
                        return _buildProjectItem(activeList[index], false);
                      },
                    ),

              // Completed Projects Tab
              completedList.isEmpty
                  ? _buildEmptyState(
                      'No Completed Projects Yet',
                      'Projects you finish and get approved will appear here along with your certificates.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: completedList.length,
                      itemBuilder: (context, index) {
                        return _buildProjectItem(completedList[index], true);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_shared_outlined,
                size: 54, color: AppColors.grayText),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project, bool isCompleted) {
    final status = project['status'] ?? 'In Progress';
    final pId = project['projectId']?.toString() ??
        project['id']?.toString() ??
        '';
    final hasSubmission = AppDataService.instance.getSubmission(pId) != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
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
                      (project['company'] ?? 'C')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
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
                        project['title'] ?? 'Title',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        project['company'] ?? 'Company',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 14),

            // Due Date & Metadata
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.grayText),
                const SizedBox(width: 4),
                Text(
                  'Assigned: ${project['appliedDate'] ?? 'Nov 2026'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.grayText,
                  ),
                ),
                const Spacer(),
                if (hasSubmission) ...[
                  const Icon(Icons.check_circle_rounded,
                      size: 13, color: AppColors.statusOpen),
                  const SizedBox(width: 4),
                  Text(
                    'Work Uploaded',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusOpen,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepNavy,
                      side: const BorderSide(color: AppColors.lightGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentProjectDetailsScreen(project: project),
                        ),
                      );
                    },
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isCompleted) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        if (status == 'Revision Requested') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FeedbackScreen(project: project),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SubmitWorkScreen(project: project),
                            ),
                          );
                        }
                      },
                      child: Text(
                        status == 'Revision Requested'
                            ? 'Feedback'
                            : hasSubmission
                                ? 'Update Work'
                                : 'Submit Work',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.lightAqua;
    Color fg = AppColors.primaryBlue;

    if (status == 'Completed' || status == 'Accepted') {
      bg = AppColors.statusOpen.withValues(alpha: 0.12);
      fg = AppColors.statusOpen;
    } else if (status == 'Revision Requested') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (status == 'Under Review' || status == 'Shortlisted') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
