import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

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
  final _availabilityController =
      TextEditingController(text: '10-15 hrs/week (Flexible)');
  final _portfolioController = TextEditingController();

  bool _isSubmitting = false;
  bool _autoValidate = false;

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
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
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
            'Please fill all required fields correctly according to specifications.',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final cover = _coverMessageController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AppDataService.instance.addApplication(
        project: widget.project,
        coverMessage: cover,
        skills: _skillsController.text.trim(),
        availability: _availabilityController.text.trim(),
        portfolioLink: _portfolioController.text.trim(),
      );

      if (!mounted) return;

      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                'Your application has been received by ${widget.project['company'] ?? 'the company'} and saved persistently. You can track its progress in My Applications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grayText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to details/explore
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
          content: Text('Error submitting application: $e'),
          backgroundColor: Colors.red,
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
    final title = widget.project['title'] ?? 'Project';
    final company = widget.project['company'] ?? 'Company';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apply for Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                        company[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        Text(
                          company,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Title
            Text(
              'Application Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Message
                  Text(
                    'Cover Message *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _coverMessageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Introduce yourself, mention why you are interested in this project and why you are a great fit...',
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Cover message is required';
                      }
                      if (v.length < 20) {
                        return 'Cover message must be at least 20 characters (currently ${v.length})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Relevant Skills
                  Text(
                    'Relevant Skills & Experience *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Flutter, Dart, REST API, Git',
                      prefixIcon: Icon(Icons.code_rounded, size: 20),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Please specify your relevant skills (required)';
                      }
                      if (v.length < 2) {
                        return 'Please enter valid skill names';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Availability
                  Text(
                    'Weekly Availability *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _availabilityController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 10-15 hrs/week (Flexible)',
                      prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Please enter your weekly availability';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Portfolio / GitHub Link
                  Text(
                    'Portfolio / GitHub Profile Link *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
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
                        return 'Portfolio / GitHub link is required';
                      }
                      if (!_isValidUrl(v)) {
                        return 'Please enter a valid URL link (e.g. https://github.com/username or https://...)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitApplication,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Application',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
