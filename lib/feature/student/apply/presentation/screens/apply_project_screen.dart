import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';

class ApplyProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ApplyProjectScreen({super.key, required this.project});

  @override
  State<ApplyProjectScreen> createState() => _ApplyProjectScreenState();
}

class _ApplyProjectScreenState extends State<ApplyProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverMessageController = TextEditingController();
  final _skillsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _portfolioController = TextEditingController();

  bool _isSubmitting = false;
  bool _autoValidate = false;

  static const List<String> _availabilityPresets = [
    '10 hrs/week (Part-time)',
    '15-20 hrs/week',
    'Flexible Evening Hours',
    'Full-time Sprint',
  ];

  @override
  void initState() {
    super.initState();
    final savedSkills = AppDataService.instance.getSkills();
    if (savedSkills.isNotEmpty) {
      _skillsController.text = savedSkills.join(', ');
    }
    final profile = AppDataService.instance.getProfile();
    final link = profile['portfolioUrl']?.toString().trim() ??
        profile['githubUrl']?.toString().trim() ??
        '';
    if (link.isNotEmpty) {
      _portfolioController.text = link;
    }
    _availabilityController.text = _availabilityPresets.first;
  }

  @override
  void dispose() {
    _coverMessageController.dispose();
    _skillsController.dispose();
    _availabilityController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String? text) {
    if (text == null) return false;
    final val = text.trim();
    if (val.isEmpty || val.contains(' ')) return false;

    String normalized = val;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return false;
    }

    final parts = uri.host.split('.');
    final tld = parts.last;
    if (tld.length < 2 || !RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
      return false;
    }

    return true;
  }

  Future<void> _submitApplication() async {
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields accurately before submitting.',
          ),
          backgroundColor: AppColors.statusClosed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final cover = _coverMessageController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      await AppDataService.instance.addApplication(
        project: widget.project,
        coverMessage: cover,
        skills: _skillsController.text.trim(),
        availability: _availabilityController.text.trim(),
        portfolioLink: _portfolioController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lightAqua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.statusOpen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Application Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your application has been sent to ${widget.project['company'] ?? 'the partner company'} and saved to Supabase. Track review stages in My Applications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grayText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SupabaseHelper.friendlyError(e)),
          backgroundColor: AppColors.statusClosed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.project['title']?.toString() ?? 'Project';
    final company =
        (widget.project['company']?.toString().trim().isNotEmpty == true)
            ? widget.project['company'].toString().trim()
            : 'Partner Company';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ExecutiveAppBar(
        title: 'Apply for Project',
        subtitle: company,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Summary Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightGray),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.lightAqua,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            SupabaseHelper.initialsFor(company, fallback: 'CO'),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            Text(
                              company,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.grayText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  'Application Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 14),

                Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Cover Message *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _coverMessageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Explain why you are a strong fit and how you plan to tackle the project deliverables...',
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Cover message is required';
                          if (v.length < 20) {
                            return 'Cover message must be at least 20 characters (currently ${v.length})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _fieldLabel('Relevant Skills & Experience *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Flutter, Dart, REST API, SQL',
                          prefixIcon: Icon(Icons.code_rounded, size: 20),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Please specify your relevant skills';
                          }
                          if (v.length < 2) {
                            return 'Please enter valid skill names';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _fieldLabel('Weekly Availability *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _availabilityController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 10-15 hrs/week',
                          prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                        ),
                        validator: (value) {
                          if ((value?.trim() ?? '').isEmpty) {
                            return 'Please enter your weekly availability';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _availabilityPresets.map((preset) {
                          return ActionChip(
                            label: Text(preset,
                                style: GoogleFonts.inter(fontSize: 11)),
                            onPressed: () {
                              _availabilityController.text = preset;
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      _fieldLabel('Portfolio / GitHub Profile Link *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _portfolioController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://github.com/your-username',
                          prefixIcon: Icon(Icons.link_rounded, size: 20),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Portfolio or GitHub link is required';
                          }
                          if (!_isValidUrl(v)) {
                            return 'Enter a valid URL (e.g. https://github.com/username)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }
}
