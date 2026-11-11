import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/feedback/presentation/screens/feedback_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';
import 'package:link_vibe/feature/student/submissions/presentation/screens/submit_work_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

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

  Future<void> _refreshProjects({bool showFeedback = true}) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final hasClient = SupabaseHelper.clientOrNull != null;
      if (hasClient) {
        await AppDataService.instance.syncFromSupabase(forceRefresh: true);
      } else {
        await AppDataService.instance.init();
      }
      if (!mounted || !showFeedback) return;
      final syncError = AppDataService.instance.lastSyncError;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              syncError != null
                  ? SupabaseHelper.friendlyError(syncError)
                  : hasClient
                      ? 'Projects and statuses refreshed.'
                      : 'Refreshed local projects.',
            ),
            backgroundColor:
                syncError != null ? AppColors.statusClosed : AppColors.statusOpen,
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(SupabaseHelper.friendlyError(e)),
              backgroundColor: AppColors.statusClosed,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _openCompanyChat(Map<String, dynamic> project) async {
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    await AppDataService.instance.openOrCreateConversation(
      companyName: company,
      peerUserId: project['companyUserId']?.toString(),
      supervisorName: '$company Lead',
      projectTitle: project['title']?.toString(),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final allApps = AppDataService.instance.getApplications();

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
            actions: [
              IconButton(
                tooltip:
                    _isRefreshing ? 'Syncing Projects...' : 'Refresh Projects',
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: _isRefreshing ? null : _refreshProjects,
              ),
              const SizedBox(width: 4),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.grayText,
              indicatorColor: AppColors.primaryBlue,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              tabs: [
                Tab(text: 'Active (${activeList.length})'),
                Tab(text: 'Completed (${completedList.length})'),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: _refreshProjects,
                    child: activeList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 40),
                              AppEmptyState(
                                icon: Icons.folder_shared_outlined,
                                title: 'No Active Projects',
                                subtitle:
                                    'Apply for open projects from Explore and once a partner company shortlists or assigns you, it will appear here.',
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: activeList.length,
                            itemBuilder: (_, index) =>
                                _buildProjectItem(activeList[index], false),
                          ),
                  ),
                  RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: _refreshProjects,
                    child: completedList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 40),
                              AppEmptyState(
                                icon: Icons.verified_outlined,
                                title: 'No Completed Projects Yet',
                                subtitle:
                                    'Finished projects approved by your company supervisor will appear here alongside your verified certificates.',
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: completedList.length,
                            itemBuilder: (_, index) =>
                                _buildProjectItem(completedList[index], true),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project, bool isCompleted) {
    final status = project['status']?.toString() ?? 'In Progress';
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    final pId = project['projectId']?.toString() ??
        project['id']?.toString() ??
        '';
    final hasSubmission = AppDataService.instance.getSubmission(pId) != null;
    final assignedDate = project['appliedDate']?.toString().trim() ?? 'Recently';
    final feedback = project['companyFeedback']?.toString().trim() ?? '';

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
                        project['title']?.toString() ?? 'Untitled Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
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
            const SizedBox(height: 12),

            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.grayText),
                    const SizedBox(width: 4),
                    Text(
                      'Updated: $assignedDate',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
                if (hasSubmission)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.statusOpen),
                      const SizedBox(width: 4),
                      Text(
                        'Work Uploaded',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusOpen,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

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
                  'Supervisor Note: $feedback',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentProjectDetailsScreen(project: project),
                      ),
                    );
                  },
                  child: const Text('Details'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onPressed: () => _openCompanyChat(project),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                  label: const Text('Message'),
                ),
                if (!isCompleted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'Revision Requested'
                          ? const Color(0xFFD97706)
                          : AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => status == 'Revision Requested'
                              ? FeedbackScreen(project: project)
                              : SubmitWorkScreen(project: project),
                        ),
                      );
                    },
                    icon: Icon(
                      status == 'Revision Requested'
                          ? Icons.rate_review_rounded
                          : Icons.upload_file_rounded,
                      size: 16,
                    ),
                    label: Text(
                      status == 'Revision Requested'
                          ? 'Feedback'
                          : hasSubmission
                              ? 'Update Work'
                              : 'Submit Work',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CertificatesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                    label: const Text('Certificate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
