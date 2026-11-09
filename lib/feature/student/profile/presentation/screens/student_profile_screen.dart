import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSupabaseUser();
    });
  }

  void _syncSupabaseUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final name = user.userMetadata?['name'];
      final email = user.email;
      final university = user.userMetadata?['university'];
      final currentProfile = AppDataService.instance.getProfile();
      final currentName = currentProfile['name']?.toString() ?? '';
      final isGeneric = currentName.isEmpty || currentName == 'Ahmed Khan';

      AppDataService.instance.updateProfile({
        if (name != null && name.toString().isNotEmpty && isGeneric)
          'name': name.toString(),
        if (email != null && email.isNotEmpty) 'email': email,
        if (university != null && university.toString().isNotEmpty)
          'university': university.toString(),
      });
    }
  }

  void _showAddSkillDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add New Skill',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Node.js, SQL, Docker, SEO',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSkill = controller.text.trim();
              if (newSkill.isNotEmpty) {
                AppDataService.instance.addSkill(newSkill);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Skill "$newSkill" added and saved!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final profile = AppDataService.instance.getProfile();
    final nameCtrl = TextEditingController(text: profile['name']);
    final uniCtrl = TextEditingController(text: profile['university']);
    final phoneCtrl = TextEditingController(
        text: profile['phone'] ?? '+92 300 1234567');
    final bioCtrl = TextEditingController(text: profile['bio']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: nameCtrl),
              const SizedBox(height: 12),
              Text('University', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: uniCtrl),
              const SizedBox(height: 12),
              Text('Contact Phone', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              Text('Professional Bio', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: bioCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AppDataService.instance.updateProfile({
                'name': nameCtrl.text.trim(),
                'university': uniCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated and saved permanently!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final profile = AppDataService.instance.getProfile();
        final skills = AppDataService.instance.getSkills();
        final privacy = AppDataService.instance.getPrivacySettings();
        final showEmail = privacy['showEmail'] ?? true;
        final showPhone = privacy['showPhone'] ?? false;
        final publicPortfolio = privacy['publicPortfolio'] ?? true;
        final profileVisibility = privacy['profileVisibility'] ?? true;

        final name = (profile['name'] != null &&
                profile['name'].toString().isNotEmpty &&
                profile['name'].toString() != 'Ahmed Khan')
            ? profile['name'].toString()
            : (AppDataService.instance.userName.isNotEmpty
                ? AppDataService.instance.userName
                : (profile['name'] ?? 'Student'));
        final email = (profile['email'] != null && profile['email'].toString().isNotEmpty)
            ? profile['email'].toString()
            : (AppDataService.instance.userEmail.isNotEmpty
                ? AppDataService.instance.userEmail
                : 'student@campusconnect.edu.pk');
        final university = (profile['university'] != null &&
                profile['university'].toString().isNotEmpty)
            ? profile['university'].toString()
            : 'National University';
        final degree = profile['degree'] ?? 'BS Computer Science';
        final bio = profile['bio'] ?? 'Student passionate about real-world projects.';

        final completedCount = AppDataService.instance.completedProjectsCount;
        final certsCount = AppDataService.instance.certificatesCount;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Student Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.deepNavy),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile Visibility Warning Banner (if toggled Private)
                if (!profileVisibility) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_off_rounded,
                          size: 20,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Profile Visibility is Private: Your profile is hidden from partner company directory searches.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Profile Avatar & Edit Button
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lightAqua,
                          border: Border.all(
                            color: AppColors.primaryBlue,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name & Degree
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  degree,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 4),
                if (showEmail)
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_off_outlined,
                        size: 13,
                        color: AppColors.grayText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Email hidden (Privacy Settings)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // 3 Statistics Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileStat(
                          completedCount.toString(), 'Projects', AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildProfileStat(
                          certsCount.toString(), 'Certificates', AppColors.teal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildProfileStat(
                          '4.9 ★', 'Rating', const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Academic & Bio Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                            'Academic Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: const Icon(Icons.edit_outlined,
                                size: 16, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.school_outlined, 'Institute', university),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on_outlined, 'Location',
                          profile['location'] ?? 'Lahore, Pakistan'),
                      if (showPhone) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone_outlined, 'Phone',
                            profile['phone'] ?? '+92 300 1234567'),
                      ],
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.lightGray, height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'About / Bio',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.darkText,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Skills & Portfolio Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                          Row(
                            children: [
                              Text(
                                'Skills & Expertise',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: publicPortfolio
                                      ? AppColors.lightAqua
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  publicPortfolio ? 'Public' : 'Private',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: publicPortfolio
                                        ? AppColors.teal
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 20,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: _showAddSkillDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.deepNavy,
                            ),
                            backgroundColor: AppColors.lightAqua.withValues(alpha: 0.5),
                            side: BorderSide(
                              color: AppColors.teal.withValues(alpha: 0.3),
                            ),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.grayText,
                            ),
                            onDeleted: () {
                              AppDataService.instance.removeSkill(skill);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Navigation Shortcuts Menu Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        Icons.business_center_rounded,
                        'My Projects',
                        () => widget.onTabChange?.call(2),
                        const Color(0xFFD97706),
                      ),
                      const Divider(height: 1, indent: 56, color: AppColors.lightGray),
                      _buildMenuItem(
                        Icons.workspace_premium_rounded,
                        'My Certificates',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CertificatesScreen(),
                            ),
                          );
                        },
                        AppColors.teal,
                      ),
                      const Divider(height: 1, indent: 56, color: AppColors.lightGray),
                      _buildMenuItem(
                        Icons.bookmark_rounded,
                        'Saved Projects (${AppDataService.instance.getSavedProjects().length})',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedProjectsScreen(),
                            ),
                          );
                        },
                        AppColors.primaryBlue,
                      ),
                      const Divider(height: 1, indent: 56, color: AppColors.lightGray),
                      _buildMenuItem(
                        Icons.chat_bubble_outline_rounded,
                        'Messages with Companies',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatListScreen(),
                            ),
                          );
                        },
                        const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grayText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.grayText),
              ),
              Text(
                val,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.grayText,
      ),
      onTap: onTap,
    );
  }
}
