import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'package:link_vibe/feature/student/saved/presentation/screens/saved_projects_screen.dart';
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
    final user = SupabaseHelper.currentUser;
    if (user == null) return;

    final name = user.userMetadata?['name']?.toString().trim() ?? '';
    final email = user.email?.trim() ?? '';
    final university =
        user.userMetadata?['university']?.toString().trim() ?? '';
    final currentProfile = AppDataService.instance.getProfile();

    final updates = <String, dynamic>{};
    if ((currentProfile['name']?.toString().trim() ?? '').isEmpty &&
        name.isNotEmpty) {
      updates['name'] = name;
    }
    if ((currentProfile['email']?.toString().trim() ?? '').isEmpty &&
        email.isNotEmpty) {
      updates['email'] = email;
    }
    if ((currentProfile['university']?.toString().trim() ?? '').isEmpty &&
        university.isNotEmpty) {
      updates['university'] = university;
    }

    if (updates.isNotEmpty) {
      AppDataService.instance.updateProfile(updates);
    }
  }

  Future<void> _showAddSkillDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
            hintText: 'e.g. Flutter, SQL, UI/UX, Python',
          ),
          onSubmitted: (val) => Navigator.pop(dialogCtx, val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (added != null && added.isNotEmpty) {
      await AppDataService.instance.addSkill(added);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skill "$added" added and synced!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final profile = AppDataService.instance.getProfile();
    final nameCtrl =
        TextEditingController(text: profile['name']?.toString() ?? '');
    final uniCtrl =
        TextEditingController(text: profile['university']?.toString() ?? '');
    final deptCtrl =
        TextEditingController(text: profile['department']?.toString() ?? '');
    final degreeCtrl =
        TextEditingController(text: profile['degree']?.toString() ?? '');
    final semesterCtrl =
        TextEditingController(text: profile['semester']?.toString() ?? '');
    final cgpaCtrl = TextEditingController(
      text: profile['cgpa'] != null ? profile['cgpa'].toString() : '',
    );
    final phoneCtrl =
        TextEditingController(text: profile['phone']?.toString() ?? '');
    final portfolioCtrl = TextEditingController(
      text: profile['portfolioUrl']?.toString() ??
          profile['githubUrl']?.toString() ??
          '',
    );
    final bioCtrl =
        TextEditingController(text: profile['bio']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Edit Academic Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogField('Full Name', nameCtrl, 'Enter full name'),
                _dialogField('Institute / University', uniCtrl,
                    'e.g. FAST NUCES / NUST'),
                _dialogField('Department', deptCtrl, 'e.g. Computer Science'),
                _dialogField('Degree Program', degreeCtrl, 'e.g. BSCS'),
                Row(
                  children: [
                    Expanded(
                      child: _dialogField(
                          'Semester', semesterCtrl, 'e.g. 7th'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dialogField(
                        'CGPA',
                        cgpaCtrl,
                        'e.g. 3.65',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                _dialogField(
                  'Contact Phone',
                  phoneCtrl,
                  'e.g. +92 3xx xxxxxxx',
                  keyboardType: TextInputType.phone,
                ),
                _dialogField(
                  'Portfolio / GitHub URL',
                  portfolioCtrl,
                  'https://github.com/username',
                  keyboardType: TextInputType.url,
                ),
                _dialogField(
                  'Professional Bio',
                  bioCtrl,
                  'Highlight your academic strengths and goals',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final parsedCgpa = double.tryParse(cgpaCtrl.text.trim());
      await AppDataService.instance.updateProfile({
        'name': nameCtrl.text.trim(),
        'university': uniCtrl.text.trim(),
        'department': deptCtrl.text.trim(),
        'degree': degreeCtrl.text.trim(),
        'semester': semesterCtrl.text.trim(),
        'cgpa': ?parsedCgpa,
        'phone': phoneCtrl.text.trim(),
        'portfolioUrl': portfolioCtrl.text.trim(),
        'githubUrl': portfolioCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated and synchronized with Supabase.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    nameCtrl.dispose();
    uniCtrl.dispose();
    deptCtrl.dispose();
    degreeCtrl.dispose();
    semesterCtrl.dispose();
    cgpaCtrl.dispose();
    phoneCtrl.dispose();
    portfolioCtrl.dispose();
    bioCtrl.dispose();
  }

  Widget _dialogField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  String _computeRatingDisplay() {
    final certs = AppDataService.instance.getCertificates();
    final ratings = certs
        .map((c) => (c['rating'] as num?)?.toDouble())
        .whereType<double>()
        .where((r) => r > 0)
        .toList();
    if (ratings.isEmpty) return '—';
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    return '${avg.toStringAsFixed(1)} ★';
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

        final pName = profile['name']?.toString().trim() ?? '';
        final name = pName.isNotEmpty
            ? pName
            : (AppDataService.instance.userName.trim().isNotEmpty
                ? AppDataService.instance.userName.trim()
                : 'Student');

        final pEmail = profile['email']?.toString().trim() ?? '';
        final email = pEmail.isNotEmpty
            ? pEmail
            : AppDataService.instance.userEmail.trim();

        final university = profile['university']?.toString().trim() ?? '';
        final degree = profile['degree']?.toString().trim() ?? '';
        final department = profile['department']?.toString().trim() ?? '';
        final semester = profile['semester']?.toString().trim() ?? '';
        final cgpaVal = (profile['cgpa'] as num?)?.toDouble();
        final phone = profile['phone']?.toString().trim() ?? '';
        final portfolioUrl = profile['portfolioUrl']?.toString().trim() ??
            profile['githubUrl']?.toString().trim() ??
            '';
        final bio = profile['bio']?.toString().trim() ?? '';

        final completedCount = AppDataService.instance.completedProjectsCount;
        final certsCount = AppDataService.instance.certificatesCount;
        final ratingDisplay = _computeRatingDisplay();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Student Profile'),
            actions: [
              IconButton(
                tooltip: 'Edit Profile',
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primaryBlue),
                onPressed: _showEditProfileDialog,
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.deepNavy),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primaryBlue,
            onRefresh: () =>
                AppDataService.instance.syncFromSupabase(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    children: [
                      if (!profileVisibility) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.statusPending
                                  .withValues(alpha: 0.5),
                            ),
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
                                  'Profile Visibility is Private: Partner companies cannot discover your profile in searches.',
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

                      // Avatar & Edit
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.brandGradient,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  SupabaseHelper.initialsFor(
                                    name,
                                    fallback: 'ST',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
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

                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      if (degree.isNotEmpty || department.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (degree.isNotEmpty) degree,
                            if (department.isNotEmpty) department,
                          ].join(' • '),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      if (showEmail && email.isNotEmpty)
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      else if (!showEmail)
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

                      // Live Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileStat(
                              completedCount.toString(),
                              'Projects',
                              AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildProfileStat(
                              certsCount.toString(),
                              'Certificates',
                              AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildProfileStat(
                              ratingDisplay,
                              'Rating',
                              AppColors.statusPending,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Academic Profile Card (strictly NO Location row!)
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
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: _showEditProfileDialog,
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 17, color: AppColors.primaryBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              Icons.school_outlined,
                              'Institute',
                              university.isNotEmpty ? university : 'Not specified',
                            ),
                            if (semester.isNotEmpty ||
                                (cgpaVal != null && cgpaVal > 0)) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.menu_book_outlined,
                                'Academic Progress',
                                [
                                  if (semester.isNotEmpty) 'Semester $semester',
                                  if (cgpaVal != null && cgpaVal > 0)
                                    'CGPA ${cgpaVal.toStringAsFixed(2)}',
                                ].join(' • '),
                              ),
                            ],
                            if (showPhone && phone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                  Icons.phone_outlined, 'Phone', phone),
                            ],
                            if (portfolioUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.link_rounded, 'Portfolio / GitHub',
                                  portfolioUrl),
                            ],
                            const SizedBox(height: 12),
                            const Divider(
                                color: AppColors.lightGray, height: 1),
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
                              bio.isNotEmpty
                                  ? bio
                                  : 'Add a short academic bio via Edit Profile to introduce yourself to companies.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: bio.isNotEmpty
                                    ? AppColors.darkText
                                    : AppColors.grayText,
                                fontStyle: bio.isNotEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Skills & Expertise Card
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
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Skills & Expertise',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.deepNavy,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: publicPortfolio
                                              ? AppColors.lightAqua
                                              : AppColors.surfaceAlt,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          publicPortfolio ? 'Public' : 'Private',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: publicPortfolio
                                                ? AppColors.teal
                                                : AppColors.grayText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Add Skill',
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 21,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onPressed: _showAddSkillDialog,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (skills.isEmpty)
                              Text(
                                'No skills added yet. Tap + to highlight your technical competencies.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.grayText,
                                ),
                              )
                            else
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
                                    backgroundColor:
                                        AppColors.lightAqua.withValues(alpha: 0.5),
                                    side: BorderSide(
                                      color:
                                          AppColors.teal.withValues(alpha: 0.3),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: AppColors.grayText,
                                    ),
                                    onDeleted: () {
                                      AppDataService.instance
                                          .removeSkill(skill);
                                    },
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Shortcuts Card
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
                            const Divider(
                                height: 1,
                                indent: 56,
                                color: AppColors.lightGray),
                            _buildMenuItem(
                              Icons.workspace_premium_rounded,
                              'My Certificates',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CertificatesScreen(),
                                  ),
                                );
                              },
                              AppColors.teal,
                            ),
                            const Divider(
                                height: 1,
                                indent: 56,
                                color: AppColors.lightGray),
                            _buildMenuItem(
                              Icons.bookmark_rounded,
                              'Saved Projects (${AppDataService.instance.getSavedProjects().length})',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SavedProjectsScreen(),
                                  ),
                                );
                              },
                              AppColors.primaryBlue,
                            ),
                            const Divider(
                                height: 1,
                                indent: 56,
                                color: AppColors.lightGray),
                            _buildMenuItem(
                              Icons.chat_bubble_outline_rounded,
                              'Messages with Companies',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatListScreen(),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text(
            count,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
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
        Icon(icon, size: 17, color: AppColors.grayText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.grayText),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
      ),
    );
  }
}
