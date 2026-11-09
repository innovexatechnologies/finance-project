import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_dashboard.dart';
import 'package:link_vibe/feature/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _autoLoginTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    // Auto-login check: If user has an active session, auto navigate directly to main screen
    _autoLoginTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (AppDataService.instance.isLoggedIn) {
        _navigateToMain();
      }
    });
  }

  @override
  void dispose() {
    _autoLoginTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    if (!mounted) return;
    final role = AppDataService.instance.userRole;
    if (role == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (role == 'Company') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompanyDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentMainNav()),
      );
    }
  }

  void _onGetStartedPressed() {
    if (AppDataService.instance.isLoggedIn) {
      _navigateToMain();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071E3D),
              AppColors.deepNavy,
              Color(0xFF0F3A70),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxHeight < 620;
              final verticalSpacing = isSmall ? 16.0 : 28.0;

              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 480,
                      minHeight: (constraints.maxHeight - 40).clamp(0.0, double.infinity),
                    ),
                    child: IntrinsicHeight(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Spacing anchor
                            const SizedBox(height: 8),

                            // Brand Icon & Title
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Graduation Cap with Star Icon Container
                                  Container(
                                    width: isSmall ? 68 : 80,
                                    height: isSmall ? 68 : 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.teal.withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.school_rounded,
                                          size: isSmall ? 36 : 42,
                                          color: Colors.white,
                                        ),
                                        Positioned(
                                          top: isSmall ? 14 : 18,
                                          right: isSmall ? 14 : 18,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFBBF24),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmall ? 12 : 16),

                                  // Brand Name
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Campus',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmall ? 26 : 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Connect',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmall ? 26 : 30,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.teal,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Tagline
                                  Text(
                                    'Learn • Work • Grow',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.lightAqua.withValues(alpha: 0.85),
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: verticalSpacing),

                            // Campus Graphic & Heading Banner
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: isSmall ? 14 : 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.apartment_rounded,
                                    size: isSmall ? 38 : 46,
                                    color: AppColors.teal,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Build Your Future',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmall ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'With Real-World Experience',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: verticalSpacing),

                            // "Get Started ->" Button matching Image 1
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.deepNavy,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: _onGetStartedPressed,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: AppColors.deepNavy,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
