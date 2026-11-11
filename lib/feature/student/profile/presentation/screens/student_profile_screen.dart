import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/student_avatar.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/saved/presentation/screens/saved_projects_screen.dart';
import 'package:link_vibe/feature/student/settings/presentation/screens/settings_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const StudentProfileScreen({super.key, this.onTabChange});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _pickProfilePhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Please select an image smaller than 5 MB.'),
              backgroundColor: AppColors.statusClosed,
            ),
          );
        return;
      }

      if (mounted) {
        setState(() => _isUploadingPhoto = true);
      }

      final nameLower = picked.name.toLowerCase();
      final ext = nameLower.endsWith('.png')
          ? 'png'
          : (nameLower.endsWith('.webp') ? 'webp' : 'jpg');

      await AppDataService.instance.updateStudentAvatar(
        bytes,
        fileExtension: ext,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully.'),
            backgroundColor: AppColors.statusOpen,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not pick photo: $e'),
            backgroundColor: AppColors.statusClosed,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    if (_isUploadingPhoto) return;
    setState(() => _isUploadingPhoto = true);
    try {
      await AppDataService.instance.removeStudentAvatar();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed.'),
            backgroundColor: AppColors.statusOpen,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showAvatarOptionsSheet(bool hasPhoto) {
    if (_isUploadingPhoto) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Profile Photo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                subtitle: Text(
                  'Select a photo from your device gallery',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickProfilePhoto();
                },
              ),
              if (hasPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.statusClosed.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.statusClosed,
                    ),
                  ),
                  title: Text(
                    'Remove Current Photo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusClosed,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _removeProfilePhoto();
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF3F6FA),
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.deepNavy,
                  ),
                ),
                title: Text(
                  'Edit Academic Profile',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEditProfileDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final addedRaw = await showDialog<String>(
      context: context,
      builder: (_) => const _AddSkillDialog(),
    );

    if (addedRaw == null || addedRaw.trim().isEmpty) return;

    final entries = addedRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (entries.isEmpty) return;

    for (final skill in entries) {
      await AppDataService.instance.addSkill(skill);
    }
    if (!mounted) return;
    final label = entries.length == 1
        ? 'Skill "${entries.first}" added and synced!'
        : '${entries.length} skills added and synced!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.statusOpen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final profile = AppDataService.instance.getProfile();
    final updates = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditAcademicProfileDialog(initialProfile: profile),
    );

    if (updates == null) return;

    await AppDataService.instance.updateProfile(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated and synchronized with Supabase.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.statusOpen,
        duration: Duration(seconds: 2),
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
          appBar: ExecutiveAppBar(
            title: 'Student Profile',
            subtitle: 'Academic Portfolio & Identity',
            showLeading: Navigator.canPop(context),
            leadingBadge: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            actions: [
              ExecutiveHeaderIconButton(
                tooltip: 'Edit Profile',
                icon: Icons.edit_outlined,
                iconColor: AppColors.primaryBlue,
                onPressed: _showEditProfileDialog,
              ),
              const SizedBox(width: 8),
              ExecutiveHeaderIconButton(
                tooltip: 'Settings',
                icon: Icons.settings_outlined,
                iconColor: AppColors.deepNavy,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primaryBlue,
            backgroundColor: Colors.white,
            onRefresh: () =>
                AppDataService.instance.syncFromSupabase(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
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
                            borderRadius: BorderRadius.circular(14),
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

                      // Executive Student Hero Card
                      Builder(
                        builder: (_) {
                          final avatarUrl = profile['avatarUrl']?.toString();
                          final avatarBase64 =
                              profile['avatarBase64']?.toString();
                          final hasPhoto = (avatarBase64 != null &&
                                  avatarBase64.isNotEmpty) ||
                              (avatarUrl != null && avatarUrl.isNotEmpty);

                          final subtitleLine = (degree.isNotEmpty ||
                                  department.isNotEmpty)
                              ? [
                                  if (degree.isNotEmpty) degree,
                                  if (department.isNotEmpty) department,
                                ].join(' • ')
                              : (university.isNotEmpty
                                    ? university
                                    : 'Verified Student Portfolio');

                          final emailDisplay = (showEmail && email.isNotEmpty)
                              ? email
                              : (!showEmail
                                    ? 'Email hidden (Privacy Settings)'
                                    : null);

                          return ExecutiveHeroBanner(
                            initial: SupabaseHelper.initialsFor(
                              name,
                              fallback: 'ST',
                            ),
                            title: name,
                            subtitle: subtitleLine,
                            secondaryLine: emailDisplay,
                            secondaryIcon: showEmail
                                ? Icons.mail_outline_rounded
                                : Icons.visibility_off_outlined,
                            onMonogramTap: () =>
                                _showAvatarOptionsSheet(hasPhoto),
                            leadingVisual: Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    StudentAvatar(
                                      name: name,
                                      avatarUrl: avatarUrl,
                                      avatarBase64: avatarBase64,
                                      size: 58,
                                      borderWidth: 0,
                                    ),
                                    if (_isUploadingPhoto)
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black
                                              .withValues(alpha: 0.45),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            monogramBadgeOverlay: Tooltip(
                              message: 'Change Profile Photo',
                              child: GestureDetector(
                                onTap: () => _showAvatarOptionsSheet(hasPhoto),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            bottomContent: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ExecutiveHeroMicroStat(
                                    icon: Icons.verified_outlined,
                                    label: '$completedCount Projects',
                                  ),
                                  ExecutiveHeroMicroStat(
                                    icon: Icons.workspace_premium_outlined,
                                    label: '$certsCount Certificates',
                                  ),
                                  ExecutiveHeroMicroStat(
                                    icon: Icons.star_outline_rounded,
                                    label: 'Rating: $ratingDisplay',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 18),

                      // Academic Profile Card (strictly NO Location row!)
                      ExecutiveSectionCard(
                        title: 'Academic Profile',
                        icon: Icons.school_outlined,
                        accentColor: AppColors.primaryBlue,
                        headerTrailing: IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: _showEditProfileDialog,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.school_outlined,
                              'Institute',
                              university.isNotEmpty
                                  ? university
                                  : 'Not specified',
                            ),
                            if (semester.isNotEmpty ||
                                (cgpaVal != null && cgpaVal > 0)) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.menu_book_outlined,
                                'Academic Progress',
                                [
                                  if (semester.isNotEmpty)
                                    'Semester $semester',
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
                              _buildInfoRow(
                                Icons.link_rounded,
                                'Portfolio / GitHub',
                                portfolioUrl,
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(
                                color: AppColors.borderLight, height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'About / Bio',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 18),

                      // Skills & Expertise Card
                      ExecutiveSectionCard(
                        title: 'Skills & Expertise',
                        icon: Icons.bolt_rounded,
                        accentColor: AppColors.teal,
                        titleBadge: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: publicPortfolio
                                ? AppColors.lightAqua
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(6),
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
                        headerTrailing: IconButton(
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
                        child: skills.isEmpty
                            ? Text(
                                'No skills added yet. Tap + to highlight your technical competencies.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.grayText,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: skills.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    labelPadding: const EdgeInsets.only(
                                      left: 4,
                                      right: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepNavy,
                                    ),
                                    backgroundColor: AppColors.lightAqua
                                        .withValues(alpha: 0.55),
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
                      ),
                      const SizedBox(height: 18),

                      // Workspace Shortcuts Card
                      ExecutiveSectionCard(
                        title: 'Workspace Shortcuts',
                        icon: Icons.dashboard_customize_outlined,
                        accentColor: AppColors.indigoAccent,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
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
                              indent: 50,
                              color: AppColors.borderLight,
                            ),
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
                              indent: 50,
                              color: AppColors.borderLight,
                            ),
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

class _AddSkillDialog extends StatefulWidget {
  const _AddSkillDialog();

  @override
  State<_AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<_AddSkillDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = _controller.text.trim();
    if (val.isEmpty) {
      setState(() => _errorText = 'Please enter at least one skill.');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.pop(context, val);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add New Skill',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a technical skill or separate multiple skills with commas.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.grayText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'e.g. Flutter, SQL, UI/UX, Python',
                errorText: _errorText,
                prefixIcon: const Icon(Icons.code_rounded, size: 19),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EditAcademicProfileDialog extends StatefulWidget {
  final Map<String, dynamic> initialProfile;

  const _EditAcademicProfileDialog({required this.initialProfile});

  @override
  State<_EditAcademicProfileDialog> createState() =>
      _EditAcademicProfileDialogState();
}

class _EditAcademicProfileDialogState
    extends State<_EditAcademicProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _uniCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _degreeCtrl;
  late final TextEditingController _semesterCtrl;
  late final TextEditingController _cgpaCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _portfolioCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameCtrl = TextEditingController(text: p['name']?.toString() ?? '');
    _uniCtrl = TextEditingController(text: p['university']?.toString() ?? '');
    _deptCtrl = TextEditingController(text: p['department']?.toString() ?? '');
    _degreeCtrl = TextEditingController(text: p['degree']?.toString() ?? '');
    _semesterCtrl =
        TextEditingController(text: p['semester']?.toString() ?? '');
    _cgpaCtrl = TextEditingController(
      text: p['cgpa'] != null && (p['cgpa'] as num) > 0
          ? p['cgpa'].toString()
          : '',
    );
    _phoneCtrl = TextEditingController(text: p['phone']?.toString() ?? '');
    _portfolioCtrl = TextEditingController(
      text: p['portfolioUrl']?.toString() ??
          p['githubUrl']?.toString() ??
          '',
    );
    _bioCtrl = TextEditingController(text: p['bio']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uniCtrl.dispose();
    _deptCtrl.dispose();
    _degreeCtrl.dispose();
    _semesterCtrl.dispose();
    _cgpaCtrl.dispose();
    _phoneCtrl.dispose();
    _portfolioCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final parsedCgpa = double.tryParse(_cgpaCtrl.text.trim());
    Navigator.pop<Map<String, dynamic>>(context, {
      'name': _nameCtrl.text.trim(),
      'university': _uniCtrl.text.trim(),
      'department': _deptCtrl.text.trim(),
      'degree': _degreeCtrl.text.trim(),
      'semester': _semesterCtrl.text.trim(),
      'cgpa': ?parsedCgpa,
      'phone': _phoneCtrl.text.trim(),
      'portfolioUrl': _portfolioCtrl.text.trim(),
      'githubUrl': _portfolioCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
    });
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Edit Academic Profile',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.deepNavy,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField('Full Name', _nameCtrl, 'Enter full name'),
              _dialogField(
                'Institute / University',
                _uniCtrl,
                'e.g. FAST NUCES / NUST',
              ),
              _dialogField('Department', _deptCtrl, 'e.g. Computer Science'),
              _dialogField('Degree Program', _degreeCtrl, 'e.g. BSCS'),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      'Semester',
                      _semesterCtrl,
                      'e.g. 7th',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogField(
                      'CGPA',
                      _cgpaCtrl,
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
                _phoneCtrl,
                'e.g. +92 3xx xxxxxxx',
                keyboardType: TextInputType.phone,
              ),
              _dialogField(
                'Portfolio / GitHub URL',
                _portfolioCtrl,
                'https://github.com/username',
                keyboardType: TextInputType.url,
              ),
              _dialogField(
                'Professional Bio',
                _bioCtrl,
                'Highlight your academic strengths and goals',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
