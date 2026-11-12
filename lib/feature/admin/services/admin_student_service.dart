import 'package:flutter/foundation.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';

/// Enterprise Student Management Service backed by Supabase `students` & `profiles`.
class AdminStudentService {
  static final AdminStudentService _instance = AdminStudentService._internal();
  factory AdminStudentService() => _instance;

  AdminStudentService._internal();

  final ValueNotifier<List<AdminStudentModel>> studentsNotifier =
      ValueNotifier<List<AdminStudentModel>>([]);

  List<AdminStudentModel> get allStudents => studentsNotifier.value;

  int get totalCount => studentsNotifier.value.length;
  int get verifiedCount => studentsNotifier.value
      .where((s) => s.verificationStatus == StudentVerificationStatus.verified)
      .length;
  int get pendingCount => studentsNotifier.value
      .where((s) => s.verificationStatus == StudentVerificationStatus.pending)
      .length;
  int get rejectedCount => studentsNotifier.value
      .where((s) => s.verificationStatus == StudentVerificationStatus.rejected)
      .length;
  int get suspendedCount => studentsNotifier.value
      .where((s) => s.accountStatus == StudentAccountStatus.suspended)
      .length;
  int get activeAccountCount => studentsNotifier.value
      .where((s) => s.accountStatus == StudentAccountStatus.active)
      .length;
  int get engagedCount =>
      studentsNotifier.value.where((s) => s.isEngagedInProjects).length;

  /// Fetches registered students, project participation counts, and audit history from Supabase.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final studentRows = await supabase
          .from('students')
          .select()
          .order('created_at', ascending: false);

      // Enrich with profiles rows (handles students who haven't updated extended profile yet
      // and guards against role contamination from stale rows)
      final Map<String, Map<String, dynamic>> profilesById = {};
      final Map<String, Map<String, dynamic>> allProfilesById = {};
      try {
        final profRows = await supabase.from('profiles').select();
        for (final raw in profRows) {
          final p = Map<String, dynamic>.from(raw);
          final id = p['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          allProfilesById[id] = p;
          final uType = (p['user_type']?.toString() ?? 'student').trim().toLowerCase();
          if (uType == 'student' || uType.isEmpty) {
            profilesById[id] = p;
          }
        }
      } catch (e) {
        debugPrint('AdminStudentService profiles enrichment skipped: $e');
      }

      // Compute total applications, active, and completed project counts per student
      final Map<String, int> totalAppsByKey = {};
      final Map<String, int> activeByKey = {};
      final Map<String, int> completedByKey = {};
      try {
        final appRows = await supabase
            .from('applications')
            .select('student_id, user_id, student_email, status');
        for (final raw in appRows) {
          final a = Map<String, dynamic>.from(raw);
          final uid =
              a['student_id']?.toString() ?? a['user_id']?.toString() ?? '';
          final appEmail =
              a['student_email']?.toString().trim().toLowerCase() ?? '';
          final st = (a['status']?.toString() ?? '').toLowerCase().trim();
          final keys = <String>{
            if (uid.isNotEmpty) uid,
            if (uid.isEmpty && appEmail.isNotEmpty) 'email:$appEmail',
          };
          for (final k in keys) {
            totalAppsByKey[k] = (totalAppsByKey[k] ?? 0) + 1;
            if (st == 'completed' || st == 'certified') {
              completedByKey[k] = (completedByKey[k] ?? 0) + 1;
            } else if (st == 'accepted' ||
                st == 'approved' ||
                st == 'shortlisted' ||
                st == 'submitted' ||
                st == 'in progress' ||
                st == 'in_progress' ||
                st == 'ongoing' ||
                st == 'active') {
              activeByKey[k] = (activeByKey[k] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        debugPrint('AdminStudentService applications lookup skipped: $e');
      }

      final List<Map<String, dynamic>> auditRows = [];
      try {
        final rawLogs = await supabase
            .from('admin_audit_logs')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        for (final raw in rawLogs) {
          auditRows.add(Map<String, dynamic>.from(raw));
        }
      } catch (_) {}

      final Set<String> seenUserIds = {};
      final List<AdminStudentModel> loaded = [];

      for (final raw in studentRows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final userId = row['user_id']?.toString();
        final anyProf = userId != null ? allProfilesById[userId] : null;
        final anyRole = (anyProf?['user_type']?.toString() ?? '').trim().toLowerCase();
        if (anyRole == 'company' || anyRole == 'admin') {
          continue;
        }
        if (userId != null && userId.isNotEmpty) seenUserIds.add(userId);
        final profile = userId != null ? profilesById[userId] : null;

        final rowAccRaw = (row['account_status']?.toString().trim().toLowerCase() ??
            profile?['account_status']?.toString().trim().toLowerCase() ??
            'active');
        final name = (row['full_name']?.toString().trim().isNotEmpty == true)
            ? row['full_name'].toString().trim()
            : (profile?['name']?.toString().trim() ?? 'Student Member');
        if (rowAccRaw == 'deleted' || name.toLowerCase() == 'deleted account') {
          continue;
        }
        final email = (row['email']?.toString().trim().isNotEmpty == true)
            ? row['email'].toString().trim()
            : (profile?['email']?.toString().trim() ?? '');

        final rawVerif =
            (row['verification_status']?.toString().toLowerCase() ?? 'pending');
        StudentVerificationStatus verifStatus;
        if (rawVerif == 'verified') {
          verifStatus = StudentVerificationStatus.verified;
        } else if (rawVerif == 'rejected') {
          verifStatus = StudentVerificationStatus.rejected;
        } else {
          verifStatus = (profile?['is_verified'] == true)
              ? StudentVerificationStatus.verified
              : StudentVerificationStatus.pending;
        }

        final accStatus = rowAccRaw == 'suspended'
            ? StudentAccountStatus.suspended
            : StudentAccountStatus.active;

        final createdDt =
            SupabaseHelper.parseDate(row['created_at']) ?? DateTime.now();
        final regDate =
            '${createdDt.year}-${createdDt.month.toString().padLeft(2, '0')}-${createdDt.day.toString().padLeft(2, '0')}';

        final rawDoc = row['verification_doc']?.toString().trim() ?? '';
        final resumeUrl = row['resume_url']?.toString().trim() ?? '';
        final docUrl = rawDoc.startsWith('http')
            ? rawDoc
            : (resumeUrl.startsWith('http') ? resumeUrl : null);
        final docName = rawDoc.isNotEmpty
            ? (rawDoc.startsWith('http')
                ? Uri.tryParse(rawDoc)?.pathSegments.lastWhere(
                      (s) => s.isNotEmpty,
                      orElse: () => 'Verification_Document.pdf',
                    ) ??
                    'Verification_Document.pdf'
                : rawDoc)
            : (resumeUrl.isNotEmpty ? 'Academic_Resume_Document' : '');

        final matchingLogs = auditRows
            .where((l) {
              final target = l['target']?.toString() ?? '';
              return target == id ||
                  target.toLowerCase() == name.toLowerCase() ||
                  target.toLowerCase() == email.toLowerCase();
            })
            .map((l) => StudentAuditRecord(
                  id: l['id']?.toString() ?? '',
                  action: l['action']?.toString() ?? 'Audit Event',
                  adminName: l['admin_email']?.toString() ?? 'Administrator',
                  timestamp: SupabaseHelper.formatRelativeTime(l['created_at']),
                  note: l['details']?.toString(),
                ))
            .toList();

        loaded.add(
          AdminStudentModel(
            id: id,
            userId: userId,
            name: name,
            email: email,
            avatarInitial: SupabaseHelper.initialsFor(name, fallback: 'ST'),
            university: (row['university']?.toString().trim().isNotEmpty == true)
                ? row['university'].toString().trim()
                : (profile?['university']?.toString().trim() ?? ''),
            department: (row['department']?.toString().trim().isNotEmpty == true)
                ? row['department'].toString().trim()
                : (profile?['department']?.toString().trim() ??
                    'Computer Science'),
            degree: (row['degree']?.toString().trim().isNotEmpty == true)
                ? row['degree'].toString().trim()
                : (profile?['degree']?.toString().trim() ?? 'BS'),
            semester: (row['semester']?.toString().trim().isNotEmpty == true)
                ? row['semester'].toString().trim()
                : (profile?['semester']?.toString().trim() ?? '1st Semester'),
            cgpa: (row['cgpa'] as num?)?.toDouble() ??
                (profile?['cgpa'] as num?)?.toDouble() ??
                0.0,
            skills: SupabaseHelper.parseStringList(row['skills']),
            verificationStatus: verifStatus,
            accountStatus: accStatus,
            registrationDate: regDate,
            registrationDateTime: createdDt,
            suspensionReason: row['suspension_reason']?.toString(),
            verificationDocumentName: docName,
            verificationDocumentType: docName.isNotEmpty
                ? 'Student Enrollment / Academic Credential'
                : 'Not Uploaded',
            verificationDocumentSize: '',
            verificationDocumentUrl: docUrl,
            portfolioUrl: row['portfolio_url']?.toString() ?? '',
            githubUrl: row['github_url']?.toString() ?? '',
            bio: (row['bio']?.toString().trim().isNotEmpty == true)
                ? row['bio'].toString().trim()
                : (profile?['bio']?.toString().trim() ?? ''),
            applicationsCount: (userId != null ? totalAppsByKey[userId] : null) ??
                totalAppsByKey['email:${email.toLowerCase()}'] ??
                0,
            projectsCompletedCount:
                (userId != null ? completedByKey[userId] : null) ??
                    completedByKey['email:${email.toLowerCase()}'] ??
                    0,
            activeProjectsCount:
                (userId != null ? activeByKey[userId] : null) ??
                    activeByKey['email:${email.toLowerCase()}'] ??
                    0,
            auditHistory: matchingLogs,
          ),
        );
      }

      // Include any student profiles that do not yet have a students table row
      for (final entry in profilesById.entries) {
        if (seenUserIds.contains(entry.key)) continue;
        final p = entry.value;
        final accStatusRaw =
            p['account_status']?.toString().trim().toLowerCase() ?? '';
        final rawProfileName = p['name']?.toString().trim() ?? '';
        if (accStatusRaw == 'deleted' ||
            rawProfileName.toLowerCase() == 'deleted account') {
          continue;
        }
        final name =
            rawProfileName.isNotEmpty ? rawProfileName : 'Student Member';
        final createdDt =
            SupabaseHelper.parseDate(p['created_at']) ?? DateTime.now();
        final regDate =
            '${createdDt.year}-${createdDt.month.toString().padLeft(2, '0')}-${createdDt.day.toString().padLeft(2, '0')}';

        loaded.add(
          AdminStudentModel(
            id: entry.key,
            userId: entry.key,
            name: name,
            email: p['email']?.toString() ?? '',
            avatarInitial: SupabaseHelper.initialsFor(name, fallback: 'ST'),
            university: p['university']?.toString() ?? '',
            department: p['department']?.toString() ?? 'Computer Science',
            degree: p['degree']?.toString() ?? 'BS',
            semester: p['semester']?.toString() ?? '1st Semester',
            cgpa: (p['cgpa'] as num?)?.toDouble() ?? 0.0,
            skills: const [],
            verificationStatus: (p['is_verified'] == true)
                ? StudentVerificationStatus.verified
                : StudentVerificationStatus.pending,
            accountStatus:
                (p['account_status']?.toString().toLowerCase() == 'suspended')
                    ? StudentAccountStatus.suspended
                    : StudentAccountStatus.active,
            registrationDate: regDate,
            registrationDateTime: createdDt,
            verificationDocumentName: '',
            verificationDocumentType: 'Not Uploaded',
            verificationDocumentSize: '',
            portfolioUrl: '',
            githubUrl: '',
            bio: p['bio']?.toString() ?? '',
            applicationsCount: totalAppsByKey[entry.key] ??
                totalAppsByKey['email:${(p['email']?.toString() ?? '').trim().toLowerCase()}'] ??
                0,
            projectsCompletedCount: completedByKey[entry.key] ??
                completedByKey['email:${(p['email']?.toString() ?? '').trim().toLowerCase()}'] ??
                0,
            activeProjectsCount: activeByKey[entry.key] ??
                activeByKey['email:${(p['email']?.toString() ?? '').trim().toLowerCase()}'] ??
                0,
            auditHistory: const [],
          ),
        );
      }

      studentsNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminStudentService loadFromSupabase error: $e');
    }
  }

  /// Shared helper to persist student verification or account moderation to Supabase.
  /// Inserts a missing `students` row when moderating a profile-only account (`id == userId`).
  Future<({bool ok, String resolvedId})> _persistStudentUpdate(
    AdminStudentModel student, {
    required Map<String, dynamic> studentFields,
    Map<String, dynamic>? profileFields,
    required String auditAction,
    required String auditDetails,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      return (ok: true, resolvedId: student.id);
    }

    final effectiveUserId = SupabaseHelper.isUuid(student.userId)
        ? student.userId!
        : (SupabaseHelper.isUuid(student.id) ? student.id : '');

    if (!SupabaseHelper.isUuid(student.id) && effectiveUserId.isEmpty) {
      return (ok: false, resolvedId: student.id);
    }

    try {
      String resolvedId = student.id;
      List<dynamic> updated = const [];

      if (SupabaseHelper.isUuid(student.id) && student.id != effectiveUserId) {
        updated = await supabase
            .from('students')
            .update(studentFields)
            .eq('id', student.id)
            .select('id');
      }

      if (updated.isEmpty && effectiveUserId.isNotEmpty) {
        updated = await supabase
            .from('students')
            .update(studentFields)
            .eq('user_id', effectiveUserId)
            .select('id');
      }

      if (updated.isNotEmpty) {
        final firstId = updated.first['id']?.toString() ?? '';
        if (firstId.isNotEmpty) resolvedId = firstId;
      } else if (effectiveUserId.isNotEmpty) {
        final inserted = await supabase
            .from('students')
            .insert({
              'user_id': effectiveUserId,
              'full_name': student.name,
              'email': student.email,
              'university': student.university,
              'department': student.department,
              'degree': student.degree,
              'semester': student.semester,
              'cgpa': student.cgpa,
              'skills': student.skills,
              'bio': student.bio,
              'portfolio_url': student.portfolioUrl,
              'github_url': student.githubUrl,
              ...studentFields,
            })
            .select('id')
            .single();
        final newId = inserted['id']?.toString() ?? '';
        if (newId.isNotEmpty) resolvedId = newId;
      } else {
        return (ok: false, resolvedId: student.id);
      }

      if (profileFields != null &&
          profileFields.isNotEmpty &&
          effectiveUserId.isNotEmpty) {
        await supabase
            .from('profiles')
            .update(profileFields)
            .eq('id', effectiveUserId);
      }

      await _writeAuditLog(
        action: auditAction,
        target: student.email.isNotEmpty ? student.email : student.name,
        details: auditDetails,
      );

      return (ok: true, resolvedId: resolvedId);
    } catch (e) {
      debugPrint('AdminStudentService _persistStudentUpdate error: $e');
      return (ok: false, resolvedId: student.id);
    }
  }

  /// Approve student verification in Supabase (`students` + `profiles`).
  Future<bool> approveStudentVerification({
    required String studentId,
    required String adminName,
  }) async {
    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId || s.userId == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistStudentUpdate(
      student,
      studentFields: {
        'verification_status': 'verified',
        'updated_at': nowIso,
      },
      profileFields: {
        'is_verified': true,
        'updated_at': nowIso,
      },
      auditAction: 'STUDENT_VERIFICATION_APPROVED',
      auditDetails: 'Approved by $adminName.',
    );
    if (!persisted.ok) return false;

    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Approved',
        adminName: adminName,
        timestamp: 'Just now',
        note: 'University credentials authenticated by platform administration.',
      ),
    );

    list[idx] = student.copyWith(
      id: persisted.resolvedId,
      verificationStatus: StudentVerificationStatus.verified,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Reject student verification with mandatory reason.
  Future<bool> rejectStudentVerification({
    required String studentId,
    required String reason,
    required String adminName,
  }) async {
    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId || s.userId == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistStudentUpdate(
      student,
      studentFields: {
        'verification_status': 'rejected',
        'updated_at': nowIso,
      },
      profileFields: {
        'is_verified': false,
        'updated_at': nowIso,
      },
      auditAction: 'STUDENT_VERIFICATION_REJECTED',
      auditDetails: reason.trim(),
    );
    if (!persisted.ok) return false;

    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Rejected',
        adminName: adminName,
        timestamp: 'Just now',
        note: reason.trim(),
      ),
    );

    list[idx] = student.copyWith(
      id: persisted.resolvedId,
      verificationStatus: StudentVerificationStatus.rejected,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Request document resubmission from a student.
  Future<bool> requestDocumentResubmission({
    required String studentId,
    required String instructions,
    required String adminName,
  }) async {
    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId || s.userId == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistStudentUpdate(
      student,
      studentFields: {
        'verification_status': 'pending',
        'updated_at': nowIso,
      },
      auditAction: 'STUDENT_DOCS_REQUESTED',
      auditDetails: instructions.trim(),
    );
    if (!persisted.ok) return false;

    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Resubmission Requested',
        adminName: adminName,
        timestamp: 'Just now',
        note: instructions.trim(),
      ),
    );

    list[idx] = student.copyWith(
      id: persisted.resolvedId,
      verificationStatus: StudentVerificationStatus.pending,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Suspend student account with mandatory reason.
  Future<bool> suspendStudentAccount({
    required String studentId,
    required String reason,
    required String adminName,
  }) async {
    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId || s.userId == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistStudentUpdate(
      student,
      studentFields: {
        'account_status': 'suspended',
        'suspension_reason': reason.trim(),
        'updated_at': nowIso,
      },
      profileFields: {
        'account_status': 'suspended',
        'updated_at': nowIso,
      },
      auditAction: 'STUDENT_SUSPENDED',
      auditDetails: reason.trim(),
    );
    if (!persisted.ok) return false;

    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Suspended',
        adminName: adminName,
        timestamp: 'Just now',
        note: reason.trim(),
      ),
    );

    list[idx] = student.copyWith(
      id: persisted.resolvedId,
      accountStatus: StudentAccountStatus.suspended,
      suspensionReason: reason.trim(),
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Reactivate a suspended student account.
  Future<bool> reactivateStudentAccount({
    required String studentId,
    required String adminName,
  }) async {
    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId || s.userId == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final persisted = await _persistStudentUpdate(
      student,
      studentFields: {
        'account_status': 'active',
        'suspension_reason': null,
        'updated_at': nowIso,
      },
      profileFields: {
        'account_status': 'active',
        'updated_at': nowIso,
      },
      auditAction: 'STUDENT_REACTIVATED',
      auditDetails: 'Reactivated by $adminName.',
    );
    if (!persisted.ok) return false;

    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Reactivated',
        adminName: adminName,
        timestamp: 'Just now',
        note: 'Account reactivated after administrative governance review.',
      ),
    );

    list[idx] = student.copyWith(
      id: persisted.resolvedId,
      accountStatus: StudentAccountStatus.active,
      clearSuspensionReason: true,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Bulk Approve multiple students sequentially against Supabase.
  Future<int> bulkApproveStudents({
    required List<String> studentIds,
    required String adminName,
  }) async {
    int approvedCount = 0;
    for (final id in studentIds) {
      final ok = await approveStudentVerification(
        studentId: id,
        adminName: adminName,
      );
      if (ok) approvedCount++;
    }
    return approvedCount;
  }

  Future<void> _writeAuditLog({
    required String action,
    required String target,
    required String details,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;
    try {
      await supabase.from('admin_audit_logs').insert({
        'admin_email': SupabaseHelper.currentUser?.email ?? 'admin@skillbridge.edu.pk',
        'action': action,
        'target': target,
        'details': details,
      });
    } catch (e) {
      debugPrint('AdminStudentService audit error: $e');
    }
  }

  String exportPermittedStudentsCsv(List<AdminStudentModel> students) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Full Name,Email,University,Department,Degree,Semester,CGPA,Verification Status,Account Status,Registration Date',
    );

    for (final s in students) {
      buffer.writeln(
        '${s.id},"${s.name}","${s.email}","${s.university}","${s.department}","${s.degree}","${s.semester}",${s.cgpa},${s.verificationStatus.name},${s.accountStatus.name},${s.registrationDate}',
      );
    }
    return buffer.toString();
  }

  void reset() {
    studentsNotifier.value = [];
  }
}
