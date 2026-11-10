import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
          // Header info
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
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CampusConnect Platform Terms',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last revised: November 2026 • Version 1.0',
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
            '1. Acceptance of Terms',
            'By creating an account, browsing opportunities, or applying for projects on CampusConnect, you agree to comply with and be legally bound by these Terms and Conditions. If you do not agree with any part of these terms, please do not use the application.',
          ),
          _buildSection(
            '2. Non-Monetary Educational Platform',
            'CampusConnect is an academic and skill-building bridge connecting verified corporate partners with university students. The platform contains no payment gateway, digital wallets, bank integrations, subscription billing, or in-app monetary transactions. All projects are conducted purely for academic credit, skill enhancement, portfolio development, and verified certification.',
          ),
          _buildSection(
            '3. Student Eligibility & Code of Conduct',
            'Students agree to submit genuine academic background information, respect project deadlines, and communicate professionally with corporate supervisors. Submitting plagiarized, automated, or misleading project deliverables will lead to immediate suspension of platform privileges.',
          ),
          _buildSection(
            '4. Corporate Partner Obligations',
            'Registered companies and supervisors agree to provide clear assignment instructions, constructive revision feedback, and timely verification of deliverables for the generation of completion certificates.',
          ),
          _buildSection(
            '5. Deliverables & Intellectual Property',
            'Deliverables submitted by students remain educational works, with non-exclusive usage rights granted to partner companies solely as specified in the project description scope.',
          ),
          _buildSection(
            '6. Verified Certifications',
            'Certificates generated on CampusConnect are digitally verifiable and reflect successful completion of assignments reviewed and approved by verified partner supervisors.',
          ),
          _buildSection(
            '7. Platform Modifications & Termination',
            'CampusConnect reserves the right to amend these terms at any time. Continued use of the platform following modifications constitutes acceptance of the revised terms.',
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

