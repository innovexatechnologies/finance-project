import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

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
    final certCount = AppDataService.instance.getCertificates().length;
    expect(certCount, greaterThanOrEqualTo(2));

    await AppDataService.instance.addCertificate({
      'id': 'CC-TEST-999',
      'title': 'AI Machine Learning Certificate',
      'project': 'Deep Learning Model Tuning',
      'issuer': 'CampusConnect & AI Lab',
      'date': 'Nov 09, 2026',
    });

    expect(AppDataService.instance.getCertificates().length, equals(certCount + 1));

    // SIMULATE APP CLOSE & REOPEN
    await AppDataService.instance.init();

    expect(AppDataService.instance.getCertificates().length, equals(certCount + 1));
    final newCert = AppDataService.instance.getCertificates().firstWhere((c) => c['id'] == 'CC-TEST-999');
    expect(newCert['title'], equals('AI Machine Learning Certificate'));
  });
}

