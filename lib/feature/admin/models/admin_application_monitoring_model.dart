enum ApplicationWorkflowStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
}

enum ApplicationReportStatus {
  clear,
  reported,
  underInvestigation,
  resolved,
  dismissed,
}

enum SuspiciousFlagType {
  none,
  spamApplication,
  credentialDiscrepancy,
  offPlatformSolicitation,
  plagiarism,
  impersonation,
}

class InvestigationRecord {
  final String id;
  final String action;
  final String adminName;
  final String timestamp;
  final String? note;
  final String? findings;

  const InvestigationRecord({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    this.note,
    this.findings,
  });
}

class ApplicationReportDetail {
  final String reportId;
  final String reportedBy;
  final String reporterRole; // 'Company Liaison', 'Academic Proctor', 'System Heuristic'
  final String reportedDate;
  final String reportCategory;
  final String reportExplanation;
  final String? evidenceSnippet;
  final String severity; // 'Low', 'Medium', 'High', 'Critical'

  const ApplicationReportDetail({
    required this.reportId,
    required this.reportedBy,
    required this.reporterRole,
    required this.reportedDate,
    required this.reportCategory,
    required this.reportExplanation,
    this.evidenceSnippet,
    this.severity = 'Medium',
  });
}

class AdminApplicationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String university;
  final String degree;
  final String department;
  final String semester;
  final double cgpa;
  final bool isEducationVerified;
  final String projectId;
  final String projectTitle;
  final String projectCategory;
  final String companyId;
  final String companyName;
  final String companyLiaison;
  final String submissionDate;
  final DateTime submissionDateTime;
  final ApplicationWorkflowStatus workflowStatus;
  final ApplicationReportStatus reportStatus;
  final SuspiciousFlagType flagType;
  final String proposalSummary;
  final List<String> skills;
  final String resumeFileName;
  final String? resumeUrl;
  final String? submittedWorkUrl;
  final ApplicationReportDetail? reportDetail;
  final List<String> investigationNotes;
  final List<InvestigationRecord> investigationHistory;
  final bool isDecisionModifiedByAdmin;
  final String? administrativeDecisionNote;

  const AdminApplicationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.university,
    required this.degree,
    required this.department,
    required this.semester,
    required this.cgpa,
    required this.isEducationVerified,
    required this.projectId,
    required this.projectTitle,
    required this.projectCategory,
    required this.companyId,
    required this.companyName,
    required this.companyLiaison,
    required this.submissionDate,
    required this.submissionDateTime,
    required this.workflowStatus,
    required this.reportStatus,
    this.flagType = SuspiciousFlagType.none,
    required this.proposalSummary,
    required this.skills,
    this.resumeFileName = '',
    this.resumeUrl,
    this.submittedWorkUrl,
    this.reportDetail,
    this.investigationNotes = const [],
    this.investigationHistory = const [],
    this.isDecisionModifiedByAdmin = false,
    this.administrativeDecisionNote,
  });

  AdminApplicationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? university,
    String? degree,
    String? department,
    String? semester,
    double? cgpa,
    bool? isEducationVerified,
    String? projectId,
    String? projectTitle,
    String? projectCategory,
    String? companyId,
    String? companyName,
    String? companyLiaison,
    String? submissionDate,
    DateTime? submissionDateTime,
    ApplicationWorkflowStatus? workflowStatus,
    ApplicationReportStatus? reportStatus,
    SuspiciousFlagType? flagType,
    String? proposalSummary,
    List<String>? skills,
    String? resumeFileName,
    String? resumeUrl,
    String? submittedWorkUrl,
    ApplicationReportDetail? reportDetail,
    List<String>? investigationNotes,
    List<InvestigationRecord>? investigationHistory,
    bool? isDecisionModifiedByAdmin,
    String? administrativeDecisionNote,
  }) {
    return AdminApplicationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      cgpa: cgpa ?? this.cgpa,
      isEducationVerified: isEducationVerified ?? this.isEducationVerified,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      projectCategory: projectCategory ?? this.projectCategory,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyLiaison: companyLiaison ?? this.companyLiaison,
      submissionDate: submissionDate ?? this.submissionDate,
      submissionDateTime: submissionDateTime ?? this.submissionDateTime,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      reportStatus: reportStatus ?? this.reportStatus,
      flagType: flagType ?? this.flagType,
      proposalSummary: proposalSummary ?? this.proposalSummary,
      skills: skills ?? this.skills,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      submittedWorkUrl: submittedWorkUrl ?? this.submittedWorkUrl,
      reportDetail: reportDetail ?? this.reportDetail,
      investigationNotes: investigationNotes ?? this.investigationNotes,
      investigationHistory: investigationHistory ?? this.investigationHistory,
      isDecisionModifiedByAdmin:
          isDecisionModifiedByAdmin ?? this.isDecisionModifiedByAdmin,
      administrativeDecisionNote:
          administrativeDecisionNote ?? this.administrativeDecisionNote,
    );
  }

  String get workflowStatusDisplay {
    switch (workflowStatus) {
      case ApplicationWorkflowStatus.pending:
        return 'Pending';
      case ApplicationWorkflowStatus.accepted:
        return 'Accepted';
      case ApplicationWorkflowStatus.rejected:
        return 'Rejected';
      case ApplicationWorkflowStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  String get reportStatusDisplay {
    switch (reportStatus) {
      case ApplicationReportStatus.clear:
        return 'Clear';
      case ApplicationReportStatus.reported:
        return 'Reported';
      case ApplicationReportStatus.underInvestigation:
        return 'Under Investigation';
      case ApplicationReportStatus.resolved:
        return 'Resolved';
      case ApplicationReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  String get flagTypeDisplay {
    switch (flagType) {
      case SuspiciousFlagType.none:
        return 'None';
      case SuspiciousFlagType.spamApplication:
        return 'Spam Submissions';
      case SuspiciousFlagType.credentialDiscrepancy:
        return 'Credential Tampering';
      case SuspiciousFlagType.offPlatformSolicitation:
        return 'Off-Platform Solicitation';
      case SuspiciousFlagType.plagiarism:
        return 'Proposal Plagiarism';
      case SuspiciousFlagType.impersonation:
        return 'Identity Impersonation';
    }
  }
}

