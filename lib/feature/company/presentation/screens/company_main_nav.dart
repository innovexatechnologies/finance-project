import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/rubik_cube_transition.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_settings_service.dart';
import 'applicants_screen.dart';
import 'assigned_projects_screen.dart';
import 'company_dashboard.dart';
import 'company_messages_screen.dart';
import 'company_notifications_screen.dart';
import 'company_profile_screen.dart';
import 'company_projects_list_screen.dart';
import 'company_settings_screen.dart';
import 'post_project_screen.dart';

class CompanyMainNav extends StatefulWidget {
  final int initialIndex;

  const CompanyMainNav({super.key, this.initialIndex = 0});

  @override
  State<CompanyMainNav> createState() => _CompanyMainNavState();
}

class _CompanyMainNavState extends State<CompanyMainNav> {
  late int _currentIndex;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;
  GlobalKey<ScaffoldState>? _scaffoldKeyCache;
  bool? _isSyncingWorkspace;

  GlobalKey<ScaffoldState> get _scaffoldKey =>
      _scaffoldKeyCache ??= GlobalKey<ScaffoldState>();
  bool get _isSyncing => _isSyncingWorkspace ?? false;

  CompanyProfileService get _profileService => CompanyProfileService();
  CompanySettingsService get _settingsService => CompanySettingsService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabHistory.clear();
    _tabHistory.add(widget.initialIndex);
  }

  void _onTabChange(int index) {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      _closeDrawer();
    }
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  Future<void> _syncWorkspaceFromDrawer() async {
    if (_isSyncing) return;
    setState(() => _isSyncingWorkspace = true);
    try {
      await CompanyProfileService.loadAllCompanyPanelData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workspace synchronized'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not refresh workspace right now'),
          backgroundColor: AppColors.statusClosed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncingWorkspace = false);
      }
    }
  }

  void _openDrawerScreen(Widget screen) {
    _closeDrawer();
    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.deepNavy,
          ),
        ),
        content: Text(
          'You will be signed out of your corporate session on this device.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _settingsService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.statusClosed,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account?',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This permanently removes your company profile, posted projects, messages, and notifications from this workspace. This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.darkText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusClosed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final ok = await _settingsService.deleteAccount();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _settingsService.lastError ?? 'Could not delete account right now.',
          ),
          backgroundColor: AppColors.statusClosed,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.80).clamp(260.0, 320.0).toDouble();

    final screens = [
      CompanyDashboardScreen(
        onTabChange: _onTabChange,
        onOpenDrawer: _openDrawer,
      ),
      CompanyProjectsListScreen(onTabChange: _onTabChange),
      PostProjectScreen(onTabChange: _onTabChange),
      ApplicantsScreen(onTabChange: _onTabChange),
      AssignedProjectsScreen(onTabChange: _onTabChange),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          _closeDrawer();
          return;
        }

        // 1. Agar multiple tabs visit kiye hain tu step-by-step pichhle tab par wapis jayein
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _currentIndex = _tabHistory.last;
          });
          return;
        }

        // 2. Agar current tab Home (index 0) nahi hai, pehle Home screen par ayein
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _tabHistory.clear();
            _tabHistory.add(0);
          });
          return;
        }

        // 3. User ab Home screen par hai; 2 second window mein dobara back press se hi exit ho
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Press back again to exit CampusConnect',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.deepNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        // Home screen par dobara press hua -> cleanly exit app
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawerEnableOpenDragGesture: _currentIndex == 0,
        endDrawer: _buildStandardDrawer(drawerWidth),
        body: RubikCubeTabView(
          currentIndex: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: ValueListenableBuilder<List<ApplicantModel>>(
                valueListenable: CompanyApplicantService().applicantsNotifier,
                builder: (context, applicants, _) {
                  return ValueListenableBuilder<List<AssignmentModel>>(
                    valueListenable:
                        CompanyAssignmentService().assignmentsNotifier,
                    builder: (context, assignments, _) {
                      final pendingApplicants = applicants
                          .where((a) =>
                              a.status == 'Pending' ||
                              a.status == 'Under Review')
                          .length;

                      final pendingDeliverables = assignments
                          .where((a) =>
                              a.hasSubmission &&
                              (a.submissionStatus == 'Pending Review' ||
                                  a.submissionStatus == 'Submitted'))
                          .length;

                      return BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: _onTabChange,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        type: BottomNavigationBarType.fixed,
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedItemColor: AppColors.primaryBlue,
                        unselectedItemColor: AppColors.grayText,
                        selectedFontSize: 11,
                        unselectedFontSize: 11,
                        selectedLabelStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.home_outlined),
                            activeIcon: Icon(Icons.home_rounded),
                            label: 'Home',
                            tooltip: 'Home',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.business_center_outlined),
                            activeIcon: Icon(Icons.business_center_rounded),
                            label: 'Projects',
                            tooltip: 'Projects',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.add_circle_outline_rounded),
                            activeIcon: Icon(Icons.add_circle_rounded),
                            label: 'Post',
                            tooltip: 'Post Project',
                          ),
                          BottomNavigationBarItem(
                            icon: Badge(
                              isLabelVisible: pendingApplicants > 0,
                              label: Text(
                                pendingApplicants > 99
                                    ? '99+'
                                    : '$pendingApplicants',
                              ),
                              child: const Icon(Icons.people_outline_rounded),
                            ),
                            activeIcon: Badge(
                              isLabelVisible: pendingApplicants > 0,
                              label: Text(
                                pendingApplicants > 99
                                    ? '99+'
                                    : '$pendingApplicants',
                              ),
                              child: const Icon(Icons.people_rounded),
                            ),
                            label: 'Applicants',
                            tooltip: 'Applicants',
                          ),
                          BottomNavigationBarItem(
                            icon: Badge(
                              isLabelVisible: pendingDeliverables > 0,
                              label: Text(
                                pendingDeliverables > 99
                                    ? '99+'
                                    : '$pendingDeliverables',
                              ),
                              child: const Icon(
                                  Icons.assignment_turned_in_outlined),
                            ),
                            activeIcon: Badge(
                              isLabelVisible: pendingDeliverables > 0,
                              label: Text(
                                pendingDeliverables > 99
                                    ? '99+'
                                    : '$pendingDeliverables',
                              ),
                              child: const Icon(
                                  Icons.assignment_turned_in_rounded),
                            ),
                            label: 'Deliverables',
                            tooltip: 'Deliverables',
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardDrawer(double drawerWidth) {
    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<CompanyProfileModel>(
                valueListenable: _profileService.currentProfileNotifier,
                builder: (_, profile, _) {
                  return ListenableBuilder(
                    listenable: AppDataService.instance,
                    builder: (_, _) {
                      final displayName =
                          profile.companyName.trim().isNotEmpty
                              ? profile.companyName.trim()
                              : 'Set Up Company Profile';
                      final initial = profile.logoInitial.trim().isNotEmpty
                          ? profile.logoInitial.trim()
                          : SupabaseHelper.initialsFor(
                              displayName,
                              fallback: 'CO',
                            );
                      final subtitle = profile.industry.trim().isNotEmpty
                          ? profile.industry.trim()
                          : (profile.officialEmail.trim().isNotEmpty
                              ? profile.officialEmail.trim()
                              : 'Corporate Workspace');

                      final unreadNotifs =
                          AppDataService.instance.unreadNotificationsCount;
                      final unreadChats = AppDataService.instance
                          .getConversations()
                          .fold<int>(
                            0,
                            (sum, c) => sum + ((c['unread'] as int?) ?? 0),
                          );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.deepNavy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: AppColors.grayText,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: _closeDrawer,
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: AppColors.deepNavy,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            color: AppColors.surfaceAlt,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildDrawerMenuRow(
                                    icon: Icons.home_rounded,
                                    accentColor: AppColors.primaryBlue,
                                    title: 'Home',
                                    isSelected: _currentIndex == 0,
                                    onTap: () => _onTabChange(0),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDrawerMenuRow(
                                    icon: Icons.notifications_outlined,
                                    accentColor: AppColors.primaryBlue,
                                    title: 'Notifications',
                                    badgeCount: unreadNotifs,
                                    onTap: () => _openDrawerScreen(
                                      const CompanyNotificationsScreen(),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDrawerMenuRow(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    accentColor: AppColors.teal,
                                    title: 'Messages',
                                    badgeCount: unreadChats,
                                    onTap: () => _openDrawerScreen(
                                      const CompanyMessagesScreen(),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDrawerMenuRow(
                                    icon: Icons.business_outlined,
                                    accentColor: AppColors.deepNavy,
                                    title: 'Company Profile',
                                    onTap: () => _openDrawerScreen(
                                      const CompanyProfileScreen(),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDrawerMenuRow(
                                    icon: Icons.settings_outlined,
                                    accentColor: AppColors.indigoAccent,
                                    title: 'Settings',
                                    onTap: () => _openDrawerScreen(
                                      const CompanySettingsScreen(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            color: AppColors.surfaceAlt,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.deepNavy,
                                          side: const BorderSide(
                                            color: AppColors.borderLight,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(11),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: _syncWorkspaceFromDrawer,
                                        icon: _isSyncing
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.refresh_rounded,
                                                size: 16,
                                              ),
                                        label: Text(
                                          'Sync',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.deepNavy,
                                          side: const BorderSide(
                                            color: AppColors.borderLight,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(11),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: _confirmSignOut,
                                        icon: const Icon(
                                          Icons.logout_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          'Sign Out',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.statusClosed,
                                      backgroundColor: AppColors.errorBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                    ),
                                    onPressed: _confirmDeleteAccount,
                                    icon: const Icon(
                                      Icons.delete_forever_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      'Delete Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
  }

  Widget _buildDrawerMenuRow({
    required IconData icon,
    required Color accentColor,
    required String title,
    int badgeCount = 0,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? accentColor.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: isSelected ? 0.14 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? accentColor : AppColors.deepNavy,
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isSelected
                    ? accentColor
                    : AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

