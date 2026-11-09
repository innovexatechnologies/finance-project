import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_application_monitoring_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';

/// Enterprise Application Monitoring & Investigation Service for CampusConnect Admin Panel.
/// Provides surveillance over reported submissions, credential verification, fraud mitigation,
/// and authorized audit-tracked case resolutions.
class AdminApplicationMonitoringService {
  static final AdminApplicationMonitoringService _instance =
      AdminApplicationMonitoringService._internal();
  factory AdminApplicationMonitoringService() => _instance;

  AdminApplicationMonitoringService._internal() {
    _initApplications();
  }

  late final ValueNotifier<List<AdminApplicationModel>> applicationsNotifier;

  List<AdminApplicationModel> get allApplications => applicationsNotifier.value;

  // 1. Application Overview Metrics
  int get totalCount => applicationsNotifier.value.length;
  int get pendingCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.pending)
      .length;
  int get acceptedCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.accepted)
      .length;
  int get rejectedCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.rejected)
      .length;
  int get withdrawnCount => applicationsNotifier.value
      .where((a) => a.workflowStatus == ApplicationWorkflowStatus.withdrawn)
      .length;
  int get reportedCount => applicationsNotifier.value
      .where((a) => a.reportStatus == ApplicationReportStatus.reported)
      .length;
  int get requiringInvestigationCount => applicationsNotifier.value
      .where((a) =>
          a.reportStatus == ApplicationReportStatus.reported ||
          a.reportStatus == ApplicationReportStatus.underInvestigation)
      .length;

  void _initApplications() {
    applicationsNotifier = ValueNotifier<List<AdminApplicationModel>>([
      // 1. APP-2026-1001: Ali Khan (Accepted, Clear)
      AdminApplicationModel(
        id: 'APP-2026-1001',
        studentId: 'std_fast_01',
        studentName: 'Ali Khan',
        studentEmail: 'ali.khan@nu.edu.pk',
        university: 'FAST-NUCES Islamabad',
        degree: 'BS Computer Science (Honors)',
        department: 'Department of Computer Science',
        semester: '8th Semester (Final Year)',
        cgpa: 3.82,
        isEducationVerified: true,
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        projectCategory: 'Mobile App Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        companyLiaison: 'Dr. Arshad Malik',
        submissionDate: '2026-11-06',
        submissionDateTime: DateTime(2026, 11, 6, 11, 30),
        workflowStatus: ApplicationWorkflowStatus.accepted,
        reportStatus: ApplicationReportStatus.clear,
        flagType: SuspiciousFlagType.none,
        proposalSummary:
            'I have built 2 production Flutter apps with clean architecture and Bloc state management. I can implement catalog and checkout flows within 3 weeks with 100% test coverage.',
        skills: ['Flutter', 'Dart', 'Bloc', 'REST API', 'Git'],
        resumeFileName: 'AliKhan_Official_Resume_2026.pdf',
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_1001_1',
            action: 'Application Submitted',
            adminName: 'System Gatekeeper',
            timestamp: '2026-11-06 11:30 AM',
            findings: 'Automated verification check passed: Fast-NUCES student identity authenticated.',
          ),
        ],
      ),

      // 2. APP-2026-9041: Danish Khan (Reported - Off-Platform Solicitation)
      AdminApplicationModel(
        id: 'APP-2026-9041',
        studentId: 'std_cust_07',
        studentName: 'Danish Khan',
        studentEmail: 'danish.khan@cust.edu.pk',
        university: 'CUST Islamabad',
        degree: 'BS Software Engineering',
        department: 'Department of Software Engineering',
        semester: '3rd Semester',
        cgpa: 3.10,
        isEducationVerified: false,
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        projectCategory: 'Mobile App Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        companyLiaison: 'Dr. Arshad Malik',
        submissionDate: '2026-11-08',
        submissionDateTime: DateTime(2026, 11, 8, 14, 20),
        workflowStatus: ApplicationWorkflowStatus.pending,
        reportStatus: ApplicationReportStatus.reported,
        flagType: SuspiciousFlagType.offPlatformSolicitation,
        proposalSummary:
            'Contact me on WhatsApp +92-300-XXXXXXX for off-platform payment transfer and shortcut arrangement.',
        skills: ['HTML', 'CSS', 'Beginner Flutter'],
        resumeFileName: 'DanishKhan_Resume.pdf',
        reportDetail: const ApplicationReportDetail(
          reportId: 'REP-9041-01',
          reportedBy: 'Dr. Arshad Malik (TechVista)',
          reporterRole: 'Company Liaison',
          reportedDate: '2026-11-08 03:40 PM',
          reportCategory: 'Off-Platform Solicitation Attempt',
          reportExplanation:
              'Applicant submitted external phone numbers and solicited off-platform transactions in direct violation of CampusConnect non-financial student guidelines.',
          evidenceSnippet: 'Proposal snippet: "Contact me on WhatsApp for off-platform payment transfer..."',
          severity: 'High',
        ),
        investigationNotes: const [
          'Case logged into moderation queue by company sponsor.',
          'Pending administrative verification of student identity and phone numbers.',
        ],
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_9041_1',
            action: 'Report Filed by Corporate Sponsor',
            adminName: 'Dr. Arshad Malik (TechVista)',
            timestamp: '2026-11-08 03:40 PM',
            findings: 'Off-platform solicitation flag triggered.',
          ),
        ],
      ),

      // 3. APP-2026-8820: Sameer Tariq (Under Investigation - Credential Tampering)
      AdminApplicationModel(
        id: 'APP-2026-8820',
        studentId: 'std_uet_08',
        studentName: 'Sameer Tariq',
        studentEmail: 'sameer.tariq@uet.edu.pk',
        university: 'UET Taxila',
        degree: 'BS Computer Engineering',
        department: 'Department of Computer Engineering',
        semester: '7th Semester',
        cgpa: 3.95,
        isEducationVerified: false,
        projectId: 'proj_03',
        projectTitle: 'Automated Multi-Cloud Kubernetes Orchestrator',
        projectCategory: 'Cloud Infrastructure & DevOps',
        companyId: 'comp_02',
        companyName: 'Innovexa Cloud Technologies',
        companyLiaison: 'Khurram Shehzad',
        submissionDate: '2026-11-07',
        submissionDateTime: DateTime(2026, 11, 7, 16, 15),
        workflowStatus: ApplicationWorkflowStatus.pending,
        reportStatus: ApplicationReportStatus.underInvestigation,
        flagType: SuspiciousFlagType.credentialDiscrepancy,
        proposalSummary:
            'Top 1% ranked student with 3.95 CGPA offering automated Helm chart deployment infrastructure.',
        skills: ['Kubernetes', 'Helm', 'Docker', 'Go'],
        resumeFileName: 'SameerTariq_Transcripts_Modified.pdf',
        reportDetail: const ApplicationReportDetail(
          reportId: 'REP-8820-02',
          reportedBy: 'CampusConnect Automated Registrar Audit',
          reporterRole: 'System Heuristic',
          reportedDate: '2026-11-07 05:00 PM',
          reportCategory: 'Forged Academic Transcript Discrepancy',
          reportExplanation:
              'Official registrar cross-check indicates student CGPA is 2.40, but application self-reported 3.95 with an edited transcript document scan.',
          evidenceSnippet: 'Discrepancy: Self-reported 3.95 CGPA vs Verified UET Registrar Record 2.40 CGPA.',
          severity: 'Critical',
        ),
        investigationNotes: const [
          'Proctor request sent to UET Taxila Examination Department.',
          'Uploaded transcript file analysis reveals altered PDF font metadata in the GPA section.',
        ],
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_8820_1',
            action: 'Automated Discrepancy Flag',
            adminName: 'Registrar Vault Monitor',
            timestamp: '2026-11-07 05:00 PM',
            findings: 'Discrepancy detected between self-reported GPA and university registrar portal.',
          ),
          InvestigationRecord(
            id: 'inv_8820_2',
            action: 'Marked Under Review',
            adminName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-11-08 09:30 AM',
            note: 'Initiating forensic inspection of uploaded PDF metadata.',
          ),
        ],
      ),

      // 4. APP-2026-1002: Hamza Tariq (Pending, Clear)
      AdminApplicationModel(
        id: 'APP-2026-1002',
        studentId: 'std_lums_03',
        studentName: 'Hamza Tariq',
        studentEmail: 'hamza.tariq@lums.edu.pk',
        university: 'LUMS Lahore',
        degree: 'BS Computer Science',
        department: 'Syed Babar Ali School of Science and Engineering',
        semester: '7th Semester',
        cgpa: 3.65,
        isEducationVerified: true,
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        projectCategory: 'Mobile App Development',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        companyLiaison: 'Dr. Arshad Malik',
        submissionDate: '2026-11-08',
        submissionDateTime: DateTime(2026, 11, 8, 12, 00),
        workflowStatus: ApplicationWorkflowStatus.pending,
        reportStatus: ApplicationReportStatus.clear,
        flagType: SuspiciousFlagType.none,
        proposalSummary:
            'Full-stack mobile engineer with backend microservice experience. Interested in optimizing cart checkout, caching layers, and offline sync for your e-commerce mobile application.',
        skills: ['Flutter', 'Node.js', 'PostgreSQL', 'Docker'],
        resumeFileName: 'HamzaTariq_Resume.pdf',
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_1002_1',
            action: 'Application Submitted',
            adminName: 'System Gatekeeper',
            timestamp: '2026-11-08 12:00 PM',
            findings: 'Clear standing: No previous disciplinary infractions recorded.',
          ),
        ],
      ),

      // 5. APP-2026-7731: Farhan Zaidi (Withdrawn, Clear)
      AdminApplicationModel(
        id: 'APP-2026-7731',
        studentId: 'std_giki_09',
        studentName: 'Farhan Zaidi',
        studentEmail: 'farhan.zaidi@giki.edu.pk',
        university: 'GIKI Swabi',
        degree: 'BS Computer Engineering',
        department: 'Faculty of Computer Science & Engineering',
        semester: '6th Semester',
        cgpa: 3.42,
        isEducationVerified: true,
        projectId: 'proj_04',
        projectTitle: 'Corporate Sentiment Analysis Pipeline',
        projectCategory: 'AI / Machine Learning & Data',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        companyLiaison: 'Dr. Arshad Malik',
        submissionDate: '2026-11-02',
        submissionDateTime: DateTime(2026, 11, 2, 10, 00),
        workflowStatus: ApplicationWorkflowStatus.withdrawn,
        reportStatus: ApplicationReportStatus.clear,
        flagType: SuspiciousFlagType.none,
        proposalSummary:
            'Application voluntarily withdrawn due to conflicting university midterm schedule.',
        skills: ['Python', 'Pandas', 'FastAPI'],
        resumeFileName: 'FarhanZaidi_CV.pdf',
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_7731_1',
            action: 'Application Withdrawn by Student',
            adminName: 'Student Portal',
            timestamp: '2026-11-05 02:15 PM',
            note: 'Student requested withdrawal before company review.',
          ),
        ],
      ),

      // 6. APP-2026-6612: Usman Raza (Rejected, Dismissed False Flag)
      AdminApplicationModel(
        id: 'APP-2026-6612',
        studentId: 'std_pucit_10',
        studentName: 'Usman Raza',
        studentEmail: 'usman.raza@pucit.edu.pk',
        university: 'PUCIT Lahore',
        degree: 'BS Software Engineering',
        department: 'Department of Computer Science',
        semester: '5th Semester',
        cgpa: 3.30,
        isEducationVerified: true,
        projectId: 'proj_05',
        projectTitle: 'Smart IoT Campus Attendance Hardware Hook',
        projectCategory: 'IoT & Embedded Systems',
        companyId: 'comp_01',
        companyName: 'TechVista Innovations',
        companyLiaison: 'Dr. Arshad Malik',
        submissionDate: '2026-10-29',
        submissionDateTime: DateTime(2026, 10, 29, 15, 45),
        workflowStatus: ApplicationWorkflowStatus.rejected,
        reportStatus: ApplicationReportStatus.dismissed,
        flagType: SuspiciousFlagType.none,
        proposalSummary:
            'Hands-on experience with Arduino and ESP8266 IoT boards. Ready to assist with sensor soldering and data capture.',
        skills: ['C++', 'Arduino', 'IoT', 'Soldering'],
        resumeFileName: 'UsmanRaza_CV.pdf',
        reportDetail: const ApplicationReportDetail(
          reportId: 'REP-6612-03',
          reportedBy: 'Company Automated System',
          reporterRole: 'System Heuristic',
          reportedDate: '2026-10-30 09:00 AM',
          reportCategory: 'Automated Keyword Flag',
          reportExplanation: 'System flag triggered on word "circuit hack" in proposal summary.',
          severity: 'Low',
        ),
        investigationNotes: const [
          'Administrative review verified "circuit hack" was legitimate engineering colloquialism for a hardware prototype.',
          'Report dismissed as false positive. Student was rejected purely based on academic prerequisites by company.',
        ],
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_6612_1',
            action: 'False Flag Dismissed',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-30 11:20 AM',
            note: 'Dismissed: Technical context validated; no misconduct committed.',
          ),
        ],
      ),

      // 7. APP-2026-5509: Haris Qureshi (Rejected, Resolved: Action Taken)
      AdminApplicationModel(
        id: 'APP-2026-5509',
        studentId: 'std_ext_11',
        studentName: 'Haris Qureshi',
        studentEmail: 'haris.qureshi@unknown-domain.com',
        university: 'Non-Affiliated University',
        degree: 'External Candidate',
        department: 'Unregistered Department',
        semester: 'N/A',
        cgpa: 1.90,
        isEducationVerified: false,
        projectId: 'proj_08',
        projectTitle: 'Crypto Payment Gateway Bridge Prototype',
        projectCategory: 'Blockchain & Distributed Systems',
        companyId: 'comp_05',
        companyName: 'Apex Distributed Technologies',
        companyLiaison: 'Kamran Siddiqui',
        submissionDate: '2026-10-19',
        submissionDateTime: DateTime(2026, 10, 19, 17, 00),
        workflowStatus: ApplicationWorkflowStatus.rejected,
        reportStatus: ApplicationReportStatus.resolved,
        flagType: SuspiciousFlagType.spamApplication,
        proposalSummary:
            'Automated mass-application bot attempting to submit promotional cryptocurrency referral links across multiple projects.',
        skills: ['Spamming', 'Crypto Wallets'],
        resumeFileName: 'Unverified_File.exe',
        reportDetail: const ApplicationReportDetail(
          reportId: 'REP-5509-04',
          reportedBy: 'Automated Platform Firewall',
          reporterRole: 'System Heuristic',
          reportedDate: '2026-10-19 05:05 PM',
          reportCategory: 'Automated Bot Spam & Malicious Payload',
          reportExplanation:
              'Account submitted 40 applications within 12 seconds with executable file attachment violating platform security terms.',
          severity: 'Critical',
        ),
        investigationNotes: const [
          'Executable attachment quarantined by security sandbox.',
          'Application terminated and student account marked for permanent suspension.',
        ],
        investigationHistory: const [
          InvestigationRecord(
            id: 'inv_5509_1',
            action: 'Automated Threat Quarantine',
            adminName: 'Security Sentinel Watchdog',
            timestamp: '2026-10-19 05:05 PM',
            findings: 'Executable payload detected and isolated.',
          ),
          InvestigationRecord(
            id: 'inv_5509_2',
            action: 'Investigation Resolved & Application Revoked',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-19 06:00 PM',
            findings: 'Formal sanction: Application administratively revoked and domain blacklisted.',
          ),
        ],
        isDecisionModifiedByAdmin: true,
        administrativeDecisionNote:
            'Administrative decision: Application administratively revoked due to malicious payload.',
      ),
    ]);
  }

  // 5. Mark Case as Under Review / Investigation
  Future<bool> markCaseUnderInvestigation({
    required String applicationId,
    required String adminName,
    required String initialNote,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);

    notes.insert(0, '[$adminName]: $initialNote');
    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Case Marked Under Active Investigation',
        adminName: adminName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        note: initialNote,
      ),
    );

    list[idx] = app.copyWith(
      reportStatus: ApplicationReportStatus.underInvestigation,
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;
    return true;
  }

  // 5. Record Investigation Note
  Future<bool> recordInvestigationNote({
    required String applicationId,
    required String adminName,
    required String note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);

    notes.insert(0, '[$adminName]: $note');
    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Investigation Note Recorded',
        adminName: adminName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        note: note,
      ),
    );

    list[idx] = app.copyWith(
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;
    return true;
  }

  // 5. Dismiss Report (False Flag / No Misconduct)
  Future<bool> dismissReport({
    required String applicationId,
    required String adminName,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);

    notes.insert(0, '[$adminName - Dismissal]: $reason');
    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Report Dismissed (No Policy Violation)',
        adminName: adminName,
        timestamp: 'Today',
        findings: reason,
      ),
    );

    list[idx] = app.copyWith(
      reportStatus: ApplicationReportStatus.dismissed,
      flagType: SuspiciousFlagType.none,
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;
    return true;
  }

  // 5. Resolve Report With Action (Authorize Administrative Decision)
  Future<bool> resolveReportWithAction({
    required String applicationId,
    required String adminName,
    required String resolutionSummary,
    bool revokeApplication = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final list = List<AdminApplicationModel>.from(applicationsNotifier.value);
    final idx = list.indexWhere((a) => a.id == applicationId);
    if (idx == -1) return false;

    final app = list[idx];
    final history = List<InvestigationRecord>.from(app.investigationHistory);
    final notes = List<String>.from(app.investigationNotes);

    notes.insert(
      0,
      '[$adminName - Resolution]: $resolutionSummary ${revokeApplication ? "(Application Administratively Revoked)" : ""}',
    );

    history.insert(
      0,
      InvestigationRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        action: revokeApplication
            ? 'Investigation Concluded: Application Revoked'
            : 'Investigation Concluded: Action Recorded',
        adminName: adminName,
        timestamp: 'Today',
        findings: resolutionSummary,
      ),
    );

    list[idx] = app.copyWith(
      reportStatus: ApplicationReportStatus.resolved,
      workflowStatus: revokeApplication
          ? ApplicationWorkflowStatus.rejected
          : app.workflowStatus,
      isDecisionModifiedByAdmin: revokeApplication,
      administrativeDecisionNote: resolutionSummary,
      investigationNotes: notes,
      investigationHistory: history,
    );
    applicationsNotifier.value = list;

    // Cross-panel synchronization with CompanyApplicantService if revoked
    if (revokeApplication) {
      try {
        final applicantService = CompanyApplicantService();
        applicantService.updateApplicantStatus(
          applicantId: app.id,
          newStatus: 'Rejected',
        );
      } catch (_) {
        // Fallback in test suites
      }
    }

    return true;
  }

  // 7. Export Applications to CSV
  String exportApplicationsCsv(List<AdminApplicationModel> applications) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Application ID,Student Name,Email,University,Project Title,Company,Submission Date,Workflow Status,Report Status,Flag Type,Education Verified',
    );

    for (final a in applications) {
      buffer.writeln(
        '${a.id},"${a.studentName}","${a.studentEmail}","${a.university}","${a.projectTitle}","${a.companyName}",${a.submissionDate},${a.workflowStatusDisplay},${a.reportStatusDisplay},${a.flagTypeDisplay},${a.isEducationVerified}',
      );
    }
    return buffer.toString();
  }
}

