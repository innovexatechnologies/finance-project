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
  Map<String, bool> _notificationPreferences = {
    'pushNotifications': true,
    'emailAlerts': true,
    'newProjectsAlert': true,
    'applicationUpdates': true,
    'chatMessages': true,
    'deadlineReminders': true,
  };
  Map<String, bool> _privacySettings = {
    'profileVisibility': true,
    'showEmail': true,
    'showPhone': false,
    'publicPortfolio': true,
    'allowCompanyMessages': true,
  };
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _supportTickets = [];

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
  static const _kNotificationPreferences = 'cc_notif_prefs_v1';
  static const _kPrivacySettings = 'cc_privacy_prefs_v1';
  static const _kChatConversations = 'cc_chat_conversations_v1';
  static const _kSupportTickets = 'cc_support_tickets_v1';

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
          _profile['name'] = metaName;
        }
        final metaUni = sbUser.userMetadata?['university']?.toString();
        if (metaUni != null && metaUni.isNotEmpty) {
          _profile['university'] = metaUni;
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

    // 9. Notification Preferences
    final notifPrefsJson = _prefs!.getString(_kNotificationPreferences);
    if (notifPrefsJson != null) {
      try {
        final Map decoded = jsonDecode(notifPrefsJson);
        _notificationPreferences =
            decoded.map((k, v) => MapEntry(k.toString(), v == true));
      } catch (e) {
        debugPrint('Error loading notif prefs: $e');
      }
    }

    // 10. Privacy Settings
    final privacyJson = _prefs!.getString(_kPrivacySettings);
    if (privacyJson != null) {
      try {
        final Map decoded = jsonDecode(privacyJson);
        _privacySettings =
            decoded.map((k, v) => MapEntry(k.toString(), v == true));
      } catch (e) {
        debugPrint('Error loading privacy settings: $e');
      }
    }

    // 11. Chat Conversations
    final chatJson = _prefs!.getString(_kChatConversations);
    if (chatJson != null) {
      try {
        final List decoded = jsonDecode(chatJson);
        _conversations = decoded.map((e) {
          final m = Map<String, dynamic>.from(e);
          if (m['messages'] is List) {
            m['messages'] = (m['messages'] as List)
                .map((msg) => Map<String, dynamic>.from(msg as Map))
                .toList();
          }
          return m;
        }).toList();
      } catch (e) {
        debugPrint('Error loading conversations: $e');
      }
    }
    if (_conversations.isEmpty) {
      _conversations = [
        {
          'id': 'conv_techvista',
          'company': 'TechVista',
          'supervisor': 'Sarah Jenkins (Project Lead)',
          'lastMessage': 'The mockups look great! Please proceed to step 2.',
          'time': '10:45 AM',
          'unread': 0,
          'messages': <Map<String, dynamic>>[
            {
              'id': 'msg_1',
              'isMe': false,
              'sender': 'Sarah Jenkins',
              'text': 'Hello Ahmed! Welcome to the project workspace.',
              'time': '10:30 AM',
            },
            {
              'id': 'msg_2',
              'isMe': true,
              'sender': 'Me',
              'text': 'Thank you! Excited to collaborate and get started.',
              'time': '10:35 AM',
            },
            {
              'id': 'msg_3',
              'isMe': false,
              'sender': 'Sarah Jenkins',
              'text': 'The mockups look great! Please proceed to step 2.',
              'time': '10:45 AM',
            },
          ],
        },
        {
          'id': 'conv_google',
          'company': 'Google Mentorship',
          'supervisor': 'Dr. Arham (AI Team)',
          'lastMessage': 'Meeting scheduled for tomorrow at 3 PM PKT.',
          'time': 'Yesterday',
          'unread': 0,
          'messages': <Map<String, dynamic>>[
            {
              'id': 'msg_g1',
              'isMe': false,
              'sender': 'Dr. Arham',
              'text': 'Meeting scheduled for tomorrow at 3 PM PKT.',
              'time': 'Yesterday',
            },
          ],
        },
        {
          'id': 'conv_codecraft',
          'company': 'CodeCraft Solutions',
          'supervisor': 'Usman Tariq',
          'lastMessage': 'Certificate issued and uploaded to your portal.',
          'time': 'Oct 26',
          'unread': 0,
          'messages': <Map<String, dynamic>>[
            {
              'id': 'msg_c1',
              'isMe': false,
              'sender': 'Usman Tariq',
              'text': 'Certificate issued and uploaded to your portal.',
              'time': 'Oct 26',
            },
          ],
        },
      ];
    }

    // 12. Support Tickets
    final ticketsJson = _prefs!.getString(_kSupportTickets);
    if (ticketsJson != null) {
      try {
        final List decoded = jsonDecode(ticketsJson);
        _supportTickets =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading support tickets: $e');
      }
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

  int get unreadNotificationsCount {
    return _notifications.where((n) => n['isRead'] != true).length;
  }

  Future<void> markNotificationRead(dynamic id) async {
    final idx =
        _notifications.indexWhere((n) => n['id']?.toString() == id.toString());
    if (idx >= 0) {
      _notifications[idx]['isRead'] = true;
      notifyListeners();
      if (_prefs != null) {
        await _prefs!.setString(_kNotifications, jsonEncode(_notifications));
      }
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
  // NOTIFICATION & PRIVACY PREFERENCES
  // ==========================================

  Map<String, bool> getNotificationPreferences() =>
      Map.unmodifiable(_notificationPreferences);

  Future<void> updateNotificationPreference(String key, bool value) async {
    _notificationPreferences[key] = value;
    notifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(
          _kNotificationPreferences, jsonEncode(_notificationPreferences));
    }
  }

  Map<String, bool> getPrivacySettings() =>
      Map.unmodifiable(_privacySettings);

  Future<void> updatePrivacySetting(String key, bool value) async {
    _privacySettings[key] = value;
    notifyListeners();
    if (_prefs != null) {
      await _prefs!
          .setString(_kPrivacySettings, jsonEncode(_privacySettings));
    }
  }

  // ==========================================
  // CHAT & MESSAGING
  // ==========================================

  List<Map<String, dynamic>> getConversations() =>
      List.unmodifiable(_conversations);

  Map<String, dynamic>? getConversation(String id) {
    try {
      return _conversations.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    final conv = _conversations.firstWhere(
      (c) => c['id'] == conversationId,
      orElse: () => {},
    );
    if (conv.isNotEmpty && ((conv['unread'] as int? ?? 0) > 0)) {
      conv['unread'] = 0;
      notifyListeners();
      if (_prefs != null) {
        await _prefs!.setString(
            _kChatConversations, jsonEncode(_conversations));
      }
    }
  }

  Future<void> sendChatMessage({
    required String conversationId,
    required String text,
  }) async {
    final conv = _conversations.firstWhere(
      (c) => c['id'] == conversationId,
      orElse: () => {},
    );
    if (conv.isEmpty) return;

    const nowTime = 'Just now';
    final userMsg = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'isMe': true,
      'sender': _profile['name'] ?? (_userName.isNotEmpty ? _userName : 'Me'),
      'text': text,
      'time': nowTime,
    };

    final List<Map<String, dynamic>> msgs =
        List<Map<String, dynamic>>.from(conv['messages'] as List? ?? []);
    msgs.add(userMsg);
    conv['messages'] = msgs;
    conv['lastMessage'] = text;
    conv['time'] = nowTime;

    // Student in-app delivery notification
    addNotification(
      title: 'Message Delivered to ${conv['company']}',
      subtitle: '${conv['supervisor']} received: "$text"',
      time: 'Just now',
      type: 'chat',
    );

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(
          _kChatConversations, jsonEncode(_conversations));
    }

    // Try to record in Supabase
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user?.id ?? 'guest_student',
        'content': text,
        'company_name': conv['company'],
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // Simulated company supervisor reply after 1.5s
    final supervisor = conv['supervisor']?.toString() ?? 'Supervisor';
    final company = conv['company']?.toString() ?? 'Company';
    final studentName = _profile['name'] ?? 'Ahmed';

    Future.delayed(const Duration(milliseconds: 1400), () async {
      final supervisorReplies = [
        'Thanks for reaching out, $studentName! Received your message, looking into it now.',
        'Great to hear from you, $studentName! Keep progressing on the tasks, will review shortly.',
        'Got your note! Your submission and progress are on track.',
        'Acknowledged. Our project engineering team has received your message.',
      ];
      final replyText =
          supervisorReplies[DateTime.now().second % supervisorReplies.length];

      final replyMsg = {
        'id': 'msg_rep_${DateTime.now().millisecondsSinceEpoch}',
        'isMe': false,
        'sender': supervisor,
        'text': replyText,
        'time': 'Just now',
      };

      msgs.add(replyMsg);
      conv['lastMessage'] = replyText;
      conv['time'] = 'Just now';
      conv['unread'] = (conv['unread'] as int? ?? 0) + 1;

      addNotification(
        title: 'New message from $supervisor ($company)',
        subtitle: replyText,
        time: 'Just now',
        type: 'chat',
      );

      notifyListeners();

      if (_prefs != null) {
        await _prefs!.setString(
            _kChatConversations, jsonEncode(_conversations));
      }
    });
  }

  // ==========================================
  // SUPPORT TICKETS
  // ==========================================

  List<Map<String, dynamic>> getSupportTickets() =>
      List.unmodifiable(_supportTickets);

  Future<void> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    final ticketId = 'CC-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final ticket = {
      'id': ticketId,
      'category': category,
      'subject': subject,
      'message': message,
      'email': _userEmail.isNotEmpty ? _userEmail : (_profile['email'] ?? ''),
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'Under Review',
    };

    _supportTickets.insert(0, ticket);

    addNotification(
      title: 'Support Ticket #$ticketId Submitted',
      subtitle: 'Our support team will respond to "$subject" via email soon.',
      time: 'Just now',
      type: 'submitted',
    );

    notifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(
          _kSupportTickets, jsonEncode(_supportTickets));
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
    String? university,
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
    if (university != null && university.isNotEmpty) {
      _profile['university'] = university;
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
