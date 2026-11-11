import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/presentation/screens/company_project_detail_screen.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/student/applications/presentation/screens/my_applications_screen.dart';
import 'package:link_vibe/feature/student/certificates/presentation/screens/certificates_screen.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

enum AppLinkType { project, application, certificate }

class ParsedAppLink {
  final AppLinkType type;
  final String id;
  final String? projectId;
  final String? title;
  final Uri rawUri;

  const ParsedAppLink({
    required this.type,
    required this.id,
    this.projectId,
    this.title,
    required this.rawUri,
  });
}

/// Handles incoming SkillBridge deep links (`skillbridge://project/<id>`,
/// `skillbridge://application/<id>`, `skillbridge://certificate/<id>`) and opens
/// the corresponding screen directly inside the app.
class DeepLinkService {
  DeepLinkService._internal() {
    ShareService.deepLinkOpener = (raw, {context}) =>
        openUriString(raw, context: context);
  }

  static final DeepLinkService instance = DeepLinkService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;
  bool _workspaceReady = false;
  Uri? _pendingUri;
  String? _lastHandledKey;
  DateTime? _lastHandledAt;

  bool get hasPendingLink => _pendingUri != null;
  Uri? get pendingUri => _pendingUri;

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    ShareService.deepLinkOpener = (raw, {context}) =>
        openUriString(raw, context: context);
  }

  static String _slugify(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Parses custom scheme (`skillbridge://...`) or path-based deep links into a
  /// typed target. Ignores Supabase auth/OAuth callback URLs.
  static ParsedAppLink? parseUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (host == 'login-callback' ||
        uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('refresh_token') ||
        uri.queryParameters.containsKey('code')) {
      return null;
    }

    final rawSegments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    late final List<String> segments;

    if (scheme == ShareService.appScheme) {
      if (host.isNotEmpty && host != 'open' && host != 'app') {
        segments = [host, ...rawSegments];
      } else {
        segments = rawSegments;
      }
    } else if (scheme == 'http' || scheme == 'https') {
      segments = rawSegments;
    } else {
      return null;
    }

    if (segments.isEmpty) return null;

    final first = segments.first.toLowerCase();
    AppLinkType? type;
    String rawId = '';

    if (first == 'project' || first == 'projects') {
      type = AppLinkType.project;
      rawId = segments.length > 1
          ? segments[1]
          : (uri.queryParameters['id'] ?? uri.queryParameters['projectId'] ?? '');
    } else if (first == 'application' || first == 'applications') {
      type = AppLinkType.application;
      rawId = segments.length > 1
          ? segments[1]
          : (uri.queryParameters['id'] ??
              uri.queryParameters['applicationId'] ??
              '');
    } else if (first == 'certificate' || first == 'certificates') {
      type = AppLinkType.certificate;
      rawId = segments.length > 1
          ? segments[1]
          : (uri.queryParameters['id'] ??
              uri.queryParameters['certificateId'] ??
              '');
    } else if (first == 'verify') {
      type = AppLinkType.certificate;
      if (segments.length > 2 &&
          (segments[1].toLowerCase() == 'certificate' ||
              segments[1].toLowerCase() == 'certificates')) {
        rawId = segments[2];
      } else if (segments.length > 1) {
        rawId = segments[1];
      } else {
        rawId = uri.queryParameters['id'] ?? '';
      }
    }

    if (type == null) return null;

    String cleanId;
    try {
      cleanId = Uri.decodeComponent(rawId).trim();
    } catch (_) {
      cleanId = rawId.trim();
    }
    if (cleanId.isEmpty) return null;

    final projectId = uri.queryParameters['projectId']?.trim();
    final title = uri.queryParameters['title']?.trim();

    return ParsedAppLink(
      type: type,
      id: cleanId,
      projectId: (projectId != null && projectId.isNotEmpty) ? projectId : null,
      title: (title != null && title.isNotEmpty) ? title : null,
      rawUri: uri,
    );
  }

  /// Initializes cold-start & warm-stream listeners for incoming app links.
  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (navigatorKey != null) {
      attachNavigatorKey(navigatorKey);
    } else {
      ShareService.deepLinkOpener = (raw, {context}) =>
          openUriString(raw, context: context);
    }

    if (_initialized) return;
    _initialized = true;

    try {
      final appLinks = AppLinks();
      _linkSubscription = appLinks.uriLinkStream.listen(
        (uri) => unawaited(_handleIncomingUri(uri)),
        onError: (Object err) {
          debugPrint('DeepLinkService stream warning: $err');
        },
      );

      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null && parseUri(initialUri) != null) {
        _pendingUri = initialUri;
      }
    } catch (e) {
      debugPrint('DeepLinkService init skipped: $e');
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    final parsed = parseUri(uri);
    if (parsed == null) return;

    final key = uri.toString();
    final now = DateTime.now();
    if (_lastHandledKey == key &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastHandledKey = key;
    _lastHandledAt = now;

    if (_workspaceReady && _navigatorKey?.currentState != null) {
      await openUri(uri);
    } else {
      _pendingUri = uri;
    }
  }

  /// Marks navigation tree ready after SplashScreen and opens any queued link.
  Future<void> markWorkspaceReadyAndConsume() async {
    _workspaceReady = true;
    await consumePendingLink();
  }

  Future<void> consumePendingLink() async {
    final uri = _pendingUri;
    if (uri == null) return;

    final nav = _navigatorKey?.currentState;
    if (nav == null || !nav.mounted) return;

    _pendingUri = null;
    await openUri(uri);
  }

  Future<bool> openUriString(String raw, {BuildContext? context}) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return false;
    return openUri(uri, context: context);
  }

  /// Resolves and opens the target Project, Application, or Certificate inside
  /// the SkillBridge app.
  Future<bool> openUri(Uri uri, {BuildContext? context}) async {
    final parsed = parseUri(uri);
    if (parsed == null) return false;

    final nav = (context != null && context.mounted)
        ? Navigator.of(context)
        : _navigatorKey?.currentState;
    if (nav == null || !nav.mounted) {
      _pendingUri = uri;
      return false;
    }

    switch (parsed.type) {
      case AppLinkType.project:
        return _openProject(nav, parsed.id, titleHint: parsed.title);
      case AppLinkType.application:
        return _openApplication(nav, parsed);
      case AppLinkType.certificate:
        return _openCertificate(nav, parsed.id);
    }
  }

  Future<bool> _openProject(
    NavigatorState nav,
    String id, {
    String? titleHint,
  }) async {
    final role = AppDataService.instance.userRole.toLowerCase();
    if (role == 'company') {
      final own = _findCompanyProject(id, titleHint: titleHint);
      if (own != null && nav.mounted) {
        unawaited(
          nav.push(
            MaterialPageRoute(
              builder: (_) => CompanyProjectDetailScreen(project: own),
            ),
          ),
        );
        return true;
      }
    }

    var project = _findLocalProject(id, titleHint: titleHint);
    project ??= await _fetchRemoteProject(id, titleHint: titleHint);

    if (!nav.mounted) return false;

    if (project == null) {
      _showNotice(nav.context, 'Project could not be found in SkillBridge.');
      return false;
    }

    unawaited(
      nav.push(
        MaterialPageRoute(
          builder: (_) => StudentProjectDetailsScreen(project: project!),
        ),
      ),
    );
    return true;
  }

  ProjectModel? _findCompanyProject(String id, {String? titleHint}) {
    final targetLower = id.trim().toLowerCase();
    for (final p in CompanyProjectService().allProjects) {
      if (p.id.trim().toLowerCase() == targetLower ||
          _slugify(p.title) == targetLower ||
          (titleHint != null &&
              p.title.trim().toLowerCase() == titleHint.trim().toLowerCase())) {
        return p;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findLocalProject(String id, {String? titleHint}) {
    final targetLower = id.trim().toLowerCase();
    final combined = <Map<String, dynamic>>[
      ...AppDataService.instance.getAllProjects(),
      ...AppDataService.instance.getSavedProjects(),
    ];

    for (final p in combined) {
      final pId = (p['id'] ?? p['projectId'] ?? '').toString().trim();
      final pTitle = (p['title'] ?? '').toString().trim();
      if (pId.toLowerCase() == targetLower ||
          _slugify(pTitle) == targetLower ||
          (titleHint != null &&
              pTitle.toLowerCase() == titleHint.trim().toLowerCase())) {
        return p;
      }
    }

    final compModel = _findCompanyProject(id, titleHint: titleHint);
    if (compModel != null) {
      return _mapCompanyProjectModel(compModel);
    }
    return null;
  }

  Map<String, dynamic> _mapCompanyProjectModel(ProjectModel p) {
    return {
      'id': p.id,
      'title': p.title,
      'company': p.companyName.isNotEmpty ? p.companyName : 'Partner Company',
      'companyId': p.companyId,
      'category': p.category,
      'duration': p.duration,
      'workMode': p.projectType,
      'deadline': p.deadline,
      'status': p.status,
      'stipend': p.budget.isNotEmpty
          ? p.budget
          : 'Academic Credit / Verified Certificate',
      'budget': p.budget,
      'description': p.description,
      'requirements': p.requirements,
      'deliverables': p.deliverables,
      'additionalInstructions': p.additionalInstructions,
      'openings': p.openings,
      'skills': p.skillsRequired,
      'createdAt': p.createdAt,
    };
  }

  Future<Map<String, dynamic>?> _fetchRemoteProject(
    String id, {
    String? titleHint,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return null;

    try {
      if (SupabaseHelper.isUuid(id)) {
        final raw = await supabase
            .from('projects')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (raw != null) {
          final p = Map<String, dynamic>.from(raw);
          Map<String, dynamic>? comp;
          final compId = p['company_id']?.toString() ?? '';
          final postedBy =
              p['posted_by']?.toString() ?? p['user_id']?.toString() ?? '';
          try {
            if (SupabaseHelper.isUuid(compId)) {
              comp = await supabase
                  .from('companies')
                  .select('id, company_name, verification_status')
                  .eq('id', compId)
                  .maybeSingle();
            } else if (SupabaseHelper.isUuid(postedBy)) {
              comp = await supabase
                  .from('companies')
                  .select('id, company_name, verification_status')
                  .eq('user_id', postedBy)
                  .maybeSingle();
            }
          } catch (_) {}

          final stipend = (p['stipend']?.toString().trim().isNotEmpty == true)
              ? p['stipend'].toString()
              : (p['budget']?.toString().trim().isNotEmpty == true
                  ? p['budget'].toString()
                  : 'Academic Credit / Verified Certificate');

          return {
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
            'status': p['status']?.toString() ?? 'Open',
            'stipend': stipend,
            'budget': p['budget']?.toString() ?? stipend,
            'description': p['description']?.toString() ?? '',
            'requirements': p['requirements']?.toString() ?? '',
            'deliverables': p['deliverables']?.toString() ?? '',
            'additionalInstructions':
                p['additional_instructions']?.toString() ?? '',
            'openings': p['openings'] ?? 1,
            'skills': SupabaseHelper.parseStringList(p['skills']),
            'isVerified':
                (comp?['verification_status']?.toString() ?? '') == 'verified',
            'attachmentUrl': p['attachment_url']?.toString(),
            'createdAt': p['created_at']?.toString() ?? '',
          };
        }
      }

      await AppDataService.instance.syncFromSupabase(forceRefresh: true);
      return _findLocalProject(id, titleHint: titleHint);
    } catch (e) {
      debugPrint('DeepLinkService project fetch warning: $e');
      return null;
    }
  }

  Future<bool> _openApplication(
    NavigatorState nav,
    ParsedAppLink parsed,
  ) async {
    Map<String, dynamic>? app = _findLocalApplication(
      parsed.id,
      projectId: parsed.projectId,
    );

    if (app == null && SupabaseHelper.clientOrNull != null) {
      await AppDataService.instance.syncFromSupabase(forceRefresh: true);
      app = _findLocalApplication(parsed.id, projectId: parsed.projectId);
    }

    if (!nav.mounted) return false;

    if (app != null) {
      MyApplicationsScreen.showApplicationDetailsSheet(nav.context, app);
      return true;
    }

    // If a shared application belongs to another account, fall back to opening
    // the associated project so the recipient still lands inside SkillBridge.
    final fallbackProjectId = parsed.projectId ?? parsed.id;
    if (fallbackProjectId.isNotEmpty) {
      final openedProject = await _openProject(nav, fallbackProjectId);
      if (openedProject) return true;
    }

    if (nav.mounted) {
      _showNotice(nav.context, 'Application record could not be found.');
    }
    return false;
  }

  Map<String, dynamic>? _findLocalApplication(
    String id, {
    String? projectId,
  }) {
    final targetLower = id.trim().toLowerCase();
    final projLower = projectId?.trim().toLowerCase();
    for (final a in AppDataService.instance.getApplications()) {
      final aId = (a['id'] ?? '').toString().trim().toLowerCase();
      final aProjId = (a['projectId'] ?? '').toString().trim().toLowerCase();
      final aTitleSlug = _slugify(a['title']?.toString() ?? '');
      if (aId == targetLower ||
          aProjId == targetLower ||
          aTitleSlug == targetLower ||
          (projLower != null && aProjId == projLower)) {
        return a;
      }
    }
    return null;
  }

  Future<bool> _openCertificate(NavigatorState nav, String id) async {
    Map<String, dynamic>? cert = _findLocalCertificate(id);
    cert ??= await _fetchRemoteCertificate(id);

    if (!nav.mounted) return false;

    if (cert == null) {
      _showNotice(nav.context, 'Certificate credential could not be found.');
      return false;
    }

    CertificatesScreen.showCertificateDialog(nav.context, cert);
    return true;
  }

  Map<String, dynamic>? _findLocalCertificate(String id) {
    final targetLower = id.trim().toLowerCase();
    for (final c in AppDataService.instance.getCertificates()) {
      final cId = (c['id'] ?? '').toString().trim().toLowerCase();
      final dbId = (c['dbId'] ?? '').toString().trim().toLowerCase();
      if (cId == targetLower || dbId == targetLower) {
        return c;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchRemoteCertificate(String id) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) return null;

    try {
      final query = SupabaseHelper.isUuid(id)
          ? supabase
              .from('certificates')
              .select()
              .or('certificate_id.eq.$id,id.eq.$id')
              .limit(1)
              .maybeSingle()
          : supabase
              .from('certificates')
              .select()
              .eq('certificate_id', id)
              .limit(1)
              .maybeSingle();

      final raw = await query;
      if (raw == null) return null;

      final c = Map<String, dynamic>.from(raw);
      return {
        'id': c['certificate_id']?.toString() ?? c['id']?.toString() ?? id,
        'dbId': c['id']?.toString() ?? '',
        'studentName': c['student_name']?.toString() ?? '',
        'title': c['certificate_title']?.toString() ??
            'Certificate of Project Completion',
        'project': c['project_title']?.toString() ?? 'Corporate Sprint',
        'issuer': c['issuer']?.toString() ??
            c['company_name']?.toString() ??
            'SkillBridge Partner',
        'companyName': c['company_name']?.toString() ?? '',
        'date': c['issue_date']?.toString() ?? 'Issued',
        'status': c['status']?.toString() ?? 'valid',
        'rating': (c['overall_rating'] as num?)?.toDouble() ?? 5.0,
        'recommendation': c['recommendation_letter']?.toString() ?? '',
        'hash': c['cryptographic_hash']?.toString() ?? '',
        'verificationUrl': c['verification_url']?.toString() ?? '',
        'pdfUrl': c['pdf_url']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('DeepLinkService certificate fetch warning: $e');
      return null;
    }
  }

  void _showNotice(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @visibleForTesting
  Future<void> handleIncomingUriForTest(Uri uri) => _handleIncomingUri(uri);

  @visibleForTesting
  void resetForTest() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
    _workspaceReady = false;
    _pendingUri = null;
    _lastHandledKey = null;
    _lastHandledAt = null;
  }
}

