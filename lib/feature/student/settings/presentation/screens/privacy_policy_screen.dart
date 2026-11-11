import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.policy_outlined,
                    color: AppColors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SkillBridge Privacy Policy',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last updated: November 2026 • Version 1.0',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            '1. Commitment to Privacy',
            'SkillBridge is committed to protecting student and partner privacy. This policy outlines what data we collect, how it is used to connect students with corporate opportunities, and how your information is safeguarded.',
          ),
          _buildSection(
            '2. Information We Collect',
            'We collect details provided during registration and profile creation: your full name, university email, academic institution, department, degree program, technical skills, and submitted application notes. We do NOT collect any financial, banking, or credit card information because SkillBridge does not conduct monetary transactions.',
          ),
          _buildSection(
            '3. How We Use Information',
            'Your information is used strictly to:\n• Allow partner companies to review project applications.\n• Enable supervisors to communicate with assigned students.\n• Generate verified project completion certificates.',
          ),
          _buildSection(
            '4. Controlled Visibility & Sharing',
            'Your contact details (such as phone number and public email) are shared only with companies to whose projects you submit an active application, subject to your settings under Privacy & Visibility Settings.',
          ),
          _buildSection(
            '5. Security & Data Protection',
            'All data transmissions are encrypted using standard SSL/TLS and backed by secure Supabase cloud infrastructure with Row Level Security (RLS) policies.',
          ),
          _buildSection(
            '6. Your Rights',
            'You may view, edit, or remove your profile information at any time from the Profile tab or submit a data removal request via the Contact Support screen.',
          ),
          const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.darkText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

