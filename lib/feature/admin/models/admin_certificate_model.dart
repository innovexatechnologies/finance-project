enum AdminCertificateStatus {
  valid,
  revoked,
  pendingReview,
  draft,
}

enum CertificateType {
  completion,
  excellence,
  innovation,
  leadership,
}

class CertificateAuditRecord {
  final String id;
  final String action;
  final String adminName;
  final String timestamp;
  final String? reason;
  final String? digitalSignature;

  const CertificateAuditRecord({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    this.reason,
    this.digitalSignature,
  });
}

class AdminCertificateModel {
  final String id;
  final String credentialId; // e.g. CC-FIPS-8001-PK
  final String certificateTitle;
  final CertificateType type;
  final String studentId;
  final String studentName;
  final String studentUniversity;
  final String studentDegree;
  final String projectId;
  final String projectTitle;
  final String projectCategory;
  final String companyId;
  final String companyName;
  final String signatoryName;
  final String signatoryTitle;
  final String issueDate;
  final DateTime issueDateTime;
  final AdminCertificateStatus status;
  final String cryptographicHash;
  final Map<String, double> performanceRatings;
  final String recommendationLetter;
  final String? revocationReason;
  final String? revocationDate;
  final String? revokingAdminName;
  final List<CertificateAuditRecord> verificationHistory;
  final bool isIssued;

  const AdminCertificateModel({
    required this.id,
    required this.credentialId,
    required this.certificateTitle,
    required this.type,
    required this.studentId,
    required this.studentName,
    required this.studentUniversity,
    required this.studentDegree,
    required this.projectId,
    required this.projectTitle,
    required this.projectCategory,
    required this.companyId,
    required this.companyName,
    required this.signatoryName,
    required this.signatoryTitle,
    required this.issueDate,
    required this.issueDateTime,
    required this.status,
    required this.cryptographicHash,
    required this.performanceRatings,
    required this.recommendationLetter,
    this.revocationReason,
    this.revocationDate,
    this.revokingAdminName,
    required this.verificationHistory,
    this.isIssued = true,
  });

  AdminCertificateModel copyWith({
    String? id,
    String? credentialId,
    String? certificateTitle,
    CertificateType? type,
    String? studentId,
    String? studentName,
    String? studentUniversity,
    String? studentDegree,
    String? projectId,
    String? projectTitle,
    String? projectCategory,
    String? companyId,
    String? companyName,
    String? signatoryName,
    String? signatoryTitle,
    String? issueDate,
    DateTime? issueDateTime,
    AdminCertificateStatus? status,
    String? cryptographicHash,
    Map<String, double>? performanceRatings,
    String? recommendationLetter,
    String? revocationReason,
    String? revocationDate,
    String? revokingAdminName,
    List<CertificateAuditRecord>? verificationHistory,
    bool? isIssued,
  }) {
    return AdminCertificateModel(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      certificateTitle: certificateTitle ?? this.certificateTitle,
      type: type ?? this.type,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentUniversity: studentUniversity ?? this.studentUniversity,
      studentDegree: studentDegree ?? this.studentDegree,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      projectCategory: projectCategory ?? this.projectCategory,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      signatoryName: signatoryName ?? this.signatoryName,
      signatoryTitle: signatoryTitle ?? this.signatoryTitle,
      issueDate: issueDate ?? this.issueDate,
      issueDateTime: issueDateTime ?? this.issueDateTime,
      status: status ?? this.status,
      cryptographicHash: cryptographicHash ?? this.cryptographicHash,
      performanceRatings: performanceRatings ?? this.performanceRatings,
      recommendationLetter: recommendationLetter ?? this.recommendationLetter,
      revocationReason: revocationReason ?? this.revocationReason,
      revocationDate: revocationDate ?? this.revocationDate,
      revokingAdminName: revokingAdminName ?? this.revokingAdminName,
      verificationHistory: verificationHistory ?? this.verificationHistory,
      isIssued: isIssued ?? this.isIssued,
    );
  }

  String get statusDisplay {
    switch (status) {
      case AdminCertificateStatus.valid:
        return 'Valid';
      case AdminCertificateStatus.revoked:
        return 'Revoked';
      case AdminCertificateStatus.pendingReview:
        return 'Requires Review';
      case AdminCertificateStatus.draft:
        return 'Draft / Staged';
    }
  }

  String get typeDisplay {
    switch (type) {
      case CertificateType.completion:
        return 'Completion';
      case CertificateType.excellence:
        return 'Excellence';
      case CertificateType.innovation:
        return 'Innovation';
      case CertificateType.leadership:
        return 'Leadership';
    }
  }
}

