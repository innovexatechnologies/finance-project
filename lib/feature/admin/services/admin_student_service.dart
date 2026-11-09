import 'package:flutter/foundation.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';

/// Enterprise Student Management Service for CampusConnect Admin Panel.
class AdminStudentService {
  static final AdminStudentService _instance = AdminStudentService._internal();
  factory AdminStudentService() => _instance;

  AdminStudentService._internal() {
    _initStudents();
  }

  late final ValueNotifier<List<AdminStudentModel>> studentsNotifier;

  List<AdminStudentModel> get allStudents => studentsNotifier.value;

  // Overview Metrics Getters
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

  void _initStudents() {
    studentsNotifier = ValueNotifier<List<AdminStudentModel>>([
      // 1. Ali Khan (FAST-NUCES)
      AdminStudentModel(
        id: 'std_fast_01',
        name: 'Ali Khan',
        email: 'ali.khan@nu.edu.pk',
        avatarInitial: 'AK',
        university: 'FAST-NUCES Islamabad',
        department: 'Department of Computer Science',
        degree: 'BS Computer Science (Honors)',
        semester: '8th Semester',
        cgpa: 3.82,
        skills: ['Flutter', 'Dart', 'Bloc', 'REST API', 'Git', 'Clean Architecture'],
        verificationStatus: StudentVerificationStatus.verified,
        accountStatus: StudentAccountStatus.active,
        registrationDate: '2026-10-12',
        registrationDateTime: DateTime(2026, 10, 12, 10, 30),
        verificationDocumentName: 'FAST_StudentCard_Enrollment_AliKhan.pdf',
        verificationDocumentType: 'University Enrollment Certificate & ID Card',
        verificationDocumentSize: '2.1 MB',
        portfolioUrl: 'https://github.com/alikhan-flutter',
        githubUrl: 'https://github.com/alikhan-flutter',
        bio: 'Passionate final-year software engineering student specialized in production-grade Flutter apps and clean architecture.',
        projectsCompletedCount: 2,
        activeProjectsCount: 1,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_01',
            action: 'Institutional Degree Verified',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-14 11:20 AM',
            note: 'FAST-NUCES registrar roster matched with roll number 20P-0142.',
          ),
        ],
      ),

      // 2. Bilal Shah (GIKI)
      AdminStudentModel(
        id: 'std_giki_02',
        name: 'Bilal Shah',
        email: 'bilal.shah@giki.edu.pk',
        avatarInitial: 'BS',
        university: 'GIKI Swabi',
        department: 'Department of Computer Engineering',
        degree: 'BS Computer Engineering',
        semester: '6th Semester',
        cgpa: 3.65,
        skills: ['Embedded Systems', 'C++', 'Flutter', 'Camera API', 'SQLite'],
        verificationStatus: StudentVerificationStatus.pending,
        accountStatus: StudentAccountStatus.active,
        registrationDate: '2026-11-01',
        registrationDateTime: DateTime(2026, 11, 1, 14, 15),
        verificationDocumentName: 'GIKI_StudentVerification_Letter_2026.pdf',
        verificationDocumentType: 'Official Academic Verification Letter',
        verificationDocumentSize: '1.7 MB',
        portfolioUrl: 'https://github.com/bilalshah-giki',
        githubUrl: 'https://github.com/bilalshah-giki',
        bio: 'Hardware & mobile app enthusiast building low-level camera integrations and offline embedded systems.',
        projectsCompletedCount: 1,
        activeProjectsCount: 1,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_02',
            action: 'Document Submitted',
            adminName: 'System Gateway',
            timestamp: '2026-11-01 02:15 PM',
            note: 'Academic letter uploaded for review.',
          ),
        ],
      ),

      // 3. Zainab Bibi (UET Taxila)
      AdminStudentModel(
        id: 'std_uet_03',
        name: 'Zainab Bibi',
        email: 'zainab.bibi@uettaxila.edu.pk',
        avatarInitial: 'ZB',
        university: 'UET Taxila',
        department: 'Department of Computer Science',
        degree: 'BS Computer Science',
        semester: '7th Semester',
        cgpa: 3.55,
        skills: ['Flutter', 'Mobile Utilities', 'Local Storage', 'Dart', 'Figma'],
        verificationStatus: StudentVerificationStatus.pending,
        accountStatus: StudentAccountStatus.active,
        registrationDate: '2026-11-03',
        registrationDateTime: DateTime(2026, 11, 3, 09, 45),
        verificationDocumentName: 'UET_EnrollmentCard_Zainab.pdf',
        verificationDocumentType: 'Official Student Enrollment Card',
        verificationDocumentSize: '1.4 MB',
        portfolioUrl: 'https://github.com/zainab-uet',
        githubUrl: 'https://github.com/zainab-uet',
        bio: 'Student developer passionate about accessible user interfaces, utility tools, and reliable offline data storage.',
        projectsCompletedCount: 0,
        activeProjectsCount: 1,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_03',
            action: 'Verification Request Received',
            adminName: 'System Gateway',
            timestamp: '2026-11-03 09:45 AM',
            note: 'Awaiting administrative verification review.',
          ),
        ],
      ),

      // 4. Mustafa Hassan (PUCIT)
      AdminStudentModel(
        id: 'std_pucit_04',
        name: 'Mustafa Hassan',
        email: 'mustafa.hassan@pucit.edu.pk',
        avatarInitial: 'MH',
        university: 'PUCIT Lahore',
        department: 'Department of Data Science & AI',
        degree: 'MS Data Science',
        semester: '3rd Semester (Graduate)',
        cgpa: 3.88,
        skills: ['Python', 'NLP', 'FastAPI', 'PyTorch', 'Transformers', 'Docker'],
        verificationStatus: StudentVerificationStatus.verified,
        accountStatus: StudentAccountStatus.active,
        registrationDate: '2026-10-18',
        registrationDateTime: DateTime(2026, 10, 18, 16, 20),
        verificationDocumentName: 'PUCIT_Graduate_Transcript_Mustafa.pdf',
        verificationDocumentType: 'Official Graduate Transcript & Card',
        verificationDocumentSize: '3.2 MB',
        portfolioUrl: 'https://huggingface.co/mustafahassan',
        githubUrl: 'https://github.com/mustafahassan',
        bio: 'Graduate data science researcher specializing in natural language processing and transformer architectures.',
        projectsCompletedCount: 3,
        activeProjectsCount: 1,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_04',
            action: 'Graduate Verification Approved',
            adminName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-10-20 03:00 PM',
            note: 'PUCIT Graduate directory confirmed.',
          ),
        ],
      ),

      // 5. Danish Khan (NUST) - Rejected Verification
      AdminStudentModel(
        id: 'std_nust_05',
        name: 'Danish Khan',
        email: 'danish.khan@seecs.nust.edu.pk',
        avatarInitial: 'DK',
        university: 'NUST Islamabad',
        department: 'School of Electrical Engineering & CS',
        degree: 'BS Software Engineering',
        semester: '4th Semester',
        cgpa: 3.10,
        skills: ['Flutter', 'Java', 'Algorithms', 'OOP'],
        verificationStatus: StudentVerificationStatus.rejected,
        accountStatus: StudentAccountStatus.active,
        registrationDate: '2026-10-25',
        registrationDateTime: DateTime(2026, 10, 25, 11, 10),
        verificationDocumentName: 'Expired_Library_Pass.jpg',
        verificationDocumentType: 'Unverified ID Attachment',
        verificationDocumentSize: '650 KB',
        portfolioUrl: 'https://github.com/danish-nust',
        githubUrl: 'https://github.com/danish-nust',
        bio: 'Second-year software engineering student eager to learn commercial Flutter development.',
        projectsCompletedCount: 0,
        activeProjectsCount: 0,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_05',
            action: 'Verification Rejected',
            adminName: 'Syeda Fatima Noor (OpsAdmin)',
            timestamp: '2026-10-27 01:40 PM',
            note: 'Uploaded document was a library pass instead of official university enrollment certificate or student card.',
          ),
        ],
      ),

      // 6. Hamza Tariq (COMSATS) - Suspended Account
      AdminStudentModel(
        id: 'std_comsats_06',
        name: 'Hamza Tariq',
        email: 'hamza.tariq@comsats.edu.pk',
        avatarInitial: 'HT',
        university: 'COMSATS Islamabad',
        department: 'Department of Computer Science',
        degree: 'BS Computer Science',
        semester: '8th Semester',
        cgpa: 2.85,
        skills: ['Flutter', 'UI Design', 'Firebase'],
        verificationStatus: StudentVerificationStatus.verified,
        accountStatus: StudentAccountStatus.suspended,
        registrationDate: '2026-09-14',
        registrationDateTime: DateTime(2026, 9, 14, 13, 00),
        suspensionReason: 'Submitted plagiarized GitHub repository for milestone deliverable review. Account locked pending disciplinary committee review.',
        verificationDocumentName: 'COMSATS_StudentCard_Hamza.pdf',
        verificationDocumentType: 'Official University Student Card',
        verificationDocumentSize: '1.8 MB',
        portfolioUrl: 'https://github.com/hamzatariq-dev',
        githubUrl: 'https://github.com/hamzatariq-dev',
        bio: 'Computer science senior working on mobile application design.',
        projectsCompletedCount: 1,
        activeProjectsCount: 0,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_06_1',
            action: 'Education Verified',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-09-16 10:00 AM',
            note: 'COMSATS enrollment verified.',
          ),
          StudentAuditRecord(
            id: 'aud_06_2',
            action: 'Account Suspended',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-11-04 05:15 PM',
            note: 'Plagiarism infraction reported by corporate sponsor.',
          ),
        ],
      ),

      // 7. Sara Ahmed (LUMS)
      AdminStudentModel(
        id: 'std_lums_07',
        name: 'Sara Ahmed',
        email: 'sara.ahmed@lums.edu.pk',
        avatarInitial: 'SA',
        university: 'LUMS Lahore',
        department: 'Syed Babar Ali School of Science & Eng',
        degree: 'BS Computer Science',
        semester: '6th Semester',
        cgpa: 3.91,
        skills: ['Flutter', 'React Native', 'Kotlin', 'REST API', 'Figma'],
        verificationStatus: StudentVerificationStatus.verified,
        accountStatus: StudentAccountStatus.active,
        registrationDate: '2026-10-05',
        registrationDateTime: DateTime(2026, 10, 5, 15, 30),
        verificationDocumentName: 'LUMS_AcademicCredential_Sara.pdf',
        verificationDocumentType: 'Official Student Card & Enrollment Slip',
        verificationDocumentSize: '2.5 MB',
        portfolioUrl: 'https://github.com/sara-ahmed-lums',
        githubUrl: 'https://github.com/sara-ahmed-lums',
        bio: 'Full-stack mobile engineer with a focus on polished UI micro-interactions, responsive design, and robust APIs.',
        projectsCompletedCount: 2,
        activeProjectsCount: 1,
        auditHistory: const [
          StudentAuditRecord(
            id: 'aud_07',
            action: 'Credential Approved',
            adminName: 'Dr. Tariq Mahmood (SuperAdmin)',
            timestamp: '2026-10-06 02:20 PM',
            note: 'LUMS student credential authenticated.',
          ),
        ],
      ),
    ]);
  }

  /// Approve student verification
  Future<bool> approveStudentVerification({
    required String studentId,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Approved',
        adminName: adminName,
        timestamp: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        note: 'University credentials authenticated by platform administration.',
      ),
    );

    list[idx] = student.copyWith(
      verificationStatus: StudentVerificationStatus.verified,
      auditHistory: history,
    );
    studentsNotifier.value = list;

    // Cross-Panel Synchronization: update CompanyApplicantService
    CompanyApplicantService().updateApplicantStatus(
      applicantId: student.id,
      newStatus: 'Shortlisted',
    );

    return true;
  }

  /// Reject student verification with mandatory reason
  Future<bool> rejectStudentVerification({
    required String studentId,
    required String reason,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Verification Rejected',
        adminName: adminName,
        timestamp: 'Today',
        note: reason,
      ),
    );

    list[idx] = student.copyWith(
      verificationStatus: StudentVerificationStatus.rejected,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Request document resubmission
  Future<bool> requestDocumentResubmission({
    required String studentId,
    required String instructions,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Resubmission Requested',
        adminName: adminName,
        timestamp: 'Today',
        note: instructions,
      ),
    );

    list[idx] = student.copyWith(
      verificationStatus: StudentVerificationStatus.pending,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Suspend student account with mandatory reason
  Future<bool> suspendStudentAccount({
    required String studentId,
    required String reason,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Suspended',
        adminName: adminName,
        timestamp: 'Today',
        note: reason,
      ),
    );

    list[idx] = student.copyWith(
      accountStatus: StudentAccountStatus.suspended,
      suspensionReason: reason,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Reactivate a suspended student account
  Future<bool> reactivateStudentAccount({
    required String studentId,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = List<AdminStudentModel>.from(studentsNotifier.value);
    final idx = list.indexWhere((s) => s.id == studentId);
    if (idx == -1) return false;

    final student = list[idx];
    final history = List<StudentAuditRecord>.from(student.auditHistory);
    history.insert(
      0,
      StudentAuditRecord(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        action: 'Account Reactivated',
        adminName: adminName,
        timestamp: 'Today',
        note: 'Account reactivated after administrative governance review.',
      ),
    );

    list[idx] = student.copyWith(
      accountStatus: StudentAccountStatus.active,
      suspensionReason: null,
      auditHistory: history,
    );
    studentsNotifier.value = list;
    return true;
  }

  /// Bulk Approve multiple students
  Future<int> bulkApproveStudents({
    required List<String> studentIds,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    int approvedCount = 0;
    final list = List<AdminStudentModel>.from(studentsNotifier.value);

    for (int i = 0; i < list.length; i++) {
      if (studentIds.contains(list[i].id)) {
        final history = List<StudentAuditRecord>.from(list[i].auditHistory);
        history.insert(
          0,
          StudentAuditRecord(
            id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
            action: 'Bulk Verification Approved',
            adminName: adminName,
            timestamp: 'Today',
            note: 'Approved via batch governance sign-off.',
          ),
        );

        list[i] = list[i].copyWith(
          verificationStatus: StudentVerificationStatus.verified,
          auditHistory: history,
        );
        approvedCount++;
      }
    }

    studentsNotifier.value = list;
    return approvedCount;
  }

  /// Export permitted student records to CSV string
  String exportPermittedStudentsCsv(List<AdminStudentModel> students) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Full Name,Email,University,Department,Degree,Semester,CGPA,Verification Status,Account Status,Registration Date');

    for (final s in students) {
      buffer.writeln(
        '${s.id},"${s.name}","${s.email}","${s.university}","${s.department}","${s.degree}","${s.semester}",${s.cgpa},${s.verificationStatus.name},${s.accountStatus.name},${s.registrationDate}',
      );
    }
    return buffer.toString();
  }
}

