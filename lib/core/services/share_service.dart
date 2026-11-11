import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

/// Builds and dispatches shareable summaries with in-app SkillBridge deep links
/// for Projects, Applications, and Certificates.
class ShareService {
  ShareService._();

  static const String appScheme = 'skillbridge';

  /// Registered by DeepLinkService so fallback previews can open links in-app.
  static Future<bool> Function(String uri, {BuildContext? context})?
      deepLinkOpener;

  static String _slugify(String raw, {String fallback = 'item'}) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  static String buildProjectShareLink(Map<String, dynamic> project) {
    final rawId = (project['projectId'] ?? project['id'] ?? '')
        .toString()
        .trim();
    final title = (project['title'] ?? '').toString().trim();

    if (rawId.isNotEmpty) {
      return Uri(
        scheme: appScheme,
        host: 'project',
        pathSegments: [rawId],
      ).toString();
    }

    return Uri(
      scheme: appScheme,
      host: 'project',
      pathSegments: [
        _slugify(title.isEmpty ? 'project' : title, fallback: 'project'),
      ],
      queryParameters: {
        if (title.isNotEmpty) 'title': title,
      },
    ).toString();
  }

  static String buildApplicationShareLink(Map<String, dynamic> application) {
    final rawId = (application['id'] ?? application['applicationId'] ?? '')
        .toString()
        .trim();
    final projectId =
        (application['projectId'] ?? application['project_id'] ?? '')
            .toString()
            .trim();
    final title = (application['title'] ?? '').toString().trim();

    final targetId = rawId.isNotEmpty
        ? rawId
        : (projectId.isNotEmpty
            ? projectId
            : _slugify(title.isEmpty ? 'application' : title,
                fallback: 'application'));

    final query = <String, String>{
      if (projectId.isNotEmpty && projectId != targetId) 'projectId': projectId,
    };

    return Uri(
      scheme: appScheme,
      host: 'application',
      pathSegments: [targetId],
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  static String buildCertificateShareLink(Map<String, dynamic> certificate) {
    final certId = (certificate['id'] ??
            certificate['certificateId'] ??
            certificate['dbId'] ??
            'SB-CERT')
        .toString()
        .trim();
    return Uri(
      scheme: appScheme,
      host: 'certificate',
      pathSegments: [certId.isNotEmpty ? certId : 'SB-CERT'],
    ).toString();
  }

  static String buildProjectShareText(Map<String, dynamic> project) {
    final title = project['title']?.toString() ?? 'Project Opportunity';
    final company = project['company']?.toString() ?? 'Partner Company';
    final category = project['category']?.toString() ?? 'General';
    final stipend = project['stipend']?.toString() ??
        project['budget']?.toString() ??
        'Competitive / Experience';
    final workMode = project['workMode']?.toString() ?? 'Remote';
    final duration = project['duration']?.toString() ?? 'Flexible';
    final description = project['description']?.toString() ?? '';
    final projectLink = buildProjectShareLink(project);

    String skills = '';
    if (project['skills'] is List) {
      skills = (project['skills'] as List).join(', ');
    } else if (project['skills'] != null) {
      skills = project['skills'].toString();
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 SKILLBRIDGE PROJECT DETAILS');
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
    buffer.writeln('• Open in SkillBridge App: $projectLink');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Tap to view project in SkillBridge: $projectLink');
    return buffer.toString();
  }

  static String buildApplicationShareText(Map<String, dynamic> application) {
    final title = application['title']?.toString() ?? 'Project Application';
    final company = application['company']?.toString() ?? 'Partner Company';
    final status = application['status']?.toString() ?? 'Pending';
    final stage = application['timelineStep']?.toString() ?? '1';
    final appliedDate = application['appliedDate']?.toString() ?? 'Recently';
    final availability =
        application['availability']?.toString().trim() ?? '';
    final skills = application['skills']?.toString().trim() ?? '';
    final appLink = buildApplicationShareLink(application);

    final buffer = StringBuffer();
    buffer.writeln('📝 SKILLBRIDGE PROJECT APPLICATION');
    buffer.writeln('----------------------------------------');
    buffer.writeln('• Project: $title');
    buffer.writeln('• Company: $company');
    buffer.writeln('• Status: $status (Stage $stage of 3)');
    buffer.writeln('• Applied On: $appliedDate');
    if (availability.isNotEmpty) {
      buffer.writeln('• Availability: $availability');
    }
    if (skills.isNotEmpty) {
      buffer.writeln('• Skills: $skills');
    }
    buffer.writeln('• Open in SkillBridge App: $appLink');
    buffer.writeln('----------------------------------------');
    buffer.writeln('View application in SkillBridge: $appLink');
    return buffer.toString();
  }

  static String buildCertificateShareText(Map<String, dynamic> certificate) {
    final title =
        certificate['title']?.toString() ?? 'Project Completion Certificate';
    final project = certificate['project']?.toString() ?? 'Corporate Project';
    final certId = certificate['id']?.toString() ?? 'SB-CERT';
    final issuer = certificate['issuer']?.toString() ?? 'SkillBridge Partner';
    final date = certificate['date']?.toString() ?? '2026';
    final verifyLink = buildCertificateShareLink(certificate);
    final explicitStudent =
        certificate['studentName']?.toString().trim() ?? '';
    final studentName = explicitStudent.isNotEmpty
        ? explicitStudent
        : (AppDataService.instance.userName.isNotEmpty
                ? AppDataService.instance.userName
                : (AppDataService.instance.getProfile()['name'] ?? 'Student'))
            .toString();

    final buffer = StringBuffer();
    buffer.writeln('🎓 VERIFIED CERTIFICATE OF COMPLETION');
    buffer.writeln('----------------------------------------');
    buffer.writeln('• Certificate: $title');
    buffer.writeln('• Student Name: $studentName');
    buffer.writeln('• Project Completed: $project');
    buffer.writeln('• Issuing Authority: $issuer');
    buffer.writeln('• Credential ID: $certId');
    buffer.writeln('• Issue Date: $date');
    buffer.writeln('• Open in SkillBridge App: $verifyLink');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Verify credential in SkillBridge: $verifyLink');
    return buffer.toString();
  }

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String? title,
    String? subject,
    String? deepLinkUri,
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
          _showSharePreviewModal(
            context,
            title ?? 'Share Details',
            text,
            deepLinkUri: deepLinkUri,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showSharePreviewModal(
          context,
          title ?? 'Share Details',
          text,
          deepLinkUri: deepLinkUri,
        );
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
    final shareMsg = buildProjectShareText(project);
    final link = buildProjectShareLink(project);

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Project: $title',
      subject: 'SkillBridge Project: $title ($company)',
      deepLinkUri: link,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareApplication({
    required BuildContext context,
    required Map<String, dynamic> application,
    Rect? sharePositionOrigin,
  }) async {
    final title = application['title']?.toString() ?? 'Project Application';
    final company = application['company']?.toString() ?? 'Partner Company';
    final shareMsg = buildApplicationShareText(application);
    final link = buildApplicationShareLink(application);

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Application: $title',
      subject: 'SkillBridge Application: $title ($company)',
      deepLinkUri: link,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareCertificate({
    required BuildContext context,
    required Map<String, dynamic> certificate,
    Rect? sharePositionOrigin,
  }) async {
    final title =
        certificate['title']?.toString() ?? 'Project Completion Certificate';
    final shareMsg = buildCertificateShareText(certificate);
    final link = buildCertificateShareLink(certificate);

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Certificate: $title',
      subject: 'SkillBridge Certificate: $title',
      deepLinkUri: link,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static void _showSharePreviewModal(
    BuildContext context,
    String sheetTitle,
    String content, {
    String? deepLinkUri,
  }) {
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
            if (deepLinkUri != null &&
                deepLinkUri.isNotEmpty &&
                deepLinkOpener != null) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open Link in App'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await deepLinkOpener?.call(deepLinkUri, context: context);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
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
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complete details copied! Ready to share.',
                            ),
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
