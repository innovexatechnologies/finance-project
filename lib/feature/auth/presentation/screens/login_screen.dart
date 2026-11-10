import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/email_verification_screen.dart';
import 'package:link_vibe/feature/auth/presentation/screens/reset_password_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_dashboard.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
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
  bool _needsEmailConfirmation = false;
  bool _isResendingConfirmation = false;
  String? _errorBanner;

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

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _isResendingConfirmation) return;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    setState(() => _isResendingConfirmation = true);
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseHelper.emailRedirectUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification link resent to $email. Please check your inbox.'),
          backgroundColor: AppColors.statusOpen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isResendingConfirmation = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorBanner = null;
      _needsEmailConfirmation = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    SupabaseHelper.isInteractiveAuthInProgress = true;

    try {
      // 1. Real Supabase Cloud Authentication (when initialized)
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        final authResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = authResponse.user;
        if (user == null) {
          throw const AuthException('Unable to verify account credentials.');
        }

        final profileRow = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

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

        // Role-specific suspension checks
        if (actualRole == 'Student') {
          final stuRow = await supabase
              .from('students')
              .select('account_status, suspension_reason')
              .eq('user_id', user.id)
              .maybeSingle();
          if ((stuRow?['account_status']?.toString().toLowerCase() ?? '') ==
              'suspended') {
            final reason = stuRow?['suspension_reason']?.toString() ?? '';
            await supabase.auth.signOut();
            if (!mounted) return;
            setState(() {
              _errorBanner = reason.isNotEmpty
                  ? 'Account suspended: $reason'
                  : 'Your student account is currently suspended.';
            });
            return;
          }
        } else if (actualRole == 'Company') {
          final compRow = await supabase
              .from('companies')
              .select('account_status, suspension_reason')
              .eq('user_id', user.id)
              .maybeSingle();
          if ((compRow?['account_status']?.toString().toLowerCase() ?? '') ==
              'suspended') {
            final reason = compRow?['suspension_reason']?.toString() ?? '';
            await supabase.auth.signOut();
            if (!mounted) return;
            setState(() {
              _errorBanner = reason.isNotEmpty
                  ? 'Company account suspended: $reason'
                  : 'Your company account is currently suspended.';
            });
            return;
          }
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
                : user.userMetadata?['university']?.toString();

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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompanyDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentMainNav()),
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompanyDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentMainNav()),
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
      setState(() {
        _needsEmailConfirmation =
            e.message.toLowerCase().contains('email not confirmed');
        _errorBanner = SupabaseHelper.friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      SupabaseHelper.isInteractiveAuthInProgress = false;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openForgotPasswordDialog() {
    final resetCtrl = TextEditingController(text: _emailController.text.trim());
    bool submitting = false;
    String? feedbackMsg;
    bool isSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reset Password',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your registered email address and we will send a password recovery link.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grayText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: resetCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                if (feedbackMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSuccess ? AppColors.successBg : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      feedbackMsg!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSuccess
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final target = resetCtrl.text.trim();
                      if (target.isEmpty || !target.contains('@')) {
                        setDialogState(() {
                          isSuccess = false;
                          feedbackMsg = 'Please enter a valid email address.';
                        });
                        return;
                      }
                      setDialogState(() {
                        submitting = true;
                        feedbackMsg = null;
                      });
                      try {
                        final supabase = SupabaseHelper.clientOrNull;
                        if (supabase == null) {
                          throw Exception('Supabase client unavailable.');
                        }
                        await supabase.auth.resetPasswordForEmail(
                          target,
                          redirectTo: SupabaseHelper.emailRedirectUrl,
                        );
                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResetPasswordScreen(
                              initialEmail: target,
                              hasRecoverySession: false,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!dialogCtx.mounted) return;
                        setDialogState(() {
                          submitting = false;
                          isSuccess = false;
                          feedbackMsg = SupabaseHelper.friendlyError(e);
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Link'),
            ),
          ],
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
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 34,
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        TextSpan(
                          text: 'Connect',
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
                            'Sign in to continue to your CampusConnect portal.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.grayText,
                            ),
                          ),
                          const SizedBox(height: 18),

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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _errorBanner!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF991B1B),
                                          ),
                                        ),
                                        if (_needsEmailConfirmation) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(0, 0),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                onPressed:
                                                    _isResendingConfirmation
                                                        ? null
                                                        : _resendVerificationEmail,
                                                child: Text(
                                                  _isResendingConfirmation
                                                      ? 'Sending...'
                                                      : 'Resend verification email',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primaryBlue,
                                                    decoration:
                                                        TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(0, 0),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          EmailVerificationScreen(
                                                        email: _emailController
                                                            .text
                                                            .trim(),
                                                        role: _selectedRole,
                                                        isVerified: false,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Verify via code',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.deepNavy,
                                                    decoration:
                                                        TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
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
                                        : () => setState(() {
                                              _selectedRole = role;
                                              _errorBanner = null;
                                              _needsEmailConfirmation = false;
                                            }),
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
                              prefixIcon:
                                  const Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (val) {
                              final v = val?.trim() ?? '';
                              if (v.isEmpty) {
                                return 'Email address is required';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
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
                              crossAxisAlignment: WrapCrossAlignment.center,
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
                                  () => _obscurePassword = !_obscurePassword,
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
