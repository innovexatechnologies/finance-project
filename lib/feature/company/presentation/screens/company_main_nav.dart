import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'applicants_screen.dart';
import 'assigned_projects_screen.dart';
import 'company_dashboard.dart';
import 'company_projects_list_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabHistory.clear();
    _tabHistory.add(widget.initialIndex);
  }

  void _onTabChange(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CompanyDashboardScreen(onTabChange: _onTabChange),
      CompanyProjectsListScreen(onTabChange: _onTabChange),
      PostProjectScreen(onTabChange: _onTabChange),
      ApplicantsScreen(onTabChange: _onTabChange),
      AssignedProjectsScreen(onTabChange: _onTabChange),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

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
}

