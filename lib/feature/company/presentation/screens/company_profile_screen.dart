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
    this.startInEditMode = false,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = CompanyProfileService();

  late bool _isEditing;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;

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

  static const List<Color> _brandColors = [
    AppColors.primaryBlue,
    AppColors.deepNavy,
    AppColors.teal,
    AppColors.indigoAccent,
    AppColors.statusOpen,
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode;
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

    _selectedIndustry = _industryOptions.contains(current.industry)
        ? current.industry
        : _industryOptions.first;
    _selectedLogoInitial = current.logoInitial.isNotEmpty
        ? current.logoInitial
        : SupabaseHelper.initialsFor(current.companyName, fallback: 'CO');

    _nameController.addListener(() {
      if (_isEditing) {
        setState(() {
          _selectedLogoInitial = SupabaseHelper.initialsFor(
            _nameController.text,
            fallback: 'CO',
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Official email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted validation fields.'),
          backgroundColor: AppColors.statusClosed,
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
        _isEditing = false;
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
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monogram Accent Color',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your monogram badge "$_selectedLogoInitial" updates automatically from your company name.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _brandColors.map((color) {
                  final isSelected = _selectedLogoColor == color;
                  return InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      setState(() => _selectedLogoColor = color);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.darkText : Colors.white,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
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
        final displayName = profile.companyName.trim().isNotEmpty
            ? profile.companyName.trim()
            : 'Your Organization';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CompanyExecutiveAppBar(
            title: _isEditing ? 'Edit Profile' : 'Organization Profile',
            subtitle: profile.industry.isNotEmpty
                ? profile.industry
                : 'Corporate Identity',
            actions: [
              if (!_isEditing)
                CompanyHeaderPillButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                CompanyHeaderPillButton(
                  label: 'Cancel',
                  onPressed: _isSaving
                      ? () {}
                      : () {
                          final current = _profileService.currentProfile;
                          _nameController.text = current.companyName;
                          _descriptionController.text = current.description;
                          _emailController.text = current.officialEmail;
                          _websiteController.text = current.websiteUrl;
                          _contactPersonController.text =
                              current.contactPersonName;
                          _phoneController.text = current.phoneNumber;
                          _cityController.text = current.city;
                          _addressController.text = current.completeAddress;
                          setState(() => _isEditing = false);
                        },
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(profile, displayName),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: 'Organization Identity',
                    icon: Icons.business_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Registered Company Name *',
                          hint: 'e.g. Acme Software Solutions',
                          enabled: _isEditing,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Company name is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedIndustry,
                          decoration: const InputDecoration(
                            labelText: 'Industry Sector',
                          ),
                          items: _industryOptions
                              .map(
                                (ind) => DropdownMenuItem(
                                  value: ind,
                                  child: Text(ind),
                                ),
                              )
                              .toList(),
                          onChanged: _isEditing
                              ? (val) {
                                  if (val != null) {
                                    setState(() => _selectedIndustry = val);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Company Overview',
                          hint:
                              'Briefly describe your engineering focus, product mission, and student collaboration style...',
                          maxLines: 4,
                          enabled: _isEditing,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Contact & Leadership',
                    icon: Icons.contact_mail_outlined,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _contactPersonController,
                          label: 'Primary Contact Person *',
                          hint: 'e.g. Ayesha Khan (Engineering Lead)',
                          enabled: _isEditing,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Contact person name is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Official Corporate Email *',
                          hint: 'talent@yourcompany.com',
                          keyboardType: TextInputType.emailAddress,
                          enabled: _isEditing,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Official Phone Number *',
                          hint: '+92 300 1234567',
                          keyboardType: TextInputType.phone,
                          enabled: _isEditing,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Official Website',
                          hint: 'https://yourcompany.com',
                          keyboardType: TextInputType.url,
                          enabled: _isEditing,
                          validator: _validateWebsite,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Headquarters & Location',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _cityController,
                          label: 'City / Region',
                          hint: 'e.g. Lahore, Islamabad, Remote',
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Office Address',
                          hint: 'Suite / Floor, Business Center',
                          maxLines: 2,
                          enabled: _isEditing,
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _isSaving ? null : _handleSaveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Saving Profile...' : 'Save Organization Profile',
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildHeaderBanner(CompanyProfileModel profile, String displayName) {
    return CompanyHeroBanner(
      initial: _selectedLogoInitial,
      monogramColor: _selectedLogoColor,
      monogramTextOnWhite: false,
      title: displayName,
      subtitle: profile.industry.isNotEmpty
          ? profile.industry
          : 'Corporate Partner',
      secondaryLine: profile.officialEmail.trim().isNotEmpty
          ? profile.officialEmail.trim()
          : null,
      footerText: 'Last updated: ${profile.lastUpdated}',
      onMonogramTap: _openLogoColorSheet,
      monogramBadgeOverlay: _isEditing
          ? Container(
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
            )
          : null,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return CompanySectionCard(
      title: title,
      icon: icon,
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 13.5,
        color: enabled ? AppColors.darkText : AppColors.grayText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
