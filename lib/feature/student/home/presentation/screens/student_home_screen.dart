import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
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
  String _studentName = 'Ahmed Khan';
  List<Map<String, dynamic>> _recommendedProjects = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _defaultProjects = [
    {
      'id': '101',
      'title': 'Flutter App UI Design',
      'company': 'TechVista',
      'duration': '2-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Build responsive student dashboard widgets and integrate user state.',
      'skills': ['Flutter', 'Figma', 'UI/UX'],
    },
    {
      'id': '102',
      'title': 'Market Research on AI Tools',
      'company': 'Google',
      'duration': '3-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Analyze competitive AI frameworks and evaluate enterprise impact.',
      'skills': ['Research', 'Analysis'],
    },
    {
      'id': '103',
      'title': 'Social Media Content Creation',
      'company': 'Meta',
      'duration': '2-4 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Curate engaging educational content for campus developer circles.',
      'skills': ['Writing', 'Canva'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRecommendedProjects();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final name = user.userMetadata?['name'];
      if (name != null && name.toString().isNotEmpty) {
        setState(() {
          _studentName = name.toString();
        });
      }
    }
  }

  Future<void> _fetchRecommendedProjects() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false)
          .limit(4);

      final List<Map<String, dynamic>> loaded = [];
      for (var item in response) {
        loaded.add({
          'id': item['id']?.toString() ?? '',
          'title': item['title'] ?? 'Project',
          'company': item['company_name'] ?? 'Company',
          'duration': '3-5 days',
          'workMode': 'Remote',
          'status': item['status'] ?? 'Open',
          'description': item['description'] ?? '',
          'skills': ['Flutter', 'Research'],
        });
      }

      if (mounted) {
        setState(() {
          _recommendedProjects =
              loaded.isNotEmpty ? loaded : _defaultProjects;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recommendedProjects = _defaultProjects;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRecommendedProjects,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting & Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hello, $_studentName!',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('👋', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        Text(
                          'Explore projects and grow your skills',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: AppColors.deepNavy,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar Preview
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (widget.onTabChange != null) {
                      widget.onTabChange!(1); // Switch to Explore tab
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExploreProjectsScreen(),
                        ),
                      );
                    }
                  },
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
                            size: 20, color: AppColors.grayText),
                        const SizedBox(width: 10),
                        Text(
                          'Search for projects...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
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

                // Stats Cards Grid (Documentation Section 3 - Screen 1)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Applications',
                        '4',
                        Icons.send_rounded,
                        AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Active Projects',
                        '2',
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
                        '6',
                        Icons.check_circle_outline_rounded,
                        AppColors.statusOpen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Certificates',
                        '5',
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (widget.onTabChange != null) {
                          widget.onTabChange!(1);
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            'See All',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: AppColors.primaryBlue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Recommended Projects Cards
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: _recommendedProjects
                            .map((project) => _buildProjectCard(project))
                            .toList(),
                      ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(16),
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
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
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
        borderRadius: BorderRadius.circular(14),
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
                  'Open',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusOpen,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.bookmark_outline_rounded,
                size: 20,
                color: AppColors.grayText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
