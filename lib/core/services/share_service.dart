import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

class ShareService {
  ShareService._();

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String? title,
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
          _showSharePreviewModal(context, title ?? 'Share Details', text);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showSharePreviewModal(context, title ?? 'Share Details', text);
      }
    }
  }

  static Future<void> shareProject({
    required BuildContext context,
    required Map<String, dynamic> project,
    Rect? sharePositionOrigin,
  }) async {
    final title = project['title']?.toString() ?? 'Project Opportunity';
    final company = project['company']?.toString() ?? 'Partner Company';
    final category = project['category']?.toString() ?? 'General';
    final stipend = project['stipend']?.toString() ??
        project['budget']?.toString() ??
        'Competitive / Experience';
    final workMode = project['workMode']?.toString() ?? 'Remote';
    final duration = project['duration']?.toString() ?? 'Flexible';
    final description = project['description']?.toString() ?? '';

    String skills = '';
    if (project['skills'] is List) {
      skills = (project['skills'] as List).join(', ');
    } else if (project['skills'] != null) {
      skills = project['skills'].toString();
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 CAMPUSCONNECT PROJECT DETAILS');
    buffer.writeln('----------------------------------------');
    buffer.writeln('• Title: $title');
    buffer.writeln('• Company: $company');
    buffer.writeln('• Category: $category');
    buffer.writeln('• Work Mode: $workMode');
    buffer.writeln('• Duration: $duration');
    buffer.writeln('• Stipend: $stipend');
    if (skills.isNotEmpty) {
      buffer.writeln('• Required Skills: $skills');
    }
    if (description.isNotEmpty) {
      buffer.writeln('• Description: $description');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('Verified Project on CampusConnect');

    final shareMsg = buffer.toString();

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Project: $title',
      subject: 'CampusConnect Project: $title ($company)',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareCertificate({
    required BuildContext context,
    required Map<String, dynamic> certificate,
    Rect? sharePositionOrigin,
  }) async {
    final title = certificate['title']?.toString() ??
        'Project Completion Certificate';
    final project = certificate['project']?.toString() ?? 'Corporate Project';
    final certId = certificate['id']?.toString() ?? 'CC-CERT';
    final issuer = certificate['issuer']?.toString() ?? 'CampusConnect Partner';
    final date = certificate['date']?.toString() ?? '2026';
    final studentName =
        AppDataService.instance.getProfile()['name']?.toString() ??
            'Ahmed Khan';

    final buffer = StringBuffer();
    buffer.writeln('🎓 VERIFIED CERTIFICATE OF COMPLETION');
    buffer.writeln('----------------------------------------');
    buffer.writeln('• Certificate: $title');
    buffer.writeln('• Student Name: $studentName');
    buffer.writeln('• Project Completed: $project');
    buffer.writeln('• Issuing Authority: $issuer');
    buffer.writeln('• Verification ID: $certId');
    buffer.writeln('• Issue Date: $date');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Verified via CampusConnect Student Platform');

    final shareMsg = buffer.toString();

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Certificate: $title',
      subject: 'CampusConnect Certificate: $title',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static void _showSharePreviewModal(
      BuildContext context, String sheetTitle, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sheetTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: AppColors.darkText,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Details to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: content));
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Complete details copied! Ready to share.'),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.statusOpen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
