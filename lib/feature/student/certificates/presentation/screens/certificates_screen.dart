import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/download_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  String _resolveStudentName() {
    final pName =
        AppDataService.instance.getProfile()['name']?.toString().trim() ?? '';
    if (pName.isNotEmpty) return pName;
    if (AppDataService.instance.userName.trim().isNotEmpty) {
      return AppDataService.instance.userName.trim();
    }
    return SupabaseHelper.currentUser?.userMetadata?['name']?.toString().trim() ??
        'Student';
  }

  Future<void> _openVerificationUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open verification link.')),
      );
    }
  }

  void _showCertificateDialog(BuildContext context, Map<String, dynamic> cert) {
    final title = cert['title']?.toString() ?? 'Certificate of Completion';
    final project = cert['project']?.toString() ?? 'Corporate Project';
    final issuer = cert['issuer']?.toString() ?? 'SkillBridge Partner';
    final certId = cert['id']?.toString() ?? 'CC-CERT';
    final date = cert['date']?.toString() ?? 'Recently';
    final rating = (cert['rating'] as num?)?.toDouble();
    final recommendation = cert['recommendation']?.toString().trim() ?? '';
    final hash = cert['hash']?.toString().trim() ?? '';
    final verificationUrl = cert['verificationUrl']?.toString().trim() ?? '';
    final studentName = _resolveStudentName();

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD97706), width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warningBg,
                    border:
                        Border.all(color: const Color(0xFFF59E0B), width: 2),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD97706),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SKILLBRIDGE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This certificate is awarded to',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.grayText),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'for successful completion of',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.grayText),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$project"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                if (rating != null && rating > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Supervisor Rating: ${rating.toStringAsFixed(1)} / 5.0 ★',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
                if (recommendation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '"$recommendation"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.darkText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Issued By',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.grayText)),
                          Text(issuer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Date & Credential ID',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.grayText)),
                          Text('$date • $certId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hash.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Verification Hash: ${hash.length > 22 ? '${hash.substring(0, 22)}...' : hash}',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
                if (verificationUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        _openVerificationUrl(context, verificationUrl),
                    icon: const Icon(Icons.verified_user_outlined, size: 15),
                    label: const Text('Verify Credential Online'),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ShareService.shareCertificate(
                          context: context,
                          certificate: cert,
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: const Text('Share'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        DownloadService.openCertificateDirectly(
                          context: context,
                          certificate: cert,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Open PDF'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        DownloadService.downloadCertificate(
                          context: context,
                          certificate: cert,
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Certificates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Certificates',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                AppDataService.instance.syncFromSupabase(forceRefresh: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final certificates = AppDataService.instance.getCertificates();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () => AppDataService.instance
                    .syncFromSupabase(forceRefresh: true),
                child: certificates.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 48),
                          AppEmptyState(
                            icon: Icons.military_tech_rounded,
                            title: 'No Certificates Earned Yet',
                            subtitle:
                                'Complete assigned corporate projects and receive final supervisor approval to unlock verifiable PDF certificates.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: certificates.length,
                        itemBuilder: (context, index) {
                          final cert = certificates[index];
                          final rating = (cert['rating'] as num?)?.toDouble();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () =>
                                  _showCertificateDialog(context, cert),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      AppColors.lightAqua
                                          .withValues(alpha: 0.28),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.warningBg,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFF59E0B),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.military_tech_rounded,
                                        size: 30,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      cert['title']?.toString() ??
                                          'Project Completion Certificate',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Project: ${cert['project'] ?? 'Corporate Sprint'}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${cert['issuer'] ?? 'SkillBridge Partner'}\n${cert['date'] ?? ''} • ID: ${cert['id'] ?? ''}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.grayText,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (rating != null && rating > 0) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Rated ${rating.toStringAsFixed(1)} ★',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 9,
                                            ),
                                          ),
                                          onPressed: () {
                                            DownloadService.downloadCertificate(
                                              context: context,
                                              certificate: cert,
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.download_rounded,
                                              size: 15),
                                          label: const Text('Download PDF',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.teal,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 9,
                                            ),
                                          ),
                                          onPressed: () {
                                            DownloadService
                                                .openCertificateDirectly(
                                              context: context,
                                              certificate: cert,
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.picture_as_pdf_rounded,
                                              size: 15),
                                          label: const Text('Open PDF',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 9,
                                            ),
                                          ),
                                          onPressed: () {
                                            ShareService.shareCertificate(
                                              context: context,
                                              certificate: cert,
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.share_outlined,
                                              size: 15),
                                          label: const Text('Share',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
