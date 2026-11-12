import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/cloud_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDataService.instance.init();
  });

  test('Persistent Favourites/Bookmarks test across app restarts', () async {
    final testProject = {
      'id': 'test_proj_99',
      'title': 'Autonomous AI Agent Development',
      'company': 'DeepMind Partner',
      'duration': '5 days',
      'workMode': 'Remote',
      'status': 'Open',
    };

    // Initially not saved
    expect(AppDataService.instance.isProjectSaved('test_proj_99'), isFalse);

    // Save project
    await AppDataService.instance.toggleSaveProject(testProject);
    expect(AppDataService.instance.isProjectSaved('test_proj_99'), isTrue);
    expect(AppDataService.instance.getSavedProjects().any((p) => p['id'] == 'test_proj_99'), isTrue);

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    // Must still be saved!
    expect(AppDataService.instance.isProjectSaved('test_proj_99'), isTrue);
    expect(AppDataService.instance.getSavedProjects().any((p) => p['id'] == 'test_proj_99'), isTrue);

    // Remove from saved
    await AppDataService.instance.removeSavedProject('test_proj_99');
    expect(AppDataService.instance.isProjectSaved('test_proj_99'), isFalse);

    // Restart again
    await AppDataService.instance.init();
    expect(AppDataService.instance.isProjectSaved('test_proj_99'), isFalse);
  });

  test('Persistent Project Application test across app restarts', () async {
    final testProject = {
      'id': 'seed_2',
      'title': 'Social Media Content Creation',
      'company': 'Meta',
    };

    final initialCount = AppDataService.instance.totalApplicationsCount;

    await AppDataService.instance.addApplication(
      project: testProject,
      coverMessage: 'I have 2 years of graphic design and content creation experience.',
      skills: 'Canva, Social Media, Copywriting',
      availability: '15 hrs/week',
      portfolioLink: 'https://behance.net/test',
    );

    expect(AppDataService.instance.hasApplied('seed_2'), isTrue);
    expect(AppDataService.instance.totalApplicationsCount, equals(initialCount + 1));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.hasApplied('seed_2'), isTrue);
    expect(AppDataService.instance.totalApplicationsCount, equals(initialCount + 1));
    final app = AppDataService.instance.getApplications().firstWhere((a) => a['projectId'] == 'seed_2');
    expect(app['company'], equals('Meta'));
    expect(app['coverMessage'], contains('graphic design'));
  });

  test('Persistent Work Submission test across app restarts', () async {
    await AppDataService.instance.submitWork(
      projectId: 'seed_4',
      projectTitle: 'Flutter App Mobile UI Development',
      company: 'TechVista',
      summary: 'Completed responsive layout and connected state management.',
      workLink: 'https://github.com/student/flutter-app',
      fileName: 'final_deliverable.zip',
    );

    final sub = AppDataService.instance.getSubmission('seed_4');
    expect(sub, isNotNull);
    expect(sub!['fileName'], equals('final_deliverable.zip'));
    expect(sub['status'], equals('Under Review'));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    final reloadedSub = AppDataService.instance.getSubmission('seed_4');
    expect(reloadedSub, isNotNull);
    expect(reloadedSub!['fileName'], equals('final_deliverable.zip'));
    expect(reloadedSub['summary'], contains('responsive layout'));
  });

  test('Persistent Custom Project Creation across app restarts', () async {
    final initialCount = AppDataService.instance.getAllProjects().length;

    await AppDataService.instance.addProject({
      'title': 'Full-Stack GraphQL API',
      'description': 'Develop scalable backend GraphQL services with subscriptions.',
      'stipend': '35-50K',
      'company': 'InnovateTech',
      'category': 'Development',
      'duration': '7 days',
      'workMode': 'Remote',
      'status': 'Open',
    });

    expect(AppDataService.instance.getAllProjects().length, equals(initialCount + 1));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getAllProjects().length, equals(initialCount + 1));
    final proj = AppDataService.instance.getAllProjects().firstWhere((p) => p['title'] == 'Full-Stack GraphQL API');
    expect(proj['company'], equals('InnovateTech'));
    expect(proj['stipend'], equals('35-50K'));
  });

  test('Persistent Profile & Skills across app restarts', () async {
    await AppDataService.instance.addSkill('Docker & Kubernetes');
    await AppDataService.instance.updateProfile({
      'name': 'Rabia Student',
      'bio': 'Senior Software Engineering Student specializing in Cloud & Mobile apps.',
    });

    expect(AppDataService.instance.getSkills(), contains('Docker & Kubernetes'));
    expect(AppDataService.instance.getProfile()['name'], equals('Rabia Student'));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getSkills(), contains('Docker & Kubernetes'));
    expect(AppDataService.instance.getProfile()['name'], equals('Rabia Student'));
    expect(AppDataService.instance.getProfile()['bio'], contains('Senior Software Engineering Student'));
  });

  test('Persistent Auth Session & Auto-Login across app restarts', () async {
    // Initially not logged in
    expect(AppDataService.instance.isLoggedIn, isFalse);

    // Login user
    await AppDataService.instance.saveAuthSession(
      role: 'Student',
      email: 'student@campus.edu.pk',
      name: 'Ahmed Khan',
      userId: 'usr_test_123',
    );

    expect(AppDataService.instance.isLoggedIn, isTrue);
    expect(AppDataService.instance.userRole, equals('Student'));
    expect(AppDataService.instance.userEmail, equals('student@campus.edu.pk'));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    // Must still be logged in!
    expect(AppDataService.instance.isLoggedIn, isTrue);
    expect(AppDataService.instance.userRole, equals('Student'));
    expect(AppDataService.instance.userEmail, equals('student@campus.edu.pk'));

    // Test logout clears auth session
    await AppDataService.instance.clearAuthSession();
    expect(AppDataService.instance.isLoggedIn, isFalse);

    // Reopen after logout
    await AppDataService.instance.init();
    expect(AppDataService.instance.isLoggedIn, isFalse);
  });

  test('Persistent Certificates across app restarts', () async {
    final initialCertCount = AppDataService.instance.getCertificates().length;
    expect(initialCertCount, equals(0));

    await AppDataService.instance.addCertificate({
      'id': 'CC-TEST-999',
      'title': 'AI Machine Learning Certificate',
      'project': 'Deep Learning Model Tuning',
      'issuer': 'SkillBridge & AI Lab',
      'date': 'Nov 09, 2026',
    });

    expect(
      AppDataService.instance.getCertificates().length,
      equals(initialCertCount + 1),
    );

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(
      AppDataService.instance.getCertificates().length,
      equals(initialCertCount + 1),
    );
    final newCert = AppDataService.instance
        .getCertificates()
        .firstWhere((c) => c['id'] == 'CC-TEST-999');
    expect(newCert['title'], equals('AI Machine Learning Certificate'));
  });

  test('Persistent Privacy Settings across app restarts', () async {
    await AppDataService.instance.updatePrivacySetting('showPhone', true);
    await AppDataService.instance.updatePrivacySetting('profileVisibility', false);

    expect(AppDataService.instance.getPrivacySettings()['showPhone'], isTrue);
    expect(AppDataService.instance.getPrivacySettings()['profileVisibility'], isFalse);

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getPrivacySettings()['showPhone'], isTrue);
    expect(AppDataService.instance.getPrivacySettings()['profileVisibility'], isFalse);
  });

  test('In-app short password & credential update persists across app restarts', () async {
    await AppDataService.instance.registerUserAccount(
      email: 'direct@skillbridge.pk',
      password: 'ab',
      name: 'A',
      university: 'X',
      role: 'Student',
    );
    expect(
      AppDataService.instance.verifyLocalCredentials('direct@skillbridge.pk', 'ab'),
      isTrue,
    );

    await AppDataService.instance.updateAccountPassword('direct@skillbridge.pk', '123');

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(
      AppDataService.instance.verifyLocalCredentials('direct@skillbridge.pk', 'ab'),
      isFalse,
    );
    expect(
      AppDataService.instance.verifyLocalCredentials('direct@skillbridge.pk', '123'),
      isTrue,
    );
  });

  test('Signup University and Profile Info Persistence', () async {
    await AppDataService.instance.saveAuthSession(
      role: 'Student',
      email: 'rabia.cs@nuces.edu.pk',
      name: 'Rabia Tariq',
      university: 'FAST NUCES Lahore',
    );

    expect(AppDataService.instance.getProfile()['name'], equals('Rabia Tariq'));
    expect(AppDataService.instance.getProfile()['university'], equals('FAST NUCES Lahore'));
    expect(AppDataService.instance.getProfile()['email'], equals('rabia.cs@nuces.edu.pk'));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getProfile()['name'], equals('Rabia Tariq'));
    expect(AppDataService.instance.getProfile()['university'], equals('FAST NUCES Lahore'));
    expect(AppDataService.instance.getProfile()['email'], equals('rabia.cs@nuces.edu.pk'));
  });

  test('Support Ticket Submission and Persistence', () async {
    await AppDataService.instance.submitSupportTicket(
      category: 'Technical Issue',
      subject: 'Deliverable file failed to load',
      message: 'Getting timeout when uploading 15MB file.',
    );

    expect(AppDataService.instance.getSupportTickets(), isNotEmpty);
    expect(AppDataService.instance.getSupportTickets().first['subject'], equals('Deliverable file failed to load'));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getSupportTickets(), isNotEmpty);
    expect(AppDataService.instance.getSupportTickets().first['subject'], equals('Deliverable file failed to load'));
  });

  test('Privacy Settings Persistence (showEmail, showPhone, profileVisibility)', () async {
    await AppDataService.instance.updatePrivacySetting('showEmail', false);
    await AppDataService.instance.updatePrivacySetting('showPhone', true);
    await AppDataService.instance.updatePrivacySetting('profileVisibility', false);
    await AppDataService.instance.updatePrivacySetting('publicPortfolio', false);

    expect(AppDataService.instance.getPrivacySettings()['showEmail'], isFalse);
    expect(AppDataService.instance.getPrivacySettings()['showPhone'], isTrue);
    expect(AppDataService.instance.getPrivacySettings()['profileVisibility'], isFalse);
    expect(AppDataService.instance.getPrivacySettings()['publicPortfolio'], isFalse);

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getPrivacySettings()['showEmail'], isFalse);
    expect(AppDataService.instance.getPrivacySettings()['showPhone'], isTrue);
    expect(AppDataService.instance.getPrivacySettings()['profileVisibility'], isFalse);
    expect(AppDataService.instance.getPrivacySettings()['publicPortfolio'], isFalse);
  });

  test('URL Validation for Apply Project & Submit Work Forms', () {
    bool isValidUrl(String? text) {
      if (text == null) return false;
      final val = text.trim();
      if (val.isEmpty || val.contains(' ')) return false;

      String normalized = val;
      if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
        normalized = 'https://$normalized';
      }

      final uri = Uri.tryParse(normalized);
      if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
        return false;
      }

      final parts = uri.host.split('.');
      final tld = parts.last;
      if (tld.length < 2 || !RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
        return false;
      }

      return true;
    }

    // Invalid values (plain text, missing domain, spaces, incomplete)
    expect(isValidUrl(null), isFalse);
    expect(isValidUrl(''), isFalse);
    expect(isValidUrl('   '), isFalse);
    expect(isValidUrl('my link'), isFalse);
    expect(isValidUrl('portfolio link text'), isFalse);
    expect(isValidUrl('some_random_word'), isFalse);
    expect(isValidUrl('github'), isFalse);
    expect(isValidUrl('http://invalid'), isFalse);
    expect(isValidUrl('test.123'), isFalse);

    // Valid URLs
    expect(isValidUrl('https://github.com/student/link_vibe'), isTrue);
    expect(isValidUrl('http://myportfolio.pk'), isTrue);
    expect(isValidUrl('github.com/student/repo'), isTrue);
    expect(isValidUrl('www.figma.com/file/12345/design'), isTrue);
    expect(isValidUrl('https://drive.google.com/drive/folders/xyz'), isTrue);
  });

  test('User Registration & Credential Verification with exact Name and University', () async {
    await AppDataService.instance.registerUserAccount(
      email: 'rabia.dev@punjab.edu.pk',
      password: 'password123',
      name: 'Rabia Tariq',
      university: 'Punjab University College of IT',
      role: 'Student',
    );

    // Verify local credentials work
    expect(AppDataService.instance.verifyLocalCredentials('rabia.dev@punjab.edu.pk', 'password123'), isTrue);
    expect(AppDataService.instance.verifyLocalCredentials('rabia.dev@punjab.edu.pk', 'wrongpass'), isFalse);

    // Verify name and institute persisted
    final acc = AppDataService.instance.findUserAccount('rabia.dev@punjab.edu.pk');
    expect(acc, isNotNull);
    expect(acc!['name'], equals('Rabia Tariq'));
    expect(acc['university'], equals('Punjab University College of IT'));

    expect(AppDataService.instance.userName, equals('Rabia Tariq'));
    expect(AppDataService.instance.getProfile()['university'], equals('Punjab University College of IT'));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.verifyLocalCredentials('rabia.dev@punjab.edu.pk', 'password123'), isTrue);
    final reloadedAcc = AppDataService.instance.findUserAccount('rabia.dev@punjab.edu.pk');
    expect(reloadedAcc!['name'], equals('Rabia Tariq'));
    expect(reloadedAcc['university'], equals('Punjab University College of IT'));
  });

  test('Password Reset & Immediate Login with New Password', () async {
    await AppDataService.instance.registerUserAccount(
      email: 'student.test@campusconnect.pk',
      password: 'oldPassword1',
      name: 'Test Student',
      university: 'NUST Islamabad',
      role: 'Student',
    );

    expect(AppDataService.instance.verifyLocalCredentials('student.test@campusconnect.pk', 'oldPassword1'), isTrue);

    // Reset / Update password
    await AppDataService.instance.updateAccountPassword('student.test@campusconnect.pk', 'newStrongPass99');

    // Old password must fail, new password must succeed!
    expect(AppDataService.instance.verifyLocalCredentials('student.test@campusconnect.pk', 'oldPassword1'), isFalse);
    expect(AppDataService.instance.verifyLocalCredentials('student.test@campusconnect.pk', 'newStrongPass99'), isTrue);

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.verifyLocalCredentials('student.test@campusconnect.pk', 'newStrongPass99'), isTrue);
    expect(AppDataService.instance.verifyLocalCredentials('student.test@campusconnect.pk', 'oldPassword1'), isFalse);
  });

  test('Student Avatar base64 persistence and removal across app restarts', () async {
    final samplePng = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1,
      13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);

    await AppDataService.instance.updateStudentAvatar(
      samplePng,
      fileExtension: 'png',
    );
    expect(
      AppDataService.instance.getProfile()['avatarBase64']?.toString(),
      isNotEmpty,
    );

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();
    expect(
      AppDataService.instance.getProfile()['avatarBase64']?.toString(),
      isNotEmpty,
    );

    await AppDataService.instance.removeStudentAvatar();
    expect(AppDataService.instance.getProfile()['avatarBase64'], isNull);
    expect(AppDataService.instance.getProfile()['avatarUrl'], isNull);

    await AppDataService.instance.init();
    expect(AppDataService.instance.getProfile()['avatarBase64'], isNull);
  });

  test('Same email can log out and re-login cleanly across restarts', () async {
    await AppDataService.instance.registerUserAccount(
      email: 'sameuser@gmail.com',
      password: 'Password123',
      name: 'Same User',
      university: 'NUST',
      role: 'Student',
    );
    await AppDataService.instance.saveAuthSession(
      role: 'Student',
      email: 'sameuser@gmail.com',
      name: 'Same User',
      university: 'NUST',
    );
    expect(AppDataService.instance.isLoggedIn, isTrue);

    await AppDataService.instance.clearAuthSession();
    expect(AppDataService.instance.isLoggedIn, isFalse);
    expect(
      AppDataService.instance.verifyLocalCredentials(
        'sameuser@gmail.com',
        'Password123',
      ),
      isTrue,
    );

    await AppDataService.instance.saveAuthSession(
      role: 'Student',
      email: 'sameuser@gmail.com',
      name: 'Same User',
      university: 'NUST',
    );
    expect(AppDataService.instance.isLoggedIn, isTrue);
    await AppDataService.instance.init();
    expect(AppDataService.instance.isLoggedIn, isTrue);
    expect(AppDataService.instance.userEmail, equals('sameuser@gmail.com'));
  });

  test('Project application limit blocks applying when 10 students have applied',
      () async {
    expect(AppDataService.maxApplicationsPerProject, equals(10));
    const projId = 'proj-cap-10';
    final project = {
      'id': projId,
      'title': 'FinTech Ledger Audit',
      'company': 'Systems Limited',
      'openings': 5,
    };

    AppDataService.instance.setProjectApplicantsCountForTest(projId, 10);
    expect(
      AppDataService.instance.isProjectApplicationLimitReached(projId),
      isTrue,
    );

    await expectLater(
      () => AppDataService.instance.addApplication(
        project: project,
        coverMessage: 'Experienced Flutter & SQL engineer ready to deliver.',
        skills: 'Flutter, SQL',
        availability: '15-20 hrs/week',
      ),
      throwsException,
    );
    expect(AppDataService.instance.hasApplied(projId), isFalse);

    AppDataService.instance.setProjectApplicantsCountForTest(projId, 9);
    expect(
      AppDataService.instance.isProjectApplicationLimitReached(projId),
      isFalse,
    );
    await AppDataService.instance.addApplication(
      project: project,
      coverMessage: 'Experienced Flutter & SQL engineer ready to deliver.',
      skills: 'Flutter, SQL',
      availability: '15-20 hrs/week',
    );
    expect(AppDataService.instance.hasApplied(projId), isTrue);
    expect(AppDataService.instance.getProjectApplicantsCount(projId), equals(10));
    expect(
      AppDataService.instance.isProjectApplicationLimitReached(projId),
      isTrue,
    );
  });

  test('CloudStorageService utilities and resume persistence work cleanly', () async {
    expect(CloudStorageService.sanitizeFileName('my resume (1).pdf'), 'my_resume__1_.pdf');
    expect(CloudStorageService.extensionFromName('archive.tar.gz'), 'gz');
    expect(CloudStorageService.extensionFromName('document.pdf'), 'pdf');
    expect(CloudStorageService.mimeTypeForExtension('pdf'), 'application/pdf');
    expect(CloudStorageService.mimeTypeForExtension('zip'), 'application/zip');
    expect(CloudStorageService.formatBytes(500), '500 B');
    expect(CloudStorageService.formatBytes(1024 * 1024 * 2), '2.0 MB');

    final loc = CloudStorageService.extractStorageLocation(
      'https://xyz.supabase.co/storage/v1/object/public/student-docs/user1/resumes/12345_cv.pdf',
    );
    expect(loc, isNotNull);
    expect(loc?.bucket, 'student-docs');
    expect(loc?.objectPath, 'user1/resumes/12345_cv.pdf');

    expect(
      CloudStorageService.displayNameFromUrl(
        'https://xyz.supabase.co/storage/v1/object/public/student-docs/user1/resumes/1700000000000_my_cv.pdf',
      ),
      'my_cv.pdf',
    );

    await AppDataService.instance.updateStudentResume('https://xyz.supabase.co/storage/v1/object/public/student-docs/cv.pdf');
    expect(
      AppDataService.instance.getProfile()['resumeUrl'],
      'https://xyz.supabase.co/storage/v1/object/public/student-docs/cv.pdf',
    );
  });
}

