import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';
import 'package:link_vibe/feature/student/notifications/presentation/screens/notifications_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';

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
      if (mounted) _syncUserWithProfile();
    });
  }

  void _syncUserWithProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final name = user.userMetadata?['name'];
      final email = user.email;
      final university = user.userMetadata?['university'];
      final currentProfile = AppDataService.instance.getProfile();
      final currentName = currentProfile['name']?.toString() ?? '';
      final isGeneric = currentName.isEmpty || currentName == 'Ahmed Khan';

      AppDataService.instance.updateProfile({
        if (name != null && name.toString().isNotEmpty && isGeneric)
          'name': name.toString(),
        if (email != null && email.isNotEmpty) 'email': email,
        if (university != null && university.toString().isNotEmpty)
          'university': university.toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final profile = AppDataService.instance.getProfile();
        final studentName = (profile['name'] != null &&
                profile['name'].toString().isNotEmpty &&
                profile['name'].toString() != 'Ahmed Khan')
            ? profile['name'].toString()
            : (AppDataService.instance.userName.isNotEmpty
                ? AppDataService.instance.userName
                : (profile['name'] ?? 'Student'));
        final recommendedProjects =
            AppDataService.instance.getAllProjects().take(4).toList();

        final totalApps = AppDataService.instance.totalApplicationsCount;
        final activeProjects = AppDataService.instance.activeProjectsCount;
        final completedProjects = AppDataService.instance.completedProjectsCount;
        final certs = AppDataService.instance.certificatesCount;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Profile Avatar, Greeting, and Notification Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => widget.onTabChange?.call(4),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.lightAqua,
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 30,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Hello, $studentName!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('👋', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              Text(
                                'Explore projects and grow your skills',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grayText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.lightGray),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.deepNavy,
                                size: 22,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (AppDataService.instance.unreadNotificationsCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar Navigation Anchor
                  GestureDetector(
                    onTap: () => widget.onTabChange?.call(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.grayText, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Search for projects, companies...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hero Banner Card: "Turn Your Skills Into Earning"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F3A70),
                          AppColors.primaryBlue,
                          AppColors.teal,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Turn Your Skills\nInto Earning',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Work on real projects from top companies',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.deepNavy,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  if (widget.onTabChange != null) {
                                    widget.onTabChange!(1);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ExploreProjectsScreen(),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore Now',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: AppColors.deepNavy,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.laptop_chromebook_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Access 4 Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        Icons.folder_open_rounded,
                        'Projects',
                        AppColors.lightAqua,
                        AppColors.primaryBlue,
                        () => widget.onTabChange?.call(1),
                      ),
                      _buildQuickAction(
                        Icons.workspace_premium_rounded,
                        'Certificates',
                        const Color(0xFFE0F7FA),
                        AppColors.teal,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CertificatesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        Icons.assignment_turned_in_rounded,
                        'My Work',
                        const Color(0xFFFEF3C7),
                        const Color(0xFFD97706),
                        () => widget.onTabChange?.call(2),
                      ),
                      _buildQuickAction(
                        Icons.person_outline_rounded,
                        'Profile',
                        const Color(0xFFEDE9FE),
                        const Color(0xFF7C3AED),
                        () => widget.onTabChange?.call(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Live Reactive Stats Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Applications',
                          totalApps.toString(),
                          Icons.send_rounded,
                          AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Active Projects',
                          activeProjects.toString(),
                          Icons.play_circle_outline_rounded,
                          AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Completed Projects',
                          completedProjects.toString(),
                          Icons.check_circle_outline_rounded,
                          AppColors.statusOpen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Certificates',
                          certs.toString(),
                          Icons.military_tech_rounded,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Recommended Projects Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommended Projects',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onTabChange?.call(1),
                        child: Row(
                          children: [
                            Text(
                              'See All',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recommended Projects List
                  ...recommendedProjects.map((p) => _buildProjectCard(p)),
                ],
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 11,
                    color: AppColors.grayText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final id = project['id']?.toString() ?? '';
    final isSaved = AppDataService.instance.isProjectSaved(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.lightGray, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProjectDetailsScreen(project: project),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project['company']} • ${project['duration']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusOpen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project['status'] ?? 'Open',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusOpen,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.grayText,
                ),
                onPressed: () {
                  ShareService.shareProject(
                    context: context,
                    project: project,
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 22,
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
            ],
          ),
        ),
      ),
    );
  }
}
