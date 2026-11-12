import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/skillbridge_logo.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/reset_password_screen.dart';
import 'package:link_vibe/feature/auth/presentation/widgets/auth_form_helpers.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_main_nav.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/company/services/company_settings_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;

  const LoginScreen({super.key, this.initialRole = 'Student'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late String _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _needsEmailVerification = false;
  String? _errorBanner;
  String? _infoBanner;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == 'Company' ? 'Company' : 'Student';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRoleChange(String role) {
    if (_selectedRole == role) return;
    resetAuthRoleForm(
      formKey: _formKey,
      controllers: [_emailController, _passwordController],
    );
    setState(() {
      _selectedRole = role;
      _obscurePassword = true;
      _needsEmailVerification = false;
      _errorBanner = null;
      _infoBanner = null;
    });
  }

  Future<void> _resendVerificationEmail() async {
    final supabase = SupabaseHelper.clientOrNull;
    final email = _emailController.text.trim().toLowerCase();
    if (supabase == null || email.isEmpty || !email.contains('@')) return;

    setState(() {
      _isLoading = true;
      _errorBanner = null;
      _infoBanner = null;
    });
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'io.supabase.campusconnect://login-callback',
      );
      if (!mounted) return;
      setState(() {
        _infoBanner =
            'Verification link sent to $email. Please open the link in your email inbox, then sign in.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorBanner = null;
      _infoBanner = null;
      _needsEmailVerification = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    SupabaseHelper.beginInteractiveAuth();

    try {
      // 1. Real Supabase Cloud Authentication (when initialized)
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        final AuthResponse authResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = authResponse.user;
        if (user == null) {
          throw const AuthException('Unable to verify account credentials.');
        }

        Map<String, dynamic>? profileRow;
        try {
          profileRow = await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .limit(1)
              .maybeSingle();
        } catch (e) {
          debugPrint('LoginScreen profile lookup skipped: $e');
        }

        final accountStatus =
            (profileRow?['account_status']?.toString() ?? 'active')
                .trim()
                .toLowerCase();

        if (accountStatus == 'suspended') {
          await supabase.auth.signOut();
          if (!mounted) return;
          setState(() {
            _errorBanner =
                'Your account has been suspended by an administrator. Contact platform support for assistance.';
          });
          return;
        }

        final actualRole = await SupabaseHelper.resolveAccountRole(
          supabase,
          user,
          profileRow: profileRow,
        );

        // Enforce strict separation: Admin must log in via Governance Admin Console,
        // and Student/Company can only enter their matching portal.
        if (actualRole == 'Admin') {
          await supabase.auth.signOut();
          if (!mounted) return;
          setState(() {
            _errorBanner =
                'Admin accounts must sign in through Governance Admin Console below.';
          });
          return;
        }

        if (actualRole != _selectedRole) {
          await supabase.auth.signOut();
          if (!mounted) return;
          setState(() {
            _errorBanner =
                'This account is registered as a $actualRole. Please select $actualRole under Portal Role to sign in.';
          });
          return;
        }

        final resolvedName =
            (profileRow?['name']?.toString().trim().isNotEmpty == true)
                ? profileRow!['name'].toString().trim()
                : (user.userMetadata?['name']?.toString().trim().isNotEmpty ==
                        true
                    ? user.userMetadata!['name'].toString().trim()
                    : (email.split('@').first));
        final resolvedUni =
            (profileRow?['university']?.toString().trim().isNotEmpty == true)
                ? profileRow!['university'].toString().trim()
                : (user.userMetadata?['university']?.toString().trim() ?? '');

        // Ensure profile row exists in Supabase so Admin always sees this account
        if (profileRow == null) {
          try {
            await supabase.from('profiles').upsert({
              'id': user.id,
              'name': resolvedName,
              'email': user.email ?? email,
              'user_type': actualRole,
              'university': resolvedUni,
              'account_status': 'active',
            });
          } catch (e) {
            debugPrint('LoginScreen profile backfill warning: $e');
          }
        }

        // Role-specific suspension checks & missing role-row healing
        if (actualRole == 'Student') {
          try {
            final stuRow = await supabase
                .from('students')
                .select()
                .eq('user_id', user.id)
                .limit(1)
                .maybeSingle();
            if (stuRow == null) {
              await supabase.from('students').insert({
                'user_id': user.id,
                'full_name': resolvedName,
                'email': user.email ?? email,
                'university': resolvedUni,
              });
            } else if ((stuRow['account_status']?.toString().toLowerCase() ?? '') ==
                'suspended') {
              final reason = stuRow['suspension_reason']?.toString() ?? '';
              await supabase.auth.signOut();
              if (!mounted) return;
              setState(() {
                _errorBanner = reason.isNotEmpty
                    ? 'Account suspended: $reason'
                    : 'Your student account is currently suspended.';
              });
              return;
            }
          } catch (e) {
            debugPrint('LoginScreen student status check skipped: $e');
          }
        } else if (actualRole == 'Company') {
          try {
            final compRow = await supabase
                .from('companies')
                .select()
                .eq('user_id', user.id)
                .limit(1)
                .maybeSingle();
            if (compRow == null) {
              await supabase.from('companies').insert({
                'user_id': user.id,
                'company_name': resolvedName,
                'email': user.email ?? email,
                'industry': resolvedUni.isNotEmpty
                    ? resolvedUni
                    : 'Software & Cloud Services',
                'verification_status': 'not_submitted',
                'logo_initial':
                    SupabaseHelper.initialsFor(resolvedName, fallback: 'CO'),
              });
            } else if ((compRow['account_status']?.toString().toLowerCase() ?? '') ==
                'suspended') {
              final reason = compRow['suspension_reason']?.toString() ?? '';
              await supabase.auth.signOut();
              if (!mounted) return;
              setState(() {
                _errorBanner = reason.isNotEmpty
                    ? 'Company account suspended: $reason'
                    : 'Your company account is currently suspended.';
              });
              return;
            }
          } catch (e) {
            debugPrint('LoginScreen company status check skipped: $e');
          }
        }

        // Clear any previous user's cached workspace before loading this account
        if (AppDataService.instance.userId.isNotEmpty &&
            AppDataService.instance.userId != user.id) {
          await AppDataService.instance.clearAuthSession();
        }
        CompanyProfileService().reset();
        CompanyVerificationService().reset();
        CompanyProjectService().reset();
        CompanyApplicantService().reset();
        CompanyAssignmentService().reset();
        CompanySettingsService().reset();

        await AppDataService.instance.saveAuthSession(
          role: actualRole,
          email: user.email ?? email,
          name: resolvedName,
          university: resolvedUni,
          userId: user.id,
        );

        if (actualRole == 'Company') {
          await CompanyProfileService.loadAllCompanyPanelData();
        } else {
          await AppDataService.instance.syncFromSupabase(forceRefresh: true);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $resolvedName!'),
            backgroundColor: AppColors.statusOpen,
          ),
        );

        if (actualRole == 'Company') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CompanyMainNav()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentMainNav()),
            (route) => false,
          );
        }
        return;
      }

      // 2. Offline unit/widget test registry fallback ONLY when Supabase is null
      final isLocalValid =
          AppDataService.instance.verifyLocalCredentials(email, password);
      if (isLocalValid) {
        final acc = AppDataService.instance.findUserAccount(email);
        final rawLocalRole = (acc?['role']?.toString() ?? 'Student').trim();
        final actualRole = rawLocalRole.toLowerCase() == 'admin'
            ? 'Admin'
            : (rawLocalRole.toLowerCase() == 'company' ? 'Company' : 'Student');

        if (actualRole == 'Admin') {
          setState(() {
            _errorBanner =
                'Admin accounts must sign in through Governance Admin Console below.';
          });
          return;
        }
        if (actualRole != _selectedRole) {
          setState(() {
            _errorBanner =
                'This account is registered as a $actualRole. Please select $actualRole under Portal Role to sign in.';
          });
          return;
        }

        final name = acc?['name']?.toString() ?? 'User';
        final university = acc?['university']?.toString();

        await AppDataService.instance.saveAuthSession(
          role: actualRole,
          email: email,
          name: name,
          university: university,
        );

        if (!mounted) return;
        if (actualRole == 'Company') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CompanyMainNav()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentMainNav()),
            (route) => false,
          );
        }
        return;
      }

      setState(() {
        _errorBanner =
            'Supabase is not initialized and no local test account matches these credentials.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final unconfirmed = SupabaseHelper.isEmailNotConfirmedError(e);
      setState(() {
        _needsEmailVerification = unconfirmed;
        _errorBanner = unconfirmed
            ? 'Please verify your email address using the link sent to your inbox before signing in.'
            : SupabaseHelper.friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      SupabaseHelper.endInteractiveAuth();
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Header
                  SkillBridgeLogo(
                    size: 74,
                    circular: true,
                    shadows: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Skill',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        TextSpan(
                          text: 'Bridge',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learn • Collaborate • Verify',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grayText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lightGray),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to continue to your SkillBridge portal.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                          const SizedBox(height: 18),

                          if (_infoBanner != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.statusOpen.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                _infoBanner!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (_errorBanner != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorBanner!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_needsEmailVerification) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _resendVerificationEmail,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Resend Verification Link',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Role Selector Pills (Student & Company only; Admin uses Governance Console below)
                          Text(
                            'Portal Role',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Student', 'Company'].map((role) {
                              final selected = _selectedRole == role;
                              final IconData icon = role == 'Company'
                                  ? Icons.business_rounded
                                  : Icons.school_outlined;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: role == 'Company' ? 0 : 10,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _isLoading
                                        ? null
                                        : () => _handleRoleChange(role),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primaryBlue
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primaryBlue
                                              : AppColors.lightGray,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            icon,
                                            size: 18,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.grayText,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              role,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: selected
                                                    ? Colors.white
                                                    : AppColors.darkText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          KeyedSubtree(
                            key: ValueKey('login_fields_$_selectedRole'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Email Address',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    hintText: _selectedRole == 'Company'
                                        ? 'team@company.com'
                                        : 'you@university.edu',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (val) {
                                    final v = val?.trim() ?? '';
                                    if (v.isEmpty) {
                                      return 'Email address is required';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Password',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : _openForgotPasswordDialog,
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  enabled: !_isLoading,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.grayText,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text(
                                      'Sign In as $_selectedRole',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign Up Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.grayText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SignupScreen(initialRole: _selectedRole),
                            ),
                          );
                        },
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dedicated Governance Admin Portal Shortcut
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLoginScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                            color: AppColors.deepNavy,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Governance Admin Console',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepNavy,
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
          ),
        ),
      ),
    );
  }
}
