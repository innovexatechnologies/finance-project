import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Persistent Storage & Data Management Service for CampusConnect
class AppDataService extends ChangeNotifier {
  AppDataService._internal();
  static final AppDataService instance = AppDataService._internal();

  SharedPreferences? _prefs;

  // Cache in memory for instant synchronous UI reads
  bool _isLoggedIn = false;
  String _userRole = 'Student';
  String _userEmail = '';
  String _userName = '';
  String _userId = '';

  List<Map<String, dynamic>> _savedProjects = [];
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _customProjects = [];
  Map<String, Map<String, dynamic>> _workSubmissions = {};
  Map<String, dynamic> _profile = {};
  List<String> _skills = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _certificates = [];

  // Keys
  static const _kIsLoggedIn = 'cc_is_logged_in_v1';
  static const _kUserRole = 'cc_user_role_v1';
  static const _kUserEmail = 'cc_user_email_v1';
  static const _kUserName = 'cc_user_name_v1';
  static const _kUserId = 'cc_user_id_v1';
  static const _kSavedProjects = 'cc_saved_projects_v1';
  static const _kApplications = 'cc_applications_v1';
  static const _kCustomProjects = 'cc_custom_projects_v1';
  static const _kSubmissions = 'cc_submissions_v1';
  static const _kProfile = 'cc_profile_v1';
  static const _kSkills = 'cc_skills_v1';
  static const _kNotifications = 'cc_notifications_v1';
  static const _kCertificates = 'cc_certificates_v1';

  // Default seed projects matching user document and image
  static final List<Map<String, dynamic>> defaultSeedProjects = [
    {
      'id': 'seed_1',
      'title': 'Market Research on AI Tools',
      'company': 'Google',
      'category': 'Research',
      'duration': '3-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'stipend': '15-30K',
      'description':
          'Conduct comprehensive market research on the latest enterprise AI tools and compile an analytical executive summary.',
      'skills': ['Research', 'Analysis', 'Report Writing'],
      'isVerified': true,
      'createdAt': '2026-11-06T10:00:00.000Z',
    },
    {
      'id': 'seed_2',
      'title': 'Social Media Content Creation',
      'company': 'Meta',
      'category': 'Marketing',
      'duration': '2-4 days',
      'workMode': 'Remote',
      'status': 'Open',
      'stipend': '12-25K',
      'description':
          'Design viral engaging banners and write creative copy for international developer community campaigns.',
      'skills': ['Copywriting', 'Canva', 'Social Media'],
      'isVerified': true,
      'createdAt': '2026-11-05T12:00:00.000Z',
    },
    {
      'id': 'seed_3',
      'title': 'UI/UX Design for Web App',
      'company': 'Microsoft',
      'category': 'Design',
      'duration': '5-7 days',
      'workMode': 'Remote',
      'status': 'Open',
      'stipend': '20-40K',
      'description':
          'Create high-fidelity wireframes and prototype components using Figma for cloud service management portal.',
      'skills': ['Figma', 'UI/UX', 'Wireframing'],
      'isVerified': true,
      'createdAt': '2026-11-04T08:00:00.000Z',
    },
    {
      'id': 'seed_4',
      'title': 'Flutter App Mobile UI Development',
      'company': 'TechVista',
      'category': 'Development',
      'duration': '4-6 days',
      'workMode': 'Remote',
      'status': 'Open',
      'stipend': '25-50K',
      'description':
          'Implement pixel-perfect responsive Flutter screens and integrate REST API endpoints with smooth state handling.',
      'skills': ['Flutter', 'Dart', 'REST APIs'],
      'isVerified': true,
      'createdAt': '2026-11-03T15:00:00.000Z',
    },
    {
      'id': 'seed_5',
      'title': 'Product Analysis Report',
      'company': 'Amazon',
      'category': 'Research',
      'duration': '3-6 days',
      'workMode': 'Remote',
      'status': 'Open',
      'stipend': '18-35K',
      'description':
          'Analyze logistics bottlenecks and produce strategic operational efficiency recommendations for fulfillment hubs.',
      'skills': ['Data Analysis', 'Excel', 'Problem Solving'],
      'isVerified': true,
      'createdAt': '2026-11-02T11:00:00.000Z',
    },
    {
      'id': 'seed_6',
      'title': 'Python Data Pipeline Optimization',
      'company': 'CodeCraft',
      'category': 'Data Analysis',
      'duration': '3-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'stipend': '20-35K',
      'description':
          'Clean, transform and process CSV datasets using Pandas and NumPy for automated reporting pipelines.',
      'skills': ['Python', 'Pandas', 'Data Cleaning'],
      'isVerified': true,
      'createdAt': '2026-11-01T09:00:00.000Z',
    },
  ];

  static final List<Map<String, dynamic>> defaultSeedCertificates = [
    {
      'id': 'CC-2026-8841',
      'title': 'Project Completion Certificate',
      'project': 'Barcode Scanning Mobile Utility',
      'issuer': 'CampusConnect & CodeCraft Solutions',
      'date': 'March 15, 2026',
    },
    {
      'id': 'CC-2026-7732',
      'title': 'Project Completion Certificate',
      'project': 'Flutter App Mobile UI Development',
      'issuer': 'CampusConnect & TechVista Corp',
      'date': 'Feb 28, 2026',
    },
  ];

  /// Initialize persistent storage and load cached data
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAllFromPrefs();
  }

  void _loadAllFromPrefs() {
    if (_prefs == null) return;

    // 0. Auth Session Persistence
    _isLoggedIn = _prefs!.getBool(_kIsLoggedIn) ?? false;
    _userRole = _prefs!.getString(_kUserRole) ?? 'Student';
    _userEmail = _prefs!.getString(_kUserEmail) ?? '';
    _userName = _prefs!.getString(_kUserName) ?? '';
    _userId = _prefs!.getString(_kUserId) ?? '';

    // Check Supabase session
    try {
      final sbUser = Supabase.instance.client.auth.currentUser;
      if (sbUser != null) {
        _isLoggedIn = true;
        _userId = sbUser.id;
        if (sbUser.email != null && sbUser.email!.isNotEmpty) {
          _userEmail = sbUser.email!;
        }
        final metaRole = sbUser.userMetadata?['user_type']?.toString();
        if (metaRole != null && metaRole.isNotEmpty) {
          _userRole = metaRole;
        }
        final metaName = sbUser.userMetadata?['name']?.toString();
        if (metaName != null && metaName.isNotEmpty) {
          _userName = metaName;
        }
      }
    } catch (_) {}

    // 1. Saved Projects
    final savedJson = _prefs!.getString(_kSavedProjects);
    if (savedJson != null) {
      try {
        final List decoded = jsonDecode(savedJson);
        _savedProjects = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading saved projects: $e');
      }
    }

    // 2. Applications
    final appsJson = _prefs!.getString(_kApplications);
    if (appsJson != null) {
      try {
        final List decoded = jsonDecode(appsJson);
        _applications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading applications: $e');
      }
    } else {
      // Default seed applications
      _applications = [
        {
          'id': 'app_1',
          'projectId': 'seed_4',
          'title': 'Flutter App Mobile UI Development',
          'company': 'TechVista',
          'status': 'In Progress',
          'appliedDate': 'Nov 04, 2026',
          'timelineStep': 2,
        },
        {
          'id': 'app_2',
          'projectId': 'seed_1',
          'title': 'Market Research on AI Tools',
          'company': 'Google',
          'status': 'Shortlisted',
          'appliedDate': 'Nov 06, 2026',
          'timelineStep': 2,
        },
        {
          'id': 'app_3',
          'projectId': 'seed_prev',
          'title': 'Barcode Scanning Mobile Utility',
          'company': 'CodeCraft Solutions',
          'status': 'Completed',
          'appliedDate': 'Nov 02, 2026',
          'timelineStep': 3,
        },
      ];
    }

    // 3. Custom Projects added by user / company
    final customProjectsJson = _prefs!.getString(_kCustomProjects);
    if (customProjectsJson != null) {
      try {
        final List decoded = jsonDecode(customProjectsJson);
        _customProjects = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading custom projects: $e');
      }
    }

    // 4. Submissions
    final subJson = _prefs!.getString(_kSubmissions);
    if (subJson != null) {
      try {
        final Map decoded = jsonDecode(subJson);
        _workSubmissions = decoded.map((k, v) =>
            MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
      } catch (e) {
        debugPrint('Error loading submissions: $e');
      }
    }

    // 5. Profile
    final profileJson = _prefs!.getString(_kProfile);
    if (profileJson != null) {
      try {
        _profile = Map<String, dynamic>.from(jsonDecode(profileJson));
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    } else {
      _profile = {
        'name': 'Ahmed Khan',
        'email': 'ahmed.khan@student.edu.pk',
        'phone': '+92 300 1234567',
        'university': 'National University of Computer & Emerging Sciences',
        'department': 'Computer Science',
        'degree': 'BS Computer Science',
        'semester': '6th Semester',
        'location': 'Lahore, Pakistan',
        'bio':
            'Passionate Computer Science student specializing in Flutter app development and responsive UI/UX architecture. Eager to solve real corporate challenges.',
      };
    }

    // 6. Skills
    final skillsJson = _prefs!.getStringList(_kSkills);
    if (skillsJson != null) {
      _skills = List<String>.from(skillsJson);
    } else {
      _skills = [
        'Flutter',
        'Dart',
        'UI/UX Design',
        'REST APIs',
        'Firebase',
        'Git & GitHub',
        'Python',
        'Problem Solving',
      ];
    }

    // 7. Notifications
    final notifJson = _prefs!.getString(_kNotifications);
    if (notifJson != null) {
      try {
        final List decoded = jsonDecode(notifJson);
        _notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading notifications: $e');
      }
    } else {
      _notifications = [
        {
          'id': 'notif_1',
          'title': 'Application Shortlisted!',
          'subtitle': 'Google shortlisted your application for AI Market Research.',
          'time': '2h ago',
          'type': 'shortlisted',
          'isRead': false,
        },
        {
          'id': 'notif_2',
          'title': 'New Project Assigned',
          'subtitle': 'TechVista assigned you the Flutter App Mobile UI project.',
          'time': '5h ago',
          'type': 'assigned',
          'isRead': false,
        },
        {
          'id': 'notif_3',
          'title': 'Work Approved & Points Earned',
          'subtitle': 'CodeCraft approved your work! You earned 500 achievement points.',
          'time': '1d ago',
          'type': 'approved',
          'isRead': true,
        },
        {
          'id': 'notif_4',
          'title': 'Certificate Issued',
          'subtitle': 'Your certificate for Barcode Scanning Mobile Utility is now ready.',
          'time': '2d ago',
          'type': 'certificate',
          'isRead': true,
        },
      ];
    }

    // 8. Certificates
    final certJson = _prefs!.getString(_kCertificates);
    if (certJson != null) {
      try {
        final List decoded = jsonDecode(certJson);
        _certificates = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading certificates: $e');
        _certificates = List.from(defaultSeedCertificates);
      }
    } else {
      _certificates = List.from(defaultSeedCertificates);
    }

    notifyListeners();
  }

  // ==========================================
  // SAVED / BOOKMARKED PROJECTS (FAVOURITES)
  // ==========================================

  List<Map<String, dynamic>> getSavedProjects() => List.unmodifiable(_savedProjects);

  bool isProjectSaved(String projectId) {
    return _savedProjects.any((p) => p['id']?.toString() == projectId.toString());
  }

  Future<void> toggleSaveProject(Map<String, dynamic> project) async {
    final id = project['id']?.toString();
    if (id == null || id.isEmpty) return;

    final index = _savedProjects.indexWhere((p) => p['id']?.toString() == id);
    if (index >= 0) {
      _savedProjects.removeAt(index);
    } else {
      _savedProjects.insert(0, Map<String, dynamic>.from(project));
    }

    notifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kSavedProjects, jsonEncode(_savedProjects));
    }
  }

  Future<void> removeSavedProject(String projectId) async {
    _savedProjects.removeWhere((p) => p['id']?.toString() == projectId.toString());
    notifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kSavedProjects, jsonEncode(_savedProjects));
    }
  }

  // ==========================================
  // APPLICATIONS
  // ==========================================

  List<Map<String, dynamic>> getApplications() => List.unmodifiable(_applications);

  bool hasApplied(String projectId) {
    return _applications.any((a) => a['projectId']?.toString() == projectId.toString());
  }

  Future<void> addApplication({
    required Map<String, dynamic> project,
    required String coverMessage,
    required String skills,
    required String availability,
    String? portfolioLink,
  }) async {
    final newApp = {
      'id': 'app_${DateTime.now().millisecondsSinceEpoch}',
      'projectId': project['id']?.toString() ?? '',
      'title': project['title'] ?? 'Untitled Project',
      'company': project['company'] ?? 'Company',
      'status': 'Pending',
      'appliedDate': _formattedDate(DateTime.now()),
      'timelineStep': 1,
      'coverMessage': coverMessage,
      'skills': skills,
      'availability': availability,
      'portfolioLink': portfolioLink ?? '',
    };

    _applications.insert(0, newApp);

    // Also add an automated in-app notification
    addNotification(
      title: 'Application Submitted',
      subtitle: 'Your application for "${project['title']}" was sent to ${project['company']}.',
      time: 'Just now',
      type: 'submitted',
    );

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kApplications, jsonEncode(_applications));
    }

    // Background push to Supabase if available
    _pushApplicationToSupabase(newApp, project);
  }

  Future<void> _pushApplicationToSupabase(
      Map<String, dynamic> app, Map<String, dynamic> project) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final applicantId = user?.id ?? 'guest_student';
      final studentName = user?.userMetadata?['name'] ?? _profile['name'] ?? 'Ahmed Khan';

      final pId = project['id'];
      // Only insert if integer/valid id or string id
      if (pId != null) {
        await supabase.from('applications').insert({
          'project_id': pId,
          'applicant_id': applicantId,
          'name': studentName,
          'role': app['skills']?.toString().isNotEmpty == true
              ? app['skills']
              : 'Student Applicant',
          'status': 'Pending',
        });
      }
    } catch (_) {
      // Offline or uninitialized; local storage handles it smoothly
    }
  }

  // ==========================================
  // PROJECTS (ALL + CUSTOM ADDED)
  // ==========================================

  List<Map<String, dynamic>> getAllProjects() {
    // Combine custom projects first, then default seed projects (avoiding duplicate IDs)
    final existingIds = <String>{};
    final combined = <Map<String, dynamic>>[];

    for (var p in _customProjects) {
      final id = p['id']?.toString() ?? '';
      if (id.isNotEmpty && !existingIds.contains(id)) {
        existingIds.add(id);
        combined.add(p);
      }
    }

    for (var p in defaultSeedProjects) {
      final id = p['id']?.toString() ?? '';
      if (!existingIds.contains(id)) {
        existingIds.add(id);
        combined.add(p);
      }
    }

    return combined;
  }

  Future<void> addProject(Map<String, dynamic> project) async {
    final id = project['id']?.toString() ??
        'proj_${DateTime.now().millisecondsSinceEpoch}';
    final fullProject = {
      ...project,
      'id': id,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _customProjects.insert(0, fullProject);
    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kCustomProjects, jsonEncode(_customProjects));
    }

    // Background push to Supabase if available
    _pushProjectToSupabase(fullProject);
  }

  Future<void> _pushProjectToSupabase(Map<String, dynamic> p) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      await supabase.from('projects').insert({
        'title': p['title'],
        'description': p['description'] ?? '',
        'budget': p['stipend'] ?? p['budget'] ?? 'N/A',
        'company_name': p['company'] ?? p['company_name'] ?? 'Company',
        'status': p['status'] ?? 'Open',
        'user_id': user?.id,
      });
    } catch (_) {
      // Offline or uninitialized; local storage handles it smoothly
    }
  }

  // ==========================================
  // SUBMISSIONS & ACTIVE PROJECTS
  // ==========================================

  Map<String, dynamic>? getSubmission(String projectId) {
    return _workSubmissions[projectId];
  }

  Future<void> submitWork({
    required String projectId,
    required String projectTitle,
    required String company,
    required String summary,
    required String workLink,
    required String fileName,
  }) async {
    final subData = {
      'projectId': projectId,
      'projectTitle': projectTitle,
      'company': company,
      'summary': summary,
      'workLink': workLink,
      'fileName': fileName,
      'submittedAt': _formattedDate(DateTime.now()),
      'status': 'Under Review',
    };

    _workSubmissions[projectId] = subData;

    // Update application or project status if matching
    final appIndex = _applications.indexWhere((a) => a['projectId'] == projectId);
    if (appIndex >= 0) {
      _applications[appIndex]['status'] = 'Under Review';
    }

    addNotification(
      title: 'Work Submitted Successfully',
      subtitle: 'Your submission for "$projectTitle" is now under review by $company.',
      time: 'Just now',
      type: 'submitted',
    );

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kSubmissions, jsonEncode(_workSubmissions));
      await _prefs!.setString(_kApplications, jsonEncode(_applications));
    }
  }

  // ==========================================
  // PROFILE & SKILLS
  // ==========================================

  Map<String, dynamic> getProfile() => Map.unmodifiable(_profile);

  Future<void> updateProfile(Map<String, dynamic> updatedFields) async {
    _profile.addAll(updatedFields);
    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
    }

    // Sync to Supabase profiles table if logged in
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'name': _profile['name'],
          'email': _profile['email'],
        });
      }
    } catch (_) {}
  }

  List<String> getSkills() => List.unmodifiable(_skills);

  Future<void> addSkill(String skill) async {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || _skills.contains(trimmed)) return;

    _skills.add(trimmed);
    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setStringList(_kSkills, _skills);
    }
  }

  Future<void> removeSkill(String skill) async {
    _skills.remove(skill);
    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setStringList(_kSkills, _skills);
    }
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  List<Map<String, dynamic>> getNotifications() => List.unmodifiable(_notifications);

  Future<void> addNotification({
    required String title,
    required String subtitle,
    required String time,
    required String type,
  }) async {
    _notifications.insert(0, {
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'type': type,
      'isRead': false,
    });

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kNotifications, jsonEncode(_notifications));
    }
  }

  Future<void> markNotificationsRead() async {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kNotifications, jsonEncode(_notifications));
    }
  }

  // ==========================================
  // AUTH SESSION PERSISTENCE
  // ==========================================

  bool get isLoggedIn {
    if (_isLoggedIn) return true;
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  String get userRole => _userRole;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String get userId => _userId;

  Future<void> saveAuthSession({
    required String role,
    String? email,
    String? name,
    String? userId,
  }) async {
    _isLoggedIn = true;
    _userRole = role;
    if (email != null && email.isNotEmpty) _userEmail = email;
    if (name != null && name.isNotEmpty) _userName = name;
    if (userId != null && userId.isNotEmpty) _userId = userId;

    if (name != null && name.isNotEmpty) {
      _profile['name'] = name;
    }
    if (email != null && email.isNotEmpty) {
      _profile['email'] = email;
    }

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setBool(_kIsLoggedIn, true);
      await _prefs!.setString(_kUserRole, _userRole);
      if (_userEmail.isNotEmpty) await _prefs!.setString(_kUserEmail, _userEmail);
      if (_userName.isNotEmpty) await _prefs!.setString(_kUserName, _userName);
      if (_userId.isNotEmpty) await _prefs!.setString(_kUserId, _userId);
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
    }
  }

  Future<void> clearAuthSession() async {
    _isLoggedIn = false;
    _userRole = 'Student';
    _userEmail = '';
    _userName = '';
    _userId = '';

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setBool(_kIsLoggedIn, false);
      await _prefs!.remove(_kUserRole);
      await _prefs!.remove(_kUserEmail);
      await _prefs!.remove(_kUserName);
      await _prefs!.remove(_kUserId);
    }
  }

  // ==========================================
  // CERTIFICATES
  // ==========================================

  List<Map<String, dynamic>> getCertificates() => List.unmodifiable(_certificates);

  Future<void> addCertificate(Map<String, dynamic> cert) async {
    _certificates.insert(0, cert);
    notifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kCertificates, jsonEncode(_certificates));
    }
  }

  // ==========================================
  // STATS
  // ==========================================

  int get totalApplicationsCount => _applications.length;

  int get activeProjectsCount {
    return _applications
        .where((a) =>
            a['status'] == 'In Progress' ||
            a['status'] == 'Under Review' ||
            a['status'] == 'Accepted' ||
            a['status'] == 'Revision Requested')
        .length;
  }

  int get completedProjectsCount {
    return _applications.where((a) => a['status'] == 'Completed').length;
  }

  int get certificatesCount => _certificates.length;

  // Helper date formatter
  String _formattedDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year;
    return '$m $d, $y';
  }
}
