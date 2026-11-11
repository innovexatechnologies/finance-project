import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CertificatePdfService {
  CertificatePdfService._();

  static Future<Uint8List> generateCertificatePdf({
    required String studentName,
    required String projectTitle,
    required String certificateTitle,
    required String issuer,
    required String certId,
    required String issueDate,
  }) async {
    final pdf = pw.Document();

    final navy = PdfColor.fromHex('#1E3A8A');
    final teal = PdfColor.fromHex('#0D9488');
    final gold = PdfColor.fromHex('#D97706');
    final darkText = PdfColor.fromHex('#0F172A');
    final grayText = PdfColor.fromHex('#64748B');
    final lightBg = PdfColor.fromHex('#F8FAFC');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: lightBg,
              border: pw.Border.all(color: navy, width: 4),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: teal, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title / Branding
                  pw.Column(
                    children: [
                      pw.Text(
                        'SKILLBRIDGE',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: navy,
                          letterSpacing: 3,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'STUDENT CORPORATE COLLABORATION PLATFORM',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: teal,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'CERTIFICATE OF COMPLETION',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  // Presentation text
                  pw.Text(
                    'This is proudly presented to',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                      color: grayText,
                    ),
                  ),

                  // Student Name
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: gold, width: 2),
                      ),
                    ),
                    child: pw.Text(
                      studentName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  // Project completion description
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32),
                    child: pw.Text(
                      'For outstanding dedication, professional collaboration, and successful completion of the verified industry sprint "$projectTitle" under the supervision of $issuer.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: darkText,
                        lineSpacing: 1.4,
                      ),
                    ),
                  ),

                  // Footer: Verification info, Seal, Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Left: Verification Metadata
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Certificate ID: $certId',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Issue Date: $issueDate',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: grayText,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Verified Portal: skillbridge.edu.pk/verify',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: teal,
                            ),
                          ),
                        ],
                      ),

                      // Center: Official Stamp
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: gold, width: 1.5),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'SKILLBRIDGE',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            pw.Text(
                              'VERIFIED CREDENTIAL',
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Authorized Signature Line
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 130,
                            height: 1,
                            color: grayText,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            issuer,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          pw.Text(
                            'Authorized Industry Partner',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: grayText,
                            ),
                          ),
                        ],
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

    return pdf.save();
  }
}

