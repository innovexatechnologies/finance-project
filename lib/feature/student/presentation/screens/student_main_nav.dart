import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/student/home/presentation/screens/student_home_screen.dart';
import 'package:link_vibe/feature/student/explore/presentation/screens/explore_projects_screen.dart';
import 'package:link_vibe/feature/student/my_projects/presentation/screens/my_projects_screen.dart';
import 'package:link_vibe/feature/student/notifications/presentation/screens/notifications_screen.dart';
import 'package:link_vibe/feature/student/profile/presentation/screens/student_profile_screen.dart';

class StudentMainNav extends StatefulWidget {
  final int initialIndex;

  const StudentMainNav({super.key, this.initialIndex = 0});

  @override
  State<StudentMainNav> createState() => _StudentMainNavState();
}

class _StudentMainNavState extends State<StudentMainNav> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentHomeScreen(onTabChange: _onTabChange),
      const ExploreProjectsScreen(),
      const MyProjectsScreen(),
      const NotificationsScreen(),
      StudentProfileScreen(onTabChange: _onTabChange),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabChange,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: AppColors.grayText,
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
                  icon: Icon(Icons.notifications_none_rounded),
                  activeIcon: Icon(Icons.notifications_rounded),
                  label: 'Alerts',
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
    );
  }
}
