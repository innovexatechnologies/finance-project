import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/download_service.dart';
import 'package:link_vibe/core/services/share_service.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  void _showCertificateDialog(BuildContext context, Map<String, dynamic> cert) {
    final title = cert['title'] ?? 'Certificate of Completion';
    final project = cert['project'] ?? 'Corporate Project';
    final issuer = cert['issuer'] ?? 'CampusConnect & Partner';
    final certId = cert['id'] ?? 'CC-2026-CERT';
    final date = cert['date'] ?? 'March 2026';
    final studentName =
        AppDataService.instance.getProfile()['name'] ?? 'Ahmed Khan';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD97706), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Certificate Badge Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD97706),
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CAMPUSCONNECT',
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
                'This is proudly presented to',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.grayText),
              ),
              const SizedBox(height: 4),
              Text(
                studentName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'for outstanding completion of',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.grayText),
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
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Issued By',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.grayText)),
                      Text(issuer,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Date & ID',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.grayText)),
                      Text('$date • $certId',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
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
                      label: const Text('Open'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
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
                  ),
                ],
              ),
            ],
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
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final certificates = AppDataService.instance.getCertificates();

          if (certificates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.lightAqua,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        size: 40,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Certificates Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Complete assigned projects and get company approvals to earn verified certificates.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: certificates.length,
            itemBuilder: (context, index) {
              final cert = certificates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showCertificateDialog(context, cert),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          AppColors.lightAqua.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Golden Ribbon Badge Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            size: 32,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Certificate Title
                        Text(
                          cert['title'] ?? 'Project Completion Certificate',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Project
                        Text(
                          'For: ${cert['project'] ?? 'Project'}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Issuer & Date
                        Text(
                          '${cert['issuer'] ?? 'CampusConnect'}\n${cert['date'] ?? ''} • ID: ${cert['id'] ?? ''}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grayText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Download, Open and Share buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                DownloadService.downloadCertificate(
                                  context: context,
                                  certificate: cert,
                                );
                              },
                              icon: const Icon(Icons.download_rounded, size: 15),
                              label: const Text('Download PDF',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                DownloadService.openCertificateDirectly(
                                  context: context,
                                  certificate: cert,
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded,
                                  size: 15),
                              label: const Text('Open PDF',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.deepNavy,
                                side: const BorderSide(
                                    color: AppColors.lightGray),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                ShareService.shareCertificate(
                                  context: context,
                                  certificate: cert,
                                );
                              },
                              icon: const Icon(Icons.share_outlined, size: 15),
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
          );
        },
      ),
    );
  }
}
