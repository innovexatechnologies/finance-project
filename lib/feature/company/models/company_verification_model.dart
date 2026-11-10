enum VerificationStatus {
  notSubmitted,
  pending,
  verified,
  rejected,
}

class CompanyVerificationModel {
  final String companyId;
  final String officialEmail;
  final bool isEmailVerified;
  final String? emailOtp;
  final String? businessEvidenceFileName;
  final String? businessEvidenceType;
  final String? businessEvidenceFileSize;
  final String? businessEvidenceUrl;
  final String? websiteUrl;
  final VerificationStatus status;
  final String? submittedAt;
  final String? reviewedAt;
  final String? adminFeedback;
  final String? reviewerName;

  const CompanyVerificationModel({
    required this.companyId,
    required this.officialEmail,
    this.isEmailVerified = false,
    this.emailOtp,
    this.businessEvidenceFileName,
    this.businessEvidenceType = 'SECP / Company Registration',
    this.businessEvidenceFileSize,
    this.businessEvidenceUrl,
    this.websiteUrl,
    this.status = VerificationStatus.notSubmitted,
    this.submittedAt,
    this.reviewedAt,
    this.adminFeedback,
    this.reviewerName,
  });

  CompanyVerificationModel copyWith({
    String? companyId,
    String? officialEmail,
    bool? isEmailVerified,
    String? emailOtp,
    String? businessEvidenceFileName,
    String? businessEvidenceType,
    String? businessEvidenceFileSize,
    String? businessEvidenceUrl,
    String? websiteUrl,
    VerificationStatus? status,
    String? submittedAt,
    String? reviewedAt,
    String? adminFeedback,
    String? reviewerName,
  }) {
    return CompanyVerificationModel(
      companyId: companyId ?? this.companyId,
      officialEmail: officialEmail ?? this.officialEmail,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      emailOtp: emailOtp ?? this.emailOtp,
      businessEvidenceFileName:
          businessEvidenceFileName ?? this.businessEvidenceFileName,
      businessEvidenceType: businessEvidenceType ?? this.businessEvidenceType,
      businessEvidenceFileSize:
          businessEvidenceFileSize ?? this.businessEvidenceFileSize,
      businessEvidenceUrl: businessEvidenceUrl ?? this.businessEvidenceUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      reviewerName: reviewerName ?? this.reviewerName,
    );
  }

  factory CompanyVerificationModel.fromJson(Map<String, dynamic> json) {
    VerificationStatus parseStatus(String? val) {
      switch (val?.toLowerCase()) {
        case 'pending':
          return VerificationStatus.pending;
        case 'verified':
          return VerificationStatus.verified;
        case 'rejected':
          return VerificationStatus.rejected;
        default:
          return VerificationStatus.notSubmitted;
      }
    }

    return CompanyVerificationModel(
      companyId: (json['company_id'] ?? '').toString(),
      officialEmail: (json['official_email'] ?? '').toString(),
      isEmailVerified: json['is_email_verified'] ?? false,
      emailOtp: json['email_otp']?.toString(),
      businessEvidenceFileName: json['business_evidence_file_name']?.toString(),
      businessEvidenceType:
          (json['business_evidence_type'] ?? 'SECP / Company Registration')
              .toString(),
      businessEvidenceFileSize: json['business_evidence_file_size']?.toString(),
      businessEvidenceUrl:
          (json['business_evidence_url'] ?? json['evidence_url'])?.toString(),
      websiteUrl: json['website_url']?.toString(),
      status: parseStatus(json['status']?.toString()),
      submittedAt: json['submitted_at']?.toString(),
      reviewedAt: json['reviewed_at']?.toString(),
      adminFeedback: json['admin_feedback']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String statusString;
    switch (status) {
      case VerificationStatus.pending:
        statusString = 'pending';
        break;
      case VerificationStatus.verified:
        statusString = 'verified';
        break;
      case VerificationStatus.rejected:
        statusString = 'rejected';
        break;
      case VerificationStatus.notSubmitted:
        statusString = 'not_submitted';
        break;
    }

    return {
      'company_id': companyId,
      'official_email': officialEmail,
      'is_email_verified': isEmailVerified,
      'email_otp': emailOtp,
      'business_evidence_file_name': businessEvidenceFileName,
      'business_evidence_type': businessEvidenceType,
      'business_evidence_file_size': businessEvidenceFileSize,
      'business_evidence_url': businessEvidenceUrl,
      'website_url': websiteUrl,
      'status': statusString,
      'submitted_at': submittedAt,
      'reviewed_at': reviewedAt,
      'admin_feedback': adminFeedback,
      'reviewer_name': reviewerName,
    };
  }
}

