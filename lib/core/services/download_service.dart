import 'package:flutter/material.dart';
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
      final certId = certificate['id'] ?? 'CC-${DateTime.now().millisecondsSinceEpoch}';
      final date = certificate['date'] ?? 'March 2026';
      final studentName = AppDataService.instance.getProfile()['name'] ?? 'Ahmed Khan';

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
• Verification Link : https://campusconnect.edu.pk/verify/$certId

------------------------------------------------------------------------
Verified by CampusConnect Platform (Learn • Work • Grow)
Empowering Students with Real-World Corporate Experience.
========================================================================
''';

      final safeName = 'Certificate_${studentName.replaceAll(' ', '_')}_$certId.txt';
      await saveAndDownloadFile(
        fileName: safeName,
        content: certContent,
        mimeType: 'text/plain;charset=utf-8',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Certificate downloaded successfully! ($safeName)',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
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
}
