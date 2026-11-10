class StudentPortfolioItem {
  final String id;
  final String title;
  final String description;
  final List<String> techStack;
  final String projectUrl;
  final String? attachmentName;
  final String? attachmentType; // 'Code', 'Design', 'Report', 'Demo APK'

  const StudentPortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.techStack,
    this.projectUrl = '',
    this.attachmentName,
    this.attachmentType,
  });

  factory StudentPortfolioItem.fromJson(Map<String, dynamic> json) {
    return StudentPortfolioItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      techStack: (json['tech_stack'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      projectUrl: json['project_url'] ?? '',
      attachmentName: json['attachment_name'],
      attachmentType: json['attachment_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tech_stack': techStack,
      'project_url': projectUrl,
      'attachment_name': attachmentName,
      'attachment_type': attachmentType,
    };
  }
}

class PreviousProjectRecord {
  final String id;
  final String title;
  final String organization;
  final String role;
  final String completionDate;
  final double rating;
  final String clientFeedback;

  const PreviousProjectRecord({
    required this.id,
    required this.title,
    required this.organization,
    required this.role,
    required this.completionDate,
    this.rating = 5.0,
    required this.clientFeedback,
  });

  factory PreviousProjectRecord.fromJson(Map<String, dynamic> json) {
    return PreviousProjectRecord(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      organization: json['organization'] ?? '',
      role: json['role'] ?? '',
      completionDate: json['completion_date'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      clientFeedback: json['client_feedback'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'role': role,
      'completion_date': completionDate,
      'rating': rating,
      'client_feedback': clientFeedback,
    };
  }
}

class StudentCertificate {
  final String id;
  final String title;
  final String issuer;
  final String issueDate;
  final String credentialId;
  final String? verificationUrl;

  const StudentCertificate({
    required this.id,
    required this.title,
    required this.issuer,
    required this.issueDate,
    required this.credentialId,
    this.verificationUrl,
  });

  factory StudentCertificate.fromJson(Map<String, dynamic> json) {
    return StudentCertificate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      issuer: json['issuer'] ?? '',
      issueDate: json['issue_date'] ?? '',
      credentialId: json['credential_id'] ?? '',
      verificationUrl: json['verification_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'issuer': issuer,
      'issue_date': issueDate,
      'credential_id': credentialId,
      'verification_url': verificationUrl,
    };
  }
}

class ApplicantModel {
  final String id;
  final String studentId;
  final String projectId;
  final String projectTitle;
  final String name;
  final String email;
  final String university;
  final bool isEducationVerified;
  final String degree;
  final String department;
  final String semester;
  final double cgpa;
  final List<String> skills;
  final String appliedDate;
  final String proposalSummary;
  final String status; // 'Pending', 'Under Review', 'Shortlisted', 'Accepted', 'Rejected'
  final String avatarInitial;
  final String? profilePictureUrl;
  final String portfolioUrl;
  final double rating;
  final String bio;
  final String resumeFileName;
  final List<StudentPortfolioItem> portfolioProjects;
  final List<PreviousProjectRecord> previousProjects;
  final List<StudentCertificate> certificates;

  ApplicantModel({
    required this.id,
    String? studentId,
    required this.projectId,
    this.projectTitle = 'Project Challenge',
    required this.name,
    required this.email,
    required this.university,
    this.isEducationVerified = false,
    required this.degree,
    this.department = '',
    this.semester = '',
    required this.cgpa,
    required this.skills,
    required this.appliedDate,
    required this.proposalSummary,
    this.status = 'Pending',
    this.avatarInitial = 'ST',
    this.profilePictureUrl,
    this.portfolioUrl = '',
    this.rating = 0.0,
    this.bio = '',
    this.resumeFileName = '',
    this.portfolioProjects = const [],
    this.previousProjects = const [],
    this.certificates = const [],
  }) : studentId = studentId ?? id;

  ApplicantModel copyWith({
    String? id,
    String? studentId,
    String? projectId,
    String? projectTitle,
    String? name,
    String? email,
    String? university,
    bool? isEducationVerified,
    String? degree,
    String? department,
    String? semester,
    double? cgpa,
    List<String>? skills,
    String? appliedDate,
    String? proposalSummary,
    String? status,
    String? avatarInitial,
    String? profilePictureUrl,
    String? portfolioUrl,
    double? rating,
    String? bio,
    String? resumeFileName,
    List<StudentPortfolioItem>? portfolioProjects,
    List<PreviousProjectRecord>? previousProjects,
    List<StudentCertificate>? certificates,
  }) {
    return ApplicantModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      name: name ?? this.name,
      email: email ?? this.email,
      university: university ?? this.university,
      isEducationVerified: isEducationVerified ?? this.isEducationVerified,
      degree: degree ?? this.degree,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      cgpa: cgpa ?? this.cgpa,
      skills: skills ?? this.skills,
      appliedDate: appliedDate ?? this.appliedDate,
      proposalSummary: proposalSummary ?? this.proposalSummary,
      status: status ?? this.status,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      rating: rating ?? this.rating,
      bio: bio ?? this.bio,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      portfolioProjects: portfolioProjects ?? this.portfolioProjects,
      previousProjects: previousProjects ?? this.previousProjects,
      certificates: certificates ?? this.certificates,
    );
  }

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    final nameStr = (json['name'] ?? json['student_name'] ?? '').toString();
    return ApplicantModel(
      id: (json['id'] ?? '').toString(),
      studentId: (json['student_id'] ?? json['user_id'])?.toString(),
      projectId: (json['project_id'] ?? '').toString(),
      projectTitle: (json['project_title'] ?? 'Project Challenge').toString(),
      name: nameStr,
      email: (json['email'] ?? json['student_email'] ?? '').toString(),
      university: (json['university'] ?? '').toString(),
      isEducationVerified: json['is_education_verified'] ?? false,
      degree: (json['degree'] ?? json['student_degree'] ?? '').toString(),
      department:
          (json['department'] ?? json['student_department'] ?? '').toString(),
      semester: (json['semester'] ?? json['student_semester'] ?? '').toString(),
      cgpa: ((json['cgpa'] ?? json['student_cgpa']) as num?)?.toDouble() ?? 0.0,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      appliedDate:
          (json['applied_date'] ?? json['submitted_at'] ?? 'Recently').toString(),
      proposalSummary: (json['proposal_summary'] ??
              json['cover_letter'] ??
              'No proposal summary provided.')
          .toString(),
      status: (json['status'] ?? 'Pending').toString(),
      avatarInitial: json['avatar_initial']?.toString() ??
          (nameStr.trim().length >= 2
              ? nameStr.trim().substring(0, 2).toUpperCase()
              : 'ST'),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      portfolioUrl:
          (json['portfolio_url'] ?? json['portfolio_link'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      bio: (json['bio'] ?? '').toString(),
      resumeFileName:
          (json['resume_file_name'] ?? json['resume_link'] ?? '').toString(),
      portfolioProjects: (json['portfolio_projects'] as List<dynamic>?)
              ?.map((p) =>
                  StudentPortfolioItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      previousProjects: (json['previous_projects'] as List<dynamic>?)
              ?.map((p) =>
                  PreviousProjectRecord.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((c) =>
                  StudentCertificate.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'project_id': projectId,
      'project_title': projectTitle,
      'name': name,
      'email': email,
      'university': university,
      'is_education_verified': isEducationVerified,
      'degree': degree,
      'department': department,
      'semester': semester,
      'cgpa': cgpa,
      'skills': skills,
      'applied_date': appliedDate,
      'proposal_summary': proposalSummary,
      'status': status,
      'avatar_initial': avatarInitial,
      'profile_picture_url': profilePictureUrl,
      'portfolio_url': portfolioUrl,
      'rating': rating,
      'bio': bio,
      'resume_file_name': resumeFileName,
      'portfolio_projects': portfolioProjects.map((p) => p.toJson()).toList(),
      'previous_projects': previousProjects.map((p) => p.toJson()).toList(),
      'certificates': certificates.map((c) => c.toJson()).toList(),
    };
  }
}
