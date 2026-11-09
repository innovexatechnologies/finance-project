import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      if (result.status == ShareResultStatus.unavailable) {
        if (context.mounted) {
          await _copyToClipboard(context, text);
        }
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, text);
      }
    }
  }

  static Future<void> shareProject({
    required BuildContext context,
    required Map<String, dynamic> project,
    Rect? sharePositionOrigin,
  }) async {
    final title = project['title'] ?? 'CampusConnect Project';
    final company = project['company'] ?? 'CampusConnect Partner';
    final stipend = project['stipend'] ?? project['budget'] ?? 'Competitive';
    final workMode = project['workMode'] ?? 'Remote';
    final duration = project['duration'] ?? 'Flexible';

    final shareMsg = '''
Check out this verified project on CampusConnect!

🚀 Project: $title
🏢 Company: $company
💰 Stipend: $stipend
🌐 Work Mode: $workMode
⏱️ Duration: $duration

Apply now on CampusConnect: https://campusconnect.edu.pk/projects/${project['id'] ?? 'explore'}
''';

    await shareText(
      context: context,
      text: shareMsg,
      subject: 'CampusConnect Project: $title',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareCertificate({
    required BuildContext context,
    required Map<String, dynamic> certificate,
    Rect? sharePositionOrigin,
  }) async {
    final title = certificate['title'] ?? 'Project Completion Certificate';
    final project = certificate['project'] ?? 'CampusConnect';
    final certId = certificate['id'] ?? 'CC-2026-CERT';
    final issuer = certificate['issuer'] ?? 'CampusConnect Partner';
    final date = certificate['date'] ?? '2026';

    final shareMsg = '''
🎓 I just earned a verified certificate on CampusConnect!

📜 Certificate: $title
💼 Project: $project
🏛️ Issued by: $issuer
🆔 Verification ID: $certId
📅 Date: $date

Verify online: https://campusconnect.edu.pk/verify/$certId
''';

    await shareText(
      context: context,
      text: shareMsg,
      subject: 'CampusConnect Certificate: $title',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Share details copied to clipboard! You can paste and share anywhere.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F3A70),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
