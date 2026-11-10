import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';

class SubmitWorkScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const SubmitWorkScreen({super.key, required this.project});

  @override
  State<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends State<SubmitWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  final _linkController = TextEditingController();
  final _fileNameController = TextEditingController();
  bool _isSubmitting = false;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousSubmission();
  }

  void _loadPreviousSubmission() {
    final projectId = widget.project['projectId']?.toString() ??
        widget.project['id']?.toString() ??
        '';
    final existing = AppDataService.instance.getSubmission(projectId);
    if (existing != null) {
      _responseController.text = existing['summary']?.toString() ?? '';
      _linkController.text = existing['workLink']?.toString() ?? '';
      _fileNameController.text = existing['fileName']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    _linkController.dispose();
    _fileNameController.dispose();
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

  Future<void> _submitWork() async {
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide a valid URL, deliverable label, and detailed summary.',
          ),
          backgroundColor: AppColors.statusClosed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final projectId = widget.project['projectId']?.toString() ??
          widget.project['id']?.toString() ??
          '';
      final projectTitle =
          widget.project['title']?.toString().trim().isNotEmpty == true
              ? widget.project['title'].toString().trim()
              : 'Assigned Project';
      final company =
          widget.project['company']?.toString().trim().isNotEmpty == true
              ? widget.project['company'].toString().trim()
              : 'Partner Company';

      await AppDataService.instance.submitWork(
        projectId: projectId,
        projectTitle: projectTitle,
        company: company,
        summary: _responseController.text.trim(),
        workLink: _linkController.text.trim(),
        fileName: _fileNameController.text.trim(),
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
                  Icons.task_alt_rounded,
                  size: 48,
                  color: AppColors.statusOpen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Work Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your deliverable has been recorded and sent to $company for review.',
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
                  child: const Text('Back to My Projects'),
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
          content: Text('Error submitting work: $e'),
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
    final title = widget.project['title']?.toString().trim().isNotEmpty == true
        ? widget.project['title'].toString().trim()
        : 'Project Deliverable';
    final company =
        widget.project['company']?.toString().trim().isNotEmpty == true
            ? widget.project['company'].toString().trim()
            : 'Partner Company';
    final deadline = widget.project['deadline']?.toString().trim() ?? '';
    final projectId = widget.project['projectId']?.toString() ??
        widget.project['id']?.toString() ??
        '';
    final existingSubmission = AppDataService.instance.getSubmission(projectId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit Project Work'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightGray),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: existingSubmission != null
                                ? 'Submitted'
                                : (deadline.isNotEmpty
                                    ? 'Due: $deadline'
                                    : 'Pending'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Partner: $company',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (existingSubmission != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.teal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Previous submission recorded (${existingSubmission['submittedAt'] ?? 'Recently'}). Update fields below to resubmit.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Summary & Methodology *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _responseController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe completed deliverables, key findings, methodology, and testing verification...',
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Work summary is required';
                          if (v.length < 20) {
                            return 'Provide at least 20 characters (currently ${v.length})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _label('Project URL / Cloud Drive / GitHub Repo *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _linkController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://github.com/username/deliverable',
                          prefixIcon: Icon(Icons.link_rounded, size: 20),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Deliverable repository or cloud link is required';
                          }
                          if (!_isValidUrl(v)) {
                            return 'Enter a valid URL (e.g. https://github.com/user/repo)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _label('Deliverable Package / File Name *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fileNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. final_report.pdf or source_build.zip',
                          prefixIcon: Icon(Icons.description_outlined, size: 20),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Please specify your deliverable file name or artifact label';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitWork,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            existingSubmission != null
                                ? 'Update & Resubmit Work'
                                : 'Submit Work',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }
}
