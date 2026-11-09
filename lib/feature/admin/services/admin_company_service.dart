import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_company_model.dart';
import 'package:link_vibe/feature/company/models/company_verification_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/company/services/company_verification_service.dart';

/// Enterprise Company Management Service for CampusConnect Admin Panel.
/// Manages corporate registry, verification review, account regulation, and cross-panel sync.
class AdminCompanyService {
  static final AdminCompanyService _instance = AdminCompanyService._internal();
  factory AdminCompanyService() => _instance;

  AdminCompanyService._internal() {
    _initCompanies();
    _listenToCompanyUpdates();
  }

  late final ValueNotifier<List<AdminCompanyModel>> companiesNotifier;

  List<AdminCompanyModel> get allCompanies => companiesNotifier.value;

  // 1. Company Overview Metrics
  int get totalCount => companiesNotifier.value.length;
  int get verifiedCount => companiesNotifier.value
      .where((c) => c.verificationStatus == CompanyVerificationState.verified)
      .length;
  int get pendingCount => companiesNotifier.value
      .where((c) => c.verificationStatus == CompanyVerificationState.pending)
      .length;
  int get rejectedCount => companiesNotifier.value
      .where((c) => c.verificationStatus == CompanyVerificationState.rejected)
      .length;
  int get suspendedCount => companiesNotifier.value
      .where((c) => c.accountStatus == CompanyAccountState.suspended)
      .length;

  void _initCompanies() {
    final company = CompanyProfileService().currentProfile;
    final verif = CompanyVerificationService().currentVerification;
    final projectsCount = CompanyProjectService().getProjectsForCompany(company.id).length;

    CompanyVerificationState initialStatus = CompanyVerificationState.pending;
    if (verif.status == VerificationStatus.verified) {
      initialStatus = CompanyVerificationState.verified;
    } else if (verif.status == VerificationStatus.rejected) {
      initialStatus = CompanyVerificationState.rejected;
    }

    companiesNotifier = ValueNotifier<List<AdminCompanyModel>>([
      // 1. TechVista Innovations (comp_01 - Live company)
      AdminCompanyModel(
        id: company.id,
        companyName: company.companyName,
        logoInitial: company.logoInitial,
        officialEmail: company.officialEmail,
        isEmailVerified: verif.isEmailVerified,
        industry: company.industry,
        city: company.city,
        completeAddress: company.completeAddress,
        contactPersonName: company.contactPersonName,
        phoneNumber: company.phoneNumber,
        websiteUrl: company.websiteUrl,
        description: company.description,
        registrationNumber: 'SECP-ISB-2019-9481',
        verificationStatus: initialStatus,
        accountStatus: CompanyAccountState.active,
        registrationDate: '2026-10-01',
        registrationDateTime: DateTime(2026, 10, 1, 09, 30),
        evidenceFileName: verif.businessEvidenceFileName ?? 'SECP_Registration_TechVista_2026.pdf',
        evidenceFileType: verif.businessEvidenceType ?? 'SECP / Corporate Certificate',
        evidenceFileSize: verif.businessEvidenceFileSize ?? '2.4 MB',
        postedProjectsCount: projectsCount > 0 ? projectsCount : 4,
        auditHistory: const [
          CompanyAuditRecord(
            id: 'aud_c01_1',
            action: 'Account Provisioned',
            adminName: 'Governance Gateway',
            timestamp: '2026-10-01 09:30 AM',
            note: 'Corporate partner initialized on platform.',
          ),
          CompanyAuditRecord(
            id: 'aud_c01_2',
            action: 'Official Email Verified',
            adminName: 'Automated Mail Vault',
            timestamp: '2026-10-01 10:15 AM',
            note: 'Verified with official domain code dispatch.',
          ),
        ],
      ),

      // 2. Innovexa Cloud Technologies (comp_02)
      AdminCompanyModel(
        id: 'comp_02',
        companyName: 'Innovexa Cloud Technologies',
        logoInitial: 'IN',
        officialEmail: 'partnerships@innovexacloud.io',
        isEmailVerified: true,
        industry: 'Cloud Infrastructure & DevOps',
        city: 'Lahore',
        completeAddress: 'Arfa Software Technology Park, Ferozepur Road, Lahore',
        contactPersonName: 'Khurram Shehzad',
        phoneNumber: '+92 42 35889100',
        websiteUrl: 'https://innovexacloud.io',
        description: 'Specialized enterprise Kubernetes and multi-cloud infrastructure consultancy partnering with universities for open-source engineering sprints.',
        registrationNumber: 'SECP-LHR-2021-3829',
        verificationStatus: CompanyVerificationState.verified,
        accountStatus: CompanyAccountState.active,
        registrationDate: '2026-09-18',
        registrationDateTime: DateTime(2026, 9, 18, 14, 20),
        evidenceFileName: 'SECP_Form29_Innovexa.pdf',
        evidenceFileType: 'SECP Certificate of Incorporation',
        evidenceFileSize: '3.1 MB',
        postedProjectsCount: 2,
        auditHistory: const [
          CompanyAuditRecord(
            id: 'aud_c02',
            action: 'Corporate Verification Approved',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-09-20 11:45 AM',
            note: 'Verified against SECP active registry.',
          ),
        ],
      ),

      // 3. CodeCraft Mobile Systems (comp_03)
      AdminCompanyModel(
        id: 'comp_03',
        companyName: 'CodeCraft Mobile Systems',
        logoInitial: 'CC',
        officialEmail: 'admin@codecraft.com.pk',
        isEmailVerified: true,
        industry: 'Mobile App Development',
        city: 'Karachi',
        completeAddress: 'Clifton Block 4, Corporate Tower 3, Karachi',
        contactPersonName: 'Murtaza Hashmi',
        phoneNumber: '+92 21 35824900',
        websiteUrl: 'https://codecraft.com.pk',
        description: 'Boutique cross-platform application engineering agency developing high-scale mobile products for national logistics providers.',
        registrationNumber: 'NTN-FBR-7749201-9',
        verificationStatus: CompanyVerificationState.pending,
        accountStatus: CompanyAccountState.active,
        registrationDate: '2026-11-02',
        registrationDateTime: DateTime(2026, 11, 2, 11, 00),
        evidenceFileName: 'FBR_ActiveTaxpayer_NTN.pdf',
        evidenceFileType: 'FBR Active Taxpayer NTN Certificate',
        evidenceFileSize: '1.8 MB',
        postedProjectsCount: 1,
        auditHistory: const [
          CompanyAuditRecord(
            id: 'aud_c03',
            action: 'Evidence Uploaded',
            adminName: 'System Gateway',
            timestamp: '2026-11-02 11:00 AM',
            note: 'NTN documentation submitted for verification.',
          ),
        ],
      ),

      // 4. ByteWorks Automation Labs (comp_04)
      AdminCompanyModel(
        id: 'comp_04',
        companyName: 'ByteWorks Automation Labs',
        logoInitial: 'BW',
        officialEmail: 'info@byteworks.org',
        isEmailVerified: false,
        industry: 'IoT & Embedded Systems',
        city: 'Peshawar',
        completeAddress: 'Industrial Estate Hayatabad, Phase 7, Peshawar',
        contactPersonName: 'Engr. Junaid Afridi',
        phoneNumber: '+92 91 5892110',
        websiteUrl: 'https://byteworks.org',
        description: 'Hardware prototyping laboratory providing custom embedded sensors, firmware development, and IoT telemetry dashboards.',
        registrationNumber: 'SECP-PEW-2022-1104',
        verificationStatus: CompanyVerificationState.rejected,
        accountStatus: CompanyAccountState.active,
        registrationDate: '2026-10-24',
        registrationDateTime: DateTime(2026, 10, 24, 16, 40),
        evidenceFileName: 'Registration_Scan_LowRes.png',
        evidenceFileType: 'Business Registration Document',
        evidenceFileSize: '840 KB',
        postedProjectsCount: 1,
        auditHistory: const [
          CompanyAuditRecord(
            id: 'aud_c04',
            action: 'Verification Rejected',
            adminName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-10-26 03:30 PM',
            note: 'Uploaded document was an illegible PNG scan missing official registrar seal.',
          ),
        ],
      ),

      // 5. Apex Distributed Technologies (comp_05 - Suspended)
      AdminCompanyModel(
        id: 'comp_05',
        companyName: 'Apex Distributed Technologies',
        logoInitial: 'AD',
        officialEmail: 'legal@apexdistrib.tech',
        isEmailVerified: true,
        industry: 'Blockchain & Distributed Systems',
        city: 'Islamabad',
        completeAddress: 'Blue Area, Jinnah Avenue, Islamabad',
        contactPersonName: 'Kamran Siddiqui',
        phoneNumber: '+92 51 2801450',
        websiteUrl: 'https://apexdistrib.tech',
        description: 'Distributed ledger architecture firm researching zero-knowledge proofs and smart contract security verification.',
        registrationNumber: 'SECP-ISB-2020-5519',
        verificationStatus: CompanyVerificationState.verified,
        accountStatus: CompanyAccountState.suspended,
        registrationDate: '2026-08-10',
        registrationDateTime: DateTime(2026, 8, 10, 10, 00),
        suspensionReason: 'Company posted non-academic cryptocurrency promotional materials violating CampusConnect platform standards.',
        evidenceFileName: 'Apex_Incorporation_Certificate.pdf',
        evidenceFileType: 'SECP Certificate of Incorporation',
        evidenceFileSize: '2.8 MB',
        postedProjectsCount: 1,
        auditHistory: const [
          CompanyAuditRecord(
            id: 'aud_c05_1',
            action: 'Verified',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-08-12 12:00 PM',
            note: 'SECP credentials verified.',
          ),
          CompanyAuditRecord(
            id: 'aud_c05_2',
            action: 'Account Suspended',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-11-01 04:20 PM',
            note: 'Scope violation: commercial crypto advertising on student board.',
          ),
        ],
      ),

      // 6. DataPulse Analytics Pakistan (comp_06)
      AdminCompanyModel(
        id: 'comp_06',
        companyName: 'DataPulse Analytics Pakistan',
        logoInitial: 'DP',
        officialEmail: 'careers@datapulse.pk',
        isEmailVerified: true,
        industry: 'AI / Machine Learning & Data',
        city: 'Rawalpindi',
        completeAddress: 'Civic Centre, Bahria Town Phase 4, Rawalpindi',
        contactPersonName: 'Ayesha Nadeem',
        phoneNumber: '+92 51 5732100',
        websiteUrl: 'https://datapulse.pk',
        description: 'Predictive analytics and business intelligence lab training computer vision models for clinical healthcare applications.',
        registrationNumber: 'SECP-RWP-2023-8821',
        verificationStatus: CompanyVerificationState.verified,
        accountStatus: CompanyAccountState.active,
        registrationDate: '2026-09-30',
        registrationDateTime: DateTime(2026, 9, 30, 15, 10),
        evidenceFileName: 'DataPulse_SECP_FormA.pdf',
        evidenceFileType: 'SECP Form A Statutory Filing',
        evidenceFileSize: '2.2 MB',
        postedProjectsCount: 2,
        auditHistory: const [
          CompanyAuditRecord(
            id: 'aud_c06',
            action: 'Verification Approved',
            adminName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-10-02 01:15 PM',
            note: 'SECP incorporation matched.',
          ),
        ],
      ),
    ]);
  }

  void _listenToCompanyUpdates() {
    // Listen to changes in CompanyVerificationService
    CompanyVerificationService().verificationNotifier.addListener(() {
      final updatedVerif = CompanyVerificationService().currentVerification;
      final currentList = List<AdminCompanyModel>.from(companiesNotifier.value);
      final idx = currentList.indexWhere((c) => c.id == updatedVerif.companyId);

      if (idx != -1) {
        CompanyVerificationState state = CompanyVerificationState.pending;
        if (updatedVerif.status == VerificationStatus.verified) {
          state = CompanyVerificationState.verified;
        } else if (updatedVerif.status == VerificationStatus.rejected) {
          state = CompanyVerificationState.rejected;
        }

        currentList[idx] = currentList[idx].copyWith(
          verificationStatus: state,
          isEmailVerified: updatedVerif.isEmailVerified,
          evidenceFileName: updatedVerif.businessEvidenceFileName,
        );
        companiesNotifier.value = currentList;
      }
    });
  }

  /// 5. Approve Company Verification
  Future<bool> approveCompanyVerification({
    required String companyId,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Approved',
        adminName: adminName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        note: 'SECP registration certificate validated and approved.',
      ),
    );

    list[idx] = company.copyWith(
      verificationStatus: CompanyVerificationState.verified,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    // Cross-Panel Synchronization
    if (companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().simulateAdminApproval();
      CompanyProfileService().updateProfile(
        CompanyProfileService().currentProfile.copyWith(isVerified: true),
      );
    }

    return true;
  }

  /// 5. Reject Company Verification with Mandatory Reason
  Future<bool> rejectCompanyVerification({
    required String companyId,
    required String reason,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Rejected',
        adminName: adminName,
        timestamp: 'Today',
        note: reason,
      ),
    );

    list[idx] = company.copyWith(
      verificationStatus: CompanyVerificationState.rejected,
      auditHistory: history,
    );
    companiesNotifier.value = list;

    // Cross-Panel Synchronization
    if (companyId == CompanyProfileService().currentProfile.id) {
      CompanyVerificationService().simulateAdminRejection(reason);
    }

    return true;
  }

  /// 5. Request Additional Verification Documents
  Future<bool> requestAdditionalDocuments({
    required String companyId,
    required String instructions,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Additional Documents Requested',
        adminName: adminName,
        timestamp: 'Today',
        note: instructions,
      ),
    );

    list[idx] = company.copyWith(
      verificationStatus: CompanyVerificationState.pending,
      auditHistory: history,
    );
    companiesNotifier.value = list;
    return true;
  }

  /// 6. Suspend Company Account with Mandatory Reason
  Future<bool> suspendCompanyAccount({
    required String companyId,
    required String reason,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Suspended',
        adminName: adminName,
        timestamp: 'Today',
        note: reason,
      ),
    );

    list[idx] = company.copyWith(
      accountStatus: CompanyAccountState.suspended,
      suspensionReason: reason,
      auditHistory: history,
    );
    companiesNotifier.value = list;
    return true;
  }

  /// 6. Reactivate Suspended Company Account
  Future<bool> reactivateCompanyAccount({
    required String companyId,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminCompanyModel>.from(companiesNotifier.value);
    final idx = list.indexWhere((c) => c.id == companyId);
    if (idx == -1) return false;

    final company = list[idx];
    final history = List<CompanyAuditRecord>.from(company.auditHistory);
    history.insert(
      0,
      CompanyAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Reactivated',
        adminName: adminName,
        timestamp: 'Today',
        note: 'Corporate account reactivated by administrative governance sign-off.',
      ),
    );

    list[idx] = company.copyWith(
      accountStatus: CompanyAccountState.active,
      suspensionReason: null,
      auditHistory: history,
    );
    companiesNotifier.value = list;
    return true;
  }

  /// 7. Export Permitted Company Records to CSV
  String exportCompaniesCsv(List<AdminCompanyModel> companies) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Company Name,Email,Industry,City,Address,Registration Number,Verification Status,Account Status,Registration Date,Projects Count');

    for (final c in companies) {
      buffer.writeln(
        '${c.id},"${c.companyName}","${c.officialEmail}","${c.industry}","${c.city}","${c.completeAddress}","${c.registrationNumber}",${c.verificationStatus.name},${c.accountStatus.name},${c.registrationDate},${c.postedProjectsCount}',
      );
    }
    return buffer.toString();
  }
}
