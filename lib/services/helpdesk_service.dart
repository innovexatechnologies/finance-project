import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
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
    return StudentBankDetails(
      bankName: 'Meezan Bank Limited',
      accountTitle: studentName ?? 'Awarded Student',
      accountNumberIban: 'PK36MEZN0001234567890123',
      provider: 'Bank Account',
    );
  }

  factory StudentBankDetails.fromJson(Map<String, dynamic> json) {
    return StudentBankDetails(
      bankName: (json['bank_name'] ?? json['bankName'] ?? json['provider'] ?? 'Meezan Bank').toString(),
      accountTitle: (json['account_title'] ?? json['accountTitle'] ?? 'Student Account').toString(),
      accountNumberIban: (json['account_number_iban'] ?? json['account_number'] ?? json['accountNumber'] ?? 'PK36MEZN0001234567890123').toString(),
      provider: (json['provider'] ?? 'Bank Account').toString(),
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
  }) {
    return HelpdeskTicket(
      id: id,
      projectId: projectId,
      projectTitle: projectTitle,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      companyId: companyId,
      companyName: companyName,
      companyEmail: companyEmail,
      escrowAmount: escrowAmount,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      submittedAt: submittedAt,
      studentBankDetails: studentBankDetails ?? this.studentBankDetails,
    );
  }

  factory HelpdeskTicket.fromJson(Map<String, dynamic> json) {
    return HelpdeskTicket(
      id: (json['id'] ?? '').toString(),
      projectId: (json['project_id'] ?? json['projectId'] ?? '').toString(),
      projectTitle: (json['project_title'] ?? json['projectTitle'] ?? 'Project Deliverable').toString(),
      studentId: (json['student_id'] ?? json['studentId'] ?? '').toString(),
      studentName: (json['student_name'] ?? json['studentName'] ?? 'Student').toString(),
      studentEmail: (json['student_email'] ?? json['studentEmail'] ?? '').toString(),
      companyId: (json['company_id'] ?? json['companyId'] ?? '').toString(),
      companyName: (json['company_name'] ?? json['companyName'] ?? 'Corporate Partner').toString(),
      companyEmail: (json['company_email'] ?? json['companyEmail'] ?? '').toString(),
      escrowAmount: (json['escrow_amount'] as num?)?.toDouble() ?? 10000.0,
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
          : StudentBankDetails.fallback(studentName: json['student_name']?.toString()),
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

  /// Fetches helpdesk tickets from Supabase with full relational joins
  Future<void> fetchTickets() async {
    isLoadingNotifier.value = true;
    _lastError = null;

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      // Fallback: Populate mock ticket if local list is empty for demo/testing
      if (ticketsNotifier.value.isEmpty) {
        _populateFallbackTickets();
      }
      isLoadingNotifier.value = false;
      return;
    }

    try {
      final response = await supabase
          .from('helpdesk_tickets')
          .select('''
            id,
            project_id,
            student_id,
            company_id,
            reason,
            status,
            created_at,
            projects!inner(
              id,
              title,
              escrow_amount,
              submitted_at,
              delivered_at,
              payment_status,
              company_name
            ),
            student:profiles!helpdesk_tickets_student_id_fkey(
              id,
              name,
              email,
              bank_name,
              account_title,
              account_number_iban
            ),
            company:profiles!helpdesk_tickets_company_id_fkey(
              id,
              name,
              email
            )
          ''')
          .order('created_at', ascending: false);

      final List<HelpdeskTicket> loaded = [];

      for (final row in response) {
        final proj = row['projects'] as Map<String, dynamic>? ?? {};
        final studentProfile = row['student'] as Map<String, dynamic>? ?? {};
        final companyProfile = row['company'] as Map<String, dynamic>? ?? {};

        final studentId = row['student_id']?.toString() ?? '';
        final studentName = studentProfile['name']?.toString() ?? 'Awarded Student';

        // Fetch student bank details
        StudentBankDetails bankDetails = await getStudentBankDetails(
          studentId,
          projectId: row['project_id']?.toString(),
          studentName: studentName,
          profileBankData: studentProfile,
        );

        final ticket = HelpdeskTicket(
          id: row['id']?.toString() ?? '',
          projectId: row['project_id']?.toString() ?? '',
          projectTitle: (proj['title'] ?? 'Project Deliverable').toString(),
          studentId: studentId,
          studentName: studentName,
          studentEmail: studentProfile['email']?.toString() ?? '',
          companyId: row['company_id']?.toString() ?? '',
          companyName: (proj['company_name'] ?? companyProfile['name'] ?? 'Corporate Partner').toString(),
          companyEmail: companyProfile['email']?.toString() ?? '',
          escrowAmount: (proj['escrow_amount'] as num?)?.toDouble() ?? 10000.0,
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
        projectTitle: 'Warehouse Management System Deliverables',
        studentId: 'student-danish-1',
        studentName: 'Danish Ali',
        studentEmail: 'danish.ali@student.edu.pk',
        companyId: 'company-partner-1',
        companyName: 'TechnoSolutions Ltd',
        companyEmail: 'contact@technosolutions.com',
        escrowAmount: 15000.0,
        reason: 'Work completed and submitted 2 days ago. Company has not reviewed or provided any response on deliverables.',
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 26)), // >= 24h: Ready for payout
        submittedAt: now.subtract(const Duration(hours: 74)), // > 48h ago
        studentBankDetails: const StudentBankDetails(
          bankName: 'Meezan Bank Limited',
          accountTitle: 'Danish Ali',
          accountNumberIban: 'PK36MEZN0009876543210123',
          provider: 'Bank Account',
        ),
      ),
      HelpdeskTicket(
        id: 'HD-MOCK-2',
        projectId: 'project-flutter-2',
        projectTitle: 'Mobile E-Commerce Dashboard UI',
        studentId: 'student-rehman-2',
        studentName: 'Abdul Rehman',
        studentEmail: 'abdulrehman78ali@gmail.com',
        companyId: 'company-partner-2',
        companyName: 'Apex Digital Hub',
        companyEmail: 'apex.corporate@gmail.com',
        escrowAmount: 10000.0,
        reason: 'Final submission uploaded. 48 hours passed without any approval or rejection. Requesting platform intervention.',
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 14)), // < 24h: Waiting for company
        submittedAt: now.subtract(const Duration(hours: 62)),
        studentBankDetails: const StudentBankDetails(
          bankName: 'JazzCash Digital Wallet',
          accountTitle: 'Abdul Rehman',
          accountNumberIban: '03001234567',
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

  /// Fetch Student Bank Details from DB or local SharedPreferences
  Future<StudentBankDetails> getStudentBankDetails(
    String studentId, {
    String? projectId,
    String? studentName,
    Map<String, dynamic>? profileBankData,
  }) async {
    // 1. Check passed profile bank data
    if (profileBankData != null) {
      final iban = profileBankData['account_number_iban']?.toString();
      final title = profileBankData['account_title']?.toString();
      final bName = profileBankData['bank_name']?.toString();
      if (iban != null && iban.isNotEmpty) {
        return StudentBankDetails(
          bankName: bName ?? 'Bank Account',
          accountTitle: title ?? studentName ?? 'Student Account',
          accountNumberIban: iban,
        );
      }
    }

    final supabase = SupabaseHelper.clientOrNull;
    if (supabase != null && SupabaseHelper.isUuid(studentId)) {
      try {
        final pmRows = await supabase
            .from('student_payment_methods')
            .select()
            .eq('user_id', studentId)
            .limit(1);

        if (pmRows.isNotEmpty) {
          final row = pmRows.first;
          return StudentBankDetails(
            bankName: (row['bank_name'] ?? row['provider'] ?? 'Bank Account').toString(),
            accountTitle: (row['account_title'] ?? studentName ?? 'Student Account').toString(),
            accountNumberIban: (row['account_number'] ?? row['account_number_iban'] ?? '').toString(),
            provider: (row['provider'] ?? 'Bank Account').toString(),
          );
        }
      } catch (e) {
        debugPrint('getStudentBankDetails query error: $e');
      }
    }

    // 2. Local SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final account = prefs.getString('student_payment_account');
      final title = prefs.getString('student_payment_title');
      final provider = prefs.getString('student_payment_provider');
      if (account != null && account.isNotEmpty) {
        return StudentBankDetails(
          bankName: provider ?? 'Bank Account',
          accountTitle: title ?? studentName ?? 'Awarded Student',
          accountNumberIban: account,
          provider: provider ?? 'Bank Account',
        );
      }
    } catch (_) {}

    return StudentBankDetails.fallback(studentName: studentName);
  }

  /// Step 3: Student Submits Help Request
  /// Inserts into `helpdesk_tickets`, marks `projects.has_help_request = true`,
  /// and automatically triggers urgent 24-hour company notice.
  Future<bool> createHelpdeskTicket({
    required String projectId,
    required String reason,
    String? studentId,
    String? companyId,
    String? projectTitle,
    String? companyName,
    double? escrowAmount,
  }) async {
    _lastError = null;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final supabase = SupabaseHelper.clientOrNull;

    final effectiveStudentId = studentId ?? supabase?.auth.currentUser?.id ?? 'student-self';
    final effectiveCompanyId = companyId;

    StudentBankDetails bankDetails = await getStudentBankDetails(
      effectiveStudentId,
      projectId: projectId,
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
              if (effectiveCompanyId != null && SupabaseHelper.isUuid(effectiveCompanyId))
                'company_id': effectiveCompanyId,
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
    final compList = List<ProjectModel>.from(CompanyProjectService().allProjects);
    final cIdx = compList.indexWhere((p) => p.id == projectId);
    if (cIdx != -1) {
      compList[cIdx] = compList[cIdx].copyWith(hasHelpRequest: true);
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // 4. Update local ticketsNotifier
    final newTicket = HelpdeskTicket(
      id: 'HD-${now.millisecondsSinceEpoch}',
      projectId: projectId,
      projectTitle: projectTitle ?? 'Assigned Project',
      studentId: effectiveStudentId,
      studentName: 'Awarded Student',
      studentEmail: '',
      companyId: effectiveCompanyId ?? '',
      companyName: companyName ?? 'Partner Company',
      companyEmail: '',
      escrowAmount: escrowAmount ?? 10000.0,
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
    String? transactionId,
  }) async {
    _lastError = null;
    final nowIso = DateTime.now().toIso8601String();
    final tid = transactionId != null && transactionId.trim().isNotEmpty
        ? transactionId.trim()
        : 'HD-TID-${DateTime.now().millisecondsSinceEpoch}';

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
    );

    // 6. Update CompanyProjectService
    final compList = List<ProjectModel>.from(CompanyProjectService().allProjects);
    final cIdx = compList.indexWhere((p) => p.id == projectId);
    if (cIdx != -1) {
      compList[cIdx] = compList[cIdx].copyWith(
        status: 'completed',
        paymentStatus: 'paid',
        payoutTransactionId: tid,
        hasHelpRequest: false,
      );
      CompanyProjectService().projectsNotifier.value = compList;
    }

    // 7. Update ticketsNotifier
    final updated = ticketsNotifier.value.map((t) {
      if (t.id == ticketId || t.projectId == projectId) {
        return t.copyWith(status: 'resolved');
      }
      return t;
    }).toList();
    ticketsNotifier.value = updated;
    await _saveToCache();

    return true;
  }
}
