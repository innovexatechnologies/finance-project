import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/section_header.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/student/applications/presentation/screens/my_applications_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';
import 'package:link_vibe/core/widgets/student_avatar.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const StudentHomeScreen({super.key, this.onTabChange});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateDashboard();
    });
  }

  Future<void> _hydrateDashboard() async {
    _syncUserWithProfile();
    await AppDataService.instance.syncFromSupabase(forceRefresh: true);
  }

  void _syncUserWithProfile() {
    final user = SupabaseHelper.currentUser;
    if (user == null) return;

    final name = user.userMetadata?['name']?.toString().trim() ?? '';
    final email = user.email?.trim() ?? '';
    final university =
        user.userMetadata?['university']?.toString().trim() ?? '';
    final currentProfile = AppDataService.instance.getProfile();
    final currentName = currentProfile['name']?.toString().trim() ?? '';
    final currentUni = currentProfile['university']?.toString().trim() ?? '';

    final updates = <String, dynamic>{};
    if (currentName.isEmpty && name.isNotEmpty) {
      updates['name'] = name;
    }
    if ((currentProfile['email']?.toString().trim() ?? '').isEmpty &&
        email.isNotEmpty) {
      updates['email'] = email;
    }
    if (currentUni.isEmpty && university.isNotEmpty) {
      updates['university'] = university;
    }

    if (updates.isNotEmpty) {
      AppDataService.instance.updateProfile(updates);
    }
  }

  String _resolveStudentName(Map<String, dynamic> profile) {
    final pName = profile['name']?.toString().trim() ?? '';
    if (pName.isNotEmpty) return pName;
    if (AppDataService.instance.userName.trim().isNotEmpty) {
      return AppDataService.instance.userName.trim();
    }
    final metaName =
        SupabaseHelper.currentUser?.userMetadata?['name']?.toString().trim() ??
            '';
    if (metaName.isNotEmpty) return metaName;
    return 'Student';
  }

  void _openExplore() {
    if (widget.onTabChange != null) {
      widget.onTabChange!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExploreProjectsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final profile = AppDataService.instance.getProfile();
        final studentName = _resolveStudentName(profile);
        final university = profile['university']?.toString().trim() ?? '';

        final openProjects = AppDataService.instance.getOpenProjects();
        final recommendedProjects = openProjects.take(4).toList();

        final totalApps = AppDataService.instance.totalApplicationsCount;
        final activeProjects = AppDataService.instance.activeProjectsCount;
        final completedProjects =
            AppDataService.instance.completedProjectsCount;
        final certs = AppDataService.instance.certificatesCount;
    
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () =>
                  AppDataService.instance.syncFromSupabase(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => widget.onTabChange?.call(3),
                              child: StudentAvatar(
                                name: studentName,
                                avatarUrl: profile['avatarUrl']?.toString(),
                                avatarBase64: profile['avatarBase64']?.toString(),
                                size: 48,
                                shadows: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $studentName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  Text(
                                    university.isNotEmpty
                                        ? university
                                        : 'Explore corporate projects & verify your skills',
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
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search Bar Trigger
                        GestureDetector(
                          onTap: _openExplore,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.lightGray),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.grayText,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Search corporate projects, skills, companies...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightAqua,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${openProjects.length} Open',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Hero Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.deepNavy,
                                AppColors.primaryBlue,
                                AppColors.teal,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compactHero = constraints.maxWidth < 340;
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.16),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'STUDENT WORKSPACE',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Turn Academic Skills Into Real Industry Experience',
                                          style: GoogleFonts.poppins(
                                            fontSize: compactHero ? 16 : 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Collaborate with verified companies and earn cryptographic completion certificates.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: AppColors.deepNavy,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _openExplore,
                                          icon: const Icon(
                                            Icons.explore_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Explore Projects',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!compactHero) ...[
                                    const SizedBox(width: 14),
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.22),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 46,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAction(
                                Icons.folder_open_rounded,
                                'Projects',
                                AppColors.lightAqua,
                                AppColors.primaryBlue,
                                _openExplore,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickAction(
                                Icons.workspace_premium_rounded,
                                'Certificates',
                                const Color(0xFFE0F7FA),
                                AppColors.teal,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CertificatesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickAction(
                                Icons.assignment_turned_in_rounded,
                                'My Work',
                                AppColors.warningBg,
                                const Color(0xFFD97706),
                                () => widget.onTabChange?.call(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickAction(
                                Icons.person_outline_rounded,
                                'Profile',
                                const Color(0xFFEDE9FE),
                                const Color(0xFF7C3AED),
                                () => widget.onTabChange?.call(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Stats Cards Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Applications',
                                totalApps.toString(),
                                Icons.send_rounded,
                                AppColors.primaryBlue,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyApplicationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Active Work',
                                activeProjects.toString(),
                                Icons.play_circle_outline_rounded,
                                AppColors.teal,
                                () => widget.onTabChange?.call(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Completed',
                                completedProjects.toString(),
                                Icons.check_circle_outline_rounded,
                                AppColors.statusOpen,
                                () => widget.onTabChange?.call(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Certificates',
                                certs.toString(),
                                Icons.military_tech_rounded,
                                AppColors.statusPending,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CertificatesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),

                        // Recommended Projects Section Header
                        SectionHeader(
                          title: 'Live Open Opportunities',
                          subtitle: openProjects.isEmpty
                              ? 'Synced from Supabase partner projects'
                              : '${openProjects.length} active company project${openProjects.length == 1 ? '' : 's'}',
                          actionLabel: 'See All',
                          onAction: _openExplore,
                        ),
                        const SizedBox(height: 12),

                        if (recommendedProjects.isEmpty)
                          AppEmptyState(
                            compact: true,
                            icon: Icons.explore_outlined,
                            title: 'No Open Projects Right Now',
                            subtitle:
                                'Pull down to refresh or open Explore once partner companies publish new live opportunities.',
                            actionLabel: 'Explore Catalog',
                            actionIcon: Icons.explore_rounded,
                            onAction: _openExplore,
                          )
                        else
                          ...recommendedProjects.map(_buildProjectCard),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 25),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final id = project['id']?.toString() ?? '';
    final isSaved = AppDataService.instance.isProjectSaved(id);
    final companyName =
        (project['company']?.toString().trim().isNotEmpty == true)
            ? project['company'].toString().trim()
            : 'Partner Company';
    final duration = project['duration']?.toString().trim() ?? 'Flexible';
    final status = project['status']?.toString() ?? 'Open';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentProjectDetailsScreen(project: project),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
                    SupabaseHelper.initialsFor(companyName, fallback: 'CO'),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$companyName • $duration',
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
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: const Icon(
                  Icons.share_outlined,
                  size: 19,
                  color: AppColors.grayText,
                ),
                onPressed: () {
                  ShareService.shareProject(
                    context: context,
                    project: project,
                  );
                },
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 21,
                  color: isSaved ? AppColors.teal : AppColors.grayText,
                ),
                onPressed: () {
                  AppDataService.instance.toggleSaveProject(project);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
            ],
          ),
        ),
      ),
    );
  }
}
