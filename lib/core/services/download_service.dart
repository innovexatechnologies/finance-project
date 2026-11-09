import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'download/download_stub.dart'
    if (dart.library.html) 'download/download_web.dart';

class DownloadService {
  DownloadService._();

  static Future<void> downloadCertificate({
    required BuildContext context,
    required Map<String, dynamic> certificate,
  }) async {
    try {
      final title = certificate['title'] ?? 'Project Completion Certificate';
      final project = certificate['project'] ?? 'Corporate Project';
      final issuer = certificate['issuer'] ?? 'CampusConnect & Partner';
      final certId =
          certificate['id'] ?? 'CC-${DateTime.now().millisecondsSinceEpoch}';
      final date = certificate['date'] ?? 'March 2026';
      final studentName =
          AppDataService.instance.getProfile()['name'] ?? 'Ahmed Khan';

      final certContent = '''
========================================================================
                      CAMPUSCONNECT CERTIFICATE OF COMPLETION
========================================================================

This is to certify that:

                        ${studentName.toUpperCase()}

has successfully completed the verified corporate project:

                "${project.toUpperCase()}"

Project Details:
------------------------------------------------------------------------
• Certificate Title : $title
• Issuing Authority : $issuer
• Student Name      : $studentName
• Verification ID   : $certId
• Issue Date        : $date

------------------------------------------------------------------------
Verified by CampusConnect Platform (Learn • Work • Grow)
Empowering Students with Real-World Corporate Experience.
========================================================================
''';

      final safeName =
          'Certificate_${studentName.replaceAll(' ', '_')}_$certId.txt';
      final filePath = await saveAndDownloadFile(
        fileName: safeName,
        content: certContent,
        mimeType: 'text/plain;charset=utf-8',
      );

      if (!context.mounted) return;

      // 1. Show interactive SnackBar with Open button
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloaded: $safeName',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.amberAccent,
            onPressed: () {
              openFileViewer(context, safeName, filePath, certContent);
            },
          ),
          backgroundColor: AppColors.statusOpen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );

      // 2. Open File Viewer Dialog
      openFileViewer(context, safeName, filePath, certContent);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void openFileViewer(
    BuildContext context,
    String fileName,
    String filePath,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_rounded,
                  color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificate File Opened',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                color: AppColors.darkText,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Certificate file verified and saved to device.'),
                  backgroundColor: AppColors.statusOpen,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
