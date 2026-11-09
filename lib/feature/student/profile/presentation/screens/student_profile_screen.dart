import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/saved/presentation/screens/saved_projects_screen.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/settings_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const StudentProfileScreen({super.key, this.onTabChange});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String _name = 'Ahmed Khan';
  String _email = 'ahmed.khan@student.edu.pk';
  final String _university = 'National University of Computer & Emerging Sciences';
  final String _degree = 'BS Computer Science (6th Semester)';

  final List<String> _skills = [
    'Flutter',
    'Dart',
    'UI/UX Design',
    'REST APIs',
    'Firebase',
    'Git & GitHub',
    'Python',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final name = user.userMetadata?['name'];
      final email = user.email;
      setState(() {
        if (name != null && name.toString().isNotEmpty) {
          _name = name.toString();
        }
        if (email != null && email.isNotEmpty) {
          _email = email;
        }
      });
    }
  }

  void _showAddSkillDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Skill', style: GoogleFonts.poppins(fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Node.js, SQL, Figma'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final skill = controller.text.trim();
              if (skill.isNotEmpty) {
                setState(() {
                  _skills.add(skill);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Profile Card Header matching Image 5
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                children: [
                  // Avatar with Edit Badge
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.lightAqua,
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    _name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  Text(
                    _email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Degree & University
                  Text(
                    '$_degree\n$_university',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.grayText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row matching Image 5: 12 Projects | 8 Certificates | 4.8 Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('12', 'Projects'),
                      _buildVerticalDivider(),
                      _buildStatColumn('8', 'Certificates'),
                      _buildVerticalDivider(),
                      _buildStatColumn('4.8 ★', 'Rating'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Skills & Portfolio Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Skills & Expertise',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      InkWell(
                        onTap: _showAddSkillDialog,
                        child: Text(
                          '+ Add Skill',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills
                        .map(
                          (skill) => Chip(
                            backgroundColor: AppColors.lightAqua,
                            label: Text(
                              skill,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.transparent),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Navigation List Items matching Image 5
            _buildProfileMenuItem(
              icon: Icons.business_center_outlined,
              title: 'My Projects',
              accentColor: const Color(0xFFD97706),
              onTap: () => widget.onTabChange?.call(2),
            ),
            _buildProfileMenuItem(
              icon: Icons.workspace_premium_outlined,
              title: 'My Certificates',
              accentColor: AppColors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CertificatesScreen(),
                  ),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.bookmark_border_rounded,
              title: 'Saved Projects',
              accentColor: AppColors.primaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedProjectsScreen(),
                  ),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Messages & Mentors',
              accentColor: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.stars_rounded,
              title: 'Earnings (Points)',
              subtitle: '2,400 Activity Points',
              accentColor: const Color(0xFFF59E0B),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Points can be redeemed for verified certificates and workshops.')),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings & Privacy',
              accentColor: AppColors.grayText,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.grayText,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.lightGray,
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.grayText,
        ),
        onTap: onTap,
      ),
    );
  }
}
