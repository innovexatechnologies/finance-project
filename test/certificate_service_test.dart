import 'package:flutter_test/flutter_test.dart';
import 'package:link_vibe/core/services/certificate_pdf_service.dart';
import 'package:link_vibe/feature/student/profile/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CertificatePdfService generates valid PDF binary bytes', () async {
    final pdfBytes = await CertificatePdfService.generateCertificatePdf(
      studentName: 'Ayesha Tariq',
      projectTitle: 'AI Fraud Detection Pipeline',
      certificateTitle: 'Corporate Internship Certificate',
      issuer: 'Systems Limited',
      certId: 'CC-987654',
      issueDate: 'November 2026',
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));

    // Verify standard PDF header %PDF
    final header = String.fromCharCodes(pdfBytes.take(4));
    expect(header, equals('%PDF'));
  });

  testWidgets('Academic profile does not render Location row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StudentProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Academic Profile'), findsOneWidget);
    expect(find.text('Institute'), findsOneWidget);
    // Verify Location is NOT rendered under Academic Profile
    expect(find.text('Location'), findsNothing);
  });
}
