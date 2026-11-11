import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:link_vibe/core/services/supabase_helper.dart';

/// Central Persistent & Supabase-Synchronized Data Service for SkillBridge.
class AppDataService extends ChangeNotifier {
  AppDataService._internal();
  static final AppDataService instance = AppDataService._internal();

  /// Reactive counter incremented on sync/data updates for ValueListenableBuilder screens.
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  void _safeNotifyListeners() {
    dataVersion.value++;
    try {
      final binding = SchedulerBinding.instance;
      if (binding.schedulerPhase != SchedulerPhase.idle) {
        binding.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        notifyListeners();
      }
    } catch (_) {
      notifyListeners();
    }
  }

  SharedPreferences? _prefs;

  // Session state
  bool _isLoggedIn = false;
  String _userRole = 'Student';
  String _userEmail = '';
  String _userName = '';
  String _userId = '';
  bool _isSyncing = false;
  String? _lastSyncError;

  // Entity caches (empty until fetched from Supabase or created by user)
  List<Map<String, dynamic>> _savedProjects = [];
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _projects = [];
  Map<String, Map<String, dynamic>> _workSubmissions = {};
  Map<String, dynamic> _profile = {};
  List<String> _skills = [];
  List<Map<String, dynamic>> _certificates = [];
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _supportTickets = [];
  Map<String, Map<String, dynamic>> _userAccounts = {};

  static const Map<String, bool> _defaultPrivacySettings = {
    'profileVisibility': true,
    'showEmail': true,
    'showPhone': false,
    'publicPortfolio': true,
    'allowCompanyMessages': true,
  };

  final Map<String, bool> _privacySettings =
      Map<String, bool>.from(_defaultPrivacySettings);

  // SharedPreferences keys
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
  static const _kCertificates = 'cc_certificates_v1';
  static const _kPrivacySettings = 'cc_privacy_prefs_v1';
  static const _kChatConversations = 'cc_chat_conversations_v1';
  static const _kSupportTickets = 'cc_support_tickets_v1';
  static const _kUserAccounts = 'cc_user_accounts_v1';
  static const _kPendingAuthFlow = 'cc_pending_auth_flow_v1';
  static const _kPendingAuthEmail = 'cc_pending_auth_email_v1';
  static const _kPendingAuthRole = 'cc_pending_auth_role_v1';

  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;

  /// Initialize persistent storage and load locally cached session state.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAllFromPrefs();
  }

  void _loadAllFromPrefs() {
    if (_prefs == null) return;

    _isLoggedIn = _prefs!.getBool(_kIsLoggedIn) ?? false;
    _userRole = _prefs!.getString(_kUserRole) ?? 'Student';
    _userEmail = _prefs!.getString(_kUserEmail) ?? '';
    _userName = _prefs!.getString(_kUserName) ?? '';
    _userId = _prefs!.getString(_kUserId) ?? '';

    final savedFlow = _prefs!.getString(_kPendingAuthFlow);
    if (savedFlow != null && savedFlow.isNotEmpty) {
      SupabaseHelper.setPendingAuthContext(
        flow: savedFlow,
        email: _prefs!.getString(_kPendingAuthEmail),
        role: _prefs!.getString(_kPendingAuthRole),
      );
    }

    // 1. Saved Projects
    _savedProjects = _decodeList(_prefs!.getString(_kSavedProjects));

    // 2. Applications
    _applications = _decodeList(_prefs!.getString(_kApplications));

    // 3. Projects
    _projects = _decodeList(_prefs!.getString(_kCustomProjects));

    // 4. Submissions
    _workSubmissions = {};
    final subJson = _prefs!.getString(_kSubmissions);
    if (subJson != null) {
      try {
        final Map decoded = jsonDecode(subJson);
        _workSubmissions = decoded.map(
          (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
        );
      } catch (e) {
        debugPrint('Error loading submissions: $e');
      }
    }

    // 5. Profile
    _profile = {};
    final profileJson = _prefs!.getString(_kProfile);
    if (profileJson != null) {
      try {
        _profile = Map<String, dynamic>.from(jsonDecode(profileJson));
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }

    // Check active Supabase session metadata
    final sbUser = SupabaseHelper.currentUser;
    if (sbUser != null) {
      _isLoggedIn = true;
      _userId = sbUser.id;
      if (sbUser.email != null && sbUser.email!.isNotEmpty) {
        _userEmail = sbUser.email!;
        _profile['email'] ??= _userEmail;
      }
      final metaRole = sbUser.userMetadata?['user_type']?.toString();
      if (metaRole != null && metaRole.isNotEmpty) {
        _userRole = metaRole;
      }
      final metaName = sbUser.userMetadata?['name']?.toString();
      if (metaName != null && metaName.isNotEmpty) {
        _userName = metaName;
        _profile['name'] ??= metaName;
      }
      final metaUni = sbUser.userMetadata?['university']?.toString();
      if (metaUni != null && metaUni.isNotEmpty) {
        _profile['university'] ??= metaUni;
      }
    }

    // 6. Skills
    final skillsJson = _prefs!.getStringList(_kSkills);
    _skills = skillsJson != null ? List<String>.from(skillsJson) : [];

    // 7. Certificates
    _certificates = _decodeList(_prefs!.getString(_kCertificates));

    // 8. Privacy Settings
    _privacySettings
      ..clear()
      ..addAll(_defaultPrivacySettings);
    final privacyJson = _prefs!.getString(_kPrivacySettings);
    if (privacyJson != null) {
      try {
        final Map decoded = jsonDecode(privacyJson);
        for (final entry in decoded.entries) {
          _privacySettings[entry.key.toString()] = entry.value == true;
        }
      } catch (e) {
        debugPrint('Error loading privacy settings: $e');
      }
    }

    // 11. Chat Conversations
    _conversations = [];
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

    // 12. Support Tickets
    _supportTickets = _decodeList(_prefs!.getString(_kSupportTickets));

    // 13. Offline-test Local User Accounts Registry
    _userAccounts = {};
    final accountsJson = _prefs!.getString(_kUserAccounts);
    if (accountsJson != null) {
      try {
        final Map decoded = jsonDecode(accountsJson);
        _userAccounts = decoded.map(
          (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
        );
      } catch (e) {
        debugPrint('Error loading user accounts: $e');
      }
    }

    _safeNotifyListeners();
  }

  List<Map<String, dynamic>> _decodeList(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error decoding list from prefs: $e');
      return [];
    }
  }

  // ===========================================================================
  // LIVE SUPABASE SYNCHRONIZATION
  // ===========================================================================

  /// Fetch real data from Supabase for the currently authenticated user & public catalog.
  Future<void> syncFromSupabase({bool forceRefresh = false}) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return;
    if (_isSyncing && !forceRefresh) return;

    _isSyncing = true;
    _lastSyncError = null;

    try {
      final user = supabase.auth.currentUser;

      // 1. Fetch verified/partner companies map for enrichment
      final Map<String, Map<String, dynamic>> companiesByUserId = {};
      final Map<String, Map<String, dynamic>> companiesById = {};
      try {
        final compRows = await supabase
            .from('companies')
            .select(
              'id, user_id, company_name, industry, location, verification_status, logo_initial',
            );
        for (final raw in compRows) {
          final row = Map<String, dynamic>.from(raw);
          final id = row['id']?.toString() ?? '';
          final uid = row['user_id']?.toString() ?? '';
          if (id.isNotEmpty) companiesById[id] = row;
          if (uid.isNotEmpty) companiesByUserId[uid] = row;
        }
      } catch (e) {
        debugPrint('Supabase companies lookup skipped: $e');
      }

      // 2. Fetch live projects catalog (exclude Removed/Flagged from Explore)
      try {
        final projectRows = await supabase
            .from('projects')
            .select()
            .order('created_at', ascending: false);

        final List<Map<String, dynamic>> mappedProjects = [];
        for (final raw in projectRows) {
          final p = Map<String, dynamic>.from(raw);
          final status = p['status']?.toString() ?? 'Open';
          if (status == 'Removed' || status == 'Flagged') continue;

          final postedBy =
              p['posted_by']?.toString() ?? p['user_id']?.toString() ?? '';
          final compId = p['company_id']?.toString() ?? '';
          final comp = companiesByUserId[postedBy] ?? companiesById[compId];

          final skills = SupabaseHelper.parseStringList(p['skills']);
          final stipend = (p['stipend']?.toString().trim().isNotEmpty == true)
              ? p['stipend'].toString()
              : (p['budget']?.toString().trim().isNotEmpty == true
                  ? p['budget'].toString()
                  : 'Academic Credit / Verified Certificate');

          mappedProjects.add({
            'id': p['id']?.toString() ?? '',
            'title': p['title']?.toString() ?? 'Untitled Project',
            'company': p['company_name']?.toString() ??
                comp?['company_name']?.toString() ??
                'Partner Company',
            'companyId': comp?['id']?.toString() ?? compId,
            'companyUserId': postedBy,
            'category': p['category']?.toString() ?? 'Development',
            'duration': p['duration']?.toString() ?? '3-4 Weeks',
            'workMode': p['work_mode']?.toString() ?? 'Remote',
            'deadline': p['deadline']?.toString() ?? 'Flexible',
            'status': status,
            'stipend': stipend,
            'budget': p['budget']?.toString() ?? stipend,
            'description': p['description']?.toString() ?? '',
            'requirements': p['requirements']?.toString() ?? '',
            'deliverables': p['deliverables']?.toString() ?? '',
            'additionalInstructions':
                p['additional_instructions']?.toString() ?? '',
            'openings': p['openings'] ?? 1,
            'skills': skills,
            'isVerified':
                (comp?['verification_status']?.toString() ?? '') == 'verified',
            'attachmentUrl': p['attachment_url']?.toString(),
            'createdAt': p['created_at']?.toString() ?? '',
          });
        }
        _projects = mappedProjects;
        await _prefs?.setString(_kCustomProjects, jsonEncode(_projects));
      } catch (e) {
        debugPrint('Error fetching projects: $e');
        _lastSyncError = e.toString();
      }

      if (user != null) {
        _isLoggedIn = true;
        _userId = user.id;
        _userEmail = user.email ?? _userEmail;

        // 3. Profile row
        try {
          final prof = await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .limit(1)
              .maybeSingle();
          if (prof != null) {
            final name = prof['name']?.toString().trim() ?? '';
            if (name.isNotEmpty) {
              _userName = name;
              _profile['name'] = name;
            }
            if (prof['email'] != null &&
                prof['email'].toString().trim().isNotEmpty) {
              _userEmail = prof['email'].toString().trim();
              _profile['email'] = _userEmail;
            }
            if (prof['user_type'] != null &&
                prof['user_type'].toString().trim().isNotEmpty) {
              _userRole = prof['user_type'].toString().trim();
            }
            _profile['university'] =
                prof['university']?.toString() ?? _profile['university'] ?? '';
            _profile['department'] =
                prof['department']?.toString() ?? _profile['department'] ?? '';
            _profile['degree'] =
                prof['degree']?.toString() ?? _profile['degree'] ?? '';
            _profile['semester'] =
                prof['semester']?.toString() ?? _profile['semester'] ?? '';
            if (prof['cgpa'] != null) {
              _profile['cgpa'] = (prof['cgpa'] as num).toDouble();
            }
            _profile['phone'] =
                prof['phone']?.toString() ?? _profile['phone'] ?? '';
            _profile['bio'] =
                prof['bio']?.toString() ?? _profile['bio'] ?? '';
            _profile['avatarUrl'] = prof['avatar_url']?.toString();
            _profile['isVerified'] = prof['is_verified'] == true;
            _profile['accountStatus'] =
                prof['account_status']?.toString() ?? 'active';
          }
        } catch (e) {
          debugPrint('Error fetching profile: $e');
        }

        // 4. Student record & skills
        if (_userRole.toLowerCase() == 'student') {
          try {
            final stu = await supabase
                .from('students')
                .select()
                .eq('user_id', user.id)
                .limit(1)
                .maybeSingle();
            if (stu != null) {
              if (stu['full_name'] != null &&
                  stu['full_name'].toString().trim().isNotEmpty) {
                _userName = stu['full_name'].toString().trim();
                _profile['name'] = _userName;
              }
              _profile['university'] = stu['university']?.toString() ??
                  _profile['university'] ??
                  '';
              _profile['department'] = stu['department']?.toString() ??
                  _profile['department'] ??
                  '';
              _profile['degree'] =
                  stu['degree']?.toString() ?? _profile['degree'] ?? '';
              _profile['semester'] =
                  stu['semester']?.toString() ?? _profile['semester'] ?? '';
              if (stu['cgpa'] != null) {
                _profile['cgpa'] = (stu['cgpa'] as num).toDouble();
              }
              if (stu['phone'] != null && stu['phone'].toString().isNotEmpty) {
                _profile['phone'] = stu['phone'].toString();
              }
              if (stu['bio'] != null && stu['bio'].toString().isNotEmpty) {
                _profile['bio'] = stu['bio'].toString();
              }
              _profile['githubUrl'] = stu['github_url']?.toString() ?? '';
              _profile['portfolioUrl'] =
                  stu['portfolio_url']?.toString() ?? '';
              _profile['resumeUrl'] = stu['resume_url']?.toString() ?? '';
              _profile['verificationStatus'] =
                  stu['verification_status']?.toString() ?? 'pending';
              _profile['accountStatus'] =
                  stu['account_status']?.toString() ?? 'active';

              final parsedSkills =
                  SupabaseHelper.parseStringList(stu['skills']);
              if (parsedSkills.isNotEmpty) {
                _skills = parsedSkills;
              }
            }
          } catch (e) {
            debugPrint('Error fetching student record: $e');
          }

          // 5. Saved projects
          try {
            final savedRows = await supabase
                .from('saved_projects')
                .select('project_id')
                .eq('user_id', user.id);
            final savedIds = savedRows
                .map((r) => r['project_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();
            _savedProjects = _projects
                .where((p) => savedIds.contains(p['id']?.toString()))
                .toList();
            await _prefs?.setString(_kSavedProjects, jsonEncode(_savedProjects));
          } catch (e) {
            debugPrint('Error fetching saved_projects: $e');
          }

          // 6. Applications & Submissions
          try {
            final appRows = await supabase
                .from('applications')
                .select()
                .or('student_id.eq.${user.id},user_id.eq.${user.id}')
                .order('submitted_at', ascending: false);

            final List<Map<String, dynamic>> mappedApps = [];
            final Map<String, Map<String, dynamic>> mappedSubs = {};

            for (final raw in appRows) {
              final row = Map<String, dynamic>.from(raw);
              final projectId = row['project_id']?.toString() ?? '';
              final matchingProject = _projects.firstWhere(
                (p) => p['id']?.toString() == projectId,
                orElse: () => {},
              );

              final status = row['status']?.toString() ?? 'Pending';
              final feedback = row['company_feedback']?.toString() ?? '';
              final workUrl = row['submitted_work_url']?.toString() ?? '';
              final fileName = row['file_name']?.toString() ?? '';
              final subNotes = row['submission_notes']?.toString() ?? '';
              final subTitle = row['submission_title']?.toString() ?? '';

              int timelineStep = 1;
              if (status == 'Shortlisted') timelineStep = 2;
              if (status == 'In Progress' ||
                  status == 'Accepted' ||
                  status == 'Under Review' ||
                  status == 'Revision Requested') {
                timelineStep = 2;
              }
              if (status == 'Completed') timelineStep = 3;

              final title = row['project_title']?.toString() ??
                  matchingProject['title']?.toString() ??
                  'Project';
              final company = row['company_name']?.toString() ??
                  matchingProject['company']?.toString() ??
                  'Company Partner';

              mappedApps.add({
                'id': row['id']?.toString() ?? '',
                'projectId': projectId,
                'title': title,
                'company': company,
                'companyUserId': matchingProject['companyUserId']?.toString() ?? '',
                'status': status,
                'appliedDate': _formatDbDate(row['submitted_at']),
                'timelineStep': timelineStep,
                'coverMessage': row['cover_letter']?.toString() ?? '',
                'skills': SupabaseHelper.parseStringList(row['skills']).join(', '),
                'availability': row['availability']?.toString() ?? '',
                'portfolioLink': row['portfolio_link']?.toString() ?? '',
                'companyFeedback': feedback,
                'progress': (row['progress'] as num?)?.toDouble() ?? 0.0,
                'deadline': matchingProject['deadline']?.toString() ?? 'Flexible',
              });

              if (workUrl.isNotEmpty ||
                  fileName.isNotEmpty ||
                  subNotes.isNotEmpty ||
                  status == 'Under Review' ||
                  status == 'Revision Requested' ||
                  status == 'Completed') {
                mappedSubs[projectId] = {
                  'applicationId': row['id']?.toString() ?? '',
                  'projectId': projectId,
                  'projectTitle': title,
                  'company': company,
                  'submissionTitle': subTitle,
                  'summary': subNotes,
                  'workLink': workUrl,
                  'fileName': fileName,
                  'submittedAt': _formatDbDate(
                    row['work_submitted_at'] ?? row['updated_at'],
                  ),
                  'status': status == 'Completed'
                      ? 'Approved'
                      : (status == 'Revision Requested'
                          ? 'Revision Requested'
                          : 'Under Review'),
                  'feedback': feedback,
                };
              }
            }

            _applications = mappedApps;
            _workSubmissions = mappedSubs;
            await _prefs?.setString(_kApplications, jsonEncode(_applications));
            await _prefs?.setString(
              _kSubmissions,
              jsonEncode(_workSubmissions),
            );
          } catch (e) {
            debugPrint('Error fetching applications: $e');
          }

          // 7. Certificates
          try {
            final certRows = await supabase
                .from('certificates')
                .select()
                .eq('student_id', user.id)
                .order('created_at', ascending: false);

            _certificates = certRows.map((raw) {
              final c = Map<String, dynamic>.from(raw);
              return {
                'id': c['certificate_id']?.toString() ?? c['id']?.toString() ?? '',
                'dbId': c['id']?.toString() ?? '',
                'title': c['certificate_title']?.toString() ??
                    'Certificate of Project Completion',
                'project': c['project_title']?.toString() ?? 'Corporate Sprint',
                'issuer': c['issuer']?.toString() ??
                    c['company_name']?.toString() ??
                    'SkillBridge Partner',
                'companyName': c['company_name']?.toString() ?? '',
                'date': c['issue_date']?.toString() ??
                    _formatDbDate(c['created_at']),
                'status': c['status']?.toString() ?? 'valid',
                'rating': (c['overall_rating'] as num?)?.toDouble() ?? 5.0,
                'recommendation': c['recommendation_letter']?.toString() ?? '',
                'hash': c['cryptographic_hash']?.toString() ?? '',
                'verificationUrl': c['verification_url']?.toString() ?? '',
                'pdfUrl': c['pdf_url']?.toString() ?? '',
              };
            }).toList();
            await _prefs?.setString(_kCertificates, jsonEncode(_certificates));
          } catch (e) {
            debugPrint('Error fetching certificates: $e');
          }
        }

        // 8. Messages grouped into conversations
        try {
          final msgRows = await supabase
              .from('messages')
              .select()
              .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
              .order('created_at', ascending: true);

          final Map<String, Map<String, dynamic>> convMap = {};
          for (final raw in msgRows) {
            final m = Map<String, dynamic>.from(raw);
            final senderId = m['sender_id']?.toString() ?? '';
            final receiverId = m['receiver_id']?.toString() ?? '';
            final isMe = senderId == user.id;
            final peerId = isMe ? receiverId : senderId;
            final convId = (m['conversation_id']?.toString().isNotEmpty == true)
                ? m['conversation_id'].toString()
                : 'conv_${peerId.isNotEmpty ? peerId : (m['company_name'] ?? 'general')}';

            final peerName = isMe
                ? (m['receiver_name']?.toString().trim() ?? '')
                : (m['sender_name']?.toString().trim() ?? '');
            final rawCompany = m['company_name']?.toString().trim() ?? '';
            final isCompanyUser = _userRole.toLowerCase() == 'company';
            final companyName = isCompanyUser
                ? (peerName.isNotEmpty
                    ? peerName
                    : (rawCompany.isNotEmpty ? rawCompany : 'Student'))
                : (rawCompany.isNotEmpty
                    ? rawCompany
                    : (peerName.isNotEmpty ? peerName : 'Partner'));
            final supervisorName =
                peerName.isNotEmpty ? peerName : companyName;

            convMap.putIfAbsent(
              convId,
              () => {
                'id': convId,
                'peerUserId': peerId,
                'company': companyName,
                'supervisor': supervisorName,
                'projectTitle': m['project_title']?.toString() ?? '',
                'lastMessage': '',
                'time': 'Recently',
                'unread': 0,
                'messages': <Map<String, dynamic>>[],
              },
            );

            final entry = convMap[convId]!;
            final text = m['message_text']?.toString() ?? '';
            final relTime = SupabaseHelper.formatRelativeTime(m['created_at']);
            final msgs = entry['messages'] as List<Map<String, dynamic>>;

            msgs.add({
              'id': m['id']?.toString() ?? '',
              'isMe': isMe,
              'sender': isMe ? 'Me' : supervisorName,
              'text': text,
              'time': relTime,
            });
            entry['lastMessage'] = text;
            entry['time'] = relTime;
            if (!isMe && m['is_read'] != true) {
              entry['unread'] = (entry['unread'] as int) + 1;
            }
          }

          _conversations = convMap.values.toList().reversed.toList();
          await _prefs?.setString(
            _kChatConversations,
            jsonEncode(_conversations),
          );
        } catch (e) {
          debugPrint('Error fetching messages: $e');
        }

        // 9. Support Tickets
        try {
          final ticketRows = await supabase
              .from('support_tickets')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false);

          _supportTickets = ticketRows.map((raw) {
            final t = Map<String, dynamic>.from(raw);
            return {
              'id': t['ticket_number']?.toString() ?? t['id']?.toString() ?? '',
              'dbId': t['id']?.toString() ?? '',
              'category': t['category']?.toString() ?? 'General',
              'subject': t['subject']?.toString() ?? '',
              'message': t['message']?.toString() ?? '',
              'email': t['user_email']?.toString() ?? _userEmail,
              'createdAt': t['created_at']?.toString() ?? '',
              'status': t['status']?.toString() ?? 'Open',
              'adminResponse': t['admin_response']?.toString(),
            };
          }).toList();
          await _prefs?.setString(
            _kSupportTickets,
            jsonEncode(_supportTickets),
          );
        } catch (e) {
          debugPrint('Error fetching support_tickets: $e');
        }

        // 11. User Settings
        try {
          final settingsRow = await supabase
              .from('user_settings')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();
          if (settingsRow != null) {
            final ps = settingsRow['privacy_settings'];
            if (ps is Map) {
              for (final e in ps.entries) {
                _privacySettings[e.key.toString()] = e.value == true;
              }
            }
            await _prefs?.setString(
              _kPrivacySettings,
              jsonEncode(_privacySettings),
            );
          }
        } catch (e) {
          debugPrint('Error fetching user_settings: $e');
        }

        // Persist refreshed profile/skills/session
        await _prefs?.setString(_kProfile, jsonEncode(_profile));
        await _prefs?.setStringList(_kSkills, _skills);
        await _prefs?.setString(_kUserName, _userName);
        await _prefs?.setString(_kUserEmail, _userEmail);
        await _prefs?.setString(_kUserRole, _userRole);
        await _prefs?.setString(_kUserId, _userId);
        await _prefs?.setBool(_kIsLoggedIn, _isLoggedIn);
      }
    } finally {
      _isSyncing = false;
      _safeNotifyListeners();
    }
  }

  /// Fetches active partner contacts for initiating real Supabase chats.
  /// For students: lists registered companies & active application companies.
  /// For companies: lists registered students & project applicants.
  Future<List<Map<String, dynamic>>> fetchAvailableChatContacts() async {
    final List<Map<String, dynamic>> contacts = [];
    final Set<String> seenIds = {};
    final isCompanyUser = _userRole.toLowerCase() == 'company';

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null) {
      if (isCompanyUser) {
        try {
          final rows = await supabase
              .from('students')
              .select(
                'id, user_id, full_name, university, degree, department, verification_status',
              )
              .order('full_name');
          for (final raw in rows) {
            final row = Map<String, dynamic>.from(raw);
            final uid = row['user_id']?.toString() ?? '';
            if (uid.isEmpty || uid == _userId || seenIds.contains(uid)) continue;
            seenIds.add(uid);
            final fullName = (row['full_name']?.toString().trim().isNotEmpty == true)
                ? row['full_name'].toString().trim()
                : 'Student';
            final university = row['university']?.toString().trim() ?? '';
            final degree = row['degree']?.toString().trim() ?? '';
            final department = row['department']?.toString().trim() ?? '';
            contacts.add({
              'userId': uid,
              'companyName': fullName,
              'supervisorName': [
                if (degree.isNotEmpty) degree,
                if (university.isNotEmpty) university,
              ].join(' • '),
              'industry': department.isNotEmpty ? department : university,
              'isVerified': row['verification_status'] == 'verified',
            });
          }
        } catch (e) {
          debugPrint('Error fetching student chat contacts: $e');
        }
      } else {
        try {
          final rows = await supabase
              .from('companies')
              .select(
                'id, user_id, company_name, contact_person, industry, verification_status',
              )
              .order('company_name');
          for (final raw in rows) {
            final row = Map<String, dynamic>.from(raw);
            final uid = row['user_id']?.toString() ?? '';
            if (uid.isEmpty || uid == _userId || seenIds.contains(uid)) continue;
            seenIds.add(uid);
            contacts.add({
              'userId': uid,
              'companyName': row['company_name']?.toString() ?? 'Company Partner',
              'supervisorName':
                  (row['contact_person']?.toString().trim().isNotEmpty == true)
                      ? row['contact_person'].toString().trim()
                      : (row['company_name']?.toString() ?? 'Team Lead'),
              'industry': row['industry']?.toString() ?? '',
              'isVerified': row['verification_status'] == 'verified',
            });
          }
        } catch (e) {
          debugPrint('Error fetching company chat contacts: $e');
        }
      }
    }

    if (!isCompanyUser) {
      // Fallback to companies discovered on loaded applications if needed
      for (final app in _applications) {
        final uid = app['companyUserId']?.toString() ?? '';
        final comp = app['company']?.toString() ?? '';
        if (comp.isEmpty) continue;
        final key = uid.isNotEmpty ? uid : comp.toLowerCase();
        if (seenIds.contains(key)) continue;
        seenIds.add(key);
        contacts.add({
          'userId': uid,
          'companyName': comp,
          'supervisorName': '$comp Team',
          'industry': 'Active Application',
          'isVerified': true,
        });
      }
    }

    return contacts;
  }

  String _formatDbDate(dynamic raw) {
    final dt = SupabaseHelper.parseDate(raw);
    if (dt == null) return SupabaseHelper.formatDate(DateTime.now());
    return SupabaseHelper.formatDate(dt);
  }

  // ===========================================================================
  // SAVED / BOOKMARKED PROJECTS
  // ===========================================================================

  List<Map<String, dynamic>> getSavedProjects() =>
      List.unmodifiable(_savedProjects);

  bool isProjectSaved(String projectId) {
    return _savedProjects
        .any((p) => p['id']?.toString() == projectId.toString());
  }

  Future<void> toggleSaveProject(Map<String, dynamic> project) async {
    final id = project['id']?.toString();
    if (id == null || id.isEmpty) return;

    final index = _savedProjects.indexWhere((p) => p['id']?.toString() == id);
    final bool wasSaved = index >= 0;
    if (wasSaved) {
      _savedProjects.removeAt(index);
    } else {
      _savedProjects.insert(0, Map<String, dynamic>.from(project));
    }

    _safeNotifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kSavedProjects, jsonEncode(_savedProjects));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null && SupabaseHelper.isUuid(id)) {
      try {
        if (wasSaved) {
          await supabase
              .from('saved_projects')
              .delete()
              .eq('user_id', user.id)
              .eq('project_id', id);
        } else {
          await supabase.from('saved_projects').upsert({
            'user_id': user.id,
            'project_id': id,
          }, onConflict: 'user_id,project_id');
        }
      } catch (e) {
        debugPrint('Supabase saved_projects sync error: $e');
      }
    }
  }

  Future<void> removeSavedProject(String projectId) async {
    _savedProjects.removeWhere((p) => p['id']?.toString() == projectId);
    _safeNotifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kSavedProjects, jsonEncode(_savedProjects));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null &&
        user != null &&
        SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('saved_projects')
            .delete()
            .eq('user_id', user.id)
            .eq('project_id', projectId);
      } catch (e) {
        debugPrint('Supabase remove saved_project error: $e');
      }
    }
  }

  // ===========================================================================
  // APPLICATIONS
  // ===========================================================================

  List<Map<String, dynamic>> getApplications() =>
      List.unmodifiable(_applications);

  bool hasApplied(String projectId) {
    return _applications
        .any((a) => a['projectId']?.toString() == projectId.toString());
  }

  Future<void> addApplication({
    required Map<String, dynamic> project,
    required String coverMessage,
    required String skills,
    required String availability,
    String? portfolioLink,
  }) async {
    final projectId = project['id']?.toString() ?? '';
    if (projectId.isNotEmpty && hasApplied(projectId)) return;

    final appId = SupabaseHelper.generateUuid();
    final companyName =
        project['company']?.toString() ?? project['company_name']?.toString() ?? 'Company';
    final projectTitle = project['title']?.toString() ?? 'Untitled Project';
    final companyUserId = project['companyUserId']?.toString() ?? '';

    final newApp = {
      'id': appId,
      'projectId': projectId,
      'title': projectTitle,
      'company': companyName,
      'companyUserId': companyUserId,
      'status': 'Pending',
      'appliedDate': _formattedDate(DateTime.now()),
      'timelineStep': 1,
      'coverMessage': coverMessage,
      'skills': skills,
      'availability': availability,
      'portfolioLink': portfolioLink ?? '',
      'companyFeedback': '',
      'progress': 0.0,
      'deadline': project['deadline']?.toString() ?? 'Flexible',
    };

    _applications.insert(0, newApp);
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kApplications, jsonEncode(_applications));
    }

    await _pushApplicationToSupabase(newApp, project);
  }

  Future<void> _pushApplicationToSupabase(
    Map<String, dynamic> app,
    Map<String, dynamic> project,
  ) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      final studentName =
          (_profile['name']?.toString().trim().isNotEmpty == true)
              ? _profile['name'].toString().trim()
              : (_userName.isNotEmpty
                  ? _userName
                  : (user.userMetadata?['name']?.toString() ?? 'Student'));
      final university =
          (_profile['university']?.toString().trim().isNotEmpty == true)
              ? _profile['university'].toString().trim()
              : (user.userMetadata?['university']?.toString() ?? '');
      final skillsList = SupabaseHelper.parseStringList(app['skills']);
      final projectId = project['id']?.toString();
      final companyId = project['companyId']?.toString();

      await supabase.from('applications').insert({
        'id': app['id'],
        if (SupabaseHelper.isUuid(projectId)) 'project_id': projectId,
        'project_title': app['title'],
        if (SupabaseHelper.isUuid(companyId)) 'company_id': companyId,
        'company_name': app['company'],
        'student_id': user.id,
        'user_id': user.id,
        'student_name': studentName,
        'student_email': _userEmail.isNotEmpty ? _userEmail : user.email,
        'university': university,
        'student_degree': _profile['degree']?.toString() ?? 'BS Computer Science',
        'student_department':
            _profile['department']?.toString() ?? 'Computer Science',
        'student_semester': _profile['semester']?.toString() ?? 'Senior',
        'student_cgpa': (_profile['cgpa'] as num?)?.toDouble() ?? 0.0,
        'skills': skillsList.isNotEmpty ? skillsList : _skills,
        'availability': app['availability'],
        'cover_letter': app['coverMessage'],
        'portfolio_link': app['portfolioLink'] ?? '',
        'resume_link': _profile['resumeUrl']?.toString() ?? '',
        'github_link': _profile['githubUrl']?.toString() ?? '',
        'status': 'Pending',
        'progress': 0.0,
      });
    } catch (e) {
      debugPrint('Supabase application insert failed: $e');
    }
  }

  // ===========================================================================
  // PROJECTS
  // ===========================================================================

  List<Map<String, dynamic>> getAllProjects() {
    return List.unmodifiable(_projects);
  }

  List<Map<String, dynamic>> getOpenProjects() {
    return _projects
        .where((p) {
          final status = (p['status']?.toString() ?? 'Open').toLowerCase();
          return status == 'open' || status == 'active';
        })
        .toList(growable: false);
  }

  Future<void> addProject(Map<String, dynamic> project) async {
    final existingId = project['id']?.toString() ?? '';
    final id = SupabaseHelper.isUuid(existingId)
        ? existingId
        : SupabaseHelper.generateUuid();
    final fullProject = {
      ...project,
      'id': id,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _projects.insert(0, fullProject);
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kCustomProjects, jsonEncode(_projects));
    }

    await _pushProjectToSupabase(fullProject);
  }

  Future<void> _pushProjectToSupabase(Map<String, dynamic> p) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;

    try {
      await supabase.from('projects').insert({
        'id': p['id'],
        'title': p['title'],
        'description': p['description'] ?? '',
        'requirements': p['requirements'] ?? '',
        'deliverables': p['deliverables'] ?? '',
        'category': p['category'] ?? 'Development',
        'work_mode': p['workMode'] ?? 'Remote',
        'duration': p['duration'] ?? '3-4 Weeks',
        'deadline': p['deadline'] ?? 'Flexible',
        'openings': p['openings'] ?? 1,
        'skills': SupabaseHelper.parseStringList(p['skills']),
        'stipend': p['stipend'] ?? p['budget'] ?? 'Competitive',
        'budget': p['budget'] ?? p['stipend'] ?? 'Competitive',
        'company_name': p['company'] ?? p['company_name'] ?? 'Company',
        'status': p['status'] ?? 'Open',
        'posted_by': user.id,
        'user_id': user.id,
      });
    } catch (e) {
      debugPrint('Supabase addProject failed: $e');
    }
  }

  // ===========================================================================
  // WORK SUBMISSIONS
  // ===========================================================================

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

    final appIndex = _applications.indexWhere((a) => a['projectId'] == projectId);
    if (appIndex >= 0) {
      _applications[appIndex]['status'] = 'Under Review';
      _applications[appIndex]['progress'] = 0.85;
    }

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kSubmissions, jsonEncode(_workSubmissions));
      await _prefs!.setString(_kApplications, jsonEncode(_applications));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('applications')
            .update({
              'submission_title': 'Deliverable: $projectTitle',
              'submission_notes': summary,
              'submitted_work_url': workLink,
              'file_name': fileName,
              'status': 'Under Review',
              'progress': 0.85,
              'work_submitted_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('project_id', projectId)
            .eq('student_id', user.id);
      } catch (e) {
        debugPrint('Supabase work submission sync failed: $e');
      }
    }
  }

  // ===========================================================================
  // PROFILE & SKILLS
  // ===========================================================================

  Map<String, dynamic> getProfile() => Map.unmodifiable(_profile);

  Future<void> updateProfile(Map<String, dynamic> updatedFields) async {
    bool hasChanged = false;
    updatedFields.forEach((key, val) {
      if (_profile[key] != val) {
        _profile[key] = val;
        hasChanged = true;
      }
    });

    if (!hasChanged) return;

    if (updatedFields['name'] != null &&
        updatedFields['name'].toString().trim().isNotEmpty) {
      _userName = updatedFields['name'].toString().trim();
    }
    if (updatedFields['email'] != null &&
        updatedFields['email'].toString().trim().isNotEmpty) {
      _userEmail = updatedFields['email'].toString().trim();
    }

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
      if (_userName.isNotEmpty) await _prefs!.setString(_kUserName, _userName);
      if (_userEmail.isNotEmpty) {
        await _prefs!.setString(_kUserEmail, _userEmail);
      }
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'name': _profile['name'] ?? _userName,
          'email': _profile['email'] ?? _userEmail,
          'user_type': _userRole,
          'university': _profile['university'] ?? '',
          'department': _profile['department'] ?? '',
          'degree': _profile['degree'] ?? '',
          'semester': _profile['semester'] ?? '',
          if (_profile['cgpa'] != null)
            'cgpa': double.tryParse(_profile['cgpa'].toString()) ?? 0.0,
          'phone': _profile['phone'] ?? '',
          'bio': _profile['bio'] ?? '',
          if (_profile['avatarUrl'] != null)
            'avatar_url': _profile['avatarUrl'],
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (_userRole.toLowerCase() == 'student') {
          final existing = await supabase
              .from('students')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

          final studentPayload = {
            'full_name': _profile['name'] ?? _userName,
            'email': _profile['email'] ?? _userEmail,
            'phone': _profile['phone'] ?? '',
            'university': _profile['university'] ?? '',
            'department': _profile['department'] ?? '',
            'degree': _profile['degree'] ?? '',
            'semester': _profile['semester'] ?? '',
            if (_profile['cgpa'] != null)
              'cgpa': double.tryParse(_profile['cgpa'].toString()) ?? 0.0,
            'bio': _profile['bio'] ?? '',
            'github_url': _profile['githubUrl'] ?? '',
            'portfolio_url': _profile['portfolioUrl'] ?? '',
            'resume_url': _profile['resumeUrl'] ?? '',
            'skills': _skills,
            'updated_at': DateTime.now().toIso8601String(),
          };

          if (existing != null) {
            await supabase
                .from('students')
                .update(studentPayload)
                .eq('user_id', user.id);
          } else {
            await supabase.from('students').insert({
              'user_id': user.id,
              ...studentPayload,
            });
          }
        }
      } catch (e) {
        debugPrint('Supabase profile update failed: $e');
      }
    }
  }

  List<String> getSkills() => List.unmodifiable(_skills);

  Future<void> addSkill(String skill) async {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || _skills.contains(trimmed)) return;

    _skills.add(trimmed);
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setStringList(_kSkills, _skills);
    }
    await _syncSkillsToSupabase();
  }

  Future<void> removeSkill(String skill) async {
    _skills.remove(skill);
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setStringList(_kSkills, _skills);
    }
    await _syncSkillsToSupabase();
  }

  Future<void> _syncSkillsToSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;
    try {
      await supabase.from('students').update({
        'skills': _skills,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);
    } catch (e) {
      debugPrint('Supabase skills sync failed: $e');
    }
  }

  // ===========================================================================
  // PROFILE AVATAR & PRIVACY PREFERENCES
  // ===========================================================================

  /// Stores the chosen profile image locally (instant UI + offline fallback)
  /// and uploads it to Supabase Storage + `public.profiles.avatar_url`.
  Future<String?> updateStudentAvatar(
    Uint8List bytes, {
    String fileExtension = 'jpg',
  }) async {
    final cleanExt =
        fileExtension.toLowerCase().replaceAll('.', '').isNotEmpty
            ? fileExtension.toLowerCase().replaceAll('.', '')
            : 'jpg';
    final mimeType = cleanExt == 'png'
        ? 'image/png'
        : (cleanExt == 'webp' ? 'image/webp' : 'image/jpeg');

    _profile['avatarBase64'] = base64Encode(bytes);
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return null;

    final fileName =
        'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

    String? uploadedUrl;
    for (final bucket in const ['student-docs', 'public-files']) {
      try {
        await supabase.storage.from(bucket).uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: mimeType,
              ),
            );
        uploadedUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
        break;
      } catch (e) {
        debugPrint('Avatar upload attempt on $bucket warning: $e');
      }
    }

    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
      _profile['avatarUrl'] = uploadedUrl;
      _safeNotifyListeners();
      if (_prefs != null) {
        await _prefs!.setString(_kProfile, jsonEncode(_profile));
      }
      try {
        await supabase.from('profiles').update({
          'avatar_url': uploadedUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      } catch (e) {
        debugPrint('Supabase profile avatar_url update warning: $e');
      }
    }
    return uploadedUrl;
  }

  /// Removes the student's profile photo locally and in Supabase `profiles`.
  Future<void> removeStudentAvatar() async {
    _profile.remove('avatarBase64');
    _profile['avatarUrl'] = null;
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        await supabase.from('profiles').update({
          'avatar_url': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      } catch (e) {
        debugPrint('Supabase profile avatar remove warning: $e');
      }
    }
  }

  Map<String, bool> getPrivacySettings() =>
      Map.unmodifiable(_privacySettings);

  Future<void> updatePrivacySetting(String key, bool value) async {
    _privacySettings[key] = value;
    _safeNotifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kPrivacySettings, jsonEncode(_privacySettings));
    }
    await _syncSettingsToSupabase();
  }

  Future<void> _syncSettingsToSupabase() async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) return;
    try {
      await supabase.from('user_settings').upsert({
        'user_id': user.id,
        'privacy_settings': _privacySettings,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase user_settings upsert failed: $e');
    }
  }

  // ===========================================================================
  // CHAT & MESSAGING (REAL PERSISTENCE ONLY — ZERO SIMULATED REPLIES)
  // ===========================================================================

  List<Map<String, dynamic>> getConversations() =>
      List.unmodifiable(_conversations);

  Map<String, dynamic>? getConversation(String id) {
    try {
      return _conversations.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  /// Opens an existing conversation thread with a company/peer or creates one cleanly.
  Future<String> openOrCreateConversation({
    required String companyName,
    String? peerUserId,
    String? supervisorName,
    String? projectTitle,
  }) async {
    final cleanPeerId = (peerUserId ?? '').trim();
    final existing = _conversations.firstWhere(
      (c) {
        if (cleanPeerId.isNotEmpty && c['peerUserId'] == cleanPeerId) {
          return true;
        }
        return (c['company']?.toString().toLowerCase() ?? '') ==
            companyName.trim().toLowerCase();
      },
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      return existing['id'].toString();
    }

    final myId = SupabaseHelper.currentUserId ?? _userId;
    final convId = (SupabaseHelper.isUuid(myId) &&
            SupabaseHelper.isUuid(cleanPeerId))
        ? 'conv_${myId}_$cleanPeerId'
        : 'conv_${DateTime.now().millisecondsSinceEpoch}';

    final newConv = <String, dynamic>{
      'id': convId,
      'peerUserId': cleanPeerId,
      'company': companyName.trim().isNotEmpty ? companyName.trim() : 'Partner',
      'supervisor':
          (supervisorName != null && supervisorName.trim().isNotEmpty)
              ? supervisorName.trim()
              : companyName.trim(),
      'projectTitle': projectTitle ?? '',
      'lastMessage': 'No messages yet',
      'time': 'Now',
      'unread': 0,
      'messages': <Map<String, dynamic>>[],
    };

    _conversations.insert(0, newConv);
    _safeNotifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kChatConversations, jsonEncode(_conversations));
    }
    return convId;
  }

  Future<void> markConversationRead(String conversationId) async {
    final conv = _conversations.firstWhere(
      (c) => c['id'] == conversationId,
      orElse: () => {},
    );
    if (conv.isNotEmpty && ((conv['unread'] as int? ?? 0) > 0)) {
      conv['unread'] = 0;
      _safeNotifyListeners();
      if (_prefs != null) {
        await _prefs!.setString(
          _kChatConversations,
          jsonEncode(_conversations),
        );
      }

      final supabase = SupabaseHelper.clientOrNull;
      final user = supabase?.auth.currentUser;
      if (supabase != null && user != null) {
        try {
          await supabase
              .from('messages')
              .update({'is_read': true})
              .eq('conversation_id', conversationId)
              .eq('receiver_id', user.id);
        } catch (_) {}
      }
    }
  }

  Future<void> sendChatMessage({
    required String conversationId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final conv = _conversations.firstWhere(
      (c) => c['id'] == conversationId,
      orElse: () => {},
    );
    if (conv.isEmpty) return;

    const nowTime = 'Just now';
    final senderName = _profile['name']?.toString().isNotEmpty == true
        ? _profile['name'].toString()
        : (_userName.isNotEmpty ? _userName : 'Me');
    final userMsg = {
      'id': SupabaseHelper.generateUuid(),
      'isMe': true,
      'sender': senderName,
      'text': cleanText,
      'time': nowTime,
    };

    final List<Map<String, dynamic>> msgs =
        List<Map<String, dynamic>>.from(conv['messages'] as List? ?? []);
    msgs.add(userMsg);
    conv['messages'] = msgs;
    conv['lastMessage'] = cleanText;
    conv['time'] = nowTime;

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kChatConversations, jsonEncode(_conversations));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      final peerUserId = conv['peerUserId']?.toString();
      try {
        await supabase.from('messages').insert({
          'id': userMsg['id'],
          'conversation_id': conversationId,
          'sender_id': user.id,
          if (SupabaseHelper.isUuid(peerUserId)) 'receiver_id': peerUserId,
          'sender_name': senderName,
          'receiver_name': conv['supervisor'] ?? conv['company'] ?? 'Partner',
          'company_name': _userRole.toLowerCase() == 'company'
              ? senderName
              : (conv['company'] ?? ''),
          'project_title': conv['projectTitle'] ?? '',
          'message_text': cleanText,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });

      } catch (e) {
        debugPrint('Supabase message insert error: $e');
      }
    }
  }

  // ===========================================================================
  // SUPPORT TICKETS
  // ===========================================================================

  List<Map<String, dynamic>> getSupportTickets() =>
      List.unmodifiable(_supportTickets);

  Future<void> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    final ticketNumber = 'CC-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final ticketEmail =
        _userEmail.isNotEmpty ? _userEmail : (_profile['email']?.toString() ?? '');
    final ticket = {
      'id': ticketNumber,
      'category': category,
      'subject': subject,
      'message': message,
      'email': ticketEmail,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'Open',
    };

    _supportTickets.insert(0, ticket);

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kSupportTickets, jsonEncode(_supportTickets));
    }

    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase != null && user != null) {
      try {
        await supabase.from('support_tickets').insert({
          'ticket_number': ticketNumber,
          'user_id': user.id,
          'user_name': _userName.isNotEmpty
              ? _userName
              : (_profile['name']?.toString() ?? 'User'),
          'user_email': ticketEmail,
          'user_role': _userRole,
          'category': category,
          'subject': subject,
          'message': message,
          'status': 'Open',
        });
      } catch (e) {
        debugPrint('Supabase support ticket sync error: $e');
      }
    }
  }

  // ===========================================================================
  // AUTH SESSION MANAGEMENT
  // ===========================================================================

  bool get isLoggedIn {
    if (_isLoggedIn) return true;
    return SupabaseHelper.currentUser != null;
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
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      _profile['email'] = email;
    }
    if (name != null && name.isNotEmpty) {
      _userName = name;
      _profile['name'] = name;
    }
    if (userId != null && userId.isNotEmpty) _userId = userId;
    if (university != null && university.isNotEmpty) {
      _profile['university'] = university;
    }

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setBool(_kIsLoggedIn, true);
      await _prefs!.setString(_kUserRole, _userRole);
      if (_userEmail.isNotEmpty) await _prefs!.setString(_kUserEmail, _userEmail);
      if (_userName.isNotEmpty) await _prefs!.setString(_kUserName, _userName);
      if (_userId.isNotEmpty) await _prefs!.setString(_kUserId, _userId);
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
    }
  }

  Future<void> savePendingAuthContext({
    required String flow,
    String? email,
    String? role,
  }) async {
    SupabaseHelper.setPendingAuthContext(
      flow: flow,
      email: email,
      role: role,
    );
    if (_prefs != null) {
      await _prefs!.setString(_kPendingAuthFlow, flow);
      if (email != null && email.trim().isNotEmpty) {
        await _prefs!.setString(_kPendingAuthEmail, email.trim());
      }
      if (role != null && role.trim().isNotEmpty) {
        await _prefs!.setString(_kPendingAuthRole, role.trim());
      }
    }
  }

  Future<void> clearPendingAuthContext() async {
    SupabaseHelper.pendingAuthFlow = null;
    SupabaseHelper.pendingAuthEmail = null;
    SupabaseHelper.pendingAuthRole = null;
    if (_prefs != null) {
      await _prefs!.remove(_kPendingAuthFlow);
      await _prefs!.remove(_kPendingAuthEmail);
      await _prefs!.remove(_kPendingAuthRole);
    }
  }

  /// Clears all user-scoped state & preferences so switching accounts never leaks data.
  Future<void> clearAuthSession() async {
    _isLoggedIn = false;
    _isSyncing = false;
    _lastSyncError = null;
    _userRole = 'Student';
    _userEmail = '';
    _userName = '';
    _userId = '';
    SupabaseHelper.clearAuthFlags();

    _savedProjects = [];
    _applications = [];
    _workSubmissions = {};
    _profile = {};
    _skills = [];
    _certificates = [];
    _conversations = [];
    _supportTickets = [];
    _privacySettings
      ..clear()
      ..addAll(_defaultPrivacySettings);

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setBool(_kIsLoggedIn, false);
      await _prefs!.remove(_kUserRole);
      await _prefs!.remove(_kUserEmail);
      await _prefs!.remove(_kUserName);
      await _prefs!.remove(_kUserId);
      await _prefs!.remove(_kSavedProjects);
      await _prefs!.remove(_kApplications);
      await _prefs!.remove(_kSubmissions);
      await _prefs!.remove(_kProfile);
      await _prefs!.remove(_kSkills);
      await _prefs!.remove(_kCertificates);
      await _prefs!.remove(_kChatConversations);
      await _prefs!.remove(_kSupportTickets);
      await _prefs!.remove(_kPrivacySettings);
      await _prefs!.remove(_kPendingAuthFlow);
      await _prefs!.remove(_kPendingAuthEmail);
      await _prefs!.remove(_kPendingAuthRole);
    }
  }

  // ===========================================================================
  // LOCAL OFFLINE USER REGISTRY (FOR UNIT TESTS / OFFLINE FORM PERSISTENCE)
  // ===========================================================================

  Future<void> registerUserAccount({
    required String email,
    required String password,
    required String name,
    required String university,
    required String role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanUni = university.trim();
    final cleanPass = password.trim();

    _userAccounts[cleanEmail] = {
      'email': cleanEmail,
      'password': cleanPass,
      'name': cleanName,
      'university': cleanUni,
      'role': role,
    };

    _userName = cleanName;
    _userEmail = cleanEmail;
    _userRole = role;
    _profile['name'] = cleanName;
    _profile['email'] = cleanEmail;
    _profile['university'] = cleanUni;

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kUserAccounts, jsonEncode(_userAccounts));
      await _prefs!.setString(_kProfile, jsonEncode(_profile));
      await _prefs!.setString(_kUserName, _userName);
      await _prefs!.setString(_kUserEmail, _userEmail);
      await _prefs!.setString(_kUserRole, _userRole);
      await _prefs!.setBool(_kIsLoggedIn, true);
    }
  }

  Map<String, dynamic>? findUserAccount(String email) {
    final cleanEmail = email.trim().toLowerCase();
    return _userAccounts[cleanEmail];
  }

  bool verifyLocalCredentials(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    final acc = _userAccounts[cleanEmail];
    if (acc != null && acc['password'] == cleanPass) {
      return true;
    }
    return false;
  }

  Future<void> updateAccountPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = newPassword.trim();

    if (_userAccounts.containsKey(cleanEmail)) {
      _userAccounts[cleanEmail]!['password'] = cleanPass;
    } else {
      _userAccounts[cleanEmail] = {
        'email': cleanEmail,
        'password': cleanPass,
        'name': _userName.isNotEmpty
            ? _userName
            : (_profile['name']?.toString() ?? 'Student'),
        'university': _profile['university']?.toString() ?? '',
        'role': _userRole,
      };
    }

    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kUserAccounts, jsonEncode(_userAccounts));
    }
  }

  Future<void> removeUserAccount(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;

    _userAccounts.remove(cleanEmail);
    _safeNotifyListeners();

    if (_prefs != null) {
      await _prefs!.setString(_kUserAccounts, jsonEncode(_userAccounts));
    }
  }

  // ===========================================================================
  // CERTIFICATES
  // ===========================================================================

  List<Map<String, dynamic>> getCertificates() =>
      List.unmodifiable(_certificates);

  Future<void> addCertificate(Map<String, dynamic> cert) async {
    _certificates.insert(0, cert);
    _safeNotifyListeners();
    if (_prefs != null) {
      await _prefs!.setString(_kCertificates, jsonEncode(_certificates));
    }
  }

  // ===========================================================================
  // STATS
  // ===========================================================================

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

  int get certificatesCount =>
      _certificates.where((c) => c['status'] != 'revoked').length;

  String _formattedDate(DateTime dt) => SupabaseHelper.formatDate(dt);
}
