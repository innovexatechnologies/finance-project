import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/section_header.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/core/widgets/student_avatar.dart';
import 'package:link_vibe/feature/student/applications/presentation/screens/my_applications_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';
import 'package:link_vibe/feature/student/saved/presentation/screens/saved_projects_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  final VoidCallback? onOpenDrawer;

  const StudentHomeScreen({
    super.key,
    this.onTabChange,
    this.onOpenDrawer,
  });

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
        final email = (profile['email']?.toString().trim().isNotEmpty == true)
            ? profile['email'].toString().trim()
            : AppDataService.instance.userEmail.trim();

        final openProjects = AppDataService.instance.getOpenProjects();
        final recommendedProjects = openProjects.take(4).toList();

        final totalApps = AppDataService.instance.totalApplicationsCount;
        final activeProjects = AppDataService.instance.activeProjectsCount;
        final completedProjects =
            AppDataService.instance.completedProjectsCount;
        final certs = AppDataService.instance.certificatesCount;
        final totalUnreadChats = AppDataService.instance
            .getConversations()
            .fold<int>(0, (sum, c) => sum + ((c['unread'] as int?) ?? 0));

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
                        'Student Workspace',
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
                padding: EdgeInsets.only(
                  right: widget.onOpenDrawer != null ? 8 : 14,
                ),
                child: Center(
                  child: ExecutiveHeaderIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: 'Messages',
                    badgeCount: totalUnreadChats,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatListScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (widget.onOpenDrawer != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: ExecutiveHeaderIconButton(
                      icon: Icons.menu_rounded,
                      tooltip: 'Open Workspace Menu',
                      onPressed: widget.onOpenDrawer,
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
          body: RefreshIndicator(
            color: AppColors.primaryBlue,
            backgroundColor: Colors.white,
            onRefresh: () =>
                AppDataService.instance.syncFromSupabase(forceRefresh: true),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final isWide = maxWidth >= 660;
                final isCompact = maxWidth < 340;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Executive Student Welcome Card
                            ExecutiveHeroBanner(
                              initial: SupabaseHelper.initialsFor(
                                studentName,
                                fallback: 'ST',
                              ),
                              subtitle: university.isNotEmpty
                                  ? university
                                  : 'Verified Student Workspace',
                              title: 'Welcome, $studentName',
                              secondaryLine: email.isNotEmpty
                                  ? email
                                  : 'Collaborate with verified companies',
                              onMonogramTap: () => widget.onTabChange?.call(3),
                              leadingVisual: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.14),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: StudentAvatar(
                                    name: studentName,
                                    avatarUrl: profile['avatarUrl']?.toString(),
                                    avatarBase64:
                                        profile['avatarBase64']?.toString(),
                                    size: 52,
                                    borderWidth: 0,
                                  ),
                                ),
                              ),
                              trailingAction: Tooltip(
                                message: 'Edit Profile',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => widget.onTabChange?.call(3),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: maxWidth >= 520 ? 12 : 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                        if (maxWidth >= 520) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            'Profile',
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
                              bottomContent: Container(
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
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    ExecutiveHeroMicroStat(
                                      icon: Icons.send_outlined,
                                      label:
                                          '$totalApps Application${totalApps == 1 ? '' : 's'}',
                                    ),
                                    ExecutiveHeroMicroStat(
                                      icon: Icons.work_outline_rounded,
                                      label: '$activeProjects Active Work',
                                    ),
                                    ExecutiveHeroMicroStat(
                                      icon: Icons.workspace_premium_outlined,
                                      label:
                                          '$certs Certificate${certs == 1 ? '' : 's'}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Executive Search Bar Trigger
                            Material(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _openExplore,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: AppColors.lightGray),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightAqua,
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                          Icons.search_rounded,
                                          color: AppColors.primaryBlue,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
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
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightAqua,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${openProjects.length} Open',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // KPI Workspace Overview Grid
                            _buildOverviewGrid(
                              totalApps: totalApps,
                              activeProjects: activeProjects,
                              completedProjects: completedProjects,
                              certs: certs,
                              isWide: isWide,
                              isCompact: isCompact,
                            ),
                            const SizedBox(height: 24),

                            // Executive Quick Actions Section
                            const SectionHeader(
                              title: 'Quick Actions',
                              subtitle:
                                  'Explore projects, certificates & company messages',
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionsGrid(
                              isWide: isWide,
                              isCompact: isCompact,
                              unreadChats: totalUnreadChats,
                            ),
                            const SizedBox(height: 26),

                            // Live Opportunities Section
                            SectionHeader(
                              title: 'Live Open Opportunities',
                              subtitle: openProjects.isEmpty
                                  ? 'Synced from SkillBridge partner catalog'
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
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewGrid({
    required int totalApps,
    required int activeProjects,
    required int completedProjects,
    required int certs,
    required bool isWide,
    required bool isCompact,
  }) {
    final cards = [
      ExecutiveStatCard(
        title: 'Applications',
        subtitle: 'Submitted proposals',
        count: '$totalApps',
        icon: Icons.send_rounded,
        iconColor: AppColors.primaryBlue,
        bgColor: AppColors.lightAqua,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
          );
        },
      ),
      ExecutiveStatCard(
        title: 'Active Work',
        subtitle: 'Assigned engagements',
        count: '$activeProjects',
        icon: Icons.play_circle_outline_rounded,
        iconColor: AppColors.teal,
        bgColor: const Color(0xFFCFFAFE),
        onTap: () => widget.onTabChange?.call(2),
      ),
      ExecutiveStatCard(
        title: 'Completed',
        subtitle: 'Delivered milestones',
        count: '$completedProjects',
        icon: Icons.verified_outlined,
        iconColor: AppColors.statusOpen,
        bgColor: AppColors.successBg,
        onTap: () => widget.onTabChange?.call(2),
      ),
      ExecutiveStatCard(
        title: 'Certificates',
        subtitle: 'Verified credentials',
        count: '$certs',
        icon: Icons.workspace_premium_rounded,
        iconColor: AppColors.statusPending,
        bgColor: AppColors.warningBg,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CertificatesScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Workspace Overview',
          subtitle: 'Live academic & project pipeline metrics',
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

  Widget _buildQuickActionsGrid({
    required bool isWide,
    required bool isCompact,
    required int unreadChats,
  }) {
    final tiles = [
      _buildActionTile(
        icon: Icons.explore_rounded,
        title: 'Explore Projects',
        subtitle: 'Browse opportunities',
        color: AppColors.primaryBlue,
        bgColor: AppColors.lightAqua,
        onTap: _openExplore,
      ),
      _buildActionTile(
        icon: Icons.workspace_premium_rounded,
        title: 'Certificates',
        subtitle: 'Download & share',
        color: AppColors.teal,
        bgColor: const Color(0xFFCFFAFE),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CertificatesScreen()),
          );
        },
      ),
      _buildActionTile(
        icon: Icons.bookmark_outline_rounded,
        title: 'Saved Projects',
        subtitle: 'Bookmarked list',
        color: const Color(0xFFD97706),
        bgColor: AppColors.warningBg,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedProjectsScreen()),
          );
        },
      ),
      _buildActionTile(
        icon: Icons.chat_bubble_outline_rounded,
        title: unreadChats > 0 ? 'Messages ($unreadChats)' : 'Messages',
        subtitle: 'Company chat',
        color: AppColors.indigoAccent,
        bgColor: const Color(0xFFEDE9FE),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          );
        },
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          tiles[0],
          const SizedBox(height: 10),
          tiles[1],
          const SizedBox(height: 10),
          tiles[2],
          const SizedBox(height: 10),
          tiles[3],
        ],
      );
    }
    if (isWide) {
      return IntrinsicHeight(
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
      );
    }
    return Column(
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
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGray),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
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
              ),
            ],
          ),
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
    final workMode = project['workMode']?.toString().trim() ?? 'Remote';
    final status = project['status']?.toString() ?? 'Open';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentProjectDetailsScreen(project: project),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lightAqua,
                        AppColors.primaryBlue.withValues(alpha: 0.14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      SupabaseHelper.initialsFor(companyName, fallback: 'CO'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$companyName • $workMode • $duration',
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
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Share Project',
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
                  padding: const EdgeInsets.all(6),
                  tooltip: isSaved ? 'Remove Bookmark' : 'Save Project',
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
      ),
    );
  }
}
