import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/student_avatar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/student/applications/presentation/screens/my_applications_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/home/presentation/screens/student_home_screen.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';
import 'package:link_vibe/feature/student/my_projects/presentation/screens/my_projects_screen.dart';
import 'package:link_vibe/feature/student/profile/presentation/screens/student_profile_screen.dart';
import 'package:link_vibe/feature/student/saved/presentation/screens/saved_projects_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/settings_screen.dart';

class StudentMainNav extends StatefulWidget {
  final int initialIndex;

  const StudentMainNav({super.key, this.initialIndex = 0});

  @override
  State<StudentMainNav> createState() => _StudentMainNavState();
}

class _StudentMainNavState extends State<StudentMainNav> {
  late int _currentIndex;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSyncing = false;

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

  Future<void> _syncWorkspaceFromDrawer() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await AppDataService.instance.syncFromSupabase(forceRefresh: true);
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
      if (mounted) setState(() => _isSyncing = false);
    }
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
          'You will be signed out of your student session on this device.',
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
    await AdminAuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(initialRole: 'Student'),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.80).clamp(260.0, 320.0).toDouble();

    final screens = [
      StudentHomeScreen(
        onTabChange: _onTabChange,
        onOpenDrawer: _openDrawer,
      ),
      const ExploreProjectsScreen(),
      const MyProjectsScreen(),
      StudentProfileScreen(onTabChange: _onTabChange),
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
                    'Press back again to exit SkillBridge',
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
        body: IndexedStack(
          key: const ValueKey('student_nav_stack'),
          index: _currentIndex.clamp(0, screens.length - 1),
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppColors.borderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
              child: BottomNavigationBar(
                currentIndex: _currentIndex.clamp(0, 3),
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
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore_rounded),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.business_center_outlined),
                    activeIcon: Icon(Icons.business_center_rounded),
                    label: 'My Projects',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
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
        child: ListenableBuilder(
          listenable: AppDataService.instance,
          builder: (_, _) {
            final profile = AppDataService.instance.getProfile();
            final rawName = profile['name']?.toString().trim() ?? '';
            final displayName = rawName.isNotEmpty
                ? rawName
                : (AppDataService.instance.userName.trim().isNotEmpty
                      ? AppDataService.instance.userName.trim()
                      : 'Student Workspace');
            final uni = profile['university']?.toString().trim() ?? '';
            final subtitle = uni.isNotEmpty
                ? uni
                : (AppDataService.instance.userEmail.isNotEmpty
                      ? AppDataService.instance.userEmail
                      : 'Verified Talent Profile');

            final savedCount = AppDataService.instance.getSavedProjects().length;
            final certCount = AppDataService.instance.certificatesCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                  child: Row(
                    children: [
                      StudentAvatar(
                        name: displayName,
                        avatarUrl: profile['avatarUrl']?.toString(),
                        avatarBase64: profile['avatarBase64']?.toString(),
                        size: 44,
                        borderWidth: 1.5,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                const Divider(height: 1, color: AppColors.surfaceAlt),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDrawerMenuRow(
                          icon: Icons.send_outlined,
                          accentColor: AppColors.indigoAccent,
                          title: 'My Applications',
                          onTap: () =>
                              _openDrawerScreen(const MyApplicationsScreen()),
                        ),
                        const SizedBox(height: 4),
                        _buildDrawerMenuRow(
                          icon: Icons.bookmark_outline_rounded,
                          accentColor: AppColors.primaryBlue,
                          title: 'Saved Projects',
                          badgeCount: savedCount,
                          onTap: () =>
                              _openDrawerScreen(const SavedProjectsScreen()),
                        ),
                        const SizedBox(height: 4),
                        _buildDrawerMenuRow(
                          icon: Icons.workspace_premium_outlined,
                          accentColor: AppColors.statusPending,
                          title: 'Certificates',
                          badgeCount: certCount,
                          onTap: () =>
                              _openDrawerScreen(const CertificatesScreen()),
                        ),
                        const SizedBox(height: 4),
                        _buildDrawerMenuRow(
                          icon: Icons.settings_outlined,
                          accentColor: AppColors.deepNavy,
                          title: 'Settings & Help',
                          onTap: () =>
                              _openDrawerScreen(const SettingsScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.surfaceAlt),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.deepNavy,
                            side: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _syncWorkspaceFromDrawer,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryBlue,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
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
                              borderRadius: BorderRadius.circular(11),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _confirmSignOut,
                          icon: const Icon(Icons.logout_rounded, size: 16),
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
                ),
              ],
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

