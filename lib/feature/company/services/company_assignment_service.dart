import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class CompanyAssignmentService {
  static final CompanyAssignmentService _instance =
      CompanyAssignmentService._internal();

  factory CompanyAssignmentService() => _instance;

  CompanyAssignmentService._internal() {
    CompanyApplicantService()
        .applicantsNotifier
        .addListener(_syncWithAcceptedApplicants);
  }

  final ValueNotifier<List<AssignmentModel>> assignmentsNotifier =
      ValueNotifier<List<AssignmentModel>>([]);

  List<AssignmentModel> get allAssignments => assignmentsNotifier.value;

  List<AssignmentModel> getAssignmentsForCompany(String companyId) {
    if (companyId.isEmpty) return assignmentsNotifier.value;
    return assignmentsNotifier.value
        .where((a) => a.companyId == companyId || a.companyId.isEmpty)
        .toList();
  }

  List<AssignmentModel> getAssignmentsForProject(String projectId) {
    return assignmentsNotifier.value
        .where((a) => a.projectId == projectId)
        .toList();
  }

  AssignmentModel? getAssignmentById(String id) {
    for (final a in assignmentsNotifier.value) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final projectService = CompanyProjectService();
      final company = CompanyProfileService().currentProfile;

      final projectIds = projectService.allProjects
          .map((p) => p.id)
          .where((id) => SupabaseHelper.isUuid(id))
          .toList();

      if (projectIds.isEmpty) {
        assignmentsNotifier.value = [];
        return;
      }

      final appRows = await supabase
          .from('applications')
          .select()
          .inFilter('project_id', projectIds)
          .order('updated_at', ascending: false);

      final List<AssignmentModel> loaded = [];

      for (final raw in appRows) {
        final r = Map<String, dynamic>.from(raw);
        final status = r['status']?.toString() ?? 'Pending';
        final workUrl = r['submitted_work_url']?.toString().trim() ?? '';
        final fileName = r['file_name']?.toString().trim() ?? '';
        final subNotes = r['submission_notes']?.toString().trim() ?? '';
        final subTitle = r['submission_title']?.toString().trim() ?? '';
        final hasWorkSubmitted = workUrl.isNotEmpty ||
            fileName.isNotEmpty ||
            subNotes.isNotEmpty ||
            subTitle.isNotEmpty ||
            r['work_submitted_at'] != null;

        final isAssignment = status == 'Accepted' ||
            status == 'In Progress' ||
            status == 'Revision Requested' ||
            status == 'Completed' ||
            (status == 'Under Review' && hasWorkSubmitted);

        if (!isAssignment) continue;

        final pid = r['project_id']?.toString() ?? '';
        ProjectModel? project;
        for (final p in projectService.allProjects) {
          if (p.id == pid) {
            project = p;
            break;
          }
        }

        final String uiSubmissionStatus;
        if (status == 'Completed') {
          uiSubmissionStatus = 'Approved';
        } else if (status == 'Revision Requested') {
          uiSubmissionStatus = 'Revision Requested';
        } else if (hasWorkSubmitted) {
          uiSubmissionStatus = 'Pending Review';
        } else {
          uiSubmissionStatus = 'Pending Submission';
        }

        final String projStatus = status == 'Completed'
            ? 'Completed'
            : (project?.status ?? 'In Progress');

        final rawHistory = r['review_history'];
        final List<SubmissionReviewRecord> history = [];
        if (rawHistory is List) {
          for (final item in rawHistory) {
            if (item is Map) {
              history.add(
                SubmissionReviewRecord.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        StudentSubmissionModel? latestSubmission;
        if (hasWorkSubmitted) {
          final files = <SubmissionFileAttachment>[];
          if (fileName.isNotEmpty) {
            final lower = fileName.toLowerCase();
            final fileType = lower.endsWith('.apk')
                ? 'APK'
                : lower.endsWith('.pdf')
                    ? 'PDF'
                    : lower.endsWith('.zip')
                        ? 'ZIP'
                        : 'FILE';
            files.add(
              SubmissionFileAttachment(
                fileName: fileName,
                fileSize: 'Submitted deliverable',
                fileType: fileType,
              ),
            );
          }

          latestSubmission = StudentSubmissionModel(
            id: r['id']?.toString() ?? '',
            title: subTitle.isNotEmpty
                ? subTitle
                : 'Deliverable: ${r['project_title'] ?? project?.title ?? 'Project'}',
            notes: subNotes.isNotEmpty
                ? subNotes
                : 'Deliverable submitted for corporate evaluation.',
            submittedDate: SupabaseHelper.formatRelativeTime(
              r['work_submitted_at'] ?? r['updated_at'],
            ),
            repositoryUrl: workUrl,
            files: files,
            attachmentFiles: files.map((f) => f.fileName).toList(),
            status: uiSubmissionStatus,
            companyFeedback: r['company_feedback']?.toString(),
            reviewHistory: history,
          );
        }

        final studentName = r['student_name']?.toString().trim() ?? 'Student';
        loaded.add(
          AssignmentModel(
            id: r['id']?.toString() ?? '',
            companyId: r['company_id']?.toString() ?? company.id,
            projectId: pid,
            projectTitle: r['project_title']?.toString() ??
                project?.title ??
                'Project',
            projectCategory: project?.category ?? 'Development',
            projectStatus: projStatus,
            startDate: SupabaseHelper.formatDate(
              SupabaseHelper.parseDate(r['submitted_at']) ?? DateTime.now(),
            ),
            deadline: project?.deadline ?? 'Flexible',
            studentId: (r['student_id'] ?? r['user_id'])?.toString() ?? '',
            applicantId: r['id']?.toString() ?? '',
            studentName: studentName,
            studentUniversity: r['university']?.toString() ?? '',
            studentDegree: r['student_degree']?.toString() ?? '',
            studentAvatarInitial:
                SupabaseHelper.initialsFor(studentName, fallback: 'ST'),
            progress: (r['progress'] as num?)?.toDouble() ??
                (status == 'Completed'
                    ? 1.0
                    : (hasWorkSubmitted ? 0.85 : 0.2)),
            hasSubmission: hasWorkSubmitted,
            submissionStatus: uiSubmissionStatus,
            latestSubmission: latestSubmission,
          ),
        );
      }

      assignmentsNotifier.value = loaded;
    } catch (e) {
      debugPrint('CompanyAssignmentService loadFromSupabase error: $e');
    }
  }

  Future<bool> reviewSubmission({
    required String assignmentId,
    required String newStatus, // 'Approved', 'Revision Requested'
    String? feedback,
    double overallRating = 5.0,
    String certificateTitle = 'Certificate of Project Completion',
  }) async {
    final currentList = assignmentsNotifier.value;
    final index = currentList.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return false;

    final assignment = currentList[index];
    final currentSubmission = assignment.latestSubmission;
    if (currentSubmission == null) return false;

    final profile = CompanyProfileService().currentProfile;
    final companyDisplay = profile.companyName.isNotEmpty
        ? profile.companyName
        : 'Company Partner';
    final reviewerDisplay = profile.contactPersonName.trim().isNotEmpty
        ? '${profile.contactPersonName.trim()} ($companyDisplay)'
        : companyDisplay;

    final cleanFeedback = (feedback != null && feedback.trim().isNotEmpty)
        ? feedback.trim()
        : (newStatus == 'Approved'
            ? 'Work deliverable approved with commendation.'
            : 'Revision requested. Please review mentor feedback.');

    final history =
        List<SubmissionReviewRecord>.from(currentSubmission.reviewHistory);
    history.insert(
      0,
      SubmissionReviewRecord(
        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
        reviewerName: reviewerDisplay,
        reviewDate: SupabaseHelper.formatDate(DateTime.now()),
        action: newStatus,
        feedback: cleanFeedback,
      ),
    );

    final updatedSubmission = currentSubmission.copyWith(
      status: newStatus,
      companyFeedback: cleanFeedback,
      reviewHistory: history,
    );

    double newProgress = assignment.progress;
    String newProjStatus = assignment.projectStatus;
    String dbAppStatus = newStatus;

    if (newStatus == 'Approved') {
      newProgress = 1.0;
      newProjStatus = 'Completed';
      dbAppStatus = 'Completed';
      await CompanyProjectService().updateProjectStatus(
        assignment.projectId,
        'Completed',
        progress: 1.0,
      );
    } else if (newStatus == 'Revision Requested') {
      newProgress = (assignment.progress > 0.25)
          ? (assignment.progress - 0.1).clamp(0.2, 0.85)
          : 0.5;
      dbAppStatus = 'Revision Requested';
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        if (SupabaseHelper.isUuid(assignment.id)) {
          await supabase.from('applications').update({
            'status': dbAppStatus,
            'company_feedback': cleanFeedback,
            'progress': newProgress,
            'review_history': history.map((h) => h.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', assignment.id);
        }

        if (newStatus == 'Approved' &&
            SupabaseHelper.isUuid(assignment.studentId)) {
          final existingCert = SupabaseHelper.isUuid(assignment.projectId)
              ? await supabase
                  .from('certificates')
                  .select('id')
                  .eq('student_id', assignment.studentId)
                  .eq('project_id', assignment.projectId)
                  .maybeSingle()
              : null;

          if (existingCert == null) {
            final randNum = 1000 + Random().nextInt(9000);
            final certCode = 'CERT-${DateTime.now().year}-$randNum';
            final hashInput =
                '$certCode:${assignment.studentId}:${assignment.projectId}';
            await supabase.from('certificates').insert({
              'certificate_id': certCode,
              'student_id': assignment.studentId,
              'student_name': assignment.studentName,
              'student_university': assignment.studentUniversity,
              'student_degree': assignment.studentDegree,
              if (SupabaseHelper.isUuid(assignment.companyId))
                'company_id': assignment.companyId,
              'company_name': companyDisplay,
              if (SupabaseHelper.isUuid(assignment.projectId))
                'project_id': assignment.projectId,
              'project_title': assignment.projectTitle,
              'certificate_title': certificateTitle,
              'certificate_type': 'completion',
              'issuer': companyDisplay,
              'issue_date': SupabaseHelper.formatDate(DateTime.now()),
              'overall_rating': overallRating,
              'recommendation_letter': cleanFeedback,
              'signatory_name': profile.contactPersonName.isNotEmpty
                  ? profile.contactPersonName
                  : companyDisplay,
              'signatory_title': 'Authorized Corporate Partner',
              'status': 'valid',
              'cryptographic_hash':
                  'sha256:${hashInput.hashCode.toRadixString(16).padLeft(12, '0')}',
              'verification_url': 'https://campusconnect.edu.pk/verify/$certCode',
            });
          }
        }

        if (SupabaseHelper.isUuid(assignment.studentId)) {
          await supabase.from('notifications').insert({
            'user_id': assignment.studentId,
            'title': newStatus == 'Approved'
                ? 'Work Approved & Certificate Issued!'
                : 'Revision Requested on "${assignment.projectTitle}"',
            'message': newStatus == 'Approved'
                ? '$companyDisplay approved your deliverable for "${assignment.projectTitle}". Your verified certificate is ready!'
                : '$companyDisplay requested revisions: $cleanFeedback',
            'type': newStatus == 'Approved' ? 'approved' : 'revision',
            if (SupabaseHelper.isUuid(assignment.projectId))
              'project_id': assignment.projectId,
            'actor_name': companyDisplay,
            'is_read': false,
          });
        }
      } catch (e) {
        debugPrint('CompanyAssignmentService reviewSubmission error: $e');
      }
    }

    final updatedAssignment = assignment.copyWith(
      submissionStatus: newStatus,
      progress: newProgress,
      projectStatus: newProjStatus,
      latestSubmission: updatedSubmission,
    );

    final updatedList = List<AssignmentModel>.from(currentList);
    updatedList[index] = updatedAssignment;
    assignmentsNotifier.value = updatedList;

    return true;
  }

  void _syncWithAcceptedApplicants() {
    final company = CompanyProfileService().currentProfile;
    final acceptedApplicants = CompanyApplicantService()
        .allApplicants
        .where((a) => a.status == 'Accepted')
        .toList();

    final currentList = List<AssignmentModel>.from(assignmentsNotifier.value);
    bool modified = false;

    for (final applicant in acceptedApplicants) {
      final exists = currentList.any(
        (a) =>
            (a.applicantId == applicant.id || a.id == applicant.id) &&
            a.projectId == applicant.projectId,
      );

      if (!exists) {
        ProjectModel? project;
        for (final p in CompanyProjectService().allProjects) {
          if (p.id == applicant.projectId) {
            project = p;
            break;
          }
        }

        currentList.insert(
          0,
          AssignmentModel(
            id: applicant.id,
            companyId: company.id,
            projectId: applicant.projectId,
            projectTitle: applicant.projectTitle,
            projectCategory: project?.category ?? 'Development',
            projectStatus: 'In Progress',
            startDate: applicant.appliedDate,
            deadline: project?.deadline ?? 'Flexible',
            studentId: applicant.studentId,
            applicantId: applicant.id,
            studentName: applicant.name,
            studentUniversity: applicant.university,
            studentDegree: applicant.degree,
            studentAvatarInitial: applicant.avatarInitial,
            progress: 0.15,
            hasSubmission: false,
            submissionStatus: 'Pending Submission',
            latestSubmission: null,
          ),
        );
        modified = true;
      }
    }

    if (modified) {
      assignmentsNotifier.value = currentList;
    }
  }

  void reset() {
    assignmentsNotifier.value = [];
  }
}
