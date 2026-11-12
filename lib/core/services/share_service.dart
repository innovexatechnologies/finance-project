import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

class ShareService {
  ShareService._();

  static String buildProjectShareText(Map<String, dynamic> project) {
    final title = _value(project['title'], 'Project Opportunity');
    final company = _value(project['company'], 'Partner Company');
    final category = _value(project['category'], 'General');
    final workMode = _value(project['workMode'], 'Remote');
    final duration = _value(project['duration'], 'Flexible');
    final stipend = project['stipend']?.toString().trim().isNotEmpty == true
        ? project['stipend'].toString().trim()
        : (project['budget']?.toString().trim().isNotEmpty == true
              ? project['budget'].toString().trim()
              : 'Academic Credit / Verified Certificate');
    final description = project['description']?.toString().trim() ?? '';
    final skills = project['skills'] is List
        ? (project['skills'] as List).join(', ')
        : project['skills']?.toString().trim() ?? '';

    final buffer = StringBuffer()
      ..writeln('*$title* — $company')
      ..writeln('Category: $category • $workMode • $duration')
      ..writeln('Stipend: $stipend');
    if (skills.isNotEmpty) buffer.writeln('Skills: $skills');
    if (description.isNotEmpty) {
      buffer.writeln(
        description.length > 160
            ? '${description.substring(0, 157)}...'
            : description,
      );
    }
    return buffer.toString().trim();
  }

  static String buildApplicationShareText(Map<String, dynamic> application) {
    final title = _value(application['title'], 'Project Application');
    final company = _value(application['company'], 'Partner Company');
    final status = _value(application['status'], 'Pending');
    final stage = _value(application['timelineStep'], '1');
    final appliedDate = _value(application['appliedDate'], 'Recently');
    final availability = application['availability']?.toString().trim() ?? '';
    final skills = application['skills']?.toString().trim() ?? '';

    final buffer = StringBuffer()
      ..writeln('*SkillBridge Application: $title* — $company')
      ..writeln('Status: $status (Stage $stage of 3) • Applied: $appliedDate');
    if (availability.isNotEmpty) buffer.writeln('Availability: $availability');
    if (skills.isNotEmpty) buffer.writeln('Skills: $skills');
    return buffer.toString().trim();
  }

  static String buildCertificateShareText(Map<String, dynamic> certificate) {
    final title = _value(
      certificate['title'],
      'Project Completion Certificate',
    );
    final project = _value(certificate['project'], 'Corporate Project');
    final certId = _value(certificate['id'], 'SB-CERT');
    final issuer = _value(certificate['issuer'], 'SkillBridge Partner');
    final date = _value(certificate['date'], '2026');
    final explicitStudent = certificate['studentName']?.toString().trim() ?? '';
    final studentName = explicitStudent.isNotEmpty
        ? explicitStudent
        : (AppDataService.instance.userName.isNotEmpty
                  ? AppDataService.instance.userName
                  : (AppDataService.instance.getProfile()['name'] ?? 'Student'))
              .toString();

    return '*$title*\n'
        'Awarded to $studentName for "$project"\n'
        'Issued by $issuer • $date • ID: $certId';
  }

  static String _value(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static Future<void> shareProject({
    required BuildContext context,
    required Map<String, dynamic> project,
    Rect? sharePositionOrigin,
  }) async {
    final title = _value(project['title'], 'Project Opportunity');
    final company = _value(project['company'], 'Partner Company');
    _showShareSheet(
      context: context,
      sheetTitle: 'Share Project',
      itemTitle: title,
      itemSubtitle:
          '$company • ${_value(project['workMode'], 'Remote')} • ${_value(project['duration'], 'Flexible')}',
      badgeLabel: project['stipend']?.toString().trim().isNotEmpty == true
          ? project['stipend'].toString().trim()
          : _value(project['category'], 'Open'),
      icon: Icons.work_outline_rounded,
      accentColor: AppColors.primaryBlue,
      shareText: buildProjectShareText(project),
      subject: 'SkillBridge Project: $title ($company)',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareApplication({
    required BuildContext context,
    required Map<String, dynamic> application,
    Rect? sharePositionOrigin,
  }) async {
    final title = _value(application['title'], 'Project Application');
    final company = _value(application['company'], 'Partner Company');
    final status = _value(application['status'], 'Pending');
    final stage = _value(application['timelineStep'], '1');
    _showShareSheet(
      context: context,
      sheetTitle: 'Share Application',
      itemTitle: title,
      itemSubtitle: '$company • Stage $stage of 3',
      badgeLabel: status,
      icon: Icons.assignment_outlined,
      accentColor: AppColors.indigoAccent,
      shareText: buildApplicationShareText(application),
      subject: 'SkillBridge Application: $title ($company)',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareCertificate({
    required BuildContext context,
    required Map<String, dynamic> certificate,
    Rect? sharePositionOrigin,
  }) async {
    final title = _value(
      certificate['title'],
      'Project Completion Certificate',
    );
    final issuer = _value(certificate['issuer'], 'SkillBridge Partner');
    final date = _value(certificate['date'], '2026');
    final certId = _value(certificate['id'], 'SB-CERT');
    _showShareSheet(
      context: context,
      sheetTitle: 'Share Certificate',
      itemTitle: title,
      itemSubtitle: '$issuer • $date',
      badgeLabel: certId,
      icon: Icons.workspace_premium_rounded,
      accentColor: AppColors.teal,
      shareText: buildCertificateShareText(certificate),
      subject: 'SkillBridge Certificate: $title',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static void _showShareSheet({
    required BuildContext context,
    required String sheetTitle,
    required String itemTitle,
    required String itemSubtitle,
    required String badgeLabel,
    required IconData icon,
    required Color accentColor,
    required String shareText,
    required String subject,
    Rect? sharePositionOrigin,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        sheetTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
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
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        itemSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share via Apps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _dispatchNativeShare(
                        context: context,
                        text: shareText,
                        title: sheetTitle,
                        subject: subject,
                        sharePositionOrigin: sharePositionOrigin,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all_rounded, size: 17),
                    label: const Text('Copy Details'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Share details copied.'),
                            backgroundColor: AppColors.statusOpen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _dispatchNativeShare({
    required BuildContext context,
    required String text,
    required String title,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: title,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        await _copyShareText(context, text);
      }
    } catch (_) {
      if (context.mounted) await _copyShareText(context, text);
    }
  }

  static Future<void> _copyShareText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Share details copied to clipboard.'),
          backgroundColor: AppColors.statusOpen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
