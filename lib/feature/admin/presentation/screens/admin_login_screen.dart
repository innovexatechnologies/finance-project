import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/reset_password_screen.dart';

/// Enterprise Admin Login Screen for SkillBridge
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AdminAuthService _authService = AdminAuthService();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rememberMe = _authService.isRememberMeEnabled;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await _authService.login(
      email: email,
      password: password,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success && result.admin != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Authentication verified. Welcome, ${result.admin!.fullName}.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Authentication failed. Please check your credentials.';
      });
    }
  }

  void _openForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWidescreen = constraints.maxWidth >= 960;

          if (isWidescreen) {
            return Row(
              children: [
                // Left Enterprise Branding & Security Hero Panel (42% width)
                Expanded(
                  flex: 5,
                  child: _buildBrandingHeroPanel(),
                ),

                // Right Admin Login Form (58% width)
                Expanded(
                  flex: 7,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildLoginFormCard(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Centered Card Layout for Tablet & Mobile screens
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      _buildMobileBrandingHeader(),
                      const SizedBox(height: 20),
                      _buildLoginFormCard(),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Left-side Enterprise Hero Branding Panel (Desktop & Laptop)
  Widget _buildBrandingHeroPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0F2344), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'SKILLBRIDGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ENTERPRISE CONSOLE',
                  style: TextStyle(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),

          // Central Hero Illustration & Highlights
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield Graphic
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentTeal.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.accentTeal,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Platform Governance &\nSecurity Administration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Comprehensive oversight of university student credentials, corporate SECP/NTN authorizations, project audit compliance, and system integrity.',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Feature Badges
              _buildHeroFeatureRow(
                icon: Icons.verified_user_outlined,
                title: 'Company & University Verification Desk',
                subtitle: 'Authorized multi-tier vetting of corporate identity & student degrees.',
              ),
              const SizedBox(height: 16),
              _buildHeroFeatureRow(
                icon: Icons.shield_outlined,
                title: 'Zero-Trust Administrative Realm',
                subtitle: 'Authenticated administrative session management.',
              ),
              const SizedBox(height: 16),
              _buildHeroFeatureRow(
                icon: Icons.history_edu_outlined,
                title: 'Tamper-Evident Audit Logging',
                subtitle: 'Every administrative action is signed, monitored, and timestamped.',
              ),
            ],
          ),

          // Footer Security Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: AppColors.accentTeal, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Administrative session activity is monitored in accordance with institutional governance standards.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accentTeal, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Header shown on Mobile and Tablet
  Widget _buildMobileBrandingHeader() {
    return Column(
      children: [
        SkillBridgeLogo(
          size: 64,
          circular: true,
          shadows: [
            BoxShadow(
              color: AppColors.darkNavy.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'SKILLBRIDGE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.darkNavy,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.lightIceBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ENTERPRISE ADMIN PORTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  // Right-side (or Centered) Form Card
  Widget _buildLoginFormCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading & Subtitle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Sign In',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      Text(
                        'Authorized credentials required',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Inline Error Banner
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 1. Admin Email Field
            const Text(
              'Institutional Email',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Enter institutional administrator email',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your institutional admin email';
                }
                final emailPattern =
                    RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,10}$');
                if (!emailPattern.hasMatch(value.trim())) {
                  return 'Enter a valid institutional email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 2. Password Field
            const Text(
              'Administrator Password',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) _handleLogin();
              },
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: '••••••••••••',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // 3. Remember Me & Forgot Password Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: _isLoading
                            ? null
                            : (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember device',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _isLoading ? null : _openForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 4. Secure Login Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.darkNavy.withValues(alpha: 0.6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 18,
                            color: AppColors.accentTeal,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Sign In to Console',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Security Notice regarding public registration restriction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Security Notice: Public administrator registration is permanently disabled. New credentials must be provisioned via the Governance Council.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Back to Standard Login Link
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Return to Public Portal (Student / Company)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

