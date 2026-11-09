class CertificateModel {
  final String id;
  final String credentialId;
  final String companyId;
  final String companyName;
  final String projectId;
  final String projectTitle;
  final String projectCategory;
  final String studentId;
  final String studentName;
  final String studentUniversity;
  final String studentDegree;
  final String certificateTitle; // 'Certificate of Project Completion', 'Certificate of Excellence', 'Certificate of Merit & Innovation'
  final String issueDate;
  final double overallRating; // 1.0 to 5.0
  final double technicalRating;
  final double codeQualityRating;
  final double communicationRating;
  final double timelinessRating;
  final String recommendationLetter;
  final String signatoryName;
  final String signatoryTitle;
  final String verificationUrl;
  final bool isIssued;

  const CertificateModel({
    required this.id,
    required this.credentialId,
    required this.companyId,
    required this.companyName,
    required this.projectId,
    required this.projectTitle,
    required this.projectCategory,
    required this.studentId,
    required this.studentName,
    required this.studentUniversity,
    required this.studentDegree,
    this.certificateTitle = 'Certificate of Project Completion',
    required this.issueDate,
    this.overallRating = 5.0,
    this.technicalRating = 5.0,
    this.codeQualityRating = 5.0,
    this.communicationRating = 5.0,
    this.timelinessRating = 5.0,
    required this.recommendationLetter,
    this.signatoryName = 'Danish Ali Rajpoot',
    this.signatoryTitle = 'Head of Engineering & Talent Partnerships',
    this.verificationUrl = '',
    this.isIssued = true,
  });

  CertificateModel copyWith({
    String? id,
    String? credentialId,
    String? companyId,
    String? companyName,
    String? projectId,
    String? projectTitle,
    String? projectCategory,
    String? studentId,
    String? studentName,
    String? studentUniversity,
    String? studentDegree,
    String? certificateTitle,
    String? issueDate,
    double? overallRating,
    double? technicalRating,
    double? codeQualityRating,
    double? communicationRating,
    double? timelinessRating,
    String? recommendationLetter,
    String? signatoryName,
    String? signatoryTitle,
    String? verificationUrl,
    bool? isIssued,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      projectCategory: projectCategory ?? this.projectCategory,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentUniversity: studentUniversity ?? this.studentUniversity,
      studentDegree: studentDegree ?? this.studentDegree,
      certificateTitle: certificateTitle ?? this.certificateTitle,
      issueDate: issueDate ?? this.issueDate,
      overallRating: overallRating ?? this.overallRating,
      technicalRating: technicalRating ?? this.technicalRating,
      codeQualityRating: codeQualityRating ?? this.codeQualityRating,
      communicationRating: communicationRating ?? this.communicationRating,
      timelinessRating: timelinessRating ?? this.timelinessRating,
      recommendationLetter:
          recommendationLetter ?? this.recommendationLetter,
      signatoryName: signatoryName ?? this.signatoryName,
      signatoryTitle: signatoryTitle ?? this.signatoryTitle,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      isIssued: isIssued ?? this.isIssued,
    );
  }

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] ?? '',
      credentialId: json['credential_id'] ?? '',
      companyId: json['company_id'] ?? 'comp_01',
      companyName: json['company_name'] ?? 'TechVista Innovations',
      projectId: json['project_id'] ?? '',
      projectTitle: json['project_title'] ?? '',
      projectCategory: json['project_category'] ?? 'Software Dev',
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentUniversity: json['student_university'] ?? '',
      studentDegree: json['student_degree'] ?? '',
      certificateTitle:
          json['certificate_title'] ?? 'Certificate of Project Completion',
      issueDate: json['issue_date'] ?? 'Recently',
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 5.0,
      technicalRating: (json['technical_rating'] as num?)?.toDouble() ?? 5.0,
      codeQualityRating:
          (json['code_quality_rating'] as num?)?.toDouble() ?? 5.0,
      communicationRating:
          (json['communication_rating'] as num?)?.toDouble() ?? 5.0,
      timelinessRating: (json['timeliness_rating'] as num?)?.toDouble() ?? 5.0,
      recommendationLetter: json['recommendation_letter'] ?? '',
      signatoryName: json['signatory_name'] ?? 'Authorized Signatory',
      signatoryTitle: json['signatory_title'] ?? 'Lead Corporate Partner',
      verificationUrl: json['verification_url'] ?? '',
      isIssued: json['is_issued'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credential_id': credentialId,
      'company_id': companyId,
      'company_name': companyName,
      'project_id': projectId,
      'project_title': projectTitle,
      'project_category': projectCategory,
      'student_id': studentId,
      'student_name': studentName,
      'student_university': studentUniversity,
      'student_degree': studentDegree,
      'certificate_title': certificateTitle,
      'issue_date': issueDate,
      'overall_rating': overallRating,
      'technical_rating': technicalRating,
      'code_quality_rating': codeQualityRating,
      'communication_rating': communicationRating,
      'timeliness_rating': timelinessRating,
      'recommendation_letter': recommendationLetter,
      'signatory_name': signatoryName,
      'signatory_title': signatoryTitle,
      'verification_url': verificationUrl,
      'is_issued': isIssued,
    };
  }
}

