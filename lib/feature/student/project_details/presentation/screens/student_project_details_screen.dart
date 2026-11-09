import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/student/apply/presentation/screens/apply_project_screen.dart';

class StudentProjectDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> project;

  const StudentProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final id = project['id']?.toString() ?? '';
    final title = project['title'] ?? 'Market Research on AI Tools';
    final company = project['company'] ?? 'TechVista Corp';
    final duration = project['duration'] ?? '3-5 days';
    final workMode = project['workMode'] ?? 'Remote';
    final stipend = project['stipend'] ?? project['budget'] ?? 'Competitive';
    final description = project['description'] ??
        'Conduct deep market analysis on latest AI tools and benchmark performance against industry standards.';
    final skills = (project['skills'] as List?) ??
        ['Research', 'Analysis', 'Report Writing', 'Presentation'];

    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final isSaved = AppDataService.instance.isProjectSaved(id);
        final hasApplied = AppDataService.instance.hasApplied(id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Collapsible Image Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.deepNavy,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: isSaved ? AppColors.teal : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      AppDataService.instance.toggleSaveProject(project);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? 'Project removed from bookmarks'
                                : 'Project saved to bookmarks!',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0F3A70),
                          AppColors.deepNavy,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.business_center_rounded,
                            size: 72,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              size: 32,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Verification
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text(
                            company,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grayText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.teal),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Partner',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Meta Chips Row: Duration, Remote, Stipend
                      Row(
                        children: [
                          _buildMetaBadge(
                              Icons.schedule_rounded, duration, AppColors.deepNavy),
                          const SizedBox(width: 10),
                          _buildMetaBadge(
                              Icons.public_rounded, workMode, AppColors.primaryBlue),
                          const SizedBox(width: 10),
                          _buildMetaBadge(
                              Icons.payments_outlined, stipend, AppColors.statusOpen),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // About Project
                      Text(
                        'About this Project',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.darkText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Project Objectives
                      Text(
                        'Project Objectives',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletItem(
                          'Conduct structured survey and secondary research.'),
                      _buildBulletItem(
                          'Analyze key feature differentiation and user reception.'),
                      _buildBulletItem(
                          'Deliver clean summary deck with actionable insights.'),
                      const SizedBox(height: 24),

                      // Required Skills
                      Text(
                        'Skills Required',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.lightGray),
                            ),
                            child: Text(
                              s.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Deliverables
                      Text(
                        'Deliverables',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletItem('Complete analytical report document (PDF).'),
                      _buildBulletItem('Source data references and analysis sheet.'),
                      _buildBulletItem('Verifiable certificate upon completion.'),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar: "Apply Now" or "Already Applied"
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                border: Border(top: BorderSide(color: AppColors.lightGray)),
              ),
              child: Row(
                children: [
                  // Bookmark Quick Button
                  IconButton(
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isSaved ? AppColors.teal : AppColors.grayText,
                    ),
                    onPressed: () {
                      AppDataService.instance.toggleSaveProject(project);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? 'Removed from saved projects'
                                : 'Project saved to bookmarks!',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Apply Now Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasApplied
                              ? AppColors.statusOpen
                              : AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          if (hasApplied) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'You have already applied! Check status in My Applications.'),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ApplyProjectScreen(project: project),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hasApplied ? 'Applied ✓' : 'Apply Now',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!hasApplied) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildMetaBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 5, color: AppColors.primaryBlue),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.darkText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
