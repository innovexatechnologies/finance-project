import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/certificate_pdf_service.dart';
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
          (AppDataService.instance.userName.isNotEmpty
              ? AppDataService.instance.userName
              : (AppDataService.instance.getProfile()['name'] ?? 'Ahmed Khan'))
                  .toString();

      // 1. Generate real PDF binary bytes
      final pdfBytes = await CertificatePdfService.generateCertificatePdf(
        studentName: studentName,
        projectTitle: project,
        certificateTitle: title,
        issuer: issuer,
        certId: certId,
        issueDate: date,
      );

      final safeName =
          'Certificate_${studentName.replaceAll(' ', '_')}_$certId.pdf';

      // 2. Save and trigger download
      final filePath = await saveAndDownloadFile(
        fileName: safeName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;

      // 3. Show interactive SnackBar with OPEN button
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloaded PDF: $safeName',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.amberAccent,
            onPressed: () async {
              try {
                await openDownloadedFile(
                  fileName: safeName,
                  filePath: filePath,
                  bytes: pdfBytes,
                  mimeType: 'application/pdf',
                );
              } catch (_) {}
            },
          ),
          backgroundColor: AppColors.statusOpen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
        ),
      );
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

  static Future<void> openCertificateDirectly({
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
          (AppDataService.instance.userName.isNotEmpty
              ? AppDataService.instance.userName
              : (AppDataService.instance.getProfile()['name'] ?? 'Ahmed Khan'))
                  .toString();

      final pdfBytes = await CertificatePdfService.generateCertificatePdf(
        studentName: studentName,
        projectTitle: project,
        certificateTitle: title,
        issuer: issuer,
        certId: certId,
        issueDate: date,
      );

      final safeName =
          'Certificate_${studentName.replaceAll(' ', '_')}_$certId.pdf';

      final filePath = await saveAndDownloadFile(
        fileName: safeName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      await openDownloadedFile(
        fileName: safeName,
        filePath: filePath,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open certificate: $e'),
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
    if (!context.mounted) return;
    try {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificate Document',
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await openDownloadedFile(
                    fileName: fileName,
                    filePath: filePath,
                    content: content,
                    mimeType: 'application/pdf',
                  );
                } catch (_) {}
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open in PDF App'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing file viewer dialog: $e');
    }
  }
}
