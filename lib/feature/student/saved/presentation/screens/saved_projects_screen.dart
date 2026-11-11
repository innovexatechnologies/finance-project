import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

class SavedProjectsScreen extends StatelessWidget {
  const SavedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ExecutiveAppBar(
        title: 'Saved Projects',
        subtitle: 'Bookmarked Opportunities',
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final savedProjects = AppDataService.instance.getSavedProjects();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () => AppDataService.instance
                    .syncFromSupabase(forceRefresh: true),
                child: savedProjects.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 48),
                          AppEmptyState(
                            icon: Icons.bookmark_border_rounded,
                            title: 'No Saved Projects Yet',
                            subtitle:
                                'Bookmark corporate opportunities from Home or Explore to revisit and apply anytime.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: savedProjects.length,
                        itemBuilder: (context, index) {
                          final project = savedProjects[index];
                          final id = project['id']?.toString() ?? '';
                          final company =
                              (project['company']?.toString().trim().isNotEmpty ==
                                      true)
                                  ? project['company'].toString().trim()
                                  : 'Partner Company';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StudentProjectDetailsScreen(
                                            project: project),
                                  ),
                                );
                              },
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.lightAqua,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    SupabaseHelper.initialsFor(
                                      company,
                                      fallback: 'CO',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                project['title']?.toString() ??
                                    'Untitled Project',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '$company • ${project['duration'] ?? 'Remote'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Share',
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      color: AppColors.grayText,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      ShareService.shareProject(
                                        context: context,
                                        project: project,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Remove Bookmark',
                                    icon: const Icon(
                                      Icons.bookmark_remove_rounded,
                                      color: AppColors.statusClosed,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      AppDataService.instance
                                          .removeSavedProject(id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Removed from saved projects'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
