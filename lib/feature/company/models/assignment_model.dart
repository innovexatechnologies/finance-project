class StudentSubmissionModel {
  final String id;
  final String title;
  final String notes;
  final String submittedDate;
  final String repositoryUrl;
  final String? liveDemoUrl;
  final List<String> attachmentFiles;
  final String status; // 'Submitted', 'Under Review', 'Approved', 'Revision Requested'
  final String? companyFeedback;

  const StudentSubmissionModel({
    required this.id,
    required this.title,
    required this.notes,
    required this.submittedDate,
    required this.repositoryUrl,
    this.liveDemoUrl,
    this.attachmentFiles = const [],
    this.status = 'Submitted',
    this.companyFeedback,
  });

  StudentSubmissionModel copyWith({
    String? id,
    String? title,
    String? notes,
    String? submittedDate,
    String? repositoryUrl,
    String? liveDemoUrl,
    List<String>? attachmentFiles,
    String? status,
    String? companyFeedback,
  }) {
    return StudentSubmissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      submittedDate: submittedDate ?? this.submittedDate,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      liveDemoUrl: liveDemoUrl ?? this.liveDemoUrl,
      attachmentFiles: attachmentFiles ?? this.attachmentFiles,
      status: status ?? this.status,
      companyFeedback: companyFeedback ?? this.companyFeedback,
    );
  }

  factory StudentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return StudentSubmissionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      notes: json['notes'] ?? '',
      submittedDate: json['submitted_date'] ?? 'Recently',
      repositoryUrl: json['repository_url'] ?? '',
      liveDemoUrl: json['live_demo_url'],
      attachmentFiles: (json['attachment_files'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: json['status'] ?? 'Submitted',
      companyFeedback: json['company_feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'submitted_date': submittedDate,
      'repository_url': repositoryUrl,
      'live_demo_url': liveDemoUrl,
      'attachment_files': attachmentFiles,
      'status': status,
      'company_feedback': companyFeedback,
    };
  }
}

class AssignmentModel {
  final String id;
  final String companyId;
  final String projectId;
  final String projectTitle;
  final String projectCategory;
  final String projectStatus; // 'In Progress', 'Completed', 'Open'
  final String startDate;
  final String deadline;
  final String studentId;
  final String applicantId;
  final String studentName;
  final String studentUniversity;
  final String studentDegree;
  final String studentAvatarInitial;
  final String? studentProfileImage;
  final double progress; // 0.0 to 1.0
  final bool hasSubmission;
  final String submissionStatus; // 'Submitted', 'Under Review', 'Approved', 'Revision Requested', 'Pending Submission'
  final StudentSubmissionModel? latestSubmission;

  const AssignmentModel({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.projectTitle,
    required this.projectCategory,
    required this.projectStatus,
    required this.startDate,
    required this.deadline,
    required this.studentId,
    required this.applicantId,
    required this.studentName,
    required this.studentUniversity,
    required this.studentDegree,
    required this.studentAvatarInitial,
    this.studentProfileImage,
    this.progress = 0.5,
    this.hasSubmission = false,
    this.submissionStatus = 'Pending Submission',
    this.latestSubmission,
  });

  AssignmentModel copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? projectTitle,
    String? projectCategory,
    String? projectStatus,
    String? startDate,
    String? deadline,
    String? studentId,
    String? applicantId,
    String? studentName,
    String? studentUniversity,
    String? studentDegree,
    String? studentAvatarInitial,
    String? studentProfileImage,
    double? progress,
    bool? hasSubmission,
    String? submissionStatus,
    StudentSubmissionModel? latestSubmission,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      projectCategory: projectCategory ?? this.projectCategory,
      projectStatus: projectStatus ?? this.projectStatus,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      studentId: studentId ?? this.studentId,
      applicantId: applicantId ?? this.applicantId,
      studentName: studentName ?? this.studentName,
      studentUniversity: studentUniversity ?? this.studentUniversity,
      studentDegree: studentDegree ?? this.studentDegree,
      studentAvatarInitial: studentAvatarInitial ?? this.studentAvatarInitial,
      studentProfileImage: studentProfileImage ?? this.studentProfileImage,
      progress: progress ?? this.progress,
      hasSubmission: hasSubmission ?? this.hasSubmission,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      latestSubmission: latestSubmission ?? this.latestSubmission,
    );
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? 'comp_01',
      projectId: json['project_id'] ?? '',
      projectTitle: json['project_title'] ?? '',
      projectCategory: json['project_category'] ?? 'Software Dev',
      projectStatus: json['project_status'] ?? 'In Progress',
      startDate: json['start_date'] ?? '2026-11-01',
      deadline: json['deadline'] ?? '2026-12-15',
      studentId: json['student_id'] ?? '',
      applicantId: json['applicant_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentUniversity: json['student_university'] ?? '',
      studentDegree: json['student_degree'] ?? '',
      studentAvatarInitial: json['student_avatar_initial'] ?? 'ST',
      studentProfileImage: json['student_profile_image'],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.5,
      hasSubmission: json['has_submission'] ?? false,
      submissionStatus: json['submission_status'] ?? 'Pending Submission',
      latestSubmission: json['latest_submission'] != null
          ? StudentSubmissionModel.fromJson(
              json['latest_submission'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'project_title': projectTitle,
      'project_category': projectCategory,
      'project_status': projectStatus,
      'start_date': startDate,
      'deadline': deadline,
      'student_id': studentId,
      'applicant_id': applicantId,
      'student_name': studentName,
      'student_university': studentUniversity,
      'student_degree': studentDegree,
      'student_avatar_initial': studentAvatarInitial,
      'student_profile_image': studentProfileImage,
      'progress': progress,
      'has_submission': hasSubmission,
      'submission_status': submissionStatus,
      'latest_submission': latestSubmission?.toJson(),
    };
  }
}

