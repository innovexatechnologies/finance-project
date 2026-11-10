import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
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
    return applicantsNotifier.value
        .where(
          (a) =>
              a.projectId == projectId &&
              (a.status == 'Accepted' ||
                  a.status == 'In Progress' ||
                  a.status == 'Under Review' ||
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
          .map((r) =>
              (r['student_id'] ?? r['user_id'])?.toString() ?? '')
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
            certsByStudent.putIfAbsent(sid, () => []).add(
                  StudentCertificate(
                    id: c['id']?.toString() ?? '',
                    title: c['certificate_title']?.toString() ??
                        'Certificate of Project Completion',
                    issuer: c['issuer']?.toString() ??
                        c['company_name']?.toString() ??
                        'Corporate Partner',
                    issueDate: c['issue_date']?.toString() ??
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

        final cgpaVal = (r['student_cgpa'] as num?)?.toDouble() ??
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
        final bio = _firstNonEmpty([
          stu?['bio'],
          prof?['bio'],
        ]);

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

        loaded.add(
          ApplicantModel(
            id: r['id']?.toString() ?? '',
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
            status: r['status']?.toString() ?? 'Pending',
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

    ProjectModel? matchedProject;
    for (final p in projectService.allProjects) {
      if (p.id == targetApplicant.projectId) {
        matchedProject = p;
        break;
      }
    }

    if (newStatus == 'Accepted') {
      final openings = matchedProject?.openings ?? 1;
      final acceptedCount = getAcceptedCount(targetApplicant.projectId);
      if (acceptedCount >= openings && targetApplicant.status != 'Accepted') {
        return false;
      }

      final assignedLabel = targetApplicant.university.isNotEmpty
          ? '${targetApplicant.name} (${targetApplicant.university})'
          : targetApplicant.name;
      if (matchedProject != null) {
        await projectService.updateProjectStatus(
          matchedProject.id,
          'In Progress',
          assignedStudent: assignedLabel,
          progress: 0.15,
        );
      }
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null &&
        user != null &&
        SupabaseHelper.isUuid(applicantId)) {
      try {
        await supabase.from('applications').update({
          'status': newStatus,
          if (newStatus == 'Accepted') 'progress': 0.15,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', applicantId);

        if (SupabaseHelper.isUuid(targetApplicant.studentId)) {
          final companyName = CompanyProfileService().currentProfile.companyName;
          final actor = companyName.isNotEmpty ? companyName : 'Company Partner';
          String notifTitle;
          String notifMsg;
          String notifType;
          if (newStatus == 'Accepted') {
            notifTitle = 'Application Accepted!';
            notifMsg =
                'Congratulations! $actor accepted your application for "${targetApplicant.projectTitle}".';
            notifType = 'approved';
          } else if (newStatus == 'Shortlisted') {
            notifTitle = 'Application Shortlisted';
            notifMsg =
                '$actor shortlisted your application for "${targetApplicant.projectTitle}".';
            notifType = 'submitted';
          } else if (newStatus == 'Rejected') {
            notifTitle = 'Application Update';
            notifMsg =
                'Your application for "${targetApplicant.projectTitle}" was not selected at this time.';
            notifType = 'revision';
          } else {
            notifTitle = 'Application Under Review';
            notifMsg =
                '$actor is reviewing your application for "${targetApplicant.projectTitle}".';
            notifType = 'general';
          }

          await supabase.from('notifications').insert({
            'user_id': targetApplicant.studentId,
            'title': notifTitle,
            'message': notifMsg,
            'type': notifType,
            if (SupabaseHelper.isUuid(targetApplicant.projectId))
              'project_id': targetApplicant.projectId,
            'actor_name': actor,
            'is_read': false,
          });
        }
      } catch (e) {
        debugPrint('CompanyApplicantService updateApplicantStatus error: $e');
      }
    }

    final updatedList = List<ApplicantModel>.from(currentList);
    updatedList[targetIndex] = targetApplicant.copyWith(status: newStatus);
    applicantsNotifier.value = updatedList;
    return true;
  }

  void reset() {
    applicantsNotifier.value = [];
  }
}
