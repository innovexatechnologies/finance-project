class ProjectModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String requirements;
  final List<String> skillsRequired;
  final String deliverables;
  final String deadline;
  final String projectType; // 'Remote', 'On-site', 'Hybrid'
  final int openings;
  final String additionalInstructions;
  final String companyName;
  final String companyId;
  final String status; // 'pending_payment', 'pending_verification', 'Open', 'In Progress', 'delivered', 'ready_for_payout', 'completed', 'disputed', 'rejected', 'Closed', 'Cancelled'
  final String duration;
  final int applicantsCount;
  final String? assignedStudent;
  final double progress;
  final String createdAt;
  final bool paymentSent;

  // Upfront Custodial Escrow Fields
  final double escrowAmount;
  final String? paymentMethodUsed;
  final String? transactionId;
  final String? paymentReceiptUrl;
  final bool isEscrowVerified;
  final String? verifiedAt;
  final String? rejectionReason;
  final String? moderationReason;
  final int paymentRejectionCount;

  // Delivery, Auto-Release & Dispute Fields
  final String? deliveredAt;
  final String? disputeCaseId;
  final String? disputeReason;
  final String? disputeResolution;
  final String? payoutType; // 'full_student', 'auto_released_student', 'full_company_refund', 'split_50_50'
  final double? studentPayoutAmount;
  final double? companyRefundAmount;
  final double? platformCommissionAmount;
  final String? payoutTransactionId;
  final String? payoutReceiptUrl;
  final String? refundTransactionId;
  final String? refundReceiptUrl;
  final String? completedAt;

  // Revision Tracking Fields (Max 1 Revision with 2-day deadline)
  final int revisionCount;
  final int maxRevisions;
  final String? revisionNotes;
  final String? lastRevisionRequestedAt;
  final String? revisionDeadline;

  // HelpDesk & Escrow Escalation Fields
  final String? submittedAt;
  final bool hasHelpRequest;
  final String paymentStatus;

  ProjectModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.requirements = '',
    this.skillsRequired = const [],
    this.deliverables = '',
    required this.deadline,
    this.projectType = 'Remote',
    this.openings = 1,
    this.additionalInstructions = '',
    required this.companyName,
    this.companyId = '',
    required this.status,
    this.duration = '3-4 weeks',
    this.applicantsCount = 0,
    this.assignedStudent,
    this.progress = 0.0,
    this.createdAt = 'Just now',
    this.paymentSent = false,
    this.escrowAmount = 0.0,
    this.paymentMethodUsed,
    this.transactionId,
    this.paymentReceiptUrl,
    this.isEscrowVerified = false,
    this.verifiedAt,
    this.rejectionReason,
    this.moderationReason,
    this.paymentRejectionCount = 0,
    this.deliveredAt,
    this.disputeCaseId,
    this.disputeReason,
    this.disputeResolution,
    this.payoutType,
    this.studentPayoutAmount,
    this.companyRefundAmount,
    this.platformCommissionAmount,
    this.payoutTransactionId,
    this.payoutReceiptUrl,
    this.refundTransactionId,
    this.refundReceiptUrl,
    this.completedAt,
    this.revisionCount = 0,
    this.maxRevisions = 1,
    this.revisionNotes,
    this.lastRevisionRequestedAt,
    this.revisionDeadline,
    this.submittedAt,
    this.hasHelpRequest = false,
    this.paymentStatus = 'escrow_held',
  });

  bool get isPendingPayment => status.toLowerCase() == 'pending_payment';
  bool get isPendingVerification =>
      status.toLowerCase() == 'pending_verification';
  bool get isPaymentRejected =>
      status.toLowerCase() == 'payment_rejected' ||
      status.toLowerCase() == 'rejected';
  bool get isPaymentResubmitted =>
      isPendingVerification &&
      (paymentRejectionCount > 0 ||
          (moderationReason?.contains('Resubmitted') ?? false) ||
          additionalInstructions.contains('Resubmitted'));
  bool get canResubmitPayment =>
      isPaymentRejected && paymentRejectionCount <= 1;
  bool get isLiveVerified =>
      (status.toLowerCase() == 'open') && isEscrowVerified;
  bool get isInProgress =>
      status.toLowerCase() == 'in_progress' ||
      status.toLowerCase() == 'in progress';
  bool get isDelivered =>
      status.toLowerCase() == 'delivered' ||
      status.toLowerCase() == 'submitted';
  bool get isSubmitted =>
      status.toLowerCase() == 'submitted' ||
      status.toLowerCase() == 'delivered';
  bool get isRevisionRequested => status.toLowerCase() == 'revision_requested';
  bool get isDisputed =>
      status.toLowerCase() == 'disputed' || status.toLowerCase() == 'rejected';
  bool get isDisputeResolved =>
      (disputeResolution != null && disputeResolution!.trim().isNotEmpty) ||
      (status.toLowerCase() == 'completed' &&
          payoutTransactionId != null &&
          payoutTransactionId!.trim().isNotEmpty) ||
      (status.toLowerCase() == 'cancelled' &&
          ((refundTransactionId != null &&
                  refundTransactionId!.trim().isNotEmpty) ||
              payoutType == 'dispute_company_refunded'));
  bool get isReadyForPayout =>
      status.toLowerCase() == 'ready_for_payout' ||
      status.toLowerCase() == 'approved_by_company' ||
      (status.toLowerCase() == 'completed' &&
          (payoutTransactionId == null ||
              payoutTransactionId!.trim().isEmpty));
  bool get isCompleted =>
      (status.toLowerCase() == 'completed' ||
          status.toLowerCase() == 'paid') &&
      payoutTransactionId != null &&
      payoutTransactionId!.trim().isNotEmpty;
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  DateTime? get submittedAtDateTime => submittedAt != null
      ? DateTime.tryParse(submittedAt!)
      : deliveredAtDateTime;

  bool get isHelpEligible {
    if (!isSubmitted || submittedAtDateTime == null || hasHelpRequest) return false;
    return DateTime.now().difference(submittedAtDateTime!).inHours >= 48;
  }

  Duration get helpEligibleRemaining {
    if (submittedAtDateTime == null) return Duration.zero;
    final diff = DateTime.now().difference(submittedAtDateTime!);
    const twoDays = Duration(hours: 48);
    if (diff >= twoDays) return Duration.zero;
    return twoDays - diff;
  }

  String get budget => escrowAmount > 0
      ? 'PKR ${escrowAmount.toStringAsFixed(0)}'
      : 'Academic Credit / Verified Certificate';

  int get remainingRevisions => (maxRevisions - revisionCount).clamp(0, maxRevisions);
  bool get canRequestRevision => revisionCount < maxRevisions;

  DateTime? get deliveredAtDateTime =>
      deliveredAt != null ? DateTime.tryParse(deliveredAt!) : null;

  bool get isAutoReleaseEligible {
    if (!isDelivered || deliveredAtDateTime == null) return false;
    return DateTime.now().difference(deliveredAtDateTime!).inHours >= 120; // 5 days
  }

  Duration get autoReleaseRemaining {
    if (deliveredAtDateTime == null) return Duration.zero;
    final diff = DateTime.now().difference(deliveredAtDateTime!);
    const fiveDays = Duration(days: 5);
    if (diff >= fiveDays) return Duration.zero;
    return fiveDays - diff;
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? requirements,
    List<String>? skillsRequired,
    String? deliverables,
    String? deadline,
    String? projectType,
    int? openings,
    String? additionalInstructions,
    String? companyName,
    String? companyId,
    String? status,
    String? duration,
    int? applicantsCount,
    String? assignedStudent,
    double? progress,
    String? createdAt,
    bool? paymentSent,
    double? escrowAmount,
    String? paymentMethodUsed,
    String? transactionId,
    String? paymentReceiptUrl,
    bool? isEscrowVerified,
    String? verifiedAt,
    String? rejectionReason,
    String? moderationReason,
    int? paymentRejectionCount,
    String? deliveredAt,
    String? disputeCaseId,
    String? disputeReason,
    String? disputeResolution,
    String? payoutType,
    double? studentPayoutAmount,
    double? companyRefundAmount,
    double? platformCommissionAmount,
    String? payoutTransactionId,
    String? payoutReceiptUrl,
    String? refundTransactionId,
    String? refundReceiptUrl,
    String? completedAt,
    int? revisionCount,
    int? maxRevisions,
    String? revisionNotes,
    String? lastRevisionRequestedAt,
    String? revisionDeadline,
    String? submittedAt,
    bool? hasHelpRequest,
    String? paymentStatus,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      deliverables: deliverables ?? this.deliverables,
      deadline: deadline ?? this.deadline,
      projectType: projectType ?? this.projectType,
      openings: openings ?? this.openings,
      additionalInstructions:
          additionalInstructions ?? this.additionalInstructions,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      assignedStudent: assignedStudent ?? this.assignedStudent,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      paymentSent: paymentSent ?? this.paymentSent,
      escrowAmount: escrowAmount ?? this.escrowAmount,
      paymentMethodUsed: paymentMethodUsed ?? this.paymentMethodUsed,
      transactionId: transactionId ?? this.transactionId,
      paymentReceiptUrl: paymentReceiptUrl ?? this.paymentReceiptUrl,
      isEscrowVerified: isEscrowVerified ?? this.isEscrowVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      moderationReason: moderationReason ?? this.moderationReason,
      paymentRejectionCount:
          paymentRejectionCount ?? this.paymentRejectionCount,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      disputeCaseId: disputeCaseId ?? this.disputeCaseId,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeResolution: disputeResolution ?? this.disputeResolution,
      payoutType: payoutType ?? this.payoutType,
      studentPayoutAmount: studentPayoutAmount ?? this.studentPayoutAmount,
      companyRefundAmount: companyRefundAmount ?? this.companyRefundAmount,
      platformCommissionAmount:
          platformCommissionAmount ?? this.platformCommissionAmount,
      payoutTransactionId: payoutTransactionId ?? this.payoutTransactionId,
      payoutReceiptUrl: payoutReceiptUrl ?? this.payoutReceiptUrl,
      refundTransactionId: refundTransactionId ?? this.refundTransactionId,
      refundReceiptUrl: refundReceiptUrl ?? this.refundReceiptUrl,
      completedAt: completedAt ?? this.completedAt,
      revisionCount: revisionCount ?? this.revisionCount,
      maxRevisions: maxRevisions ?? this.maxRevisions,
      revisionNotes: revisionNotes ?? this.revisionNotes,
      lastRevisionRequestedAt:
          lastRevisionRequestedAt ?? this.lastRevisionRequestedAt,
      revisionDeadline: revisionDeadline ?? this.revisionDeadline,
      submittedAt: submittedAt ?? this.submittedAt,
      hasHelpRequest: hasHelpRequest ?? this.hasHelpRequest,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills_required'] ?? json['skills'];
    final rawInstructions = (json['additional_instructions'] ?? '').toString();
    final rawModReason = json['moderation_reason']?.toString();
    final rawRejectionReason = json['rejection_reason']?.toString();

    // Resilient Rejection Reason resolution with fallbacks
    String? resolvedRejection = rawRejectionReason;
    if (resolvedRejection == null || resolvedRejection.trim().isEmpty) {
      if (rawModReason != null && rawModReason.trim().isNotEmpty) {
        resolvedRejection = _cleanRejectionTag(rawModReason);
      } else {
        resolvedRejection = _extractRejectionReason(rawInstructions);
      }
    }

    // Determine payment rejection count
    int rejectionCount =
        (json['payment_rejection_count'] as num?)?.toInt() ?? 0;
    if (rejectionCount == 0) {
      if ((rawModReason?.contains('Attempt 1') ?? false) ||
          (rawModReason?.contains('Resubmitted') ?? false) ||
          rawInstructions.contains('Resubmitted') ||
          rawInstructions.contains('Payment Rejected:')) {
        rejectionCount = 1;
      }
      if ((rawModReason?.contains('Cancelled - Final Rejection') ?? false) ||
          rawInstructions.contains('Payment Cancelled:')) {
        rejectionCount = 2;
      }
    }

    return ProjectModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? 'Development').toString(),
      description: (json['description'] ?? '').toString(),
      requirements: (json['requirements'] ?? '').toString(),
      skillsRequired: (rawSkills as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      deliverables: (json['deliverables'] ?? '').toString(),
      deadline: (json['deadline'] ?? 'Flexible').toString(),
      projectType:
          (json['project_type'] ?? json['work_mode'] ?? 'Remote').toString(),
      openings: (json['openings'] as num?)?.toInt() ?? 1,
      additionalInstructions: rawInstructions,
      companyName: (json['company_name'] ?? '').toString(),
      companyId: (json['company_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending_payment').toString(),
      duration: (json['duration'] ?? '3-4 weeks').toString(),
      applicantsCount: (json['applicants_count'] as num?)?.toInt() ?? 0,
      assignedStudent: json['assigned_student']?.toString(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['created_at'] ?? 'Recently').toString(),
      paymentSent: json['payment_sent'] == true,
      escrowAmount: _parseEscrowAmount(json),
      paymentMethodUsed: json['payment_method_used']?.toString() ??
          _extractPaymentMethod(rawInstructions),
      transactionId: json['transaction_id']?.toString() ??
          _extractTransactionId(rawInstructions),
      paymentReceiptUrl: json['payment_receipt_url']?.toString() ??
          json['attachment_url']?.toString(),
      isEscrowVerified: json['is_escrow_verified'] == true,
      verifiedAt: json['verified_at']?.toString(),
      rejectionReason: resolvedRejection,
      moderationReason: rawModReason,
      paymentRejectionCount: rejectionCount,
      deliveredAt: json['delivered_at']?.toString(),
      disputeCaseId: json['dispute_case_id']?.toString(),
      disputeReason: json['dispute_reason']?.toString(),
      disputeResolution: json['dispute_resolution']?.toString() ??
          json['disputeResolution']?.toString(),
      payoutType: json['payout_type']?.toString(),
      studentPayoutAmount:
          (json['student_payout_amount'] as num?)?.toDouble(),
      companyRefundAmount:
          (json['company_refund_amount'] as num?)?.toDouble(),
      platformCommissionAmount:
          (json['platform_commission_amount'] as num?)?.toDouble(),
      payoutTransactionId: json['payout_transaction_id']?.toString(),
      payoutReceiptUrl: json['payout_receipt_url']?.toString(),
      refundTransactionId: json['refund_transaction_id']?.toString(),
      refundReceiptUrl: json['refund_receipt_url']?.toString(),
      completedAt: json['completed_at']?.toString(),
      revisionCount: (json['revision_count'] as num?)?.toInt() ?? 0,
      maxRevisions: (json['max_revisions'] as num?)?.toInt() ?? 1,
      revisionNotes: json['revision_notes']?.toString(),
      lastRevisionRequestedAt: json['last_revision_requested_at']?.toString(),
      revisionDeadline: json['revision_deadline']?.toString() ??
          json['revisionDeadline']?.toString(),
      submittedAt: json['submitted_at']?.toString() ??
          json['submittedAt']?.toString() ??
          json['delivered_at']?.toString(),
      hasHelpRequest: json['has_help_request'] == true ||
          json['hasHelpRequest'] == true,
      paymentStatus: (json['payment_status'] ??
              json['paymentStatus'] ??
              'escrow_held')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'requirements': requirements,
      'skills_required': skillsRequired,
      'deliverables': deliverables,
      'deadline': deadline,
      'project_type': projectType,
      'openings': openings,
      'additional_instructions': additionalInstructions,
      'company_name': companyName,
      'company_id': companyId,
      'status': status,
      'duration': duration,
      'applicants_count': applicantsCount,
      'assigned_student': assignedStudent,
      'progress': progress,
      'created_at': createdAt,
      'payment_sent': paymentSent,
      'escrow_amount': escrowAmount,
      'payment_method_used': paymentMethodUsed,
      'transaction_id': transactionId,
      'payment_receipt_url': paymentReceiptUrl,
      'is_escrow_verified': isEscrowVerified,
      'verified_at': verifiedAt,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (moderationReason != null) 'moderation_reason': moderationReason,
      'payment_rejection_count': paymentRejectionCount,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (disputeCaseId != null) 'dispute_case_id': disputeCaseId,
      if (disputeReason != null) 'dispute_reason': disputeReason,
      if (disputeResolution != null) 'dispute_resolution': disputeResolution,
      if (payoutType != null) 'payout_type': payoutType,
      if (studentPayoutAmount != null)
        'student_payout_amount': studentPayoutAmount,
      if (companyRefundAmount != null)
        'company_refund_amount': companyRefundAmount,
      if (platformCommissionAmount != null)
        'platform_commission_amount': platformCommissionAmount,
      if (payoutTransactionId != null)
        'payout_transaction_id': payoutTransactionId,
      if (payoutReceiptUrl != null) 'payout_receipt_url': payoutReceiptUrl,
      if (refundTransactionId != null)
        'refund_transaction_id': refundTransactionId,
      if (refundReceiptUrl != null) 'refund_receipt_url': refundReceiptUrl,
      if (completedAt != null) 'completed_at': completedAt,
      'revision_count': revisionCount,
      'max_revisions': maxRevisions,
      if (revisionNotes != null) 'revision_notes': revisionNotes,
      if (lastRevisionRequestedAt != null)
        'last_revision_requested_at': lastRevisionRequestedAt,
      if (revisionDeadline != null) 'revision_deadline': revisionDeadline,
      if (submittedAt != null) 'submitted_at': submittedAt,
      'has_help_request': hasHelpRequest,
      'payment_status': paymentStatus,
    };
  }

  static String? _extractRejectionReason(String? instructions) {
    if (instructions == null || instructions.trim().isEmpty) return null;
    if (instructions.contains('Payment Cancelled:')) {
      final parts = instructions.split('Payment Cancelled:');
      if (parts.length > 1) return parts[1].trim();
    }
    if (instructions.contains('Payment Rejected:')) {
      final parts = instructions.split('Payment Rejected:');
      if (parts.length > 1) return parts[1].trim();
    }
    if (instructions.contains('Reason:')) {
      final match = RegExp(r'Reason:\s*([^|\n]+)').firstMatch(instructions);
      if (match != null) return match.group(1)?.trim();
    }
    return null;
  }

  static String _cleanRejectionTag(String text) {
    var cleaned = text.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^\[Attempt 1 Rejected\]\s*'), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'^\[Cancelled - Final Rejection\]\s*'), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'^\[Resubmitted - Final Chance\]\s*Prev:\s*'), '');
    return cleaned.trim();
  }

  static String? _extractTransactionId(String? instructions) {
    if (instructions == null || !instructions.contains('TID:')) return null;
    final match = RegExp(r'TID:\s*([^\s|]+)').firstMatch(instructions);
    return match?.group(1);
  }

  static String? _extractPaymentMethod(String? instructions) {
    if (instructions == null || !instructions.contains('Payment')) return null;
    final match =
        RegExp(r'Payment(?:\s*Method)?:\s*([^|]+)').firstMatch(instructions);
    return match?.group(1)?.trim();
  }

  static double _parseEscrowAmount(Map<String, dynamic> json) {
    final raw = json['escrow_amount'] ??
        json['escrowAmount'] ??
        json['budget_amount'] ??
        json['budgetAmount'] ??
        json['budget'] ??
        json['stipend'] ??
        json['amount'];
    if (raw is num && raw > 0) return raw.toDouble();
    if (raw != null) {
      final clean = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final val = double.tryParse(clean);
      if (val != null && val > 0) return val;
    }
    final fromInstructions =
        extractEscrowAmount(json['additional_instructions']?.toString());
    if (fromInstructions != null && fromInstructions > 0) {
      return fromInstructions;
    }
    return 0.0;
  }

  static double? extractEscrowAmount(String? instructions) {
    if (instructions == null || instructions.trim().isEmpty) return null;
    final match = RegExp(
      r'(?:escrow|amount|budget|deposit|price|fee|pkr)\s*[:=]?\s*(?:pkr)?\s*([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(instructions);
    if (match != null) {
      final clean = match.group(1)?.replaceAll(',', '');
      return double.tryParse(clean ?? '');
    }
    return null;
  }
}
