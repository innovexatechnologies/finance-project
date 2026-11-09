import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class FeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const FeedbackScreen({super.key, required this.project});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _revisionNotesController = TextEditingController();

  @override
  void dispose() {
    _revisionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Feedback Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.feedback_rounded,
                          color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Supervisor Feedback',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Great progress on the initial report! However, section 3 requires additional data metrics on customer retention. Please adjust and resubmit by the revised deadline.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF78350F),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Revised Deadline: Nov 18, 2026',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Revision Notes Field
            Text(
              'Revision Summary *',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _revisionNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Detail the modifications and additions made according to supervisor guidance...',
              ),
            ),
            const SizedBox(height: 20),

            // File Attachment Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded,
                      color: AppColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'revised_report_v2.pdf (Ready)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Resubmit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Revised work resubmitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Upload & Resubmit Work'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
