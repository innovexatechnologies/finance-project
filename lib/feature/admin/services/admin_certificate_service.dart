import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_certificate_model.dart';

/// Enterprise Certificate Administration & Verification Service for CampusConnect.
/// Manages credential minting, cryptographic verification, audit trails, and authorized revocation.
class AdminCertificateService {
  static final AdminCertificateService _instance =
      AdminCertificateService._internal();
  factory AdminCertificateService() => _instance;

  AdminCertificateService._internal() {
    _initCertificates();
  }

  late final ValueNotifier<List<AdminCertificateModel>> certificatesNotifier;

  List<AdminCertificateModel> get allCertificates => certificatesNotifier.value;

  // 1. Certificate Overview Metrics
  int get totalCount => certificatesNotifier.value.length;
  int get issuedCount =>
      certificatesNotifier.value.where((c) => c.isIssued).length;
  int get validCount => certificatesNotifier.value
      .where((c) => c.status == AdminCertificateStatus.valid)
      .length;
  int get revokedCount => certificatesNotifier.value
      .where((c) => c.status == AdminCertificateStatus.revoked)
      .length;
  int get requiringReviewCount => certificatesNotifier.value
      .where((c) => c.status == AdminCertificateStatus.pendingReview)
      .length;

  void _initCertificates() {
    certificatesNotifier = ValueNotifier<List<AdminCertificateModel>>([
      // 1. CERT-2026-8001: Ali Khan (Excellence, Valid)
      AdminCertificateModel(
        id: 'CERT-2026-8001',
        credentialId: 'CC-FIPS-8001-PK',
        certificateTitle: 'Certificate of Excellence & Project Completion',
        type: CertificateType.excellence,
        studentId: 'std_fast_01',
        studentName: 'Ali Khan',
        studentUniversity: 'FAST-NUCES Islamabad',
        studentDegree: 'BS Computer Science (Honors)',
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        projectCategory: 'Mobile App Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        signatoryName: 'Dr. Arshad Malik',
        signatoryTitle: 'Head of Engineering & Talent Partnerships',
        issueDate: '2026-11-01',
        issueDateTime: DateTime(2026, 11, 1, 10, 00),
        status: AdminCertificateStatus.valid,
        cryptographicHash:
            'SHA-256: 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
        performanceRatings: const {
          'Technical Architecture': 5.0,
          'Code Quality & Testing': 4.9,
          'Communication & Sprints': 5.0,
          'Timeliness & Delivery': 4.8,
        },
        recommendationLetter:
            'Ali Khan demonstrated extraordinary proficiency in Flutter state architecture and clean component modularity. His dedication and high-caliber delivery exceeded corporate expectations.',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_8001_1',
            action: 'Certificate Minted & Digitally Signed',
            adminName: 'Governance Ledger Gateway',
            timestamp: '2026-11-01 10:00 AM',
            digitalSignature: 'SIG_RSA4096_VALID_8001',
          ),
          CertificateAuditRecord(
            id: 'aud_cert_8001_2',
            action: 'Academic Ledger Cryptographic Hash Stamped',
            adminName: 'FIPS-180-4 Verifier',
            timestamp: '2026-11-01 10:05 AM',
            reason: 'Tamper-evident verification hash anchored to platform vault.',
          ),
        ],
      ),

      // 2. CERT-2026-8002: Ayesha Ahmed (Completion, Valid)
      AdminCertificateModel(
        id: 'CERT-2026-8002',
        credentialId: 'CC-FIPS-8002-PK',
        certificateTitle: 'Certificate of Project Completion',
        type: CertificateType.completion,
        studentId: 'std_nust_02',
        studentName: 'Ayesha Ahmed',
        studentUniversity: 'NUST SEECS Islamabad',
        studentDegree: 'BS Software Engineering',
        projectId: 'proj_01',
        projectTitle: 'HealthVibe Wellness UI Suite',
        projectCategory: 'Mobile App Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        signatoryName: 'Dr. Arshad Malik',
        signatoryTitle: 'Head of Engineering & Talent Partnerships',
        issueDate: '2026-10-28',
        issueDateTime: DateTime(2026, 10, 28, 14, 30),
        status: AdminCertificateStatus.valid,
        cryptographicHash:
            'SHA-256: 3c9909afec25354d551dae21590bb26e38d53f2173b8d3dc3eee4c047e7ab1c1',
        performanceRatings: const {
          'UI/UX Aesthetics': 5.0,
          'Component Tokens': 4.8,
          'Micro-Animations': 4.9,
          'Delivery Timeliness': 5.0,
        },
        recommendationLetter:
            'Ayesha produced exceptional human-centered mobile designs with polished interaction states. Highly commended for commercial product engineering roles.',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_8002_1',
            action: 'Certificate Minted & Stamped',
            adminName: 'Governance Ledger Gateway',
            timestamp: '2026-10-28 02:30 PM',
            digitalSignature: 'SIG_RSA4096_VALID_8002',
          ),
        ],
      ),

      // 3. CERT-2026-8003: Mustafa Hassan (Innovation, Valid)
      AdminCertificateModel(
        id: 'CERT-2026-8003',
        credentialId: 'CC-FIPS-8003-PK',
        certificateTitle: 'Certificate of Merit & Innovation',
        type: CertificateType.innovation,
        studentId: 'std_pucit_06',
        studentName: 'Mustafa Hassan',
        studentUniversity: 'PUCIT Lahore',
        studentDegree: 'MS Data Science',
        projectId: 'proj_04',
        projectTitle: 'Corporate Sentiment Analysis Pipeline',
        projectCategory: 'AI / Machine Learning & Data',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        signatoryName: 'Dr. Arshad Malik',
        signatoryTitle: 'Head of Engineering & Talent Partnerships',
        issueDate: '2026-10-25',
        issueDateTime: DateTime(2026, 10, 25, 11, 15),
        status: AdminCertificateStatus.valid,
        cryptographicHash:
            'SHA-256: 8b1a9953c4611296a827abf8c47804d7e8b6b23d9b4b0e8b2b7b5c8f8b6b23d9',
        performanceRatings: const {
          'Model Precision': 4.9,
          'Inference Speed': 4.8,
          'FastAPI Architecture': 5.0,
          'Documentation': 4.9,
        },
        recommendationLetter:
            'Mustafa engineered an aspect-based sentiment model achieving 92.4% test accuracy and served via optimized Docker container.',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_8003_1',
            action: 'Certificate Minted & Stamped',
            adminName: 'Governance Ledger Gateway',
            timestamp: '2026-10-25 11:15 AM',
            digitalSignature: 'SIG_RSA4096_VALID_8003',
          ),
        ],
      ),

      // 4. CERT-2026-8004: Hamza Tariq (Leadership, Valid)
      AdminCertificateModel(
        id: 'CERT-2026-8004',
        credentialId: 'CC-FIPS-8004-PK',
        certificateTitle: 'Certificate of Sprint Leadership',
        type: CertificateType.leadership,
        studentId: 'std_lums_03',
        studentName: 'Hamza Tariq',
        studentUniversity: 'LUMS Lahore',
        studentDegree: 'BS Computer Science',
        projectId: 'proj_05',
        projectTitle: 'Campus Ambassador Portal Dashboard',
        projectCategory: 'Web Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        signatoryName: 'Dr. Arshad Malik',
        signatoryTitle: 'Head of Engineering & Talent Partnerships',
        issueDate: '2026-10-15',
        issueDateTime: DateTime(2026, 10, 15, 16, 00),
        status: AdminCertificateStatus.valid,
        cryptographicHash:
            'SHA-256: 12a3456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        performanceRatings: const {
          'Frontend Architecture': 4.8,
          'Team Coordination': 5.0,
          'Testing Standards': 4.7,
        },
        recommendationLetter:
            'Hamza led student contributors effectively and deployed the web dashboard ahead of schedule with zero regression.',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_8004_1',
            action: 'Certificate Minted & Stamped',
            adminName: 'Governance Ledger Gateway',
            timestamp: '2026-10-15 04:00 PM',
            digitalSignature: 'SIG_RSA4096_VALID_8004',
          ),
        ],
      ),

      // 5. CERT-2026-9041: Danish Khan (Requires Review - Under Hold)
      AdminCertificateModel(
        id: 'CERT-2026-9041',
        credentialId: 'CC-FIPS-9041-PK',
        certificateTitle: 'Certificate of Project Completion',
        type: CertificateType.completion,
        studentId: 'std_cust_07',
        studentName: 'Danish Khan',
        studentUniversity: 'CUST Islamabad',
        studentDegree: 'BS Software Engineering',
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        projectCategory: 'Mobile App Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        signatoryName: 'Dr. Arshad Malik',
        signatoryTitle: 'Head of Engineering & Talent Partnerships',
        issueDate: '2026-11-05',
        issueDateTime: DateTime(2026, 11, 5, 12, 10),
        status: AdminCertificateStatus.pendingReview,
        cryptographicHash:
            'SHA-256: 55a43b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a',
        performanceRatings: const {
          'Task Completion': 3.5,
          'Code Quality': 3.2,
        },
        recommendationLetter:
            'Certificate generated upon initial completion milestone, currently suspended on administrative hold.',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_9041_1',
            action: 'Certificate Staged & Generated',
            adminName: 'TechVista Innovations HR',
            timestamp: '2026-11-05 12:10 PM',
          ),
          CertificateAuditRecord(
            id: 'aud_cert_9041_2',
            action: 'Administrative Review Hold Imposed',
            adminName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-11-08 04:00 PM',
            reason:
                'Student reported for off-platform solicitation infractions; credential validation placed under hold.',
          ),
        ],
      ),

      // 6. CERT-2026-7719: Sameer Tariq (Revoked - Transcript Forgery)
      AdminCertificateModel(
        id: 'CERT-2026-7719',
        credentialId: 'CC-FIPS-7719-PK',
        certificateTitle: 'Certificate of Project Completion',
        type: CertificateType.completion,
        studentId: 'std_uet_08',
        studentName: 'Sameer Tariq',
        studentUniversity: 'UET Taxila',
        studentDegree: 'BS Computer Engineering',
        projectId: 'proj_03',
        projectTitle: 'Automated Multi-Cloud Kubernetes Orchestrator',
        projectCategory: 'Cloud Infrastructure & DevOps',
        companyId: 'comp_02',
        companyName: 'Innovexa Cloud Technologies',
        signatoryName: 'Khurram Shehzad',
        signatoryTitle: 'Lead Cloud Architect',
        issueDate: '2026-10-10',
        issueDateTime: DateTime(2026, 10, 10, 15, 00),
        status: AdminCertificateStatus.revoked,
        cryptographicHash:
            'SHA-256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        performanceRatings: const {
          'Cloud Deployments': 2.0,
        },
        recommendationLetter:
            'Revoked by CampusConnect Central Governance. Void and nullified.',
        revocationReason:
            'Revoked due to registrar confirmed academic transcript tampering and fraudulent CGPA misrepresentation.',
        revocationDate: '2026-11-08',
        revokingAdminName: 'Dr. Tariq Mahmood (SuperAdmin)',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_7719_1',
            action: 'Certificate Minted',
            adminName: 'Innovexa System Portal',
            timestamp: '2026-10-10 03:00 PM',
          ),
          CertificateAuditRecord(
            id: 'aud_cert_7719_2',
            action: 'CREDENTIAL REVOKED & NULLIFIED',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-11-08 05:20 PM',
            reason:
                'Registrar confirmed academic transcript tampering and fraudulent CGPA misrepresentation.',
            digitalSignature: 'REVOKE_AUTH_FIPS_TM_7719',
          ),
        ],
      ),

      // 7. CERT-2026-5502: Haris Qureshi (Revoked - Policy Violation)
      AdminCertificateModel(
        id: 'CERT-2026-5502',
        credentialId: 'CC-FIPS-5502-PK',
        certificateTitle: 'Certificate of Project Completion',
        type: CertificateType.completion,
        studentId: 'std_ext_11',
        studentName: 'Haris Qureshi',
        studentUniversity: 'External Candidate',
        studentDegree: 'Unregistered Degree',
        projectId: 'proj_08',
        projectTitle: 'Crypto Payment Gateway Bridge Prototype',
        projectCategory: 'Blockchain & Distributed Systems',
        companyId: 'comp_05',
        companyName: 'Apex Distributed Technologies',
        signatoryName: 'Kamran Siddiqui',
        signatoryTitle: 'Managing Partner',
        issueDate: '2026-09-30',
        issueDateTime: DateTime(2026, 9, 30, 18, 00),
        status: AdminCertificateStatus.revoked,
        cryptographicHash:
            'SHA-256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        performanceRatings: const {
          'Solidity Integration': 1.0,
        },
        recommendationLetter: 'Nullified due to non-financial platform policy violation.',
        revocationReason:
            'Platform Policy Violation: Sponsored project contained prohibited financial cryptocurrency promotional mechanisms.',
        revocationDate: '2026-10-20',
        revokingAdminName: 'Dr. Tariq Mahmood (SuperAdmin)',
        verificationHistory: const [
          CertificateAuditRecord(
            id: 'aud_cert_5502_1',
            action: 'Certificate Minted',
            adminName: 'Apex Distributed Portal',
            timestamp: '2026-09-30 06:00 PM',
          ),
          CertificateAuditRecord(
            id: 'aud_cert_5502_2',
            action: 'CREDENTIAL REVOKED & NULLIFIED',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-20 04:15 PM',
            reason:
                'Platform Policy Violation: Prohibited financial cryptocurrency promotional mechanisms.',
            digitalSignature: 'REVOKE_AUTH_FIPS_TM_5502',
          ),
        ],
      ),
    ]);
  }

  // 5. Verify Certificate by ID or Hash
  AdminCertificateModel? verifyCertificate(String query) {
    final clean = query.trim().toLowerCase();
    try {
      return certificatesNotifier.value.firstWhere(
        (c) =>
            c.id.toLowerCase() == clean ||
            c.credentialId.toLowerCase() == clean ||
            c.cryptographicHash.toLowerCase().contains(clean),
      );
    } catch (_) {
      return null;
    }
  }

  // 6. Revoke Certificate with Mandatory Reason & Identity Record
  Future<bool> revokeCertificate({
    required String certificateId,
    required String reason,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCertificateModel>.from(certificatesNotifier.value);
    final idx = list.indexWhere((c) => c.id == certificateId);
    if (idx == -1) return false;

    final cert = list[idx];
    final history = List<CertificateAuditRecord>.from(cert.verificationHistory);
    history.insert(
      0,
      CertificateAuditRecord(
        id: 'aud_cert_rev_${DateTime.now().millisecondsSinceEpoch}',
        action: 'CREDENTIAL REVOKED & NULLIFIED',
        adminName: adminName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: reason,
        digitalSignature: 'REVOKE_AUTH_${adminName.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    list[idx] = cert.copyWith(
      status: AdminCertificateStatus.revoked,
      revocationReason: reason,
      revocationDate: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      revokingAdminName: adminName,
      verificationHistory: history,
    );
    certificatesNotifier.value = list;
    return true;
  }

  // 6. Mark Certificate For Review (Hold)
  Future<bool> markCertificateForReview({
    required String certificateId,
    required String reason,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final list = List<AdminCertificateModel>.from(certificatesNotifier.value);
    final idx = list.indexWhere((c) => c.id == certificateId);
    if (idx == -1) return false;

    final cert = list[idx];
    final history = List<CertificateAuditRecord>.from(cert.verificationHistory);
    history.insert(
      0,
      CertificateAuditRecord(
        id: 'aud_cert_hold_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Credential Marked For Review (Verification Hold)',
        adminName: adminName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        reason: reason,
      ),
    );

    list[idx] = cert.copyWith(
      status: AdminCertificateStatus.pendingReview,
      verificationHistory: history,
    );
    certificatesNotifier.value = list;
    return true;
  }

  // 6. Reinstate Certificate (Restore to Valid)
  Future<bool> reinstateCertificate({
    required String certificateId,
    required String justification,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCertificateModel>.from(certificatesNotifier.value);
    final idx = list.indexWhere((c) => c.id == certificateId);
    if (idx == -1) return false;

    final cert = list[idx];
    final history = List<CertificateAuditRecord>.from(cert.verificationHistory);
    history.insert(
      0,
      CertificateAuditRecord(
        id: 'aud_cert_reinstate_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Credential Reinstated & Authenticity Confirmed',
        adminName: adminName,
        timestamp: 'Today',
        reason: justification,
        digitalSignature: 'REINSTATE_AUTH_${adminName.hashCode}',
      ),
    );

    list[idx] = cert.copyWith(
      status: AdminCertificateStatus.valid,
      revocationReason: null,
      revocationDate: null,
      revokingAdminName: null,
      verificationHistory: history,
    );
    certificatesNotifier.value = list;
    return true;
  }

  // 7. Export Certificates to CSV
  String exportCertificatesCsv(List<AdminCertificateModel> certificates) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Certificate ID,Credential ID,Title,Student Name,University,Degree,Project Title,Company Name,Issue Date,Status,Cryptographic Hash,Revocation Reason',
    );

    for (final c in certificates) {
      buffer.writeln(
        '${c.id},"${c.credentialId}","${c.certificateTitle}","${c.studentName}","${c.studentUniversity}","${c.studentDegree}","${c.projectTitle}","${c.companyName}",${c.issueDate},${c.statusDisplay},"${c.cryptographicHash}","${c.revocationReason ?? ''}"',
      );
    }
    return buffer.toString();
  }
}

