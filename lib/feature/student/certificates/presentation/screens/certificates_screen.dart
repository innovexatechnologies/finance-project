import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> certificates = [
      {
        'title': 'Project Completion Certificate',
        'project': 'Barcode Scanning Mobile Utility',
        'issuer': 'Issued by CampusConnect & CodeCraft',
        'date': 'Oct 25, 2026',
        'id': 'CC-CERT-884920',
      },
      {
        'title': 'Excellence in UI/UX Engineering',
        'project': 'Flutter Design Prototype sprint',
        'issuer': 'Issued by CampusConnect & TechVista',
        'date': 'Sept 15, 2026',
        'id': 'CC-CERT-773412',
      },
      {
        'title': 'AI Market Research Analyst',
        'project': 'Competitive Framework Analysis',
        'issuer': 'Issued by CampusConnect & Google Mentors',
        'date': 'Aug 30, 2026',
        'id': 'CC-CERT-661904',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Certificates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
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
                    cert['title'],
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
                    'For: ${cert['project']}',
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
                    '${cert['issuer']}\n${cert['date']} • ID: ${cert['id']}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.grayText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Download and Share buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Downloading ${cert['title']} (PDF)...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.deepNavy,
                          side: const BorderSide(color: AppColors.lightGray),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Certificate share link copied!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
