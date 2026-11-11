import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'contact_support_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I apply for a company project?',
      'answer':
          'Navigate to the "Explore" tab, browse or search for open projects. Click "View Details" to see the project requirements, and tap "Apply Now" to submit your cover note and availability.',
      'category': 'Projects',
    },
    {
      'question': 'Is CampusConnect completely free for students?',
      'answer':
          'Yes! CampusConnect is 100% free. There are no fees, wallet balances, or payment gateways. Our mission is to bridge academia and industry with zero financial barriers.',
      'category': 'Platform',
    },
    {
      'question': 'How do I submit my completed project work?',
      'answer':
          'Go to "My Projects" tab and find your active assignment. Tap "Submit Work", enter your summary description, provide your GitHub or portfolio link, and tap "Submit Work". The company will review your deliverables.',
      'category': 'Submissions',
    },
    {
      'question': 'What should I do if a company requests revisions?',
      'answer':
          'If a company requests revisions, you will see a status update in "My Projects". Open the assignment to read the supervisor\'s feedback, modify your work, and upload revised deliverables.',
      'category': 'Submissions',
    },
    {
      'question': 'How and when do I receive project certificates?',
      'answer':
          'Once the company supervisor approves your work, an official verified completion certificate is generated automatically. You can view, download, or share it from the "Certificates" screen.',
      'category': 'Certificates',
    },
    {
      'question': 'How does messaging and company communication work?',
      'answer':
          'You can communicate directly with assigned company leads via the Messages & Chat section. All project conversations and supervisor notes are safely stored and updated in real-time.',
      'category': 'Communication',
    },
    {
      'question': 'Can I edit my profile information after signing up?',
      'answer':
          'Yes. Open the Profile tab and tap the "Edit Profile" button to update your name, university, skills, and bio at any time.',
      'category': 'Account',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      if (_searchQuery.isEmpty) return true;
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return q.contains(query) || a.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center & FAQs'),
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
          // Search box
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search questions, topics...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.grayText),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FAQ List
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredFaqs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.grayText),
                  const SizedBox(height: 12),
                  Text(
                    'No matching questions found',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try another keyword or reach out directly to support.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.grayText),
                  ),
                ],
              ),
            )
          else
            ...filteredFaqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      faq['question']!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer']!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.darkText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 24),

          // Contact Support CTA Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deepNavy, AppColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Still need help?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Our support team is available 24/7 to resolve any issues or queries.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactSupportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Contact Support Team'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deepNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    );
  }
}

