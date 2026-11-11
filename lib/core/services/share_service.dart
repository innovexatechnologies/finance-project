import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

class ShareService {
  ShareService._();

  static const String _baseWebUrl = 'https://skillbridge.app';

  static String? _firstValidUrl(List<dynamic> candidates) {
    for (final raw in candidates) {
      final val = raw?.toString().trim() ?? '';
      if (val.isEmpty) continue;
      final normalized =
          (val.startsWith('http://') || val.startsWith('https://'))
          ? val
          : (val.contains('.') && !val.contains(' ') ? 'https://$val' : '');
      if (normalized.isEmpty) continue;
      final uri = Uri.tryParse(normalized);
      if (uri != null && uri.host.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static String _slugify(String raw, {String fallback = 'item'}) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  static String buildProjectShareLink(Map<String, dynamic> project) {
    final explicit = _firstValidUrl([
      project['shareUrl'],
      project['projectUrl'],
      project['url'],
      project['websiteUrl'],
      project['link'],
    ]);
    if (explicit != null) return explicit;

    final rawId = (project['projectId'] ?? project['id'] ?? '')
        .toString()
        .trim();
    final ref = rawId.isNotEmpty
        ? Uri.encodeComponent(rawId)
        : _slugify(
            project['title']?.toString() ?? 'project',
            fallback: 'project',
          );
    return '$_baseWebUrl/projects/$ref';
  }

  static String buildCertificateShareLink(Map<String, dynamic> certificate) {
    final explicit = _firstValidUrl([
      certificate['verificationUrl'],
      certificate['verifyUrl'],
      certificate['pdfUrl'],
      certificate['url'],
      certificate['shareUrl'],
    ]);
    if (explicit != null) return explicit;

    final certId =
        (certificate['id'] ?? certificate['certificateId'] ?? 'SB-CERT')
            .toString()
            .trim();
    return '$_baseWebUrl/verify/certificate/${Uri.encodeComponent(certId.isNotEmpty ? certId : 'SB-CERT')}';
  }

  static String buildStudentProfileShareLink(Map<String, dynamic> profile) {
    final uid =
        (profile['userId'] ?? profile['id'] ?? AppDataService.instance.userId)
            .toString()
            .trim();
    if (uid.isNotEmpty) {
      return '$_baseWebUrl/students/${Uri.encodeComponent(uid)}';
    }
    final nameSlug = _slugify(
      profile['name']?.toString() ?? AppDataService.instance.userName,
      fallback: 'portfolio',
    );
    return '$_baseWebUrl/students/$nameSlug';
  }

  static String buildProjectShareText(Map<String, dynamic> project) {
    final title = project['title']?.toString() ?? 'Project Opportunity';
    final company = project['company']?.toString() ?? 'Partner Company';
    final category = project['category']?.toString() ?? 'General';
    final stipend =
        project['stipend']?.toString() ??
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
    buffer.writeln('• Project Link: $projectLink');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Explore & Apply on SkillBridge: $projectLink');
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
    final studentName =
        (AppDataService.instance.userName.isNotEmpty
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
    buffer.writeln('• Verification ID: $certId');
    buffer.writeln('• Issue Date: $date');
    buffer.writeln('• Verify Link: $verifyLink');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Verify Credential Online: $verifyLink');
    return buffer.toString();
  }

  static String buildStudentProfileShareText(
    Map<String, dynamic> profile, {
    List<String> skills = const [],
  }) {
    final name = (profile['name']?.toString().trim().isNotEmpty == true)
        ? profile['name'].toString().trim()
        : (AppDataService.instance.userName.isNotEmpty
              ? AppDataService.instance.userName
              : 'SkillBridge Student');
    final university = profile['university']?.toString().trim() ?? '';
    final degree = profile['degree']?.toString().trim() ?? '';
    final department = profile['department']?.toString().trim() ?? '';
    final portfolioUrl = _firstValidUrl([
      profile['portfolioUrl'],
      profile['githubUrl'],
    ]);
    final profileLink = buildStudentProfileShareLink(profile);

    final buffer = StringBuffer();
    buffer.writeln('👤 SKILLBRIDGE STUDENT PROFILE');
    buffer.writeln('----------------------------------------');
    buffer.writeln('• Student: $name');
    if (university.isNotEmpty) buffer.writeln('• Institute: $university');
    if (degree.isNotEmpty || department.isNotEmpty) {
      buffer.writeln(
        '• Program: ${[if (degree.isNotEmpty) degree, if (department.isNotEmpty) department].join(' • ')}',
      );
    }
    if (skills.isNotEmpty) {
      buffer.writeln('• Skills: ${skills.join(', ')}');
    }
    if (portfolioUrl != null) {
      buffer.writeln('• Portfolio / GitHub: $portfolioUrl');
    }
    buffer.writeln('• Profile Link: $profileLink');
    buffer.writeln('----------------------------------------');
    buffer.writeln('View Student Portfolio on SkillBridge: $profileLink');
    return buffer.toString();
  }

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
    final shareMsg = buildProjectShareText(project);

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Project: $title',
      subject: 'SkillBridge Project: $title ($company)',
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

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Certificate: $title',
      subject: 'SkillBridge Certificate: $title',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareStudentProfile({
    required BuildContext context,
    required Map<String, dynamic> profile,
    List<String> skills = const [],
    Rect? sharePositionOrigin,
  }) async {
    final name = (profile['name']?.toString().trim().isNotEmpty == true)
        ? profile['name'].toString().trim()
        : 'Student Portfolio';
    final shareMsg = buildStudentProfileShareText(profile, skills: skills);

    await shareText(
      context: context,
      text: shareMsg,
      title: 'Share Profile: $name',
      subject: 'SkillBridge Portfolio: $name',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static void _showSharePreviewModal(
    BuildContext context,
    String sheetTitle,
    String content,
  ) {
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
