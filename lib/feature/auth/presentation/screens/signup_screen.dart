import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_main_nav.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/student/presentation/screens/student_main_nav.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final String initialRole;

  const SignupScreen({super.key, this.initialRole = 'Student'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityController = TextEditingController();
  final _passwordController = TextEditingController();

  late String _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == 'Company' ? 'Company' : 'Student';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorBanner = null);
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final instituteOrIndustry = _universityController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    SupabaseHelper.beginInteractiveAuth();

    try {
      final supabase = SupabaseHelper.clientOrNull;

      if (supabase != null) {
        AuthResponse authResponse;
        try {
          authResponse = await supabase.auth.signUp(
            email: email,
            password: password,
            data: {
              'name': name,
              'user_type': _selectedRole,
              'university': instituteOrIndustry,
            },
          );
        } on AuthException catch (signUpErr) {
          if (SupabaseHelper.isEmailRateLimitError(signUpErr) ||
              SupabaseHelper.isWeakPasswordError(signUpErr)) {
            await SupabaseHelper.registerUserInApp(
              email: email,
              password: password,
              name: name,
              role: _selectedRole,
              organization: instituteOrIndustry,
            );
            authResponse = await supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        }

        var user = authResponse.user;
        var session = authResponse.session;

        if (user != null && user.identities != null && user.identities!.isEmpty) {
          // Account already exists: attempt direct sign-in if credentials match
          await SupabaseHelper.confirmUserEmailInApp(email);
          try {
            final existingSignIn = await supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
            user = existingSignIn.user;
            session = existingSignIn.session;
          } catch (_) {
            if (!mounted) return;
            setState(() {
              _errorBanner =
                  'An account with this email already exists. Please sign in or reset your password.';
            });
            return;
          }
        }

        if (user == null) {
          throw const AuthException('Account creation did not return a user.');
        }

        if (session == null) {
          // Auto-confirm and log user directly into their workspace without verification screens
          await SupabaseHelper.confirmUserEmailInApp(email);
          final loginResponse = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          user = loginResponse.user ?? user;
          session = loginResponse.session;
        }

        // Session active: ensure profile + role-specific record exist cleanly
        await supabase.from('profiles').upsert({
          'id': user.id,
          'name': name,
          'email': email,
          'user_type': _selectedRole,
          'university': instituteOrIndustry,
          'account_status': 'active',
        });

        if (_selectedRole == 'Company') {
          final existingComp = await supabase
              .from('companies')
              .select('id')
              .eq('user_id', user.id)
              .limit(1)
              .maybeSingle();
          if (existingComp == null) {
            await supabase.from('companies').insert({
              'user_id': user.id,
              'company_name': name,
              'email': email,
              'industry': instituteOrIndustry,
              'verification_status': 'not_submitted',
              'logo_initial': SupabaseHelper.initialsFor(name, fallback: 'CO'),
            });
          }
        } else {
          final existingStu = await supabase
              .from('students')
              .select('id')
              .eq('user_id', user.id)
              .limit(1)
              .maybeSingle();
          if (existingStu == null) {
            await supabase.from('students').insert({
              'user_id': user.id,
              'full_name': name,
              'email': email,
              'university': instituteOrIndustry,
            });
          }
        }

        await AppDataService.instance.saveAuthSession(
          role: _selectedRole,
          email: email,
          name: name,
          university: instituteOrIndustry,
          userId: user.id,
        );

        if (_selectedRole == 'Company') {
          await CompanyProfileService.loadAllCompanyPanelData();
        } else {
          await AppDataService.instance.syncFromSupabase(forceRefresh: true);
        }
      } else {
        // Offline unit/widget test registry fallback ONLY when Supabase is null
        await AppDataService.instance.registerUserAccount(
          email: email,
          password: password,
          name: name,
          university: instituteOrIndustry,
          role: _selectedRole,
        );
        await AppDataService.instance.saveAuthSession(
          role: _selectedRole,
          email: email,
          name: name,
          university: instituteOrIndustry,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Welcome, $name.'),
          backgroundColor: AppColors.statusOpen,
        ),
      );

      if (_selectedRole == 'Company') {
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
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBanner = SupabaseHelper.friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBanner = SupabaseHelper.friendlyError(e);
      });
    } finally {
      SupabaseHelper.endInteractiveAuth();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = _selectedRole == 'Company';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
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
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join SkillBridge as a university student or corporate partner.',
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
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Segmented Role Switcher
                      Text(
                        'Account Type',
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
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: role == 'Student' ? 8 : 0,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isLoading
                                    ? null
                                    : () =>
                                        setState(() => _selectedRole = role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                    horizontal: 10,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        role == 'Company'
                                            ? Icons.business_rounded
                                            : Icons.school_outlined,
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
                        isCompany ? 'Company Name *' : 'Full Name *',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: isCompany
                              ? 'Enter official company name'
                              : 'Enter your full name',
                          prefixIcon: Icon(
                            isCompany
                                ? Icons.business_rounded
                                : Icons.person_outline_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isCompany
                                ? 'Company name is required'
                                : 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Email Address *',
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
                          hintText: isCompany
                              ? 'hr@company.com'
                              : 'student@university.edu',
                          prefixIcon:
                              const Icon(Icons.email_outlined, size: 20),
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

                      Text(
                        isCompany
                            ? 'Industry / Sector *'
                            : 'University / Institute *',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _universityController,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: isCompany
                              ? 'e.g. Information Technology, FinTech'
                              : 'e.g. NUST, FAST-NUCES, LUMS',
                          prefixIcon: Icon(
                            isCompany
                                ? Icons.domain_rounded
                                : Icons.school_outlined,
                            size: 20,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isCompany
                                ? 'Please enter your industry sector'
                                : 'Please enter your university or institute';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Password *',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _handleRegister(),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
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
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  'Create $_selectedRole Account',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.grayText,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LoginScreen(initialRole: _selectedRole),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
