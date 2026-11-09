import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class CompanyAssignmentService {
  static final CompanyAssignmentService _instance =
      CompanyAssignmentService._internal();

  factory CompanyAssignmentService() => _instance;

  CompanyAssignmentService._internal() {
    final company = CompanyProfileService().currentProfile;

    // Seeded with realistic assignments strictly for the logged-in company
    assignmentsNotifier = ValueNotifier<List<AssignmentModel>>([
      AssignmentModel(
        id: 'asgn_01',
        companyId: company.id,
        projectId: 'proj_01',
        projectTitle: 'Flutter E-Commerce Mobile App',
        projectCategory: 'Mobile App Development',
        projectStatus: 'In Progress',
        startDate: '2026-11-06',
        deadline: '2026-12-15',
        studentId: 'std_fast_01',
        applicantId: 'app_01',
        studentName: 'Ali Khan',
        studentUniversity: 'FAST-NUCES Islamabad',
        studentDegree: 'BS Computer Science (Final Year)',
        studentAvatarInitial: 'AK',
        progress: 0.65,
        hasSubmission: true,
        submissionStatus: 'Submitted',
        latestSubmission: const StudentSubmissionModel(
          id: 'sub_01',
          title: 'Milestone 2: Modular Catalog & Checkout Architecture',
          notes:
              'Implemented responsive catalog grid, category filter drawer, Bloc state management, and SQLite cart caching. Automated unit tests have 94% coverage. Ready for corporate code review.',
          submittedDate: 'Yesterday at 04:30 PM',
          repositoryUrl: 'https://github.com/alikhan/ecommerce-flutter',
          liveDemoUrl: 'https://app-preview.campusconnect.edu/alikhan/ecom',
          attachmentFiles: [
            'Ecommerce_v1.0_Release.apk',
            'Milestone2_Architecture_Documentation.pdf',
          ],
          status: 'Submitted',
        ),
      ),
      AssignmentModel(
        id: 'asgn_02',
        companyId: company.id,
        projectId: 'proj_03',
        projectTitle: 'Corporate Sentiment Analysis Pipeline',
        projectCategory: 'AI / Machine Learning & Data',
        projectStatus: 'In Progress',
        startDate: '2026-11-04',
        deadline: '2026-12-30',
        studentId: 'std_pucit_06',
        applicantId: 'app_06',
        studentName: 'Mustafa Hassan',
        studentUniversity: 'PUCIT Lahore',
        studentDegree: 'MS Data Science',
        studentAvatarInitial: 'MH',
        progress: 0.40,
        hasSubmission: true,
        submissionStatus: 'Under Review',
        latestSubmission: const StudentSubmissionModel(
          id: 'sub_02',
          title: 'Milestone 1: RoBERTa Fine-Tuning & FastAPI Container',
          notes:
              'Delivered tokenization scripts, fine-tuned RoBERTa model weights on conversational Roman Urdu customer feedback dataset, and initial Dockerfile.',
          submittedDate: '2 days ago',
          repositoryUrl: 'https://github.com/mustafahassan/sentiment-pipeline',
          attachmentFiles: [
            'RoBERTa_Evaluation_Metrics.pdf',
            'docker-compose.yml',
          ],
          status: 'Under Review',
        ),
      ),
      AssignmentModel(
        id: 'asgn_03',
        companyId: company.id,
        projectId: 'proj_04',
        projectTitle: 'Campus Ambassador Portal Dashboard',
        projectCategory: 'Web Development',
        projectStatus: 'Completed',
        startDate: '2026-10-15',
        deadline: '2026-11-05',
        studentId: 'std_lums_03',
        applicantId: 'app_03',
        studentName: 'Hamza Tariq',
        studentUniversity: 'LUMS Lahore',
        studentDegree: 'BS Computer Science',
        studentAvatarInitial: 'HT',
        progress: 1.0,
        hasSubmission: true,
        submissionStatus: 'Approved',
        latestSubmission: const StudentSubmissionModel(
          id: 'sub_03',
          title: 'Final Deliverable: Production React & Tailwind Dashboard',
          notes:
              'All milestone requirements completed and approved. Responsive web deployment is online and tested on multiple browsers.',
          submittedDate: '2026-11-05',
          repositoryUrl: 'https://github.com/hamzatariq-lums/ambassador-portal',
          liveDemoUrl: 'https://ambassador-portal.campusconnect.edu',
          attachmentFiles: ['Final_Release_Summary.pdf'],
          status: 'Approved',
          companyFeedback:
              'Outstanding frontend delivery! Code is clean, documented, and modular.',
        ),
      ),
      AssignmentModel(
        id: 'asgn_04',
        companyId: company.id,
        projectId: 'proj_02',
        projectTitle: 'Barcode & QR Scanner Mobile Utility',
        projectCategory: 'Mobile App Development',
        projectStatus: 'In Progress',
        startDate: '2026-11-08',
        deadline: '2026-12-01',
        studentId: 'std_giki_04',
        applicantId: 'app_04',
        studentName: 'Bilal Shah',
        studentUniversity: 'GIKI Swabi',
        studentDegree: 'BS Computer Engineering',
        studentAvatarInitial: 'BS',
        progress: 0.15,
        hasSubmission: false,
        submissionStatus: 'Pending Submission',
        latestSubmission: null,
      ),
    ]);

    // Keep synchronized with applicants service
    CompanyApplicantService().applicantsNotifier.addListener(_syncWithAcceptedApplicants);
  }

  late final ValueNotifier<List<AssignmentModel>> assignmentsNotifier;

  List<AssignmentModel> get allAssignments => assignmentsNotifier.value;

  // Filter assignments strictly belonging to the logged-in company
  List<AssignmentModel> getAssignmentsForCompany(String companyId) {
    return assignmentsNotifier.value
        .where((a) => a.companyId == companyId)
        .toList();
  }

  // Filter assignments for a specific project
  List<AssignmentModel> getAssignmentsForProject(String projectId) {
    return assignmentsNotifier.value
        .where((a) => a.projectId == projectId)
        .toList();
  }

  // Review a student work submission (Approve, Request Revision, or Under Review)
  Future<bool> reviewSubmission({
    required String assignmentId,
    required String newStatus, // 'Approved', 'Revision Requested', 'Under Review'
    String? feedback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final currentList = assignmentsNotifier.value;
    final index = currentList.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return false;

    final assignment = currentList[index];
    final currentSubmission = assignment.latestSubmission;
    if (currentSubmission == null) return false;

    final updatedSubmission = currentSubmission.copyWith(
      status: newStatus,
      companyFeedback: feedback ?? currentSubmission.companyFeedback,
    );

    // If approved, update progress
    double newProgress = assignment.progress;
    String newProjStatus = assignment.projectStatus;
    if (newStatus == 'Approved') {
      newProgress = 1.0;
      newProjStatus = 'Completed';
      // Also update project service
      CompanyProjectService().updateProjectStatus(assignment.projectId, 'Completed');
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

  // Automatic synchronization with newly accepted applicants
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
        (a) => a.applicantId == applicant.id && a.projectId == applicant.projectId,
      );

      if (!exists) {
        // Find matching project
        final project = CompanyProjectService().allProjects.firstWhere(
              (p) => p.id == applicant.projectId,
              orElse: () => CompanyProjectService().allProjects.first,
            );

        currentList.insert(
          0,
          AssignmentModel(
            id: 'asgn_${applicant.id}',
            companyId: company.id,
            projectId: applicant.projectId,
            projectTitle: applicant.projectTitle,
            projectCategory: project.category,
            projectStatus: 'In Progress',
            startDate: applicant.appliedDate,
            deadline: project.deadline,
            studentId: applicant.studentId,
            applicantId: applicant.id,
            studentName: applicant.name,
            studentUniversity: applicant.university,
            studentDegree: applicant.degree,
            studentAvatarInitial: applicant.avatarInitial,
            progress: 0.10,
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
}

