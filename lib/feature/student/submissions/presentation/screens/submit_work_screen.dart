import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

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
  bool _isSubmitting = false;
  bool _autoValidate = false;
  String _selectedFileName = 'project_report_final.pdf';

  @override
  void initState() {
    super.initState();
    _loadPreviousSubmission();
  }

  void _loadPreviousSubmission() {
    final projectId = widget.project['id']?.toString() ??
        widget.project['projectId']?.toString() ??
        '';
    final existing = AppDataService.instance.getSubmission(projectId);
    if (existing != null) {
      _responseController.text = existing['summary'] ?? '';
      _linkController.text = existing['workLink'] ?? '';
      if (existing['fileName'] != null && existing['fileName'].toString().isNotEmpty) {
        _selectedFileName = existing['fileName'];
      }
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    _linkController.dispose();
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

  void _showFileAttachmentSheet() {
    final customNameCtrl = TextEditingController();
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
              Text(
                'Select Deliverable File',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text('Final_Project_Report.pdf'),
                subtitle: const Text('2.4 MB • PDF Document'),
                onTap: () {
                  setState(() => _selectedFileName = 'Final_Project_Report.pdf');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_zip_rounded, color: Colors.amber),
                title: const Text('Source_Code_Archive.zip'),
                subtitle: const Text('14.2 MB • ZIP Archive'),
                onTap: () {
                  setState(() => _selectedFileName = 'Source_Code_Archive.zip');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.draw_rounded, color: Colors.deepPurple),
                title: const Text('UI_UX_Design_Prototypes.fig'),
                subtitle: const Text('8.1 MB • Figma Deliverable'),
                onTap: () {
                  setState(() => _selectedFileName = 'UI_UX_Design_Prototypes.fig');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: customNameCtrl,
                decoration: InputDecoration(
                  hintText: 'Or enter custom file name (e.g. results.docx)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primaryBlue),
                    onPressed: () {
                      final val = customNameCtrl.text.trim();
                      if (val.isNotEmpty) {
                        setState(() => _selectedFileName = val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitWork() async {
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all submission fields correctly (valid URL and descriptive summary required).',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedFileName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach your deliverable file before submitting.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final projectId = widget.project['id']?.toString() ??
          widget.project['projectId']?.toString() ??
          'proj_${DateTime.now().millisecondsSinceEpoch}';
      final projectTitle = widget.project['title'] ?? 'Assigned Project';
      final company = widget.project['company'] ?? 'Company';

      await AppDataService.instance.submitWork(
        projectId: projectId,
        projectTitle: projectTitle,
        company: company,
        summary: _responseController.text.trim(),
        workLink: _linkController.text.trim(),
        fileName: _selectedFileName,
      );

      if (!mounted) return;

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
                'Your work has been securely stored and sent to $company for review. You will receive feedback once evaluated.',
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
                    Navigator.pop(context); // dialog
                    Navigator.pop(context); // screen
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
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.project['title'] ?? 'Project Submission';
    final company = widget.project['company'] ?? 'TechVista';
    final projectId = widget.project['id']?.toString() ??
        widget.project['projectId']?.toString() ??
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Brief Box
            Container(
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
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lightAqua,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          existingSubmission != null
                              ? 'Submitted'
                              : 'Due Nov 15',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Client: $company',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                        'Previous submission stored (${existingSubmission['submittedAt']}). You can edit and re-submit below.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Form(
              key: _formKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submission Notes
                  Text(
                    'Summary & Notes *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _responseController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Explain what you completed, results obtained, methodology used, and any important notes...',
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Work summary is required';
                      }
                      if (v.length < 20) {
                        return 'Please provide more details (minimum 20 characters, currently ${v.length})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Live Demo / GitHub Repo Link
                  Text(
                    'Project URL / GitHub Repository Link *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _linkController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://github.com/username/project-repo',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Project / repository link is required';
                      }
                      if (!_isValidUrl(v)) {
                        return 'Please enter a valid URL link (e.g. https://github.com/username/repo or https://...)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // File Upload Section
            Text(
              'Deliverable File (PDF, ZIP, DOCX) *',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightAqua,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName.isNotEmpty
                              ? _selectedFileName
                              : 'No file selected',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedFileName.isNotEmpty
                                ? AppColors.deepNavy
                                : Colors.redAccent,
                          ),
                        ),
                        Text(
                          _selectedFileName.isNotEmpty
                              ? 'Deliverable attached • Ready for evaluation'
                              : 'Please attach a deliverable file',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _selectedFileName.isNotEmpty
                                ? AppColors.grayText
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showFileAttachmentSheet,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

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
                onPressed: _isSubmitting ? null : _submitWork,
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
                        existingSubmission != null
                            ? 'Update & Resubmit Work'
                            : 'Submit Work',
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
