import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, UserAttributes;
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdatingPassword = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    final currentEmail = AppDataService.instance.userEmail.trim();
    final sbEmail = SupabaseHelper.currentUser?.email?.trim() ?? '';
    final profileEmail =
        AppDataService.instance.getProfile()['email']?.toString().trim() ?? '';
    _emailController.text = currentEmail.isNotEmpty
        ? currentEmail
        : (sbEmail.isNotEmpty ? sbEmail : profileEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final email = _emailController.text.trim();
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill both password fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;

    if (supabase != null && newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (supabase != null && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again before changing your password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      if (supabase != null && user != null) {
        final accountEmail = user.email ?? email;
        if (currentPass.isEmpty) {
          throw const AuthException('Please enter your current password.');
        }
        SupabaseHelper.beginInteractiveAuth();
        try {
          await supabase.auth.signInWithPassword(
            email: accountEmail,
            password: currentPass,
          );
        } finally {
          SupabaseHelper.endInteractiveAuth();
        }
        await supabase.auth.updateUser(UserAttributes(password: newPass));
      } else if (email.isNotEmpty) {
        await AppDataService.instance.updateAccountPassword(email, newPass);
      }

      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated successfully! You can now sign in with your new password.',
          ),
          backgroundColor: AppColors.statusOpen,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SupabaseHelper.friendlyError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update password: ${SupabaseHelper.friendlyError(e)}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: AppColors.primaryBlue,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Security',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verify your current password to update your SkillBridge account password.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Account Email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  readOnly: SupabaseHelper.currentUser != null,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your account email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (SupabaseHelper.clientOrNull != null) ...[
                  Text(
                    'Current Password',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPass,
                    decoration: InputDecoration(
                      hintText: 'Enter current password',
                      prefixIcon: const Icon(
                        Icons.lock_person_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.grayText,
                        ),
                        onPressed: () => setState(
                          () => _obscureCurrentPass = !_obscureCurrentPass,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'New Password',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPass,
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grayText,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Confirm New Password',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    hintText: 'Re-enter new password',
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grayText,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUpdatingPassword ? null : _handleUpdatePassword,
                    icon: _isUpdatingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _isUpdatingPassword
                          ? 'Updating...'
                          : 'Update Password Now',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
