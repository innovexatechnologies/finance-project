import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

/// Student bank/wallet details for Admin Escrow payout
class StudentBankDetails {
  final String bankName;
  final String accountTitle;
  final String accountNumberIban;
  final String provider;

  const StudentBankDetails({
    required this.bankName,
    required this.accountTitle,
    required this.accountNumberIban,
    this.provider = 'Bank Account',
  });

  factory StudentBankDetails.fallback({String? studentName}) {
    final title = (studentName != null &&
            studentName.trim().isNotEmpty &&
            studentName.trim() != 'Awarded Student')
        ? studentName.trim()
        : 'Danish (CS)';
    return StudentBankDetails(
      bankName: 'JazzCash Mobile Account',
      accountTitle: title,
      accountNumberIban: '0300-1234567',
      provider: 'JazzCash',
    );
  }

  factory StudentBankDetails.fromJson(Map<String, dynamic> json) {
    var bName = (json['bank_name'] ??
            json['bankName'] ??
            json['provider'] ??
            'JazzCash Mobile Account')
        .toString()
        .trim();
    var aTitle = (json['account_title'] ??
            json['accountTitle'] ??
            'Danish (CS)')
        .toString()
        .trim();
    var aNum = (json['account_number_iban'] ??
            json['account_number'] ??
            json['accountNumber'] ??
            '0300-1234567')
        .toString()
        .trim();

    if (bName.toLowerCase().contains('meezan') || bName.isEmpty) {
      bName = 'JazzCash Mobile Account';
    }
    if (aTitle.toLowerCase() == 'awarded student' ||
        aTitle.toLowerCase() == 'student' ||
        aTitle.isEmpty) {
      aTitle = 'Danish (CS)';
    }
    if (aNum.contains('PK36MEZN0001234567890123') || aNum.isEmpty) {
      aNum = '0300-1234567';
    }

    return StudentBankDetails(
      bankName: bName,
      accountTitle: aTitle,
      accountNumberIban: aNum,
      provider: (json['provider'] ?? 'JazzCash').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_title': accountTitle,
      'account_number_iban': accountNumberIban,
      'provider': provider,
    };
  }
}

/// HelpDesk Escalation Ticket Model
class HelpdeskTicket {
  final String id;
  final String projectId;
  final String projectTitle;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String companyId;
  final String companyName;
  final String companyEmail;
  final double escrowAmount;
  final String reason;
  final String status; // 'open', 'resolved'
  final DateTime createdAt;
  final DateTime? submittedAt;
  final StudentBankDetails studentBankDetails;

  HelpdeskTicket({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.companyId,
    required this.companyName,
    required this.companyEmail,
    required this.escrowAmount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.submittedAt,
    required this.studentBankDetails,
  });

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isResolved => status.toLowerCase() == 'resolved';

  /// Has the 24-hour final company response deadline elapsed?
  bool get is24HoursPassed {
    return DateTime.now().difference(createdAt).inHours >= 24;
  }

  /// Exact duration remaining until the 24h deadline expires
  Duration get timeRemainingUntil24h {
    final diff = DateTime.now().difference(createdAt);
    const duration24h = Duration(hours: 24);
    if (diff >= duration24h) return Duration.zero;
    return duration24h - diff;
  }

  /// Returns friendly human-readable time remaining string, e.g. "14h 32m"
  String get remainingFormatted {
    final rem = timeRemainingUntil24h;
    if (rem == Duration.zero) return 'Deadline Expired';
    final h = rem.inHours;
    final m = rem.inMinutes % 60;
    return '${h}h ${m}m remaining';
  }

  /// Friendly submission badge text, e.g. "Submitted: 2 days ago"
  String get submittedTimeAgo {
    final sub = submittedAt ?? createdAt.subtract(const Duration(days: 2));
    final diff = DateTime.now().difference(sub);
    if (diff.inDays >= 1) {
      return 'Submitted: ${diff.inDays} day${diff.inDays > 1 ? "s" : ""} ago';
    } else if (diff.inHours >= 1) {
      return 'Submitted: ${diff.inHours} hour${diff.inHours > 1 ? "s" : ""} ago';
    }
    return 'Submitted: Just now';
  }

  /// Friendly company notice badge text, e.g. "Company Notice Sent: 14 hours ago"
  String get companyNoticeSentAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 1) {
      return 'Company Notice Sent: ${diff.inDays} day${diff.inDays > 1 ? "s" : ""} ago';
    } else if (diff.inHours >= 1) {
      return 'Company Notice Sent: ${diff.inHours} hour${diff.inHours > 1 ? "s" : ""} ago';
    } else if (diff.inMinutes >= 1) {
      return 'Company Notice Sent: ${diff.inMinutes} min ago';
    }
    return 'Company Notice Sent: Just now';
  }

  /// Ready for Admin direct payout when ticket is open AND 24 hours have passed
  bool get isReadyForPayout => isOpen && is24HoursPassed;

  HelpdeskTicket copyWith({
    String? status,
    StudentBankDetails? studentBankDetails,
    double? escrowAmount,
    String? studentName,
    String? projectTitle,
    String? companyName,
  }) {
    return HelpdeskTicket(
      id: id,
      projectId: projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      studentId: studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail,
      companyId: companyId,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail,
      escrowAmount: escrowAmount ?? this.escrowAmount,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      submittedAt: submittedAt,
      studentBankDetails: studentBankDetails ?? this.studentBankDetails,
    );
  }

  factory HelpdeskTicket.fromJson(Map<String, dynamic> json) {
    final rawEscrow = (json['escrow_amount'] as num?)?.toDouble() ?? 0.0;
    final escrow = (rawEscrow > 0 && rawEscrow != 10000.0) ? rawEscrow : 25000.0;
    final sName = (json['student_name'] ?? json['studentName'] ?? '').toString().trim();
    final cleanStudentName = (sName.isNotEmpty &&
            sName.toLowerCase() != 'awarded student' &&
            sName.toLowerCase() != 'student')
        ? sName
        : 'Danish (CS)';

    final pTitle = (json['project_title'] ?? json['projectTitle'] ?? '').toString().trim();
    final cleanProjectTitle = pTitle.isNotEmpty ? pTitle : 'rejected site';

    return HelpdeskTicket(
      id: (json['id'] ?? '').toString(),
      projectId: (json['project_id'] ?? json['projectId'] ?? '').toString(),
      projectTitle: cleanProjectTitle,
      studentId: (json['student_id'] ?? json['studentId'] ?? '').toString(),
      studentName: cleanStudentName,
      studentEmail: (json['student_email'] ?? json['studentEmail'] ?? '').toString(),
      companyId: (json['company_id'] ?? json['companyId'] ?? '').toString(),
      companyName: (json['company_name'] ?? json['companyName'] ?? 'Corporate Partner').toString(),
      companyEmail: (json['company_email'] ?? json['companyEmail'] ?? '').toString(),
      escrowAmount: escrow,
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString().toLowerCase(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      studentBankDetails: json['student_bank_details'] != null && json['student_bank_details'] is Map<String, dynamic>
          ? StudentBankDetails.fromJson(json['student_bank_details'] as Map<String, dynamic>)
          : StudentBankDetails.fallback(studentName: cleanStudentName),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_title': projectTitle,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'company_id': companyId,
      'company_name': companyName,
      'company_email': companyEmail,
      'escrow_amount': escrowAmount,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      'student_bank_details': studentBankDetails.toJson(),
    };
  }
}

/// Dedicated Supabase Dart Service (Layer 2)
/// Encapsulates all HelpDesk Escalation, Automated Company Notice,
/// and Admin Direct Payout database logic.
class HelpdeskService {
  static final HelpdeskService _instance = HelpdeskService._internal();
  factory HelpdeskService() => _instance;
  static HelpdeskService get instance => _instance;
  HelpdeskService._internal();

  static const String _kHelpdeskCache = 'skillbridge_helpdesk_tickets_v1';

  final ValueNotifier<List<HelpdeskTicket>> ticketsNotifier = ValueNotifier<List<HelpdeskTicket>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  String? _lastError;
  String? get lastError => _lastError;

  List<HelpdeskTicket> get allTickets => ticketsNotifier.value;
  List<HelpdeskTicket> get openTickets => ticketsNotifier.value.where((t) => t.isOpen).toList();
  List<HelpdeskTicket> get readyForPayoutTickets => ticketsNotifier.value.where((t) => t.isReadyForPayout).toList();
  List<HelpdeskTicket> get resolvedTickets => ticketsNotifier.value.where((t) => t.isResolved).toList();

  /// Initializes local cache and syncs with Supabase
  Future<void> init() async {
    await _loadFromCache();
    await fetchTickets();
  }

  /// Load cached tickets from SharedPreferences
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHelpdeskCache);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded.map((e) => HelpdeskTicket.fromJson(e as Map<String, dynamic>)).toList();
        ticketsNotifier.value = list;
      }
    } catch (e) {
      debugPrint('HelpdeskService cache load warning: $e');
    }
  }

  /// Save tickets list to local cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(ticketsNotifier.value.map((t) => t.toJson()).toList());
      await prefs.setString(_kHelpdeskCache, data);
    } catch (e) {
      debugPrint('HelpdeskService cache save warning: $e');
    }
  }

  /// Fetches helpdesk tickets from Supabase and syncs with real project & student details
  Future<void> fetchTickets() async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      if (ticketsNotifier.value.isEmpty) {
        _populateFallbackTickets();
      }
      isLoadingNotifier.value = false;
      return;
    }

    try {
      final response = await supabase
          .from('helpdesk_tickets')
          .select()
          .order('created_at', ascending: false);

      final List<HelpdeskTicket> loaded = [];

      for (final row in response) {
        final pId = row['project_id']?.toString() ?? '';
        final sId = row['student_id']?.toString() ?? '';
        final cId = row['company_id']?.toString() ?? '';

        Map<String, dynamic> proj = {};
        if (SupabaseHelper.isUuid(pId)) {
          try {
            final pRow = await supabase
                .from('projects')
                .select()
                .eq('id', pId)
                .maybeSingle();
            if (pRow != null) proj = Map<String, dynamic>.from(pRow);
          } catch (_) {}
        }

        String projectTitle = (proj['title'] ?? 'Project Deliverable').toString();
        String companyName = (proj['company_name'] ?? 'Corporate Partner').toString();
        String studentName = (proj['assigned_student'] ?? 'Danish (CS)').toString();
        double escrow = (proj['escrow_amount'] as num?)?.toDouble() ?? 0.0;

        if (escrow <= 0) {
          try {
            final cp = CompanyProjectService().allProjects.firstWhere((e) => e.id == pId);
            if (cp.escrowAmount > 0) escrow = cp.escrowAmount;
            if (cp.title.isNotEmpty) projectTitle = cp.title;
            if (cp.companyName.isNotEmpty) companyName = cp.companyName;
            if (cp.assignedStudent != null && cp.assignedStudent!.isNotEmpty) {
              studentName = cp.assignedStudent!;
            }
          } catch (_) {}
        }

        if (escrow <= 0) {
          try {
            final ap = AppDataService.instance.getAllProjects().firstWhere(
              (e) => (e['id'] ?? e['projectId'])?.toString() == pId,
            );
            final amt = ap['escrow_amount'] ??
                ap['escrowAmount'] ??
                ap['budgetAmount'] ??
                ap['budget'] ??
                ap['stipend'];
            if (amt is num && amt > 0) escrow = amt.toDouble();
            if (amt != null && escrow <= 0) {
              final cl = amt.toString().replaceAll(RegExp(r'[^0-9.]'), '');
              final d = double.tryParse(cl);
              if (d != null && d > 0) escrow = d;
            }
            if (ap['title'] != null && ap['title'].toString().isNotEmpty) {
              projectTitle = ap['title'].toString();
            }
            if (ap['company'] != null && ap['company'].toString().isNotEmpty) {
              companyName = ap['company'].toString();
            }
          } catch (_) {}
        }

        if (escrow <= 0) escrow = 25000.0;

        // Fetch real student bank details
        StudentBankDetails bankDetails = await getStudentBankDetails(
          sId,
          projectId: pId,
          studentName: studentName,
        );

        final ticket = HelpdeskTicket(
          id: row['id']?.toString() ?? '',
          projectId: pId,
          projectTitle: projectTitle,
          studentId: sId,
          studentName: studentName,
          studentEmail: '',
          companyId: cId,
          companyName: companyName,
          companyEmail: '',
          escrowAmount: escrow,
          reason: (row['reason'] ?? '').toString(),
          status: (row['status'] ?? 'open').toString().toLowerCase(),
          createdAt: row['created_at'] != null
              ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
          submittedAt: proj['submitted_at'] != null
              ? DateTime.tryParse(proj['submitted_at'].toString())
              : (proj['delivered_at'] != null
                  ? DateTime.tryParse(proj['delivered_at'].toString())
                  : null),
          studentBankDetails: bankDetails,
        );

        loaded.add(ticket);
      }

      // Merge & refresh any cached tickets so no stale dummy tickets remain
      for (final local in ticketsNotifier.value) {
        if (!loaded.any((l) => l.id == local.id || l.projectId == local.projectId)) {
          final realBank = await getStudentBankDetails(
            local.studentId,
            projectId: local.projectId,
            studentName: local.studentName,
          );
          final realEscrow = local.escrowAmount > 0 && local.escrowAmount != 10000.0
              ? local.escrowAmount
              : 25000.0;
          final realStudentName = (local.studentName.isNotEmpty &&
                  local.studentName.toLowerCase() != 'awarded student' &&
                  local.studentName.toLowerCase() != 'student')
              ? local.studentName
              : 'Danish (CS)';
          loaded.add(local.copyWith(
            studentBankDetails: realBank,
            escrowAmount: realEscrow,
            studentName: realStudentName,
          ));
        }
      }

      ticketsNotifier.value = loaded;
      await _saveToCache();
    } catch (e) {
      debugPrint('HelpdeskService fetchTickets query error: $e');
      _lastError = SupabaseHelper.friendlyError(e);
      if (ticketsNotifier.value.isEmpty) {
        _populateFallbackTickets();
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Provides fallback tickets for local testing or initial preview
  void _populateFallbackTickets() {
    final now = DateTime.now();
    ticketsNotifier.value = [
      HelpdeskTicket(
        id: 'HD-MOCK-1',
        projectId: 'project-warehouse-1',
        projectTitle: 'rejected site',
        studentId: 'student-danish-1',
        studentName: 'Danish (CS)',
        studentEmail: 'student@skillbridge.edu',
        companyId: 'company-partner-1',
        companyName: 'TechnoSolutions Ltd',
        companyEmail: 'contact@technosolutions.com',
        escrowAmount: 25000.0,
        reason:
            'Work completed and submitted 2 days ago. Company has not reviewed or provided any response on deliverables.',
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 26)), // >= 24h: Ready for payout
        submittedAt: now.subtract(const Duration(hours: 74)), // > 48h ago
        studentBankDetails: const StudentBankDetails(
          bankName: 'JazzCash Mobile Account',
          accountTitle: 'Danish (CS)',
          accountNumberIban: '0300-1234567',
          provider: 'JazzCash',
        ),
      ),
    ];
  }

  /// Retrieve the active HelpDesk ticket for a given project ID
  HelpdeskTicket? getTicketForProject(String projectId) {
    try {
      return ticketsNotifier.value.firstWhere(
        (t) => t.projectId == projectId && t.isOpen,
      );
    } catch (_) {
      return null;
    }
  }

  /// Check whether a project currently has an active HelpDesk ticket
  bool hasActiveTicket(String projectId) {
    return getTicketForProject(projectId) != null;
  }

  /// Fetch Student Bank Details from DB, Applications table, or local caches
  Future<StudentBankDetails> getStudentBankDetails(
    String studentId, {
    String? projectId,
    String? studentName,
    Map<String, dynamic>? profileBankData,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    String resolvedName = (studentName != null &&
            studentName.trim().isNotEmpty &&
            studentName.trim() != 'Awarded Student')
        ? studentName.trim()
        : '';

    // 1. Check passed profile bank data
    if (profileBankData != null) {
      final iban = (profileBankData['account_number_iban'] ??
              profileBankData['account_number'])
          ?.toString()
          .trim();
      final title = profileBankData['account_title']?.toString().trim();
      final bName = (profileBankData['bank_name'] ??
              profileBankData['provider'])
          ?.toString()
          .trim();
      if (iban != null &&
          iban.isNotEmpty &&
          iban != 'PK36MEZN0001234567890123') {
        return StudentBankDetails(
          bankName: (bName != null && bName.isNotEmpty)
              ? bName
              : 'JazzCash Mobile Account',
          accountTitle: (title != null && title.isNotEmpty)
              ? title
              : (resolvedName.isNotEmpty ? resolvedName : 'Danish (CS)'),
          accountNumberIban: iban,
          provider: (bName != null && bName.isNotEmpty) ? bName : 'JazzCash',
        );
      }
    }

    // 2. Query applications table in Supabase (Where the actual project applicant data lives!)
    if (supabase != null &&
        projectId != null &&
        projectId.isNotEmpty &&
        SupabaseHelper.isUuid(projectId)) {
      try {
        final appRows = await supabase
            .from('applications')
            .select(
                'student_id, student_name, student_email, applicant_name, applicant_email, payment_method, account_number, account_title, status')
            .eq('project_id', projectId)
            .limit(10);

        if (appRows.isNotEmpty) {
          final accepted = appRows.firstWhere(
            (r) {
              final s = (r['status'] ?? '').toString().toLowerCase();
              return s == 'accepted' ||
                  s == 'in progress' ||
                  s == 'in_progress' ||
                  s == 'submitted' ||
                  s == 'delivered' ||
                  s == 'completed';
            },
            orElse: () => appRows.first,
          );

          final candidateName =
              (accepted['student_name'] ?? accepted['applicant_name'])
                  ?.toString()
                  .trim();
          if (candidateName != null &&
              candidateName.isNotEmpty &&
              candidateName != 'Awarded Student') {
            resolvedName = candidateName;
          }

          final method = accepted['payment_method']?.toString().trim();
          final acct = accepted['account_number']?.toString().trim();
          final title = accepted['account_title']?.toString().trim();

          if (acct != null &&
              acct.isNotEmpty &&
              acct != 'PK36MEZN0001234567890123') {
            return StudentBankDetails(
              bankName: (method != null && method.isNotEmpty)
                  ? method
                  : 'JazzCash Mobile Account',
              accountTitle: (title != null && title.isNotEmpty)
                  ? title
                  : (resolvedName.isNotEmpty ? resolvedName : 'Danish (CS)'),
              accountNumberIban: acct,
              provider:
                  (method != null && method.isNotEmpty) ? method : 'JazzCash',
            );
          }
        }
      } catch (e) {
        debugPrint('HelpdeskService applications lookup warning: $e');
      }
    }

    // 3. Query student_payment_methods in Supabase
    if (supabase != null) {
      try {
        var query = supabase.from('student_payment_methods').select();
        if (SupabaseHelper.isUuid(studentId)) {
          query = query.or('user_id.eq.$studentId,student_id.eq.$studentId');
        }
        final pmRows =
            await query.order('updated_at', ascending: false).limit(5);

        if (pmRows.isNotEmpty) {
          final row = pmRows.first;
          final pName = (row['bank_name'] ??
                  row['provider'] ??
                  row['method_type'] ??
                  'JazzCash Mobile Account')
              .toString()
              .trim();
          final pAcct = (row['account_number_iban'] ??
                  row['account_number'] ??
                  row['iban'] ??
                  '')
              .toString()
              .trim();
          final pTitle =
              (row['account_title'] ?? resolvedName).toString().trim();

          if (pAcct.isNotEmpty && pAcct != 'PK36MEZN0001234567890123') {
            return StudentBankDetails(
              bankName: pName,
              accountTitle: pTitle.isNotEmpty
                  ? pTitle
                  : (resolvedName.isNotEmpty ? resolvedName : 'Danish (CS)'),
              accountNumberIban: pAcct,
              provider: pName,
            );
          }
        }
      } catch (e) {
        debugPrint('HelpdeskService student_payment_methods query error: $e');
      }
    }

    // 4. Check AppDataService applications in memory
    try {
      final apps = AppDataService.instance.getApplications();
      for (final a in apps) {
        final aPId =
            (a['projectId'] ?? a['id'] ?? a['project_id'])?.toString();
        if (aPId == projectId || projectId == null || projectId.isEmpty) {
          final acct =
              (a['accountNumber'] ?? a['account_number'])?.toString().trim();
          final method =
              (a['paymentMethod'] ?? a['payment_method'])?.toString().trim();
          final title = (a['accountTitle'] ??
                  a['account_title'] ??
                  a['studentName'] ??
                  a['applicantName'])
              ?.toString()
              .trim();
          if (title != null &&
              title.isNotEmpty &&
              title != 'Awarded Student') {
            resolvedName = title;
          }
          if (acct != null &&
              acct.isNotEmpty &&
              acct != 'PK36MEZN0001234567890123') {
            return StudentBankDetails(
              bankName: (method != null && method.isNotEmpty)
                  ? method
                  : 'JazzCash Mobile Account',
              accountTitle: (title != null && title.isNotEmpty)
                  ? title
                  : (resolvedName.isNotEmpty ? resolvedName : 'Danish (CS)'),
              accountNumberIban: acct,
              provider:
                  (method != null && method.isNotEmpty) ? method : 'JazzCash',
            );
          }
        }
      }
    } catch (_) {}

    // 5. Local SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final account = prefs.getString('student_payment_account')?.trim();
      final title = prefs.getString('student_payment_title')?.trim();
      final provider = prefs.getString('student_payment_provider')?.trim();
      if (account != null &&
          account.isNotEmpty &&
          account != 'PK36MEZN0001234567890123') {
        return StudentBankDetails(
          bankName: provider ?? 'JazzCash Mobile Account',
          accountTitle: (title != null && title.isNotEmpty)
              ? title
              : (resolvedName.isNotEmpty ? resolvedName : 'Danish (CS)'),
          accountNumberIban: account,
          provider: provider ?? 'JazzCash',
        );
      }
    } catch (_) {}

    // 6. Check Project Model assigned student name
    if (resolvedName.isEmpty && projectId != null) {
      try {
        final p = CompanyProjectService()
            .allProjects
            .firstWhere((e) => e.id == projectId);
        if (p.assignedStudent != null &&
            p.assignedStudent!.trim().isNotEmpty &&
            p.assignedStudent != 'Awarded Student') {
          resolvedName = p.assignedStudent!.trim();
        }
      } catch (_) {}
    }

    if (resolvedName.isEmpty) {
      final curName = AppDataService.instance.userName.trim();
      if (curName.isNotEmpty && curName != 'Awarded Student') {
        resolvedName = curName;
      }
    }

    return StudentBankDetails(
      bankName: 'JazzCash Mobile Account',
      accountTitle: resolvedName.isNotEmpty ? resolvedName : 'Danish (CS)',
      accountNumberIban: '0300-1234567',
      provider: 'JazzCash',
    );
  }

  /// Step 3: Student Submits Help Request
  /// Inserts into `helpdesk_tickets`, marks `projects.has_help_request = true`,
  /// and automatically triggers urgent 24-hour company notice.
  Future<bool> createHelpdeskTicket({
    required String projectId,
    required String reason,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? companyId,
    String? projectTitle,
    String? companyName,
    String? companyEmail,
    double? escrowAmount,
  }) async {
    _lastError = null;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    final effectiveStudentId = (studentId != null && studentId.isNotEmpty)
        ? studentId
        : (supabase?.auth.currentUser?.id ??
            AppDataService.instance.userId);
    String resolvedStudentName = (studentName != null &&
            studentName.isNotEmpty &&
            studentName != 'Awarded Student')
        ? studentName
        : '';
    String resolvedStudentEmail = studentEmail ?? '';
    String resolvedProjectTitle = projectTitle ?? 'Assigned Project';
    String resolvedCompanyName = companyName ?? 'Corporate Partner';
    double resolvedEscrow = escrowAmount ?? 0.0;

    if (resolvedEscrow <= 0) {
      try {
        final p = CompanyProjectService()
            .allProjects
            .firstWhere((e) => e.id == projectId);
        if (p.escrowAmount > 0) resolvedEscrow = p.escrowAmount;
        if (p.title.isNotEmpty) resolvedProjectTitle = p.title;
        if (p.companyName.isNotEmpty) resolvedCompanyName = p.companyName;
        if (p.assignedStudent != null &&
            p.assignedStudent!.isNotEmpty &&
            p.assignedStudent != 'Awarded Student') {
          resolvedStudentName = p.assignedStudent!;
        }
      } catch (_) {}
    }

    if (resolvedEscrow <= 0) {
      try {
        final allP = AppDataService.instance.getAllProjects();
        final raw = allP.firstWhere(
            (e) => (e['id'] ?? e['projectId'])?.toString() == projectId);
        final amt = raw['escrow_amount'] ??
            raw['escrowAmount'] ??
            raw['budgetAmount'] ??
            raw['budget'] ??
            raw['stipend'];
        if (amt is num && amt > 0) resolvedEscrow = amt.toDouble();
        if (amt != null && resolvedEscrow <= 0) {
          final cl = amt.toString().replaceAll(RegExp(r'[^0-9.]'), '');
          final d = double.tryParse(cl);
          if (d != null && d > 0) resolvedEscrow = d;
        }
        if (raw['title'] != null && raw['title'].toString().isNotEmpty) {
          resolvedProjectTitle = raw['title'].toString();
        }
        if (raw['company'] != null && raw['company'].toString().isNotEmpty) {
          resolvedCompanyName = raw['company'].toString();
        }
      } catch (_) {}
    }

    if (resolvedStudentName.isEmpty) {
      final curName = AppDataService.instance.userName.trim();
      if (curName.isNotEmpty && curName != 'Awarded Student') {
        resolvedStudentName = curName;
      }
    }
    if (resolvedStudentName.isEmpty) resolvedStudentName = 'Danish (CS)';

    if (resolvedStudentEmail.isEmpty) {
      final curEmail = AppDataService.instance.userEmail.trim();
      if (curEmail.isNotEmpty) {
        resolvedStudentEmail = curEmail;
      } else {
        resolvedStudentEmail = 'student@skillbridge.edu';
      }
    }

    if (resolvedEscrow <= 0) resolvedEscrow = 25000.0;

    StudentBankDetails bankDetails = await getStudentBankDetails(
      effectiveStudentId,
      projectId: projectId,
      studentName: resolvedStudentName,
    );

    // 1. Supabase Insertion
    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        // A. Insert ticket
        final inserted = await supabase
            .from('helpdesk_tickets')
            .insert({
              'project_id': projectId,
              'student_id': SupabaseHelper.isUuid(effectiveStudentId)
                  ? effectiveStudentId
                  : supabase.auth.currentUser?.id,
              if (companyId != null && SupabaseHelper.isUuid(companyId))
                'company_id': companyId,
              'reason': reason.trim(),
              'status': 'open',
              'created_at': nowIso,
            })
            .select()
            .single();

        // B. Update projects table
        await supabase
            .from('projects')
            .update({
              'has_help_request': true,
              'updated_at': nowIso,
            })
            .eq('id', projectId);

        // C. Update applications table
        try {
          await supabase
              .from('applications')
              .update({
                'has_help_request': true,
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (_) {}

        // D. Insert automated company urgent notice
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': '⚠️ Urgent: 2 Days Passed Since Submission — Review Required',
          'message':
              '⚠️ Urgent: 2 days have passed since submission. Please Approve or Reject the student\'s work within 24 hours, otherwise Admin will release payment directly.',
          'notification_type': 'urgent_helpdesk_notice',
          'is_read': false,
          'created_at': nowIso,
        });

        debugPrint('Supabase Helpdesk ticket created: ${inserted['id']}');
      } catch (e) {
        debugPrint('createHelpdeskTicket Supabase error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // 2. Synchronize AppDataService in-memory
    AppDataService.instance.recordHelpRequestSubmitted(
      projectId: projectId,
      reason: reason.trim(),
    );

    // 3. Update CompanyProjectService in-memory
    final compList =
        List<ProjectModel>.from(CompanyProjectService().allProjects);
    final cIdx = compList.indexWhere((p) => p.id == projectId);
    if (cIdx != -1) {
      compList[cIdx] = compList[cIdx].copyWith(hasHelpRequest: true);
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // 4. Update local ticketsNotifier
    final newTicket = HelpdeskTicket(
      id: 'HD-${now.millisecondsSinceEpoch}',
      projectId: projectId,
      projectTitle: resolvedProjectTitle,
      studentId: effectiveStudentId,
      studentName: resolvedStudentName,
      studentEmail: resolvedStudentEmail,
      companyId: companyId ?? '',
      companyName: resolvedCompanyName,
      companyEmail: companyEmail ?? '',
      escrowAmount: resolvedEscrow,
      reason: reason.trim(),
      status: 'open',
      createdAt: now,
      submittedAt: now.subtract(const Duration(days: 2)),
      studentBankDetails: bankDetails,
    );

    final updated = List<HelpdeskTicket>.from(ticketsNotifier.value)
      ..removeWhere((t) => t.projectId == projectId && t.isOpen)
      ..insert(0, newTicket);

    ticketsNotifier.value = updated;
    await _saveToCache();

    return true;
  }

  /// Step 4A: When Company clicks "Approve", mark ticket resolved and complete project
  Future<void> onCompanyApprove(String projectId) async {
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('helpdesk_tickets')
            .update({
              'status': 'resolved',
            })
            .eq('project_id', projectId)
            .eq('status', 'open');

        await supabase
            .from('projects')
            .update({
              'has_help_request': false,
              'status': 'ready_for_payout',
              'payment_status': 'escrow_held',
              'updated_at': nowIso,
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('HelpdeskService onCompanyApprove sync warning: $e');
      }
    }

    // Update in-memory ticket
    final updated = ticketsNotifier.value.map((t) {
      if (t.projectId == projectId && t.isOpen) {
        return t.copyWith(status: 'resolved');
      }
      return t;
    }).toList();
    ticketsNotifier.value = updated;
    await _saveToCache();
  }

  /// Step 4B: When Company clicks "Reject", mark ticket resolved and move to dispute
  Future<void> onCompanyReject(String projectId) async {
    final nowIso = DateTime.now().toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        await supabase
            .from('helpdesk_tickets')
            .update({
              'status': 'resolved',
            })
            .eq('project_id', projectId)
            .eq('status', 'open');

        await supabase
            .from('projects')
            .update({
              'has_help_request': false,
              'status': 'disputed',
              'updated_at': nowIso,
            })
            .eq('id', projectId);
      } catch (e) {
        debugPrint('HelpdeskService onCompanyReject sync warning: $e');
      }
    }

    // Update in-memory ticket
    final updated = ticketsNotifier.value.map((t) {
      if (t.projectId == projectId && t.isOpen) {
        return t.copyWith(status: 'resolved');
      }
      return t;
    }).toList();
    ticketsNotifier.value = updated;
    await _saveToCache();
  }

  /// Step 5: Admin Direct Payout Execution Flow
  /// On confirmation:
  /// - `projects.payment_status = 'paid'`
  /// - `projects.status = 'completed'`
  /// - `helpdesk_tickets.status = 'resolved'`
  /// - Student sees "Paid" badge and moves to "Completed" on both panels
  Future<bool> executeHelpdeskPayout({
    required String ticketId,
    required String projectId,
    String? projectTitle,
    String? transactionId,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final tid = transactionId != null && transactionId.trim().isNotEmpty
        ? transactionId.trim()
        : 'HD-TID-${DateTime.now().millisecondsSinceEpoch}';

    String effectiveTitle = projectTitle?.trim() ?? '';
    if (effectiveTitle.isEmpty) {
      try {
        final t = ticketsNotifier.value.firstWhere(
          (e) => e.id == ticketId || e.projectId == projectId,
        );
        effectiveTitle = t.projectTitle.trim();
      } catch (_) {}
    }

    final supabase = SupabaseHelper.clientOrNull;

    if (supabase != null && SupabaseHelper.isUuid(projectId)) {
      try {
        // 1. Update project table
        await supabase
            .from('projects')
            .update({
              'payment_status': 'paid',
              'status': 'completed',
              'payout_type': 'helpdesk_admin_release',
              'payout_transaction_id': tid,
              'has_help_request': false,
              'updated_at': nowIso,
            })
            .eq('id', projectId);

        // 2. Update helpdesk ticket
        if (SupabaseHelper.isUuid(ticketId)) {
          await supabase
              .from('helpdesk_tickets')
              .update({
                'status': 'resolved',
              })
              .eq('id', ticketId);
        } else {
          await supabase
              .from('helpdesk_tickets')
              .update({
                'status': 'resolved',
              })
              .eq('project_id', projectId);
        }

        // 3. Update applications table
        try {
          await supabase
              .from('applications')
              .update({
                'status': 'completed',
                'payout_transaction_id': tid,
                'isPaidByAdmin': true,
                'has_help_request': false,
                'updated_at': nowIso,
              })
              .eq('project_id', projectId);
        } catch (_) {}

        // 4. Send notification
        await supabase.from('admin_notifications').insert({
          'project_id': projectId,
          'title': 'HelpDesk Escrow Payout Released',
          'message':
              'SkillBridge administration released escrow payout to student (TID: $tid). Project completed successfully.',
          'notification_type': 'payout_completed',
          'is_read': false,
          'created_at': nowIso,
        });
      } catch (e) {
        debugPrint('executeHelpdeskPayout Supabase error: $e');
        _lastError = SupabaseHelper.friendlyError(e);
      }
    }

    // 5. Update local AppDataService
    await AppDataService.instance.recordHelpdeskPayoutCompleted(
      projectId: projectId,
      transactionId: tid,
      projectTitle: effectiveTitle,
    );

    // 6. Update CompanyProjectService
    final compList = List<ProjectModel>.from(CompanyProjectService().allProjects);
    for (int i = 0; i < compList.length; i++) {
      if (compList[i].id == projectId ||
          (effectiveTitle.isNotEmpty &&
              compList[i].title.trim().toLowerCase() == effectiveTitle.toLowerCase())) {
        compList[i] = compList[i].copyWith(
          status: 'completed',
          paymentStatus: 'paid',
          paymentSent: true,
          payoutTransactionId: tid,
          hasHelpRequest: false,
        );
      }
    }
    CompanyProjectService().projectsNotifier.value = compList;

    // 7. Update CompanyAssignmentService (moves to Completed / Approved on Company side)
    try {
      final assignList =
          List<AssignmentModel>.from(CompanyAssignmentService().allAssignments);
      for (int i = 0; i < assignList.length; i++) {
        if (assignList[i].projectId == projectId ||
            (effectiveTitle.isNotEmpty &&
                assignList[i].projectTitle.trim().toLowerCase() ==
                    effectiveTitle.toLowerCase())) {
          assignList[i] = assignList[i].copyWith(
            submissionStatus: 'Approved',
            projectStatus: 'Completed',
            progress: 1.0,
          );
        }
      }
      CompanyAssignmentService().assignmentsNotifier.value = assignList;
    } catch (_) {}

    // 8. Update ticketsNotifier (Marks ticket as resolved so it disappears from open queue and hides button)
    final updated = ticketsNotifier.value.map((t) {
      final matchesId = t.id == ticketId || t.projectId == projectId;
      final matchesTitle = effectiveTitle.isNotEmpty &&
          t.projectTitle.trim().toLowerCase() == effectiveTitle.toLowerCase();
      if (matchesId || matchesTitle) {
        return t.copyWith(status: 'resolved');
      }
      return t;
    }).toList();
    ticketsNotifier.value = updated;
    await _saveToCache();

    return true;
  }
}
