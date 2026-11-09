import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_dashboard.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      String role = _selectedRole;
      final metaRole = authResponse.user?.userMetadata?['user_type'];
      if (metaRole != null && metaRole.toString().isNotEmpty) {
        role = metaRole.toString();
      }

      // Persist auth session locally so app reopens directly to main screen
      await AppDataService.instance.saveAuthSession(
        role: role,
        email: email,
        name: authResponse.user?.userMetadata?['name']?.toString() ?? 'Ahmed Khan',
        userId: authResponse.user?.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome back to CampusConnect!'),
          backgroundColor: Colors.green,
        ),
      );

      if (role == 'Company') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CompanyDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentMainNav(),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      String errorMsg = e.message;
      if (errorMsg.toLowerCase().contains('invalid login credentials')) {
        errorMsg = 'Incorrect email or password. Please double check.';
      } else if (errorMsg.toLowerCase().contains('email not confirmed')) {
        errorMsg = 'Email is not confirmed yet. Please verify your inbox.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fillDemoStudent() {
    setState(() {
      _emailController.text = 'rabia32pk@gmail.com';
      _passwordController.text = '123456';
      _selectedRole = 'Student';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo student credentials filled! Click Log In.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _enterAsStudentGuest() async {
    await AppDataService.instance.saveAuthSession(
      role: 'Student',
      email: 'rabia32pk@gmail.com',
      name: 'Ahmed Khan',
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentMainNav(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Logo & Brand Icon
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.deepNavy,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Campus',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              TextSpan(
                                text: 'Connect',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Learn • Work • Grow',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grayText,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Welcome Texts
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log in to explore company projects and grow.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.grayText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Input
                  Text(
                    'Email Address',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'student@university.edu.pk',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password Input
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.grayText,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Role Selector
                  Text(
                    'Log In As',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    items: ['Student', 'Company']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Log In',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Demo Student Button (Zero Friction)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepNavy,
                        side: const BorderSide(color: AppColors.teal, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppColors.lightAqua.withValues(alpha: 0.3),
                      ),
                      onPressed: _enterAsStudentGuest,
                      icon: const Icon(Icons.rocket_launch_rounded,
                          size: 18, color: AppColors.primaryBlue),
                      label: Text(
                        'Explore Student Panel Directly',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick fill helper
                  Center(
                    child: TextButton.icon(
                      onPressed: _fillDemoStudent,
                      icon: const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.grayText),
                      label: Text(
                        'Fill Demo Student Credentials',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sign Up Link (using Wrap to prevent horizontal overflow on any device)
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Enterprise Admin Portal Link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminLoginScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'CampusConnect Admin Console 🔐',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
          ),
        ),
      ),
    );
  }
}
