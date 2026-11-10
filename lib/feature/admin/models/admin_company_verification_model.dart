import 'package:link_vibe/feature/company/models/company_verification_model.dart';

/// Comprehensive verification record for the administrative review desk
class AdminCompanyVerificationItem {
  final String id;
  final String companyId;
  final String? userId;
  final String companyName;
  final String logoInitial;
  final String industry;
  final String city;
  final String registrationNumber; // e.g. SECP-2019-8976
  final String officialEmail;
  final bool isEmailVerified;
  final String websiteUrl;
  final String documentName;
  final String documentType;
  final String documentSize;
  final String? documentUrl;
  final VerificationStatus status;
  final String submittedAt;
  final String? reviewedAt;
  final String? reviewerName;
  final String? adminFeedback;

  const AdminCompanyVerificationItem({
    required this.id,
    required this.companyId,
    this.userId,
    required this.companyName,
    required this.logoInitial,
    required this.industry,
    required this.city,
    required this.registrationNumber,
    required this.officialEmail,
    required this.isEmailVerified,
    required this.websiteUrl,
    required this.documentName,
    required this.documentType,
    required this.documentSize,
    this.documentUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerName,
    this.adminFeedback,
  });

  AdminCompanyVerificationItem copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? companyName,
    String? logoInitial,
    String? industry,
    String? city,
    String? registrationNumber,
    String? officialEmail,
    bool? isEmailVerified,
    String? websiteUrl,
    String? documentName,
    String? documentType,
    String? documentSize,
    String? documentUrl,
    VerificationStatus? status,
    String? submittedAt,
    String? reviewedAt,
    String? reviewerName,
    String? adminFeedback,
    bool clearAdminFeedback = false,
  }) {
    return AdminCompanyVerificationItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      logoInitial: logoInitial ?? this.logoInitial,
      industry: industry ?? this.industry,
      city: city ?? this.city,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      officialEmail: officialEmail ?? this.officialEmail,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      documentName: documentName ?? this.documentName,
      documentType: documentType ?? this.documentType,
      documentSize: documentSize ?? this.documentSize,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewerName: reviewerName ?? this.reviewerName,
      adminFeedback:
          clearAdminFeedback ? null : (adminFeedback ?? this.adminFeedback),
    );
  }
}

