enum StudentVerificationStatus {
  verified,
  pending,
  rejected,
}

enum StudentAccountStatus {
  active,
  suspended,
}

class StudentAuditRecord {
  final String id;
  final String action;
  final String adminName;
  final String timestamp;
  final String? note;

  const StudentAuditRecord({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    this.note,
  });
}

class AdminStudentModel {
  final String id;
  final String? userId;
  final String name;
  final String email;
  final String avatarInitial;
  final String university;
  final String department;
  final String degree;
  final String semester;
  final double cgpa;
  final List<String> skills;
  final StudentVerificationStatus verificationStatus;
  final StudentAccountStatus accountStatus;
  final String registrationDate;
  final DateTime registrationDateTime;
  final String? suspensionReason;
  final String verificationDocumentName;
  final String verificationDocumentType;
  final String verificationDocumentSize;
  final String? verificationDocumentUrl;
  final String portfolioUrl;
  final String githubUrl;
  final String bio;
  final int applicationsCount;
  final int projectsCompletedCount;
  final int activeProjectsCount;
  final List<StudentAuditRecord> auditHistory;

  bool get isEngagedInProjects =>
      applicationsCount > 0 ||
      activeProjectsCount > 0 ||
      projectsCompletedCount > 0;

  const AdminStudentModel({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.avatarInitial,
    required this.university,
    required this.department,
    required this.degree,
    required this.semester,
    required this.cgpa,
    required this.skills,
    required this.verificationStatus,
    required this.accountStatus,
    required this.registrationDate,
    required this.registrationDateTime,
    this.suspensionReason,
    required this.verificationDocumentName,
    required this.verificationDocumentType,
    required this.verificationDocumentSize,
    this.verificationDocumentUrl,
    required this.portfolioUrl,
    required this.githubUrl,
    required this.bio,
    this.applicationsCount = 0,
    this.projectsCompletedCount = 0,
    this.activeProjectsCount = 0,
    required this.auditHistory,
  });

  AdminStudentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? avatarInitial,
    String? university,
    String? department,
    String? degree,
    String? semester,
    double? cgpa,
    List<String>? skills,
    StudentVerificationStatus? verificationStatus,
    StudentAccountStatus? accountStatus,
    String? registrationDate,
    DateTime? registrationDateTime,
    String? suspensionReason,
    bool clearSuspensionReason = false,
    String? verificationDocumentName,
    String? verificationDocumentType,
    String? verificationDocumentSize,
    String? verificationDocumentUrl,
    String? portfolioUrl,
    String? githubUrl,
    String? bio,
    int? applicationsCount,
    int? projectsCompletedCount,
    int? activeProjectsCount,
    List<StudentAuditRecord>? auditHistory,
  }) {
    return AdminStudentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      university: university ?? this.university,
      department: department ?? this.department,
      degree: degree ?? this.degree,
      semester: semester ?? this.semester,
      cgpa: cgpa ?? this.cgpa,
      skills: skills ?? this.skills,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      registrationDate: registrationDate ?? this.registrationDate,
      registrationDateTime: registrationDateTime ?? this.registrationDateTime,
      suspensionReason:
          clearSuspensionReason ? null : (suspensionReason ?? this.suspensionReason),
      verificationDocumentName:
          verificationDocumentName ?? this.verificationDocumentName,
      verificationDocumentType:
          verificationDocumentType ?? this.verificationDocumentType,
      verificationDocumentSize:
          verificationDocumentSize ?? this.verificationDocumentSize,
      verificationDocumentUrl:
          verificationDocumentUrl ?? this.verificationDocumentUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      bio: bio ?? this.bio,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      projectsCompletedCount:
          projectsCompletedCount ?? this.projectsCompletedCount,
      activeProjectsCount: activeProjectsCount ?? this.activeProjectsCount,
      auditHistory: auditHistory ?? this.auditHistory,
    );
  }
}

