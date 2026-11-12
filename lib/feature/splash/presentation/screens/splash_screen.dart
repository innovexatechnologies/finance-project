import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_main_nav.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
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
  bool _isBootstrapping = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    _autoLoginTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (AppDataService.instance.isLoggedIn) {
        _bootstrapAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _autoLoginTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapAndNavigate() async {
    if (_isBootstrapping) return;
    setState(() => _isBootstrapping = true);

    try {
      final supabase = SupabaseHelper.clientOrNull;
      final role = AppDataService.instance.userRole.toLowerCase();

      if (supabase != null && supabase.auth.currentUser != null) {
        if (role == 'admin') {
          await AppDataService.instance.syncFromSupabase(forceRefresh: true);
          final restoredAdmin = await AdminAuthService()
              .restoreFromCurrentUser();
          if (!mounted) return;
          if (restoredAdmin == null) {
            await AppDataService.instance.clearAuthSession();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
            return;
          }
        } else if (role == 'company') {
          CompanyProfileService.hydrateFromLocalCache();
          unawaited(CompanyProfileService.loadAllCompanyPanelData());
        } else {
          unawaited(
            AppDataService.instance.syncFromSupabase(forceRefresh: true),
          );
        }
      } else if (role == 'company') {
        CompanyProfileService.hydrateFromLocalCache();
      }
    } catch (_) {
      // Proceed cleanly with hydrated session state
    }

    if (!mounted) return;
    _navigateToMain();
  }

  void _navigateToMain() {
    if (!mounted) return;
    final role = AppDataService.instance.userRole.toLowerCase();
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (role == 'company') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyMainNav()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentMainNav()),
      );
    }
  }

  void _onGetStartedPressed() {
    _autoLoginTimer?.cancel();
    if (AppDataService.instance.isLoggedIn) {
      _bootstrapAndNavigate();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061936), AppColors.deepNavy, Color(0xFF123E78)],
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
                      maxWidth: 460,
                      minHeight: (constraints.maxHeight - 40).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(height: 8),

                            // Brand Emblem & Wordmark
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SkillBridgeLogo(
                                    size: isSmall ? 82 : 98,
                                    circular: true,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 2,
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: AppColors.teal.withValues(
                                          alpha: 0.42,
                                        ),
                                        blurRadius: 26,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmall ? 14 : 18),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Skill',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmall ? 26 : 31,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Bridge',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmall ? 26 : 31,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.teal,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'LEARN • COLLABORATE • VERIFY',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.lightAqua,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: verticalSpacing),

                            // Ecosystem Value Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: isSmall ? 16 : 22,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.hub_rounded,
                                      size: isSmall ? 30 : 36,
                                      color: AppColors.lightAqua,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Student–Corporate Innovation Bridge',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmall ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Verified corporate projects, structured mentorship, and cryptographically signed academic certificates.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: Colors.white70,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: verticalSpacing),

                            // Primary Action CTA
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.deepNavy,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.94),
                                  disabledForegroundColor: AppColors.deepNavy,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isBootstrapping
                                    ? null
                                    : _onGetStartedPressed,
                                child: _isBootstrapping
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors.deepNavy,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              'Opening Workspace...',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.deepNavy,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Get Started',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
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
