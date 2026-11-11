import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_main_nav.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String role;
  final bool isVerified;
  final String? initialError;
  final String? initialInfo;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.role = 'Student',
    this.isVerified = false,
    this.initialError,
    this.initialInfo,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final _codeCtrl = TextEditingController();
  bool _isWorking = false;
  bool _isResending = false;
  bool _isCheckingStatus = false;
  final ResendCooldown _resendCooldown = ResendCooldown();
  late bool _verified;
  String? _errorBanner;
  String? _infoBanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verified = widget.isVerified;
    _errorBanner = widget.initialError;
    _infoBanner = widget.initialInfo;
    if (!_verified && widget.email.trim().isNotEmpty) {
      AppDataService.instance.savePendingAuthContext(
        flow: 'signup',
        email: widget.email.trim(),
        role: widget.role,
      );
    }
  }

  @override
  void didUpdateWidget(covariant EmailVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVerified != oldWidget.isVerified && widget.isVerified) {
      _verified = true;
      _errorBanner = null;
      _infoBanner = null;
    }
    if (widget.initialError != oldWidget.initialError &&
        widget.initialError != null) {
      _errorBanner = widget.initialError;
    }
    if (widget.initialInfo != oldWidget.initialInfo &&
        widget.initialInfo != null) {
      _infoBanner = widget.initialInfo;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendCooldown.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_verified && !_isWorking) {
      _checkVerificationStatus(silent: true);
    }
  }

  Future<void> _checkVerificationStatus({bool silent = false}) async {
    if (_verified || _isCheckingStatus) return;
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    final targetEmail = widget.email.trim().toLowerCase();
    final current = supabase.auth.currentUser;
    if (current == null ||
        (targetEmail.isNotEmpty &&
            (current.email ?? '').trim().toLowerCase() != targetEmail)) {
      if (!silent && mounted) {
        setState(() {
          _infoBanner =
              'Open the verification link in your inbox or enter the 6-digit code sent to ${widget.email.trim()}.';
        });
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _isCheckingStatus = true;
        _errorBanner = null;
      });
    }

    try {
      final userRes = await supabase.auth.getUser();
      final confirmed = userRes.user?.emailConfirmedAt != null;
      if (!mounted) return;
      if (confirmed) {
        await AppDataService.instance.clearPendingAuthContext();
        if (!mounted) return;
        setState(() {
          _verified = true;
          _errorBanner = null;
          _infoBanner = null;
        });
      } else if (!silent) {
        setState(() {
          _infoBanner =
              'Email is still pending confirmation. Click the link in your email or enter the 6-digit code below.';
        });
      }
    } catch (_) {
      if (current.emailConfirmedAt != null && mounted) {
        setState(() => _verified = true);
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    final targetEmail = widget.email.trim();
    if (targetEmail.isEmpty || _isResending || _resendCooldown.isActive) {
      if (targetEmail.isEmpty && mounted) {
        setState(
          () => _errorBanner =
              'Email address is missing. Please go back to Sign In and try again.',
        );
      }
      return;
    }
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    setState(() {
      _isResending = true;
      _errorBanner = null;
      _infoBanner = null;
    });

    await AppDataService.instance.savePendingAuthContext(
      flow: 'signup',
      email: targetEmail,
      role: widget.role,
    );

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: targetEmail,
        emailRedirectTo: SupabaseHelper.emailRedirectUrl,
      );
      if (!mounted) return;
      _resendCooldown.start(() {
        if (mounted) setState(() {});
      });
      setState(() {
        _infoBanner =
            'Verification email resent to $targetEmail. Check your inbox or spam folder.';
      });
    } catch (e) {
      if (!mounted) return;
      if (SupabaseHelper.isEmailRateLimitError(e) ||
          SupabaseHelper.friendlyError(e).toLowerCase().contains('seconds')) {
        _resendCooldown.start(
          () {
            if (mounted) setState(() {});
          },
          seconds: SupabaseHelper.extractRateLimitCooldownSeconds(e),
        );
      }
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyWithCode() async {
    final code = _codeCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (code.length < 6) {
      setState(
        () => _errorBanner = 'Enter the 6-digit verification code from email.',
      );
      return;
    }

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      setState(() => _errorBanner = 'Supabase client unavailable.');
      return;
    }

    setState(() {
      _isWorking = true;
      _errorBanner = null;
      _infoBanner = null;
    });
    SupabaseHelper.beginInteractiveAuth();

    try {
      final res = await supabase.auth.verifyOTP(
        email: widget.email.trim(),
        token: code,
        type: OtpType.signup,
      );
      if (res.user == null) {
        throw const AuthException('Invalid or expired verification code.');
      }
      await AppDataService.instance.clearPendingAuthContext();
      if (!mounted) return;
      setState(() => _verified = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      SupabaseHelper.endInteractiveAuth();
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _continueToPortal() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            initialRole:
                widget.role == 'Company' ? 'Company' : 'Student',
          ),
        ),
        (route) => false,
      );
      return;
    }

    setState(() {
      _isWorking = true;
      _errorBanner = null;
    });

    try {
      Map<String, dynamic>? profileRow;
      try {
        profileRow = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .limit(1)
            .maybeSingle();
      } catch (e) {
        debugPrint('EmailVerification profile lookup warning: $e');
      }

      final role = await SupabaseHelper.resolveAccountRole(
        supabase,
        user,
        profileRow: profileRow,
      );

      final resolvedName =
          (profileRow?['name']?.toString().trim().isNotEmpty == true)
              ? profileRow!['name'].toString().trim()
              : (user.userMetadata?['name']?.toString().trim().isNotEmpty ==
                      true
                  ? user.userMetadata!['name'].toString().trim()
                  : (user.email?.split('@').first ?? 'User'));
      final resolvedUni =
          (profileRow?['university']?.toString().trim().isNotEmpty == true)
              ? profileRow!['university'].toString().trim()
              : (user.userMetadata?['university']?.toString() ?? '');

      if (profileRow == null) {
        try {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'name': resolvedName,
            'email': user.email ?? widget.email.trim(),
            'user_type': role,
            'university': resolvedUni,
            'account_status': 'active',
          });
        } catch (e) {
          debugPrint('EmailVerification profile initialization warning: $e');
        }
      }

      if (role == 'Company') {
        try {
          final existingComp = await supabase
              .from('companies')
              .select('id')
              .eq('user_id', user.id)
              .limit(1)
              .maybeSingle();
          if (existingComp == null) {
            await supabase.from('companies').insert({
              'user_id': user.id,
              'company_name': resolvedName,
              'email': user.email ?? widget.email.trim(),
              'industry': resolvedUni.isNotEmpty
                  ? resolvedUni
                  : 'Software & Cloud Services',
              'verification_status': 'not_submitted',
              'is_email_verified': true,
              'logo_initial':
                  SupabaseHelper.initialsFor(resolvedName, fallback: 'CO'),
            });
          } else {
            await supabase
                .from('companies')
                .update({'is_email_verified': true})
                .eq('user_id', user.id);
          }
        } catch (e) {
          debugPrint('EmailVerification company initialization warning: $e');
        }
      } else if (role == 'Student') {
        try {
          final existingStu = await supabase
              .from('students')
              .select('id')
              .eq('user_id', user.id)
              .limit(1)
              .maybeSingle();
          if (existingStu == null) {
            await supabase.from('students').insert({
              'user_id': user.id,
              'full_name': resolvedName,
              'email': user.email ?? widget.email.trim(),
              'university': resolvedUni,
            });
          }
        } catch (e) {
          debugPrint('EmailVerification student initialization warning: $e');
        }
      }

      await AppDataService.instance.clearPendingAuthContext();
      await AppDataService.instance.saveAuthSession(
        role: role,
        email: user.email ?? widget.email,
        name: resolvedName,
        university: resolvedUni,
        userId: user.id,
      );

      Widget destination;
      if (role == 'Admin') {
        final admin = await AdminAuthService().restoreFromCurrentUser();
        if (admin == null) {
          throw Exception('Administrator session verification failed.');
        }
        destination = const AdminDashboardScreen();
      } else if (role == 'Company') {
        try {
          await CompanyProfileService.loadAllCompanyPanelData().timeout(
            const Duration(seconds: 6),
          );
        } catch (e) {
          debugPrint('Company panel preload warning: $e');
        }
        destination = const CompanyMainNav();
      } else {
        try {
          await AppDataService.instance
              .syncFromSupabase(forceRefresh: true)
              .timeout(const Duration(seconds: 6));
        } catch (e) {
          debugPrint('Student portal preload warning: $e');
        }
        destination = const StudentMainNav();
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = SupabaseHelper.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portalLabel = widget.role == 'Admin'
        ? 'Admin Console'
        : (widget.role == 'Company' ? 'Company Portal' : 'Student Portal');

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _verified
                            ? AppColors.successBg
                            : AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _verified
                            ? Icons.verified_rounded
                            : Icons.mark_email_unread_outlined,
                        size: 36,
                        color: _verified
                            ? AppColors.statusOpen
                            : AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _verified
                          ? 'Email Verified Successfully'
                          : 'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _verified
                          ? 'Your account (${widget.email}) is verified for your $portalLabel.'
                          : 'We sent a verification link & code to ${widget.email}. Click the link or enter the 6-digit verification code below.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.grayText,
                        height: 1.5,
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
                        ),
                        child: Text(
                          _infoBanner!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_verified) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isWorking ? null : _continueToPortal,
                          child: _isWorking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text('Continue to $portalLabel'),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_isWorking,
                        decoration: const InputDecoration(
                          labelText: '6-Digit Verification Code',
                          hintText: 'Enter code from email',
                          prefixIcon: Icon(Icons.pin_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isWorking ? null : _verifyWithCode,
                          child: _isWorking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text('Verify & Activate Account'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          TextButton(
                            onPressed:
                                (_isResending || _resendCooldown.isActive)
                                    ? null
                                    : _resendEmail,
                            child: Text(
                              _isResending
                                  ? 'Sending...'
                                  : _resendCooldown.isActive
                                      ? 'Resend in ${_resendCooldown.remainingSeconds}s'
                                      : 'Resend Email',
                            ),
                          ),
                          if (SupabaseHelper.currentUser != null)
                            TextButton(
                              onPressed: _isCheckingStatus
                                  ? null
                                  : () => _checkVerificationStatus(
                                      silent: false,
                                    ),
                              child: Text(
                                _isCheckingStatus
                                    ? 'Checking...'
                                    : 'Check Status',
                              ),
                            ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(
                                    initialRole: widget.role == 'Company'
                                        ? 'Company'
                                        : 'Student',
                                  ),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Back to Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

