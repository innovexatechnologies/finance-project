import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';

class FeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const FeedbackScreen({super.key, required this.project});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _revisionNotesController = TextEditingController();
  final _linkController = TextEditingController();
  final _fileNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final projectId = widget.project['projectId']?.toString() ??
        widget.project['id']?.toString() ??
        '';
    final existing = AppDataService.instance.getSubmission(projectId);
    if (existing != null) {
      _revisionNotesController.text = existing['summary']?.toString() ?? '';
      _linkController.text = existing['workLink']?.toString() ?? '';
      _fileNameController.text = existing['fileName']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _revisionNotesController.dispose();
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
    final tld = uri.host.split('.').last;
    return tld.length >= 2 && RegExp(r'^[a-zA-Z]+$').hasMatch(tld);
  }

  Future<void> _submitRevision() async {
    if (!_formKey.currentState!.validate()) return;

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
        summary: _revisionNotesController.text.trim(),
        workLink: _linkController.text.trim(),
        fileName: _fileNameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revised deliverables submitted for review!'),
          backgroundColor: AppColors.statusOpen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit revision: $e'),
          backgroundColor: AppColors.statusClosed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.project['projectId']?.toString() ??
        widget.project['id']?.toString() ??
        '';
    final existing = AppDataService.instance.getSubmission(projectId);
    final rawFeedback = widget.project['companyFeedback']?.toString().trim() ??
        existing?['feedback']?.toString().trim() ??
        '';
    final feedbackText = rawFeedback.isNotEmpty
        ? rawFeedback
        : 'Your supervisor requested adjustments to the previous submission. Please address the updates below and resubmit.';
    final deadline = widget.project['deadline']?.toString().trim() ?? '';
    final projectTitle =
        widget.project['title']?.toString().trim().isNotEmpty == true
            ? widget.project['title'].toString().trim()
            : 'Project Revision';
    final company =
        widget.project['company']?.toString().trim().isNotEmpty == true
            ? widget.project['company'].toString().trim()
            : 'Partner Company';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feedback & Revisions'),
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
                // Project Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
                      const StatusBadge(label: 'Revision Requested'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Supervisor Feedback Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statusPending),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.feedback_rounded,
                              color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Supervisor Feedback',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedbackText,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: const Color(0xFF78350F),
                          height: 1.5,
                        ),
                      ),
                      if (deadline.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Target Deadline: $deadline',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revision Notes *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _revisionNotesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Summarize the updates made in response to supervisor feedback...',
                        ),
                        validator: (val) {
                          final v = val?.trim() ?? '';
                          if (v.isEmpty) return 'Revision notes are required';
                          if (v.length < 20) {
                            return 'Provide at least 20 characters describing revisions';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Updated Deliverable URL *',
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
                          hintText: 'https://github.com/username/updated-work',
                          prefixIcon: Icon(Icons.link_rounded, size: 20),
                        ),
                        validator: (val) {
                          final v = val?.trim() ?? '';
                          if (v.isEmpty) return 'Updated URL is required';
                          if (!_isValidUrl(v)) {
                            return 'Please enter a valid URL link';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Updated Deliverable File Name *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fileNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. deliverable_v2.pdf',
                          prefixIcon:
                              Icon(Icons.attach_file_rounded, size: 20),
                        ),
                        validator: (val) {
                          if ((val?.trim() ?? '').isEmpty) {
                            return 'Deliverable file name is required';
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
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitRevision,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'Resubmitting...'
                          : 'Resubmit Updated Work',
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
}
