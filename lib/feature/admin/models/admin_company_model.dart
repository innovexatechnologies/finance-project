enum CompanyVerificationState {
  verified,
  pending,
  rejected,
}

enum CompanyAccountState {
  active,
  suspended,
}

class CompanyAuditRecord {
  final String id;
  final String action;
  final String adminName;
  final String timestamp;
  final String? note;

  const CompanyAuditRecord({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    this.note,
  });
}

class AdminCompanyModel {
  final String id;
  final String? userId;
  final String companyName;
  final String logoInitial;
  final String officialEmail;
  final bool isEmailVerified;
  final String industry;
  final String city;
  final String completeAddress;
  final String contactPersonName;
  final String phoneNumber;
  final String websiteUrl;
  final String description;
  final String registrationNumber; // e.g. SECP-ISB-2019-9481
  final CompanyVerificationState verificationStatus;
  final CompanyAccountState accountStatus;
  final String registrationDate;
  final DateTime registrationDateTime;
  final String? suspensionReason;
  final String evidenceFileName;
  final String evidenceFileType;
  final String evidenceFileSize;
  final String? evidenceUrl;
  final int postedProjectsCount;
  final List<CompanyAuditRecord> auditHistory;

  const AdminCompanyModel({
    required this.id,
    this.userId,
    required this.companyName,
    required this.logoInitial,
    required this.officialEmail,
    required this.isEmailVerified,
    required this.industry,
    required this.city,
    required this.completeAddress,
    required this.contactPersonName,
    required this.phoneNumber,
    required this.websiteUrl,
    required this.description,
    required this.registrationNumber,
    required this.verificationStatus,
    required this.accountStatus,
    required this.registrationDate,
    required this.registrationDateTime,
    this.suspensionReason,
    required this.evidenceFileName,
    required this.evidenceFileType,
    required this.evidenceFileSize,
    this.evidenceUrl,
    this.postedProjectsCount = 0,
    required this.auditHistory,
  });

  AdminCompanyModel copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? logoInitial,
    String? officialEmail,
    bool? isEmailVerified,
    String? industry,
    String? city,
    String? completeAddress,
    String? contactPersonName,
    String? phoneNumber,
    String? websiteUrl,
    String? description,
    String? registrationNumber,
    CompanyVerificationState? verificationStatus,
    CompanyAccountState? accountStatus,
    String? registrationDate,
    DateTime? registrationDateTime,
    String? suspensionReason,
    bool clearSuspensionReason = false,
    String? evidenceFileName,
    String? evidenceFileType,
    String? evidenceFileSize,
    String? evidenceUrl,
    int? postedProjectsCount,
    List<CompanyAuditRecord>? auditHistory,
  }) {
    return AdminCompanyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      logoInitial: logoInitial ?? this.logoInitial,
      officialEmail: officialEmail ?? this.officialEmail,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      industry: industry ?? this.industry,
      city: city ?? this.city,
      completeAddress: completeAddress ?? this.completeAddress,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      description: description ?? this.description,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      registrationDate: registrationDate ?? this.registrationDate,
      registrationDateTime: registrationDateTime ?? this.registrationDateTime,
      suspensionReason:
          clearSuspensionReason ? null : (suspensionReason ?? this.suspensionReason),
      evidenceFileName: evidenceFileName ?? this.evidenceFileName,
      evidenceFileType: evidenceFileType ?? this.evidenceFileType,
      evidenceFileSize: evidenceFileSize ?? this.evidenceFileSize,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      postedProjectsCount: postedProjectsCount ?? this.postedProjectsCount,
      auditHistory: auditHistory ?? this.auditHistory,
    );
  }
}

