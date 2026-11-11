import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
import 'package:link_vibe/feature/company/presentation/widgets/company_executive_app_bar.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';

class CompanyProfileScreen extends StatefulWidget {
  final bool startInEditMode;

  const CompanyProfileScreen({
    super.key,
    this.startInEditMode = true,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = CompanyProfileService();

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  int _formResetRevision = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;

  late String _selectedIndustry;
  late String _selectedLogoInitial;
  Color _selectedLogoColor = AppColors.primaryBlue;

  static const List<String> _industryOptions = [
    'Software & Cloud Services',
    'Artificial Intelligence & Data',
    'FinTech & Banking',
    'Cybersecurity',
    'Healthcare & Biotech',
    'E-Commerce & Logistics',
    'EdTech & Learning',
    'Telecommunications',
    'Design & Creative Media',
  ];

  static const List<_BrandColorOption> _brandColors = [
    _BrandColorOption(color: AppColors.primaryBlue, label: 'Cobalt'),
    _BrandColorOption(color: AppColors.deepNavy, label: 'Executive Navy'),
    _BrandColorOption(color: AppColors.teal, label: 'Ocean Teal'),
    _BrandColorOption(color: AppColors.indigoAccent, label: 'Indigo'),
    _BrandColorOption(color: AppColors.statusOpen, label: 'Emerald'),
  ];

  @override
  void initState() {
    super.initState();
    final current = _profileService.currentProfile;

    _nameController = TextEditingController(text: current.companyName);
    _descriptionController = TextEditingController(text: current.description);
    _emailController = TextEditingController(text: current.officialEmail);
    _websiteController = TextEditingController(text: current.websiteUrl);
    _contactPersonController =
        TextEditingController(text: current.contactPersonName);
    _phoneController = TextEditingController(text: current.phoneNumber);
    _cityController = TextEditingController(text: current.city);
    _addressController = TextEditingController(text: current.completeAddress);

    _selectedIndustry = _resolveIndustry(current.industry);
    _selectedLogoInitial = _deriveInitial(current);

    for (final ctrl in _allControllers) {
      ctrl.addListener(_handleFieldChanged);
    }
    _profileService.currentProfileNotifier.addListener(_syncFromServiceIfClean);
  }

  List<TextEditingController> get _allControllers => [
        _nameController,
        _descriptionController,
        _emailController,
        _websiteController,
        _contactPersonController,
        _phoneController,
        _cityController,
        _addressController,
      ];

  String _resolveIndustry(String industry) {
    final clean = industry.trim();
    if (clean.isNotEmpty) return clean;
    return _industryOptions.first;
  }

  List<String> get _effectiveIndustryOptions {
    if (_industryOptions.contains(_selectedIndustry)) {
      return _industryOptions;
    }
    return [_selectedIndustry, ..._industryOptions];
  }

  String _deriveInitial(CompanyProfileModel profile) {
    if (profile.logoInitial.trim().isNotEmpty) {
      return profile.logoInitial.trim();
    }
    return SupabaseHelper.initialsFor(profile.companyName, fallback: 'CO');
  }

  void _syncFromServiceIfClean() {
    if (!mounted || _hasUnsavedChanges) return;
    _applyProfileToControllers(_profileService.currentProfile);
  }

  void _applyProfileToControllers(CompanyProfileModel profile) {
    for (final ctrl in _allControllers) {
      ctrl.removeListener(_handleFieldChanged);
    }

    _nameController.text = profile.companyName;
    _descriptionController.text = profile.description;
    _emailController.text = profile.officialEmail;
    _websiteController.text = profile.websiteUrl;
    _contactPersonController.text = profile.contactPersonName;
    _phoneController.text = profile.phoneNumber;
    _cityController.text = profile.city;
    _addressController.text = profile.completeAddress;

    for (final ctrl in _allControllers) {
      ctrl.addListener(_handleFieldChanged);
    }

    setState(() {
      _selectedIndustry = _resolveIndustry(profile.industry);
      _selectedLogoInitial = _deriveInitial(profile);
      _hasUnsavedChanges = false;
      _formResetRevision++;
    });
  }

  void _handleFieldChanged() {
    if (!mounted) return;
    final current = _profileService.currentProfile;
    final dirty = _computeIsDirty(current);
    final liveInitial = _nameController.text.trim().isNotEmpty
        ? SupabaseHelper.initialsFor(_nameController.text, fallback: 'CO')
        : _deriveInitial(current);

    setState(() {
      _hasUnsavedChanges = dirty;
      _selectedLogoInitial = liveInitial;
    });
  }

  bool _computeIsDirty(CompanyProfileModel baseline) {
    return _nameController.text.trim() != baseline.companyName.trim() ||
        _selectedIndustry != _resolveIndustry(baseline.industry) ||
        _descriptionController.text.trim() != baseline.description.trim() ||
        _emailController.text.trim() != baseline.officialEmail.trim() ||
        _websiteController.text.trim() != baseline.websiteUrl.trim() ||
        _contactPersonController.text.trim() !=
            baseline.contactPersonName.trim() ||
        _phoneController.text.trim() != baseline.phoneNumber.trim() ||
        _cityController.text.trim() != baseline.city.trim() ||
        _addressController.text.trim() != baseline.completeAddress.trim();
  }

  int get _completedFieldCount {
    final checks = [
      _nameController.text.trim().isNotEmpty,
      _selectedIndustry.trim().isNotEmpty,
      _descriptionController.text.trim().isNotEmpty,
      _contactPersonController.text.trim().isNotEmpty,
      _emailController.text.trim().isNotEmpty,
      _phoneController.text.trim().isNotEmpty,
      _websiteController.text.trim().isNotEmpty,
      _cityController.text.trim().isNotEmpty ||
          _addressController.text.trim().isNotEmpty,
    ];
    return checks.where((filled) => filled).length;
  }

  double get _completionRatio => _completedFieldCount / 8.0;

  @override
  void dispose() {
    _profileService.currentProfileNotifier
        .removeListener(_syncFromServiceIfClean);
    for (final ctrl in _allControllers) {
      ctrl.removeListener(_handleFieldChanged);
      ctrl.dispose();
    }
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Official corporate email is required';
    }
    final emailRegex = RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid corporate email (e.g. contact@yourcompany.com)';
    }
    return null;
  }

  String? _validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    if (!trimmed.contains('.') || trimmed.length < 5) {
      return 'Enter a valid website URL (e.g. https://yourcompany.com)';
    }
    if (!trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('www.')) {
      return 'URL should start with http://, https://, or www.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Official phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.length < 10 || clean.length > 15) {
      return 'Enter a valid phone number (10 to 15 digits)';
    }
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(clean)) {
      return 'Phone number contains invalid characters';
    }
    return null;
  }

  Future<void> _handleSaveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the highlighted required fields.'),
          backgroundColor: AppColors.statusClosed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final existing = _profileService.currentProfile;
      final derivedInitial = SupabaseHelper.initialsFor(
        _nameController.text,
        fallback: _selectedLogoInitial.isNotEmpty ? _selectedLogoInitial : 'CO',
      );

      final updatedProfile = CompanyProfileModel(
        id: existing.id,
        companyName: _nameController.text.trim(),
        industry: _selectedIndustry,
        description: _descriptionController.text.trim(),
        officialEmail: _emailController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        completeAddress: _addressController.text.trim(),
        logoUrl: existing.logoUrl,
        logoInitial: derivedInitial,
        isVerified: existing.isVerified,
      );

      await _profileService.updateProfile(updatedProfile);

      if (!mounted) return;
      setState(() {
        _selectedLogoInitial = derivedInitial;
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company profile saved successfully.'),
          backgroundColor: AppColors.statusOpen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppColors.statusClosed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openLogoColorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Monogram Accent Color',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your monogram "$_selectedLogoInitial" updates automatically from your company name.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _brandColors.map((option) {
                  final isSelected = _selectedLogoColor == option.color;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedLogoColor = option.color);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? option.color.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? option.color
                              : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: option.color,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            option.label,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CompanyProfileModel>(
      valueListenable: _profileService.currentProfileNotifier,
      builder: (context, profile, _) {
        final liveName = _nameController.text.trim();
        final displayName = liveName.isNotEmpty
            ? liveName
            : (profile.companyName.trim().isNotEmpty
                ? profile.companyName.trim()
                : 'Your Organization');

        final liveEmail = _emailController.text.trim();
        final displayEmail = liveEmail.isNotEmpty
            ? liveEmail
            : profile.officialEmail.trim();

        final completionPercent = (_completionRatio * 100).round();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CompanyExecutiveAppBar(
            title: 'Organization Profile',
            subtitle: _selectedIndustry,
            actions: [
              if (_hasUnsavedChanges)
                CompanyHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Reset Changes',
                  onPressed: _isSaving
                      ? null
                      : () => _applyProfileToControllers(profile),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '$completionPercent% Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroIdentityCard(
                        profile: profile,
                        displayName: displayName,
                        displayEmail: displayEmail,
                        completionPercent: completionPercent,
                      ),
                      const SizedBox(height: 18),
                      CompanySectionCard(
                        title: 'Organization Identity',
                        icon: Icons.business_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabeledField(
                              label: 'Registered Company Name',
                              isRequired: true,
                              child: _buildStyledTextField(
                                controller: _nameController,
                                hint: 'e.g. Acme Software Solutions',
                                icon: Icons.apartment_rounded,
                                capitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Company name is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Industry Sector',
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(_formResetRevision),
                                initialValue: _selectedIndustry,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.darkText,
                                ),
                                decoration: _fieldDecoration(
                                  hint: 'Select primary industry',
                                  icon: Icons.category_outlined,
                                ),
                                items: _effectiveIndustryOptions
                                    .map(
                                      (ind) => DropdownMenuItem(
                                        value: ind,
                                        child: Text(
                                          ind,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedIndustry = val;
                                      _hasUnsavedChanges = _computeIsDirty(
                                        _profileService.currentProfile,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBrandColorStrip(),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Company Overview',
                              child: _buildStyledTextField(
                                controller: _descriptionController,
                                hint:
                                    'Describe your product mission, engineering stack, and student mentorship focus...',
                                icon: Icons.notes_rounded,
                                maxLines: 4,
                                capitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CompanySectionCard(
                        title: 'Contact & Leadership',
                        icon: Icons.contact_mail_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabeledField(
                              label: 'Primary Contact Person',
                              isRequired: true,
                              child: _buildStyledTextField(
                                controller: _contactPersonController,
                                hint: 'e.g. Ayesha Khan (Engineering Lead)',
                                icon: Icons.person_outline_rounded,
                                capitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Contact person name is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Official Corporate Email',
                              isRequired: true,
                              child: _buildStyledTextField(
                                controller: _emailController,
                                hint: 'talent@yourcompany.com',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Official Phone Number',
                              isRequired: true,
                              child: _buildStyledTextField(
                                controller: _phoneController,
                                hint: '+92 300 1234567',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: _validatePhone,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Official Website',
                              child: _buildStyledTextField(
                                controller: _websiteController,
                                hint: 'https://yourcompany.com',
                                icon: Icons.language_rounded,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                validator: _validateWebsite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CompanySectionCard(
                        title: 'Headquarters & Location',
                        icon: Icons.location_on_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabeledField(
                              label: 'City / Region',
                              child: _buildStyledTextField(
                                controller: _cityController,
                                hint: 'e.g. Lahore, Islamabad, Remote',
                                icon: Icons.location_city_rounded,
                                capitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Office Address',
                              child: _buildStyledTextField(
                                controller: _addressController,
                                hint: 'Suite / Floor, Business Center',
                                icon: Icons.pin_drop_outlined,
                                maxLines: 2,
                                capitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.done,
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
          bottomNavigationBar: _buildBottomSaveBar(completionPercent),
        );
      },
    );
  }

  Widget _buildHeroIdentityCard({
    required CompanyProfileModel profile,
    required String displayName,
    required String displayEmail,
    required int completionPercent,
  }) {
    final completed = _completedFieldCount;

    return CompanyHeroBanner(
      initial: _selectedLogoInitial,
      monogramColor: _selectedLogoColor,
      monogramTextOnWhite: false,
      title: displayName,
      subtitle: _selectedIndustry,
      secondaryLine: displayEmail.isNotEmpty ? displayEmail : null,
      onMonogramTap: _openLogoColorSheet,
      monogramBadgeOverlay: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppColors.softShadow,
        ),
        child: const Icon(
          Icons.palette_outlined,
          size: 13,
          color: AppColors.deepNavy,
        ),
      ),
      bottomContent: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Profile Readiness ($completed/8 completed)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completionPercent%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightAqua,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _completionRatio.clamp(0.05, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionPercent == 100
                      ? AppColors.statusOpen
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: ${profile.lastUpdated}',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandColorStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.palette_outlined,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Brand Accent',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _brandColors.map((option) {
              final selected = _selectedLogoColor == option.color;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedLogoColor = option.color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.deepNavy : Colors.white,
                        width: selected ? 2.5 : 1.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: option.color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepNavy,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 3),
                Text(
                  '*',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines > 1 ? maxLines : 1,
      enabled: true,
      readOnly: false,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: capitalization,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
        height: 1.4,
      ),
      decoration: _fieldDecoration(
        hint: hint,
        icon: icon,
        maxLines: maxLines,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    final isMultiline = maxLines > 1;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13.5,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.background,
      alignLabelWithHint: isMultiline,
      prefixIcon: isMultiline
          ? Padding(
              padding: EdgeInsets.only(bottom: (maxLines - 1) * 18.0),
              child: Icon(icon, size: 19, color: AppColors.primaryBlue),
            )
          : Icon(icon, size: 19, color: AppColors.primaryBlue),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isMultiline ? 14 : 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.statusClosed, width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.statusClosed, width: 1.7),
      ),
    );
  }

  Widget _buildBottomSaveBar(int completionPercent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _hasUnsavedChanges
                                    ? AppColors.statusPending
                                    : AppColors.statusOpen,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                _hasUnsavedChanges
                                    ? 'Unsaved edits'
                                    : 'Ready to save',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$completionPercent% profile completeness',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _isSaving ? null : _handleSaveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandColorOption {
  final Color color;
  final String label;

  const _BrandColorOption({
    required this.color,
    required this.label,
  });
}
