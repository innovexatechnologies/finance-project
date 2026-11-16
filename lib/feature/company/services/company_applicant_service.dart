import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

class CompanyApplicantService {
  static final CompanyApplicantService _instance =
      CompanyApplicantService._internal();

  factory CompanyApplicantService() => _instance;

  CompanyApplicantService._internal();

  final ValueNotifier<List<ApplicantModel>> applicantsNotifier =
      ValueNotifier<List<ApplicantModel>>([]);

  List<ApplicantModel> get allApplicants => applicantsNotifier.value;

  List<ApplicantModel> getApplicantsForProject(String projectId) {
    return applicantsNotifier.value
        .where((a) => a.projectId == projectId)
        .toList();
  }

  ApplicantModel? getApplicantById(String id) {
    for (final a in applicantsNotifier.value) {
      if (a.id == id || a.studentId == id) return a;
    }
    return null;
  }

  int getAcceptedCount(String projectId) {
    for (final project in CompanyProjectService().allProjects) {
      if (project.id == projectId &&
          project.assignedStudent?.trim().isNotEmpty == true) {
        return 1;
      }
    }

    return applicantsNotifier.value
        .where(
          (a) =>
              a.projectId == projectId &&
              (a.status == 'Accepted' ||
                  a.status == 'In Progress' ||
                  a.status == 'Revision Requested' ||
                  a.status == 'Completed'),
        )
        .length;
  }

  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final projectService = CompanyProjectService();
      var projectIds = projectService.allProjects
          .map((p) => p.id)
          .where((id) => SupabaseHelper.isUuid(id))
          .toList();

      if (projectIds.isEmpty) {
        final ownedRows = await supabase
            .from('projects')
            .select('id')
            .or('posted_by.eq.${user.id},user_id.eq.${user.id}');
        projectIds = ownedRows
            .map((r) => r['id']?.toString() ?? '')
            .where((id) => SupabaseHelper.isUuid(id))
            .toList();
      }

      if (projectIds.isEmpty) {
        applicantsNotifier.value = [];
        return;
      }

      final appRows = await supabase
          .from('applications')
          .select()
          .inFilter('project_id', projectIds)
          .order('submitted_at', ascending: false);

      final studentIds = appRows
          .map((r) => (r['student_id'] ?? r['user_id'])?.toString() ?? '')
          .where((id) => SupabaseHelper.isUuid(id))
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> studentByUser = {};
      final Map<String, Map<String, dynamic>> profileByUser = {};
      final Map<String, List<StudentCertificate>> certsByStudent = {};

      if (studentIds.isNotEmpty) {
        try {
          final stuRows = await supabase
              .from('students')
              .select()
              .inFilter('user_id', studentIds);
          for (final s in stuRows) {
            final uid = s['user_id']?.toString() ?? '';
            if (uid.isNotEmpty) {
              studentByUser[uid] = Map<String, dynamic>.from(s);
            }
          }
        } catch (e) {
          debugPrint('CompanyApplicantService students fetch error: $e');
        }

        try {
          final profRows = await supabase
              .from('profiles')
              .select()
              .inFilter('id', studentIds);
          for (final p in profRows) {
            final uid = p['id']?.toString() ?? '';
            if (uid.isNotEmpty) {
              profileByUser[uid] = Map<String, dynamic>.from(p);
            }
          }
        } catch (e) {
          debugPrint('CompanyApplicantService profiles fetch error: $e');
        }

        try {
          final certRows = await supabase
              .from('certificates')
              .select()
              .inFilter('student_id', studentIds)
              .order('created_at', ascending: false);
          for (final raw in certRows) {
            final c = Map<String, dynamic>.from(raw);
            if (c['status'] == 'revoked') continue;
            final sid = c['student_id']?.toString() ?? '';
            if (sid.isEmpty) continue;
            certsByStudent
                .putIfAbsent(sid, () => [])
                .add(
                  StudentCertificate(
                    id: c['id']?.toString() ?? '',
                    title:
                        c['certificate_title']?.toString() ??
                        'Certificate of Project Completion',
                    issuer:
                        c['issuer']?.toString() ??
                        c['company_name']?.toString() ??
                        'Corporate Partner',
                    issueDate:
                        c['issue_date']?.toString() ??
                        SupabaseHelper.formatDate(
                          SupabaseHelper.parseDate(c['created_at']) ??
                              DateTime.now(),
                        ),
                    credentialId: c['certificate_id']?.toString() ?? '',
                    verificationUrl: c['verification_url']?.toString(),
                  ),
                );
          }
        } catch (e) {
          debugPrint('CompanyApplicantService certificates fetch error: $e');
        }
      }

      final List<ApplicantModel> loaded = [];
      for (final raw in appRows) {
        final r = Map<String, dynamic>.from(raw);
        final sid = (r['student_id'] ?? r['user_id'])?.toString() ?? '';
        final stu = studentByUser[sid];
        final prof = profileByUser[sid];

        final name = _firstNonEmpty([
          r['student_name'],
          stu?['full_name'],
          prof?['name'],
          'Student Applicant',
        ]);
        final email = _firstNonEmpty([
          r['student_email'],
          stu?['email'],
          prof?['email'],
        ]);
        final university = _firstNonEmpty([
          r['university'],
          stu?['university'],
          prof?['university'],
          'University Partner',
        ]);
        final degree = _firstNonEmpty([
          r['student_degree'],
          stu?['degree'],
          prof?['degree'],
          'Undergraduate Program',
        ]);
        final department = _firstNonEmpty([
          r['student_department'],
          stu?['department'],
          prof?['department'],
        ]);
        final semester = _firstNonEmpty([
          r['student_semester'],
          stu?['semester'],
          prof?['semester'],
        ]);

        final cgpaVal =
            (r['student_cgpa'] as num?)?.toDouble() ??
            (stu?['cgpa'] as num?)?.toDouble() ??
            (prof?['cgpa'] as num?)?.toDouble() ??
            0.0;

        final appSkills = SupabaseHelper.parseStringList(r['skills']);
        final stuSkills = SupabaseHelper.parseStringList(stu?['skills']);
        final skills = appSkills.isNotEmpty ? appSkills : stuSkills;

        final portfolioUrl = _firstNonEmpty([
          r['portfolio_link'],
          r['github_link'],
          stu?['portfolio_url'],
          stu?['github_url'],
        ]);
        final resumeName = _firstNonEmpty([
          r['resume_link'],
          stu?['resume_url'],
        ]);
        final bio = _firstNonEmpty([stu?['bio'], prof?['bio']]);

        final verifStatus =
            stu?['verification_status']?.toString().toLowerCase() ?? '';
        final isVerified =
            verifStatus == 'verified' || (prof?['is_verified'] == true);

        final pid = r['project_id']?.toString() ?? '';
        ProjectModel? matchedProj;
        for (final p in projectService.allProjects) {
          if (p.id == pid) {
            matchedProj = p;
            break;
          }
        }

        final appId = r['id']?.toString() ?? '';
        final localIdx =
            applicantsNotifier.value.indexWhere((a) => a.id == appId);
        final wasAcceptedLocally = localIdx != -1 &&
            (applicantsNotifier.value[localIdx].status == 'Accepted' ||
                applicantsNotifier.value[localIdx].status == 'In Progress');
        final isAssignedInProject = (matchedProj?.assignedStudent != null &&
            matchedProj!.assignedStudent!.trim().isNotEmpty &&
            matchedProj.assignedStudent!
                .toLowerCase()
                .contains(name.toLowerCase()));

        String rawStatus = r['status']?.toString() ?? 'Pending';
        if (rawStatus == 'Pending' &&
            (wasAcceptedLocally || isAssignedInProject)) {
          rawStatus = 'Accepted';
        }

        loaded.add(
          ApplicantModel(
            id: appId,
            studentId: sid,
            projectId: pid,
            projectTitle: _firstNonEmpty([
              r['project_title'],
              matchedProj?.title,
              'Project Challenge',
            ]),
            name: name,
            email: email,
            university: university,
            isEducationVerified: isVerified,
            degree: degree,
            department: department,
            semester: semester,
            cgpa: cgpaVal,
            skills: skills,
            appliedDate: SupabaseHelper.formatDate(
              SupabaseHelper.parseDate(r['submitted_at']) ?? DateTime.now(),
            ),
            proposalSummary: _firstNonEmpty([
              r['cover_letter'],
              'No proposal summary provided.',
            ]),
            status: rawStatus,
            avatarInitial: SupabaseHelper.initialsFor(name, fallback: 'ST'),
            profilePictureUrl: prof?['avatar_url']?.toString(),
            portfolioUrl: portfolioUrl,
            rating: 0.0,
            bio: bio,
            resumeFileName: resumeName,
            certificates: certsByStudent[sid] ?? const [],
          ),
        );
      }

      applicantsNotifier.value = loaded;
    } catch (e) {
      debugPrint('CompanyApplicantService loadFromSupabase error: $e');
    }
  }

  String _firstNonEmpty(List<dynamic> candidates) {
    for (final item in candidates) {
      if (item != null && item.toString().trim().isNotEmpty) {
        return item.toString().trim();
      }
    }
    return '';
  }

  Future<bool> updateApplicantStatus({
    required String applicantId,
    required String newStatus,
  }) async {
    final currentList = applicantsNotifier.value;
    final targetIndex = currentList.indexWhere((a) => a.id == applicantId);
    if (targetIndex == -1) return false;

    final targetApplicant = currentList[targetIndex];
    final projectService = CompanyProjectService();
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;

    ProjectModel? matchedProject;
    for (final p in projectService.allProjects) {
      if (p.id == targetApplicant.projectId) {
        matchedProject = p;
        break;
      }
    }

    if (newStatus == 'Accepted') {
      if (targetApplicant.status == 'Accepted' ||
          targetApplicant.status == 'Completed' ||
          targetApplicant.status == 'In Progress') {
        return true;
      }

      if ((supabase == null || user == null) &&
          targetApplicant.status != 'Accepted') {
        final openings = matchedProject?.openings ?? 1;
        if (getAcceptedCount(targetApplicant.projectId) >= openings) {
          return false;
        }
      }

      final assignedLabel = targetApplicant.university.isNotEmpty
          ? '${targetApplicant.name} (${targetApplicant.university})'
          : targetApplicant.name;

      if (supabase != null && user != null) {
        if (!SupabaseHelper.isUuid(applicantId)) return false;
        final nowIso = DateTime.now().toIso8601String();

        // 1. Try assignment RPC (SECURITY DEFINER)
        try {
          await supabase.rpc(
            'assign_applicant_to_project',
            params: {
              'p_application_id': applicantId,
              'p_confirm_existing': false,
            },
          );
        } catch (e) {
          debugPrint('CompanyApplicantService assignment RPC attempt 1 notice: $e');
          try {
            await supabase.rpc(
              'assign_applicant_to_project',
              params: {
                'p_application_id': applicantId,
                'p_confirm_existing': true,
              },
            );
          } catch (e2) {
            debugPrint('CompanyApplicantService assignment RPC attempt 2 notice: $e2');
          }
        }

        // 2. Direct database updates fallback/reinforcement
        // Ensure project_assignments table has record (satisfies trigger enforce_application_assignment_status)
        try {
          await supabase.from('project_assignments').upsert({
            'application_id': applicantId,
            'project_id': targetApplicant.projectId,
            'student_id': targetApplicant.studentId,
            'assigned_at': nowIso,
          });
        } catch (paErr) {
          debugPrint('Direct project_assignments upsert notice: $paErr');
        }

        // Update applications table for accepted student
        try {
          await supabase
              .from('applications')
              .update({
                'status': 'Accepted',
                'progress': 0.15,
                'updated_at': nowIso,
              })
              .eq('id', applicantId);
        } catch (appErr) {
          debugPrint('Direct applications update notice: $appErr');
        }

        // Update other applications for this project to Rejected
        try {
          await supabase
              .from('applications')
              .update({
                'status': 'Rejected',
                'updated_at': nowIso,
              })
              .eq('project_id', targetApplicant.projectId)
              .neq('id', applicantId);
        } catch (_) {}

        // Update projects table to In Progress & assigned student
        if (targetApplicant.projectId.isNotEmpty &&
            SupabaseHelper.isUuid(targetApplicant.projectId)) {
          try {
            await supabase
                .from('projects')
                .update({
                  'status': 'In Progress',
                  'assigned_student': assignedLabel,
                  'progress': 0.15,
                  'updated_at': nowIso,
                })
                .eq('id', targetApplicant.projectId);
          } catch (projErr) {
            debugPrint('Direct projects update In Progress notice: $projErr');
            try {
              await supabase
                  .from('projects')
                  .update({
                    'status': 'in_progress',
                    'assigned_student': assignedLabel,
                    'progress': 0.15,
                    'updated_at': nowIso,
                  })
                  .eq('id', targetApplicant.projectId);
            } catch (_) {}
          }
        }
      }

      if (matchedProject != null) {
        await projectService.updateProjectStatus(
          matchedProject.id,
          'In Progress',
          assignedStudent: assignedLabel,
          progress: 0.15,
        );
      }

      // Keep AppDataService synchronized immediately across all sessions
      await AppDataService.instance.recordApplicantAccepted(
        applicationId: applicantId,
        projectId: targetApplicant.projectId,
        studentId: targetApplicant.studentId,
        studentName: targetApplicant.name,
        studentUniversity: targetApplicant.university,
        projectTitle: targetApplicant.projectTitle,
      );

      // Keep CompanyAssignmentService in sync immediately for Deliverables tab
      final assignmentService = CompanyAssignmentService();
      final existingAssignmentIndex =
          assignmentService.allAssignments.indexWhere(
        (a) => a.id == applicantId || a.projectId == targetApplicant.projectId,
      );
      final newAssignment = AssignmentModel(
        id: applicantId,
        companyId: matchedProject?.companyId ?? '',
        projectId: targetApplicant.projectId,
        projectTitle: targetApplicant.projectTitle,
        projectCategory: matchedProject?.category ?? 'Development',
        projectStatus: 'In Progress',
        startDate: targetApplicant.appliedDate,
        deadline: matchedProject?.deadline ?? 'Flexible',
        studentId: targetApplicant.studentId,
        applicantId: applicantId,
        studentName: targetApplicant.name,
        studentUniversity: targetApplicant.university,
        studentDegree: targetApplicant.degree,
        studentAvatarInitial: targetApplicant.avatarInitial,
        progress: 0.15,
        hasSubmission: false,
        submissionStatus: 'Pending Submission',
        latestSubmission: null,
      );
      if (existingAssignmentIndex != -1) {
        final list = List<AssignmentModel>.from(assignmentService.allAssignments);
        list[existingAssignmentIndex] = newAssignment;
        assignmentService.assignmentsNotifier.value = list;
      } else {
        assignmentService.assignmentsNotifier.value = [
          newAssignment,
          ...assignmentService.allAssignments,
        ];
      }
    } else if (supabase != null &&
        user != null &&
        SupabaseHelper.isUuid(applicantId)) {
      try {
        await supabase
            .from('applications')
            .update({
              'status': newStatus,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', applicantId);
      } catch (e) {
        debugPrint('CompanyApplicantService updateApplicantStatus error: $e');
        return false;
      }
    }

    applicantsNotifier.value = currentList.map((applicant) {
      if (applicant.id == applicantId) {
        return targetApplicant.copyWith(status: newStatus);
      }
      if (newStatus == 'Accepted' &&
          applicant.projectId == targetApplicant.projectId) {
        return applicant.copyWith(status: 'Rejected');
      }
      return applicant;
    }).toList();

    await CompanyProfileService.persistLocalCache();
    return true;
  }

  void reset() {
    applicantsNotifier.value = [];
  }
}
