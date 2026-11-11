import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/section_header.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/company_dashboard_data.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicants_screen.dart';
import 'assigned_projects_screen.dart';
import 'company_profile_screen.dart';
import 'company_project_detail_screen.dart';
import 'company_projects_list_screen.dart';
import 'post_project_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  final VoidCallback? onOpenDrawer;
  final bool isDrawerOpen;

  const CompanyDashboardScreen({
    super.key,
    this.onTabChange,
    this.onOpenDrawer,
    this.isDrawerOpen = false,
  });

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final _profileService = CompanyProfileService();
  final _projectService = CompanyProjectService();
  final _applicantService = CompanyApplicantService();
  final _assignmentService = CompanyAssignmentService();

  bool _isLoading = true;
  String? _errorMessage;

  bool get _drawerOpen => widget.isDrawerOpen;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await CompanyProfileService.loadAllCompanyPanelData();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to synchronize corporate workspace. Pull to retry.';
        });
      }
    }
  }

  List<CompanyActivityItem> _deriveRecentActivities(
    List<ProjectModel> projects,
    List<ApplicantModel> applicants,
    List<AssignmentModel> assignments,
  ) {
    final List<CompanyActivityItem> items = [];

    for (final a in assignments.where((x) => x.hasSubmission).take(3)) {
      items.add(
        CompanyActivityItem(
          id: 'sub_${a.id}',
          title: a.submissionStatus == 'Approved'
              ? 'Deliverable Approved'
              : 'Milestone Deliverable Submitted',
          subtitle:
              '${a.studentName} (${a.submissionStatus}) on "${a.projectTitle}"',
          timeAgo: a.latestSubmission?.submittedDate ?? 'Recently',
          type: CompanyActivityType.submission,
          projectId: a.projectId,
        ),
      );
    }

    for (final app in applicants.take(4)) {
      final cgpaText = app.cgpa > 0
          ? ' • CGPA ${app.cgpa.toStringAsFixed(2)}'
          : '';
      items.add(
        CompanyActivityItem(
          id: 'app_${app.id}',
          title: app.status == 'Accepted'
              ? 'Candidate Hired'
              : app.status == 'Shortlisted'
                  ? 'Candidate Shortlisted'
                  : 'New Student Application',
          subtitle:
              '${app.name} (${app.university}) for "${app.projectTitle}"$cgpaText',
          timeAgo: app.appliedDate,
          type: CompanyActivityType.application,
          projectId: app.projectId,
        ),
      );
    }

    for (final p in projects.take(3)) {
      items.add(
        CompanyActivityItem(
          id: 'proj_${p.id}',
          title: p.status == 'Completed'
              ? 'Challenge Completed'
              : p.status == 'Draft'
                  ? 'Project Saved as Draft'
                  : 'Project Listing Active',
          subtitle:
              '"${p.title}" • ${p.applicantsCount} application(s) • ${p.status}',
          timeAgo: p.createdAt,
          type: p.status == 'Completed'
              ? CompanyActivityType.statusUpdate
              : CompanyActivityType.projectActivity,
          projectId: p.id,
        ),
      );
    }

    return items.take(6).toList();
  }

  Future<void> _navigateToCreateProject() async {
    if (_profileService.isSuspended) {
      _showSuspendedSnack();
      return;
    }

    if (widget.onTabChange != null) {
      widget.onTabChange!(2);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostProjectScreen(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corporate project listings updated.'),
          backgroundColor: AppColors.statusOpen,
        ),
      );
    }
  }

  Future<void> _navigateToCompanyProfile({bool editMode = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProfileScreen(startInEditMode: editMode),
      ),
    );
  }

  void _navigateToApplicants() {
    if (widget.onTabChange != null) {
      widget.onTabChange!(3);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicantsScreen(),
      ),
    );
  }

  void _navigateToAssignedProjects() {
    if (widget.onTabChange != null) {
      widget.onTabChange!(4);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignedProjectsScreen(),
      ),
    );
  }

  void _navigateToProjectsView({String filter = 'All'}) {
    if (widget.onTabChange != null) {
      widget.onTabChange!(1);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProjectsListScreen(initialFilter: filter),
      ),
    );
  }

  void _showSuspendedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _profileService.suspensionReason?.isNotEmpty == true
              ? 'Account suspended: ${_profileService.suspensionReason}'
              : 'Your company account is currently suspended by governance administrators.',
        ),
        backgroundColor: AppColors.statusClosed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeScaffold();
  }

  Widget _buildHomeScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            SkillBridgeLogo(
              size: 38,
              circular: false,
              borderRadius: 11,
              shadows: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SkillBridge',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavy,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Corporate Portal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.grayText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: ListenableBuilder(
                listenable: AppDataService.instance,
                builder: (context, _) {
                  final totalUnread = AppDataService.instance
                      .getConversations()
                      .fold<int>(
                        0,
                        (sum, c) => sum + ((c['unread'] as int?) ?? 0),
                      );

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Tooltip(
                        message: 'Open Workspace Menu',
                        child: Material(
                          color: _drawerOpen
                              ? AppColors.lightAqua
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: widget.onOpenDrawer,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _drawerOpen
                                      ? AppColors.primaryBlue.withValues(
                                          alpha: 0.45,
                                        )
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Icon(
                                  _drawerOpen
                                      ? Icons.close_rounded
                                      : Icons.menu_rounded,
                                  key: ValueKey<bool>(_drawerOpen),
                                  color: AppColors.deepNavy,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (totalUnread > 0 && !_drawerOpen)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusClosed,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.8,
                                ),
                              ),
                              child: Text(
                                totalUnread > 9 ? '9+' : '$totalUnread',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.lightGray.withValues(alpha: 0.75),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryBlue,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Synchronizing Corporate Workspace...',
              style: GoogleFonts.inter(
                color: AppColors.grayText,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.statusClosed,
              title: 'Sync Unavailable',
              subtitle: _errorMessage!,
              actionLabel: 'Retry Sync',
              actionIcon: Icons.refresh_rounded,
              onAction: _loadDashboardData,
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<CompanyProfileModel>(
      valueListenable: _profileService.currentProfileNotifier,
      builder: (context, profile, _) {
        return ValueListenableBuilder<List<ProjectModel>>(
          valueListenable: _projectService.projectsNotifier,
          builder: (context, projects, _) {
            return ValueListenableBuilder<List<ApplicantModel>>(
              valueListenable: _applicantService.applicantsNotifier,
              builder: (context, applicants, _) {
                return ValueListenableBuilder<List<AssignmentModel>>(
                  valueListenable: _assignmentService.assignmentsNotifier,
                  builder: (context, assignments, _) {
                        final stats = CompanyDashboardStats(
                          totalPostedProjects: projects.length,
                          activeProjects: projects
                              .where(
                                (p) =>
                                    p.status == 'Open' ||
                                    p.status == 'In Progress',
                              )
                              .length,
                          completedProjects: projects
                              .where((p) => p.status == 'Completed')
                              .length,
                          pendingApplications: applicants
                              .where(
                                (a) =>
                                    a.status == 'Pending' ||
                                    a.status == 'Under Review',
                              )
                              .length,
                        );

                        final activities = _deriveRecentActivities(
                          projects,
                          applicants,
                          assignments,
                        );

                        return RefreshIndicator(
                          onRefresh: _loadDashboardData,
                          color: AppColors.primaryBlue,
                          backgroundColor: Colors.white,
                          child: LayoutBuilder(
                            builder: (context, viewportConstraints) {
                              final maxWidth = viewportConstraints.maxWidth;
                              final isDesktop = maxWidth >= 900;
                              final isTabletOrWide = maxWidth >= 660;
                              final isCompact = maxWidth < 340;

                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  32,
                                ),
                                children: [
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1040,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_profileService.isSuspended) ...[
                                            _buildSuspendedBanner(),
                                            const SizedBox(height: 16),
                                          ],
                                          _buildWelcomeCard(
                                            profile: profile,
                                            stats: stats,
                                            totalApplicants: applicants.length,
                                            showWideEditLabel:
                                                maxWidth >= 520,
                                          ),
                                          const SizedBox(height: 24),
                                          _buildSummaryStatsGrid(
                                            stats: stats,
                                            isWide: isTabletOrWide,
                                            isCompact: isCompact,
                                          ),
                                          const SizedBox(height: 26),
                                          _buildQuickActionsSection(
                                            totalApplicants: applicants.length,
                                            isWide: isTabletOrWide,
                                            isCompact: isCompact,
                                          ),
                                          const SizedBox(height: 28),
                                          if (isDesktop)
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 6,
                                                  child:
                                                      _buildActiveProjectsSpotlight(
                                                        projects,
                                                      ),
                                                ),
                                                const SizedBox(width: 22),
                                                Expanded(
                                                  flex: 4,
                                                  child:
                                                      _buildRecentActivitySection(
                                                        activities,
                                                      ),
                                                ),
                                              ],
                                            )
                                          else ...[
                                            _buildActiveProjectsSpotlight(
                                              projects,
                                            ),
                                            const SizedBox(height: 26),
                                            _buildRecentActivitySection(
                                              activities,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
      },
    );
  }

  Widget _buildSuspendedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusClosed.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gpp_bad_rounded, color: AppColors.statusClosed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organization Account Suspended',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusClosed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _profileService.suspensionReason?.isNotEmpty == true
                      ? _profileService.suspensionReason!
                      : 'New project posting is paused. Contact governance support from Settings.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard({
    required CompanyProfileModel profile,
    required CompanyDashboardStats stats,
    required int totalApplicants,
    required bool showWideEditLabel,
  }) {
    final displayName = profile.companyName.trim().isNotEmpty
        ? profile.companyName.trim()
        : 'Set Up Company Profile';
    final initial = profile.logoInitial.trim().isNotEmpty
        ? profile.logoInitial.trim()
        : SupabaseHelper.initialsFor(displayName, fallback: 'CO');

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -36,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 84,
              bottom: -48,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToCompanyProfile(editMode: false),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.poppins(
                                  color: AppColors.deepNavy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.industry.isNotEmpty
                                      ? profile.industry
                                      : 'Corporate Workspace',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (profile.officialEmail
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.mail_outline_rounded,
                                        color: Colors.white70,
                                        size: 13.5,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          profile.officialEmail,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withValues(
                                              alpha: 0.86,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Edit Profile',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _navigateToCompanyProfile(editMode: true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: showWideEditLabel ? 12 : 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                    if (showWideEditLabel) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        'Edit',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildHeroMicroStat(
                              icon: Icons.folder_copy_outlined,
                              label:
                                  '${stats.activeProjects} Active Challenge${stats.activeProjects == 1 ? '' : 's'}',
                            ),
                            _buildHeroMicroStat(
                              icon: Icons.people_outline_rounded,
                              label:
                                  '$totalApplicants Applicant${totalApplicants == 1 ? '' : 's'}',
                            ),
                            _buildHeroMicroStat(
                              icon: Icons.verified_outlined,
                              label: '${stats.completedProjects} Completed',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMicroStat({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.lightAqua),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStatsGrid({
    required CompanyDashboardStats stats,
    required bool isWide,
    required bool isCompact,
  }) {
    final cards = [
      _buildStatCard(
        title: 'Total Projects',
        subtitle: 'All listings',
        count: '${stats.totalPostedProjects}',
        icon: Icons.folder_copy_outlined,
        iconColor: AppColors.primaryBlue,
        bgColor: AppColors.lightAqua,
        onTap: () => _navigateToProjectsView(filter: 'All'),
      ),
      _buildStatCard(
        title: 'Active Challenges',
        subtitle: 'Open & in progress',
        count: '${stats.activeProjects}',
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.teal,
        bgColor: const Color(0xFFCFFAFE),
        onTap: () => _navigateToProjectsView(filter: 'Open'),
      ),
      _buildStatCard(
        title: 'Completed',
        subtitle: 'Delivered & certified',
        count: '${stats.completedProjects}',
        icon: Icons.verified_outlined,
        iconColor: AppColors.statusOpen,
        bgColor: AppColors.successBg,
        onTap: () => _navigateToProjectsView(filter: 'Completed'),
      ),
      _buildStatCard(
        title: 'Pending Review',
        subtitle: 'Applicant pipeline',
        count: '${stats.pendingApplications}',
        icon: Icons.people_outline_rounded,
        iconColor: AppColors.statusPending,
        bgColor: AppColors.warningBg,
        onTap: _navigateToApplicants,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Workspace Overview',
          subtitle: 'Live corporate pipeline metrics',
        ),
        const SizedBox(height: 12),
        if (isCompact)
          Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
              const SizedBox(height: 12),
              cards[3],
            ],
          )
        else if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
          )
        else
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[3]),
                  ],
                ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.9)),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 3, color: iconColor),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, color: iconColor, size: 19),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_outward_rounded,
                              size: 13.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepNavy,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.grayText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection({
    required int totalApplicants,
    required bool isWide,
    required bool isCompact,
  }) {
    final tiles = [
      _buildActionTile(
        icon: Icons.add_circle_outline_rounded,
        label: 'Post Challenge',
        subLabel: 'Publish to SkillBridge',
        isPrimary: true,
        onTap: _navigateToCreateProject,
      ),
      _buildActionTile(
        icon: Icons.folder_open_rounded,
        label: 'Manage Projects',
        subLabel: 'Listings & drafts',
        iconColor: AppColors.primaryBlue,
        onTap: () => _navigateToProjectsView(filter: 'All'),
      ),
      _buildActionTile(
        icon: Icons.how_to_reg_outlined,
        label: 'Applicants',
        subLabel: totalApplicants > 0
            ? '$totalApplicants candidate(s)'
            : 'Review talent',
        iconColor: AppColors.statusPending,
        onTap: _navigateToApplicants,
      ),
      _buildActionTile(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Assigned Work',
        subLabel: 'Review deliverables',
        iconColor: AppColors.teal,
        onTap: _navigateToAssignedProjects,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Quick Actions',
          subtitle: 'Launch core recruitment workflows',
        ),
        const SizedBox(height: 12),
        if (isCompact)
          Column(
            children: [
              tiles[0],
              const SizedBox(height: 10),
              tiles[1],
              const SizedBox(height: 10),
              tiles[2],
              const SizedBox(height: 10),
              tiles[3],
            ],
          )
        else if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 10),
                Expanded(child: tiles[1]),
                const SizedBox(width: 10),
                Expanded(child: tiles[2]),
                const SizedBox(width: 10),
                Expanded(child: tiles[3]),
              ],
            ),
          )
        else
          Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: 10),
                    Expanded(child: tiles[1]),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[2]),
                    const SizedBox(width: 10),
                    Expanded(child: tiles[3]),
                  ],
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
    Color? iconColor,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    final tone = iconColor ?? AppColors.primaryBlue;
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? AppColors.brandGradient : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : AppColors.lightGray.withValues(alpha: 0.9),
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.18)
                        : tone.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : tone,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPrimary ? Colors.white : AppColors.deepNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isPrimary
                              ? Colors.white70
                              : AppColors.grayText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: isPrimary ? Colors.white70 : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveProjectsSpotlight(List<ProjectModel> projects) {
    final activeList = projects
        .where((p) => p.status == 'In Progress' || p.status == 'Open')
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Active Challenges',
          subtitle: activeList.isEmpty
              ? null
              : '${activeList.length} ongoing listing(s)',
          actionLabel: projects.isEmpty ? null : 'View All',
          onAction: () => _navigateToProjectsView(filter: 'All'),
        ),
        const SizedBox(height: 12),
        if (activeList.isEmpty)
          AppEmptyState(
            compact: true,
            icon: Icons.rocket_launch_outlined,
            title: 'No Active Projects Yet',
            subtitle:
                'Publish your first industry challenge so verified university students can apply.',
            actionLabel: 'Post First Challenge',
            actionIcon: Icons.add_rounded,
            onAction: _navigateToCreateProject,
          )
        else
          ...activeList.map(_buildProjectCard),
      ],
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final statusTone = StatusBadge.colorForStatus(project.status);
    final pct = (project.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.9)),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CompanyProjectDetailScreen(project: project),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.5,
                  width: double.infinity,
                  color: statusTone,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightAqua,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                project.category,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(label: project.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        project.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Execution Progress',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grayText,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: project.progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceAlt,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.teal,
                          ),
                          minHeight: 6.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_outlined,
                                size: 14,
                                color: AppColors.grayText,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Deadline: ${project.deadline}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.grayText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ApplicantsScreen(projectId: project.id),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.people_outline_rounded,
                              size: 16,
                            ),
                            label: Text(
                              '${project.applicantsCount} Applicant${project.applicantsCount == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(List<CompanyActivityItem> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Recent Activity',
          subtitle: 'Latest candidate and deliverable events',
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          const AppEmptyState(
            compact: true,
            icon: Icons.timeline_rounded,
            title: 'No Recent Activity',
            subtitle:
                'Events appear automatically when students apply or submit milestone work.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.lightGray.withValues(alpha: 0.9),
              ),
              boxShadow: AppColors.softShadow,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 58, color: AppColors.surfaceAlt),
              itemBuilder: (context, index) =>
                  _buildActivityItemTile(activities[index]),
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
        iconColor = AppColors.primaryBlue;
        bgBadgeColor = AppColors.lightAqua;
        break;
      case CompanyActivityType.submission:
        icon = Icons.upload_file_rounded;
        iconColor = AppColors.teal;
        bgBadgeColor = const Color(0xFFCFFAFE);
        break;
      case CompanyActivityType.statusUpdate:
        icon = Icons.verified_rounded;
        iconColor = AppColors.statusOpen;
        bgBadgeColor = AppColors.successBg;
        break;
      case CompanyActivityType.projectActivity:
        icon = Icons.campaign_rounded;
        iconColor = AppColors.statusPending;
        bgBadgeColor = AppColors.warningBg;
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: bgBadgeColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.deepNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.timeAgo,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          item.subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.grayText,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
