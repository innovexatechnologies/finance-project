import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
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

  final List<Map<String, dynamic>> _activeProjects = [
    {
      'title': 'Flutter App Mobile UI Development',
      'company': 'TechVista',
      'assignedDate': 'Nov 04, 2026',
      'dueDate': 'Nov 15, 2026',
      'status': 'In Progress',
      'description':
          'Build responsive student dashboard widgets and integrate user state.',
      'skills': ['Flutter', 'Figma', 'UI/UX'],
    },
    {
      'title': 'Market Research on AI Tools',
      'company': 'Google',
      'assignedDate': 'Oct 28, 2026',
      'dueDate': 'Nov 18, 2026',
      'status': 'Revision Requested',
      'description':
          'Analyze competitive AI frameworks and evaluate enterprise impact.',
      'skills': ['Research', 'Analysis'],
    },
  ];

  final List<Map<String, dynamic>> _completedProjects = [
    {
      'title': 'Barcode Scanning Mobile Utility',
      'company': 'CodeCraft Solutions',
      'assignedDate': 'Oct 10, 2026',
      'dueDate': 'Oct 25, 2026',
      'status': 'Completed',
      'description': 'Developed high-performance camera barcode reader module.',
      'skills': ['Dart', 'Flutter'],
    },
  ];

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.statusOpen;
      case 'revision requested':
        return const Color(0xFFD97706);
      case 'under review':
        return AppColors.teal;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Active Projects'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Projects List
          _buildProjectsList(_activeProjects, isActive: true),
          // Completed Projects List
          _buildProjectsList(_completedProjects, isActive: false),
        ],
      ),
    );
  }

  Widget _buildProjectsList(
    List<Map<String, dynamic>> list, {
    required bool isActive,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No projects in this category',
          style: GoogleFonts.inter(color: AppColors.grayText),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final project = list[index];
        final status = project['status'] ?? 'Active';
        final statusColor = _getStatusColor(status);
        final isRevision = status == 'Revision Requested';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.lightGray, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project['title'] ?? 'Project Title',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Company: ${project['company']}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 10),

                // Assigned & Due Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned: ${project['assignedDate']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                    Text(
                      'Due: ${project['dueDate']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.lightGray),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                        child: const Text('Instructions'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isActive)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRevision
                                ? const Color(0xFFD97706)
                                : AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (isRevision) {
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
                          child: Text(isRevision ? 'Feedback' : 'Submit Work'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
