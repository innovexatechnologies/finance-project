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

  /// Fetches registered students, project participation counts, and audit history from Supabase.
  Future<void> loadFromSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;

    try {
      final studentRows = await supabase
          .from('students')
          .select()
          .order('created_at', ascending: false);

      // Enrich with profiles rows (handles students who haven't updated extended profile yet)
      final Map<String, Map<String, dynamic>> profilesById = {};
      try {
        final profRows = await supabase
            .from('profiles')
            .select()
            .ilike('user_type', 'student');
        for (final raw in profRows) {
          final p = Map<String, dynamic>.from(raw);
          final id = p['id']?.toString() ?? '';
          if (id.isNotEmpty) profilesById[id] = p;
        }
      } catch (e) {
        debugPrint('AdminStudentService profiles enrichment skipped: $e');
      }

      // Compute active/completed project counts per student user_id from applications
      final Map<String, int> activeByUser = {};
      final Map<String, int> completedByUser = {};
      try {
        final appRows = await supabase
            .from('applications')
            .select('student_id, user_id, status');
        for (final raw in appRows) {
          final a = Map<String, dynamic>.from(raw);
          final uid =
              a['student_id']?.toString() ?? a['user_id']?.toString() ?? '';
          if (uid.isEmpty) continue;
          final st = (a['status']?.toString() ?? '').toLowerCase();
          if (st == 'completed' || st == 'certified') {
            completedByUser[uid] = (completedByUser[uid] ?? 0) + 1;
          } else if (st == 'accepted' || st == 'approved' || st == 'shortlisted') {
            activeByUser[uid] = (activeByUser[uid] ?? 0) + 1;
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
        if (userId != null && userId.isNotEmpty) seenUserIds.add(userId);
        final profile = userId != null ? profilesById[userId] : null;

        final name = (row['full_name']?.toString().trim().isNotEmpty == true)
            ? row['full_name'].toString().trim()
            : (profile?['name']?.toString().trim() ?? 'Student Member');
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

        final rawAcc = (row['account_status']?.toString().toLowerCase() ??
            profile?['account_status']?.toString().toLowerCase() ??
            'active');
        final accStatus = rawAcc == 'suspended'
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
            projectsCompletedCount:
                userId != null ? (completedByUser[userId] ?? 0) : 0,
            activeProjectsCount:
                userId != null ? (activeByUser[userId] ?? 0) : 0,
            auditHistory: matchingLogs,
          ),
        );
      }

      // Include any student profiles that do not yet have a students table row
      for (final entry in profilesById.entries) {
        if (seenUserIds.contains(entry.key)) continue;
        final p = entry.value;
        final name = (p['name']?.toString().trim().isNotEmpty == true)
            ? p['name'].toString().trim()
            : 'Student Member';
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
            projectsCompletedCount: completedByUser[entry.key] ?? 0,
            activeProjectsCount: activeByUser[entry.key] ?? 0,
            auditHistory: const [],
          ),
        );
      }

      studentsNotifier.value = loaded;
    } catch (e) {
      debugPrint('AdminStudentService loadFromSupabase error: $e');
    }
  }

  /// Approve student verification in Supabase (`students` + `profiles` + `notifications`).
  Future<bool> approveStudentVerification({
    required String studentId,
    required String adminName,
  }) async {
    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      try {
        if (SupabaseHelper.isUuid(studentId) && studentId != student.userId) {
          await supabase.from('students').update({
            'verification_status': 'verified',
            'updated_at': nowIso,
          }).eq('id', studentId);
        } else if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('students').update({
            'verification_status': 'verified',
            'updated_at': nowIso,
          }).eq('user_id', student.userId!);
        }

        if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('profiles').update({
            'is_verified': true,
            'updated_at': nowIso,
          }).eq('id', student.userId!);

          await _notifyStudent(
            userId: student.userId!,
            title: 'Academic Verification Approved',
            message:
                'Your student profile (${student.name}) has been verified by CampusConnect Administration.',
            type: 'verification',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'STUDENT_VERIFICATION_APPROVED',
          target: student.email.isNotEmpty ? student.email : student.name,
          details: 'Approved by $adminName.',
        );
      } catch (e) {
        debugPrint('AdminStudentService approveStudentVerification error: $e');
        return false;
      }
    }

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
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      try {
        if (SupabaseHelper.isUuid(studentId) && studentId != student.userId) {
          await supabase.from('students').update({
            'verification_status': 'rejected',
            'updated_at': nowIso,
          }).eq('id', studentId);
        } else if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('students').update({
            'verification_status': 'rejected',
            'updated_at': nowIso,
          }).eq('user_id', student.userId!);
        }

        if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('profiles').update({
            'is_verified': false,
            'updated_at': nowIso,
          }).eq('id', student.userId!);

          await _notifyStudent(
            userId: student.userId!,
            title: 'Academic Verification Rejected',
            message: reason.trim(),
            type: 'verification',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'STUDENT_VERIFICATION_REJECTED',
          target: student.email.isNotEmpty ? student.email : student.name,
          details: reason.trim(),
        );
      } catch (e) {
        debugPrint('AdminStudentService rejectStudentVerification error: $e');
        return false;
      }
    }

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
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      try {
        if (SupabaseHelper.isUuid(studentId) && studentId != student.userId) {
          await supabase.from('students').update({
            'verification_status': 'pending',
            'updated_at': nowIso,
          }).eq('id', studentId);
        } else if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('students').update({
            'verification_status': 'pending',
            'updated_at': nowIso,
          }).eq('user_id', student.userId!);
        }

        if (SupabaseHelper.isUuid(student.userId)) {
          await _notifyStudent(
            userId: student.userId!,
            title: 'Resubmit Verification Document',
            message: instructions.trim(),
            type: 'verification',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'STUDENT_DOCS_REQUESTED',
          target: student.email.isNotEmpty ? student.email : student.name,
          details: instructions.trim(),
        );
      } catch (e) {
        debugPrint('AdminStudentService requestDocumentResubmission error: $e');
        return false;
      }
    }

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
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      try {
        if (SupabaseHelper.isUuid(studentId) && studentId != student.userId) {
          await supabase.from('students').update({
            'account_status': 'suspended',
            'suspension_reason': reason.trim(),
            'updated_at': nowIso,
          }).eq('id', studentId);
        } else if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('students').update({
            'account_status': 'suspended',
            'suspension_reason': reason.trim(),
            'updated_at': nowIso,
          }).eq('user_id', student.userId!);
        }

        if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('profiles').update({
            'account_status': 'suspended',
            'updated_at': nowIso,
          }).eq('id', student.userId!);

          await _notifyStudent(
            userId: student.userId!,
            title: 'Student Account Suspended',
            message: reason.trim(),
            type: 'governance',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'STUDENT_SUSPENDED',
          target: student.email.isNotEmpty ? student.email : student.name,
          details: reason.trim(),
        );
      } catch (e) {
        debugPrint('AdminStudentService suspendStudentAccount error: $e');
        return false;
      }
    }

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
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null) {
      try {
        if (SupabaseHelper.isUuid(studentId) && studentId != student.userId) {
          await supabase.from('students').update({
            'account_status': 'active',
            'suspension_reason': null,
            'updated_at': nowIso,
          }).eq('id', studentId);
        } else if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('students').update({
            'account_status': 'active',
            'suspension_reason': null,
            'updated_at': nowIso,
          }).eq('user_id', student.userId!);
        }

        if (SupabaseHelper.isUuid(student.userId)) {
          await supabase.from('profiles').update({
            'account_status': 'active',
            'updated_at': nowIso,
          }).eq('id', student.userId!);

          await _notifyStudent(
            userId: student.userId!,
            title: 'Student Account Reactivated',
            message: 'Your CampusConnect student account has been reactivated.',
            type: 'governance',
            actorName: adminName,
          );
        }

        await _writeAuditLog(
          action: 'STUDENT_REACTIVATED',
          target: student.email.isNotEmpty ? student.email : student.name,
          details: 'Reactivated by $adminName.',
        );
      } catch (e) {
        debugPrint('AdminStudentService reactivateStudentAccount error: $e');
        return false;
      }
    }

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

  Future<void> _notifyStudent({
    required String userId,
    required String title,
    required String message,
    required String type,
    required String actorName,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null || !SupabaseHelper.isUuid(userId)) return;
    try {
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'actor_name': actorName,
      });
    } catch (e) {
      debugPrint('AdminStudentService notify error: $e');
    }
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
        'admin_email': SupabaseHelper.currentUser?.email ?? 'admin@campusconnect.edu.pk',
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
