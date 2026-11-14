import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

/// Builds, previews, and dispatches shareable summaries with SkillBridge deep
/// links for Projects, Applications, and Certificates.
class ShareService {
  ShareService._();

  static const String appScheme = 'skillbridge';

  /// Registered by DeepLinkService so share previews and pasted links open
  /// directly inside the app.
  static Future<bool> Function(String uri, {BuildContext? context})?
      deepLinkOpener;
  static Future<bool> Function(String rawText, {BuildContext? context})?
      deepLinkTextOpener;

  static String _slugify(String raw, {String fallback = 'item'}) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  static String buildProjectShareLink(Map<String, dynamic> project) {
    final rawId =
        (project['projectId'] ?? project['id'] ?? '').toString().trim();
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
            : _slugify(
                title.isEmpty ? 'application' : title,
                fallback: 'application',
              ));

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
    final title = project['title']?.toString().trim().isNotEmpty == true
        ? project['title'].toString().trim()
        : 'Project Opportunity';
    final company = project['company']?.toString().trim().isNotEmpty == true
        ? project['company'].toString().trim()
        : 'Partner Company';
    final category = project['category']?.toString().trim() ?? 'General';
    final workMode = project['workMode']?.toString().trim() ?? 'Remote';
    final duration = project['duration']?.toString().trim() ?? 'Flexible';
    final description = project['description']?.toString().trim() ?? '';
    final projectLink = buildProjectShareLink(project);

    String skills = '';
    if (project['skills'] is List) {
      skills = (project['skills'] as List).join(', ');
    } else if (project['skills'] != null) {
      skills = project['skills'].toString().trim();
    }

    final buffer = StringBuffer()
      ..writeln('*$title* — $company')
      ..writeln('Category: $category • $workMode • $duration');
    if (skills.isNotEmpty) {
      buffer.writeln('Skills: $skills');
    }
    if (description.isNotEmpty) {
      final shortDesc = description.length > 160
          ? '${description.substring(0, 157)}...'
          : description;
      buffer.writeln(shortDesc);
    }
    buffer
      ..writeln()
      ..write('Open in SkillBridge: $projectLink');
    return buffer.toString();
  }

  static String buildApplicationShareText(Map<String, dynamic> application) {
    final title = application['title']?.toString().trim().isNotEmpty == true
        ? application['title'].toString().trim()
        : 'Project Application';
    final company = application['company']?.toString().trim().isNotEmpty == true
        ? application['company'].toString().trim()
        : 'Partner Company';
    final status = application['status']?.toString().trim() ?? 'Pending';
    final stage = application['timelineStep']?.toString() ?? '1';
    final appliedDate = application['appliedDate']?.toString().trim() ?? 'Recently';
    final availability =
        application['availability']?.toString().trim() ?? '';
    final skills = application['skills']?.toString().trim() ?? '';
    final appLink = buildApplicationShareLink(application);

    final buffer = StringBuffer()
      ..writeln('*SkillBridge Application: $title* — $company')
      ..writeln('Status: $status (Stage $stage of 3) • Applied: $appliedDate');
    if (availability.isNotEmpty) {
      buffer.writeln('Availability: $availability');
    }
    if (skills.isNotEmpty) {
      buffer.writeln('Skills: $skills');
    }
    buffer
      ..writeln()
      ..write('Open in SkillBridge: $appLink');
    return buffer.toString();
  }

  static String buildCertificateShareText(Map<String, dynamic> certificate) {
    final title =
        certificate['title']?.toString().trim().isNotEmpty == true
            ? certificate['title'].toString().trim()
            : 'Project Completion Certificate';
    final project = certificate['project']?.toString().trim() ?? 'Corporate Project';
    final certId = certificate['id']?.toString().trim() ?? 'SB-CERT';
    final issuer = certificate['issuer']?.toString().trim() ?? 'SkillBridge Partner';
    final date = certificate['date']?.toString().trim() ?? '2026';
    final verifyLink = buildCertificateShareLink(certificate);
    final explicitStudent =
        certificate['studentName']?.toString().trim() ?? '';
    final studentName = explicitStudent.isNotEmpty
        ? explicitStudent
        : (AppDataService.instance.userName.isNotEmpty
                ? AppDataService.instance.userName
                : (AppDataService.instance.getProfile()['name'] ?? 'Student'))
            .toString();

    final buffer = StringBuffer()
      ..writeln('*$title*')
      ..writeln('Awarded to $studentName for "$project"')
      ..writeln('Issued by $issuer • $date • ID: $certId')
      ..writeln()
      ..write('Verify in SkillBridge: $verifyLink');
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
    await _dispatchNativeShare(
      context: context,
      text: text,
      title: title ?? 'Share Details',
      subject: subject,
      deepLinkUri: deepLinkUri,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> _dispatchNativeShare({
    required BuildContext context,
    required String text,
    required String title,
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
      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Share text & link copied to clipboard.'),
              backgroundColor: AppColors.statusOpen,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (_) {
      if (!context.mounted) return;
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Share details & link copied to clipboard.'),
            backgroundColor: AppColors.statusOpen,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  static Future<void> shareProject({
    required BuildContext context,
    required Map<String, dynamic> project,
    Rect? sharePositionOrigin,
  }) async {
    final title = (project['title']?.toString().trim().isNotEmpty == true)
        ? project['title'].toString().trim()
        : 'Project Opportunity';
    final company = (project['company']?.toString().trim().isNotEmpty == true)
        ? project['company'].toString().trim()
        : 'Partner Company';
    final workMode = project['workMode']?.toString().trim() ?? 'Remote';
    final duration = project['duration']?.toString().trim() ?? 'Flexible';
    final category = project['category']?.toString().trim() ?? 'Academic';
    final shareMsg = buildProjectShareText(project);
    final link = buildProjectShareLink(project);

    _showProfessionalShareSheet(
      context: context,
      sheetTitle: 'Share Project',
      itemTitle: title,
      itemSubtitle: '$company • $workMode • $duration',
      badgeLabel: category,
      icon: Icons.work_outline_rounded,
      accentColor: AppColors.primaryBlue,
      shareLink: link,
      shareText: shareMsg,
      subject: 'SkillBridge Project: $title ($company)',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareApplication({
    required BuildContext context,
    required Map<String, dynamic> application,
    Rect? sharePositionOrigin,
  }) async {
    final title = (application['title']?.toString().trim().isNotEmpty == true)
        ? application['title'].toString().trim()
        : 'Project Application';
    final company =
        (application['company']?.toString().trim().isNotEmpty == true)
            ? application['company'].toString().trim()
            : 'Partner Company';
    final status = application['status']?.toString().trim() ?? 'Pending';
    final stage = application['timelineStep']?.toString() ?? '1';
    final shareMsg = buildApplicationShareText(application);
    final link = buildApplicationShareLink(application);

    _showProfessionalShareSheet(
      context: context,
      sheetTitle: 'Share Application',
      itemTitle: title,
      itemSubtitle: '$company • Stage $stage of 3',
      badgeLabel: status,
      icon: Icons.assignment_outlined,
      accentColor: AppColors.indigoAccent,
      shareLink: link,
      shareText: shareMsg,
      subject: 'SkillBridge Application: $title ($company)',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> shareCertificate({
    required BuildContext context,
    required Map<String, dynamic> certificate,
    Rect? sharePositionOrigin,
  }) async {
    final title =
        (certificate['title']?.toString().trim().isNotEmpty == true)
            ? certificate['title'].toString().trim()
            : 'Project Completion Certificate';
    final issuer =
        (certificate['issuer']?.toString().trim().isNotEmpty == true)
            ? certificate['issuer'].toString().trim()
            : 'SkillBridge Partner';
    final date = certificate['date']?.toString().trim() ?? '2026';
    final certId = certificate['id']?.toString().trim() ?? 'SB-CERT';
    final shareMsg = buildCertificateShareText(certificate);
    final link = buildCertificateShareLink(certificate);

    _showProfessionalShareSheet(
      context: context,
      sheetTitle: 'Share Certificate',
      itemTitle: title,
      itemSubtitle: '$issuer • $date',
      badgeLabel: certId,
      icon: Icons.workspace_premium_rounded,
      accentColor: AppColors.teal,
      shareLink: link,
      shareText: shareMsg,
      subject: 'SkillBridge Certificate: $title',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> showOpenSharedLinkDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _OpenSharedLinkDialog(hostContext: context),
    );
  }

  static void _showProfessionalShareSheet({
    required BuildContext context,
    required String sheetTitle,
    required String itemTitle,
    required String itemSubtitle,
    required String badgeLabel,
    required IconData icon,
    required Color accentColor,
    required String shareLink,
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
                const SizedBox(height: 14),
                Text(
                  'Direct SkillBridge Link',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                  decoration: BoxDecoration(
                    color: AppColors.lightAqua.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shareLink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        tooltip: 'Copy Link',
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: shareLink),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Link copied! Paste in any app or use Open Link inside SkillBridge.',
                                ),
                                backgroundColor: AppColors.statusOpen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
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
                        deepLinkUri: shareLink,
                        sharePositionOrigin: sharePositionOrigin,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all_rounded, size: 17),
                        label: const Text(
                          'Copy Details',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: shareText),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Complete details & link copied! Ready to share.',
                                ),
                                backgroundColor: AppColors.statusOpen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                      ),
                    ),
                    if (deepLinkOpener != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new_rounded, size: 17),
                          label: const Text(
                            'Open in App',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await deepLinkOpener?.call(
                              shareLink,
                              context: context,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenSharedLinkDialog extends StatefulWidget {
  final BuildContext hostContext;

  const _OpenSharedLinkDialog({required this.hostContext});

  @override
  State<_OpenSharedLinkDialog> createState() => _OpenSharedLinkDialogState();
}

class _OpenSharedLinkDialogState extends State<_OpenSharedLinkDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _isOpening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      setState(() => _errorText = 'Clipboard does not contain a link yet.');
      return;
    }
    setState(() {
      _controller.text = text;
      _errorText = null;
    });
  }

  Future<void> _openLink() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = 'Please paste a SkillBridge link first.');
      return;
    }

    setState(() {
      _isOpening = true;
      _errorText = null;
    });

    final hostContext = widget.hostContext;
    final navigator = Navigator.of(context);

    final opener = ShareService.deepLinkTextOpener ?? ShareService.deepLinkOpener;
    if (opener == null) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _errorText = 'Link handler is not ready yet.';
        });
      }
      return;
    }

    navigator.pop();
    final opened = await opener(
      raw,
      context: hostContext.mounted ? hostContext : null,
    );
    if (!opened && hostContext.mounted) {
      ScaffoldMessenger.of(hostContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open that SkillBridge link. Check the link and try again.',
            ),
            backgroundColor: AppColors.statusClosed,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.lightAqua,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: AppColors.primaryBlue,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open Shared Link',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a SkillBridge link or shared message to jump straight to that project, application, or certificate inside the app.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.grayText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 2,
              minLines: 1,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              decoration: InputDecoration(
                hintText: 'skillbridge://project/...',
                errorText: _errorText,
                suffixIcon: TextButton(
                  onPressed: _pasteFromClipboard,
                  child: const Text('Paste'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isOpening ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isOpening ? null : _openLink,
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const Text('Open in App'),
        ),
      ],
    );
  }
}
