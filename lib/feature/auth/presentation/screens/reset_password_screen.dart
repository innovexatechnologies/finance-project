import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final String? initialError;
  final bool isRecoverySession;

  const ResetPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.initialError,
    this.isRecoverySession = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isSaving = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdated = false;
  bool _linkSent = false;
  String? _errorBanner;
  String? _infoBanner;

  bool get _hasLiveSupabase => SupabaseHelper.clientOrNull != null;

  bool get _isSignedInAsTarget {
    final supabase = SupabaseHelper.clientOrNull;
    final currentEmail =
        supabase?.auth.currentUser?.email?.trim().toLowerCase() ?? '';
    final enteredEmail = _emailCtrl.text.trim().toLowerCase();
    return currentEmail.isNotEmpty && currentEmail == enteredEmail;
  }

  bool get _canSetPasswordDirectly =>
      !_hasLiveSupabase || widget.isRecoverySession || _isSignedInAsTarget;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _errorBanner = widget.initialError;
    if (widget.isRecoverySession) {
      _infoBanner =
          'Email link verified. Enter your new password below to complete the reset.';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    setState(() {
      _errorBanner = null;
      _infoBanner = null;
    });
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _errorBanner = 'Please enter a valid email address first.',
      );
      return;
    }

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    setState(() => _isSaving = true);
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.campusconnect://login-callback',
      );
      if (!mounted) return;
      setState(() {
        _linkSent = true;
        _infoBanner =
            'Password reset link sent to $email. Open the link from your email inbox to set a new password in SkillBridge.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorBanner = null;
      _infoBanner = null;
    });

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && !_canSetPasswordDirectly) {
      await _sendResetLink();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    final newPassword = _newPassCtrl.text.trim();

    setState(() => _isSaving = true);
    SupabaseHelper.beginInteractiveAuth();

    try {
      if (supabase != null) {
        await supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } else {
        final existing = AppDataService.instance.findUserAccount(email);
        if (existing == null) {
          throw const AuthException(
            'No account found for this email address.',
          );
        }
        await AppDataService.instance.updateAccountPassword(email, newPassword);
      }

      if (!mounted) return;
      setState(() => _isUpdated = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      SupabaseHelper.endInteractiveAuth();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.deepNavy,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGray),
                  boxShadow: AppColors.softShadow,
                ),
                child: _isUpdated ? _buildSuccessView() : _buildFormView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: AppColors.statusOpen,
            size: 36,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Password Updated',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your SkillBridge account password has been updated successfully. You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppColors.grayText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _goToLogin,
            child: const Text('Continue to Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    final requiresEmailLink = _hasLiveSupabase && !_canSetPasswordDirectly;
    final showPasswordFields = !requiresEmailLink;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    Text(
                      requiresEmailLink
                          ? 'Verify via email link to reset your password'
                          : 'Set a new password directly in the app',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.grayText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              child: Text(
                _errorBanner!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

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
            const SizedBox(height: 14),
          ],

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
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSaving && !widget.isRecoverySession,
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) {
              final v = val?.trim() ?? '';
              if (v.isEmpty || !v.contains('@')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          if (showPasswordFields) ...[
            Text(
              'New Password',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: _obscureNew,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.grayText,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (val) {
                final v = val?.trim() ?? '';
                if (v.isEmpty) {
                  return 'Enter a new password';
                }
                if (_hasLiveSupabase && v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            Text(
              'Confirm New Password',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: 'Re-enter new password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.grayText,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (val) {
                if (val?.trim() != _newPassCtrl.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
          ] else
            const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSubmit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      requiresEmailLink
                          ? (_linkSent
                              ? 'Resend Reset Link'
                              : 'Send Password Reset Link')
                          : 'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _goToLogin,
              child: Text(
                'Return to Sign In',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grayText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
