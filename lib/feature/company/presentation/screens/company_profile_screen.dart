import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/company_profile_model.dart';
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

  // Form Field Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;

  // Selected State
  late String _selectedIndustry;
  late String _selectedLogoInitial;
  late Color _selectedLogoColor;

  final List<String> _industryOptions = [
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

  final List<Map<String, dynamic>> _logoPresets = [
    {'label': 'TV (Default)', 'initial': 'TV', 'color': AppColors.primary},
    {'label': 'Cloud Tech', 'initial': 'CT', 'color': AppColors.accentTeal},
    {'label': 'AI Systems', 'initial': 'AI', 'color': Color(0xFF7C3AED)},
    {'label': 'Data Labs', 'initial': 'DL', 'color': Color(0xFF059669)},
    {'label': 'Global Soft', 'initial': 'GS', 'color': AppColors.darkNavy},
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

    _selectedIndustry = current.industry.isNotEmpty
        ? current.industry
        : _industryOptions.first;
    _selectedLogoInitial = current.logoInitial;
    _selectedLogoColor = AppColors.primary;
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

  // Email format validator
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Official email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid corporate email (e.g. name@company.com)';
    }
    return null;
  }

  // Website URL validator
  String? _validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Website URL is required';
    }
    final trimmed = value.trim();
    if (!trimmed.contains('.') || trimmed.length < 5) {
      return 'Enter a valid website URL (e.g. https://company.com)';
    }
    if (!trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('www.')) {
      return 'URL should start with http://, https://, or www.';
    }
    return null;
  }

  // Phone number validator
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

  // Save profile changes
  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors below.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = CompanyProfileModel(
        id: _profileService.currentProfile.id,
        companyName: _nameController.text.trim(),
        industry: _selectedIndustry,
        description: _descriptionController.text.trim(),
        officialEmail: _emailController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        completeAddress: _addressController.text.trim(),
        logoInitial: _selectedLogoInitial,
        isVerified: true,
      );

      await _profileService.updateProfile(updatedProfile);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company profile successfully updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while saving. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Logo selection bottom sheet
  void _openLogoPickerBottomSheet() {
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Organization Logo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a verified corporate brand icon or customize monogram:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ..._logoPresets.map((preset) {
                final isSelected = _selectedLogoInitial == preset['initial'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: preset['color'] as Color,
                    child: Text(
                      preset['initial'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    preset['label'] as String,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLogoInitial = preset['initial'] as String;
                      _selectedLogoColor = preset['color'] as Color;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Company Profile (Screen 23)'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _isEditing ? AppColors.error : AppColors.primary,
            ),
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              size: 18,
            ),
            label: Text(
              _isEditing ? 'Cancel' : 'Edit Profile',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Reset form to saved profile
                  final current = _profileService.currentProfile;
                  _nameController.text = current.companyName;
                  _descriptionController.text = current.description;
                  _emailController.text = current.officialEmail;
                  _websiteController.text = current.websiteUrl;
                  _contactPersonController.text = current.contactPersonName;
                  _phoneController.text = current.phoneNumber;
                  _cityController.text = current.city;
                  _addressController.text = current.completeAddress;
                  _selectedIndustry = current.industry;
                  _selectedLogoInitial = current.logoInitial;
                }
                _isEditing = !_isEditing;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // 1. Logo Upload & Identity Header
            _buildLogoAndHeaderSection(),
            const SizedBox(height: 20),

            // 2. Organization Information Card
            _buildSectionCard(
              title: 'Organization Identity',
              icon: Icons.business_outlined,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Company Name',
                  hint: 'e.g. TechVista Innovations',
                  icon: Icons.corporate_fare_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    if (val.trim().length < 3) {
                      return 'Company name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildIndustryDropdown(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Company Description',
                  hint:
                      'Provide an overview of your organization and the domain of challenges you offer...',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Company description is required';
                    }
                    if (val.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Official Contact & Web Presence Card
            _buildSectionCard(
              title: 'Official Contact & Web Presence',
              icon: Icons.contact_mail_outlined,
              children: [
                _buildTextField(
                  controller: _emailController,
                  label: 'Official Email',
                  hint: 'e.g. partnerships@company.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _websiteController,
                  label: 'Website URL',
                  hint: 'e.g. https://techvistainnovations.com',
                  icon: Icons.language_rounded,
                  keyboardType: TextInputType.url,
                  validator: _validateWebsite,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Official Phone Number',
                  hint: 'e.g. +92 300 1234567',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Point of Contact (Representative) Card
            _buildSectionCard(
              title: 'Authorized Representative',
              icon: Icons.badge_outlined,
              children: [
                _buildTextField(
                  controller: _contactPersonController,
                  label: 'Contact Person Name',
                  hint: 'e.g. Danish Ali Rajpoot (HR / Project Lead)',
                  icon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Contact person name is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Office Location & Address Card
            _buildSectionCard(
              title: 'Headquarters & Location',
              icon: Icons.location_on_outlined,
              children: [
                _buildTextField(
                  controller: _cityController,
                  label: 'City / Region',
                  hint: 'e.g. Islamabad, Pakistan',
                  icon: Icons.location_city_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'City or region is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Complete Office Address',
                  hint: 'e.g. Plot 42, Executive Tech Park, Sector I-9/3',
                  icon: Icons.map_outlined,
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Complete office address is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Save / Action Button
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _handleSaveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSaving ? 'Saving Profile...' : 'Save Profile Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightIceBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Profile is in view mode. Tap "Edit Profile" in top-right to update organization details.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 1. Logo Upload & Identity Header
  Widget _buildLogoAndHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _openLogoPickerBottomSheet,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: _selectedLogoColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightIceBlue,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedLogoColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _selectedLogoInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _openLogoPickerBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'TechVista Innovations',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'Verified Campus Corporate Partner',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: _openLogoPickerBottomSheet,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Change Brand Logo'),
              ),
            ),
        ],
      ),
    );
  }

  // Section Card wrapper
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Text Input field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: _isEditing ? AppColors.textPrimary : AppColors.darkNavy,
        fontWeight: _isEditing ? FontWeight.normal : FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: _isEditing ? AppColors.background : const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  // Industry Dropdown
  Widget _buildIndustryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedIndustry,
      decoration: InputDecoration(
        labelText: 'Industry Sector',
        prefixIcon: const Icon(
          Icons.domain_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        filled: true,
        fillColor: _isEditing ? AppColors.background : const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: _industryOptions
          .map(
            (ind) => DropdownMenuItem(
              value: ind,
              child: Text(
                ind,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: _isEditing
          ? (val) {
              if (val != null) {
                setState(() {
                  _selectedIndustry = val;
                });
              }
            }
          : null,
    );
  }
}

