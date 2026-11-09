import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/company_dashboard_data.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicants_screen.dart';
import 'company_profile_screen.dart';
import 'company_project_detail_screen.dart';
import 'company_projects_list_screen.dart';
import 'company_verification_screen.dart';
import 'post_project_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Logged-in Company Profile State
  CompanyProfileInfo _companyProfile = const CompanyProfileInfo(
    companyName: 'TechVista Innovations',
    tagline: 'Bridging Talent & High-Tech Projects',
    industry: 'Software & Cloud Services',
    isVerified: true,
    unreadNotificationsCount: 3,
  );

  // Corporate Dashboard Statistics State
  CompanyDashboardStats _stats = const CompanyDashboardStats(
    totalPostedProjects: 5,
    activeProjects: 3,
    completedProjects: 2,
    pendingApplications: 8,
  );

  // Projects list for the company
  List<ProjectModel> _projects = [];

  // Recent activity stream
  List<CompanyActivityItem> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Simulating clean asynchronous company data fetch
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final activeProfile = CompanyProfileService().currentProfile;
      _companyProfile = CompanyProfileInfo(
        companyName: activeProfile.companyName,
        tagline: activeProfile.industry,
        industry: activeProfile.industry,
        isVerified: activeProfile.isVerified,
        unreadNotificationsCount: _companyProfile.unreadNotificationsCount,
      );

      _projects = CompanyProjectService().projects;

      _recalculateStats();

      _activities = [
        const CompanyActivityItem(
          id: 'act_1',
          title: 'New Student Application',
          subtitle:
              'Ali Khan applied for "Flutter E-Commerce Mobile App" (CGPA: 3.8)',
          timeAgo: '12m ago',
          type: CompanyActivityType.application,
          projectId: 'proj_01',
        ),
        const CompanyActivityItem(
          id: 'act_2',
          title: 'Milestone 2 Submitted',
          subtitle:
              'Ayesha Ahmed uploaded milestone deliverables for "Sentiment Pipeline"',
          timeAgo: '45m ago',
          type: CompanyActivityType.submission,
          projectId: 'proj_03',
        ),
        const CompanyActivityItem(
          id: 'act_3',
          title: 'Project Status Updated',
          subtitle:
              '"Campus Ambassador Portal" verified and marked as Completed',
          timeAgo: '3h ago',
          type: CompanyActivityType.statusUpdate,
          projectId: 'proj_04',
        ),
        const CompanyActivityItem(
          id: 'act_4',
          title: 'Candidate Shortlisted',
          subtitle:
              'Bilal Shah shortlisted for "Barcode & QR Scanner Mobile Utility"',
          timeAgo: '1d ago',
          type: CompanyActivityType.projectActivity,
          projectId: 'proj_02',
        ),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load company dashboard data. Please retry.';
      });
    }
  }

  void _recalculateStats() {
    int active = 0;
    int completed = 0;
    int totalApps = 0;

    for (var project in _projects) {
      if (project.status == 'In Progress' || project.status == 'Open') {
        active++;
      } else if (project.status == 'Completed') {
        completed++;
      }
      totalApps += project.applicantsCount;
    }

    _stats = CompanyDashboardStats(
      totalPostedProjects: _projects.length,
      activeProjects: active,
      completedProjects: completed,
      pendingApplications: totalApps,
    );
  }

  // Update dashboard when a new project is created
  void _onProjectCreated(ProjectModel newProject) {
    setState(() {
      _projects.insert(0, newProject);
      _recalculateStats();
      _activities.insert(
        0,
        CompanyActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Project Published',
          subtitle: '"${newProject.title}" is now open for campus applications',
          timeAgo: 'Just now',
          type: CompanyActivityType.projectActivity,
          projectId: newProject.id,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dashboard updated: "${newProject.title}" is live!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // Navigation: Screen 25 (Post New Project)
  Future<void> _navigateToCreateProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostProjectScreen(),
      ),
    );

    if (result == true) {
      final latest = CompanyProjectService().allProjects.first;
      _onProjectCreated(latest);
    }
  }

  // Navigation: Screen 23 (Company Profile Setup / Edit)
  Future<void> _navigateToCompanyProfile({bool editMode = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProfileScreen(startInEditMode: editMode),
      ),
    );

    // Refresh company details on dashboard
    final activeProfile = CompanyProfileService().currentProfile;
    setState(() {
      _companyProfile = CompanyProfileInfo(
        companyName: activeProfile.companyName,
        tagline: activeProfile.industry,
        industry: activeProfile.industry,
        isVerified: activeProfile.isVerified,
        unreadNotificationsCount: _companyProfile.unreadNotificationsCount,
      );
    });
  }

  // Navigation: Screen 24 (Company Verification)
  void _navigateToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyVerificationScreen(),
      ),
    );
  }

  // Navigation: Screen 28 (Review Applicants)
  void _navigateToApplicants() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicantsScreen(),
      ),
    );
  }

  // Navigation: Screen 26 (View My Projects - Filtered)
  void _navigateToProjectsView({String filter = 'All'}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProjectsListScreen(initialFilter: filter),
      ),
    );
  }

  // Notifications Preview Dialog
  void _openNotificationsPreview() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Company Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_companyProfile.unreadNotificationsCount} Unread',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightIceBlue,
                  child: Icon(Icons.person_add, color: AppColors.primary, size: 20),
                ),
                title: Text('Ali Khan applied for E-Commerce App'),
                subtitle: Text('12 minutes ago'),
              ),
              const ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.warningBg,
                  child: Icon(Icons.upload_file, color: AppColors.warning, size: 20),
                ),
                title: Text('Ayesha Ahmed submitted Milestone 2'),
                subtitle: Text('45 minutes ago'),
              ),
              const ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successBg,
                  child: Icon(Icons.verified, color: AppColors.success, size: 20),
                ),
                title: Text('Ambassador Portal delivered successfully'),
                subtitle: Text('3 hours ago'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.lightIceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAMPUSCONNECT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.darkNavy,
                  ),
                ),
                Text(
                  'Corporate Dashboard',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.darkNavy,
                  size: 24,
                ),
                tooltip: 'Notifications',
                onPressed: _openNotificationsPreview,
              ),
              if (_companyProfile.unreadNotificationsCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_companyProfile.unreadNotificationsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Company Profile Setup / Edit Icon (Screen 23)
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.darkNavy,
              size: 24,
            ),
            tooltip: 'Company Profile (Screen 23)',
            onPressed: () => _navigateToCompanyProfile(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading Company Dashboard...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // 1. Welcome Card with Company Info & Logo
          _buildWelcomeCard(),
          const SizedBox(height: 20),

          // 2. Summary Statistics Grid (4 Cards)
          _buildSummaryStatsGrid(),
          const SizedBox(height: 24),

          // 3. Quick Action Buttons (4 Actions)
          _buildQuickActionsSection(),
          const SizedBox(height: 24),

          // 4. Active Projects Spotlight
          _buildActiveProjectsSpotlight(),
          const SizedBox(height: 24),

          // 5. Recent Activity Section
          _buildRecentActivitySection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. Welcome Card
  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.darkNavy,
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToCompanyProfile(editMode: false),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo / Profile Image
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _companyProfile.companyName.length >= 2
                          ? _companyProfile.companyName.substring(0, 2).toUpperCase()
                          : 'CO',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Welcome and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back, 👋',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _companyProfile.companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          InkWell(
                            onTap: _navigateToVerification,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accentTeal.withOpacity(0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: AppColors.accentTeal,
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Corporate Partner',
                                    style: TextStyle(
                                      color: AppColors.accentTeal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Profile Button (Screen 23 Shortcut)
                IconButton(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  tooltip: 'Edit Company Profile (Screen 23)',
                  onPressed: () => _navigateToCompanyProfile(editMode: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Summary Statistics 2x2 Grid
  Widget _buildSummaryStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview & Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            // Total Posted Projects
            _buildStatCard(
              title: 'Total Posted',
              subtitle: 'All listings',
              count: '${_stats.totalPostedProjects}',
              icon: Icons.folder_open_rounded,
              iconColor: AppColors.primary,
              bgColor: AppColors.lightIceBlue,
              onTap: () => _navigateToProjectsView(filter: 'All'),
            ),

            // Active Projects
            _buildStatCard(
              title: 'Active Projects',
              subtitle: 'In progress',
              count: '${_stats.activeProjects}',
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.accentTeal,
              bgColor: const Color(0xFFE0F7FA),
              onTap: () => _navigateToProjectsView(filter: 'Active'),
            ),

            // Completed Projects
            _buildStatCard(
              title: 'Completed',
              subtitle: 'Delivered',
              count: '${_stats.completedProjects}',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              bgColor: AppColors.successBg,
              onTap: () => _navigateToProjectsView(filter: 'Completed'),
            ),

            // Pending Applications
            _buildStatCard(
              title: 'Applications',
              subtitle: 'Awaiting review',
              count: '${_stats.pendingApplications}',
              icon: Icons.people_outline_rounded,
              iconColor: AppColors.warning,
              bgColor: AppColors.warningBg,
              onTap: _navigateToApplicants,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Quick Action Buttons
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Create New Project (Primary Blue)
            Expanded(
              child: _buildActionTile(
                icon: Icons.add_rounded,
                label: 'Create Project',
                subLabel: 'Screen 25',
                color: AppColors.primary,
                textColor: Colors.white,
                isPrimary: true,
                onTap: _navigateToCreateProject,
              ),
            ),
            const SizedBox(width: 10),

            // View My Projects
            Expanded(
              child: _buildActionTile(
                icon: Icons.folder_copy_outlined,
                label: 'My Projects',
                subLabel: 'Screen 26',
                color: Colors.white,
                textColor: AppColors.darkNavy,
                iconColor: AppColors.primary,
                onTap: () => _navigateToProjectsView(filter: 'All'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Review Applicants
            Expanded(
              child: _buildActionTile(
                icon: Icons.how_to_reg_outlined,
                label: 'Review Applicants',
                subLabel: 'Screen 28',
                color: Colors.white,
                textColor: AppColors.darkNavy,
                iconColor: AppColors.warning,
                onTap: _navigateToApplicants,
              ),
            ),
            const SizedBox(width: 10),

            // View Assigned Projects
            Expanded(
              child: _buildActionTile(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Assigned Work',
                subLabel: 'Screen 30',
                color: Colors.white,
                textColor: AppColors.darkNavy,
                iconColor: AppColors.accentTeal,
                onTap: () => _navigateToProjectsView(filter: 'Active'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required Color textColor,
    Color? iconColor,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : (iconColor ?? AppColors.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : (iconColor ?? AppColors.primary),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: isPrimary ? Colors.white70 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Active Projects Spotlight
  Widget _buildActiveProjectsSpotlight() {
    final activeList = _projects
        .where((p) => p.status == 'In Progress' || p.status == 'Open')
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Project Spotlight',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToProjectsView(filter: 'Active'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (activeList.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No active projects right now. Tap "Create Project" to get started.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...activeList.map((project) => _buildProjectCard(project)),
      ],
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyProjectDetailScreen(project: project),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.status == 'In Progress'
                        ? AppColors.warningBg
                        : AppColors.infoBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.status,
                    style: TextStyle(
                      color: project.status == 'In Progress'
                          ? AppColors.warning
                          : AppColors.info,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Milestone Progress',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(project.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),

            // Bottom Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: ${project.budget}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _navigateToApplicants,
                  icon: const Icon(Icons.people, size: 16),
                  label: Text('${project.applicantsCount} Applicants'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // 5. Recent Activity Section
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            Text(
              'Live Feed',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accentTeal.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No activity recorded recently.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 60,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final item = _activities[index];
                return _buildActivityItemTile(item);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItemTile(CompanyActivityItem item) {
    IconData icon;
    Color iconColor;
    Color bgBadgeColor;

    switch (item.type) {
      case CompanyActivityType.application:
        icon = Icons.person_add_alt_1_rounded;
        iconColor = AppColors.primary;
        bgBadgeColor = AppColors.lightIceBlue;
        break;
      case CompanyActivityType.submission:
        icon = Icons.upload_file_rounded;
        iconColor = AppColors.accentTeal;
        bgBadgeColor = const Color(0xFFE0F7FA);
        break;
      case CompanyActivityType.statusUpdate:
        icon = Icons.update_rounded;
        iconColor = AppColors.success;
        bgBadgeColor = AppColors.successBg;
        break;
      case CompanyActivityType.projectActivity:
        icon = Icons.campaign_rounded;
        iconColor = AppColors.warning;
        bgBadgeColor = AppColors.warningBg;
        break;
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgBadgeColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.darkNavy,
              ),
            ),
          ),
          Text(
            item.timeAgo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          item.subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
