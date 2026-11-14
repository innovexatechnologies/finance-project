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
  final String status; // 'pending_payment', 'pending_verification', 'Open', 'In Progress', 'Completed', 'Closed', 'Cancelled', 'rejected'
  final String duration;
  final int applicantsCount;
  final String? assignedStudent;
  final double progress;
  final String createdAt;

  // Upfront Custodial Escrow Fields
  final double escrowAmount;
  final String? paymentMethodUsed;
  final String? transactionId;
  final String? paymentReceiptUrl;
  final bool isEscrowVerified;
  final String? verifiedAt;

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
    this.escrowAmount = 0.0,
    this.paymentMethodUsed,
    this.transactionId,
    this.paymentReceiptUrl,
    this.isEscrowVerified = false,
    this.verifiedAt,
  });

  bool get isPendingPayment => status.toLowerCase() == 'pending_payment';
  bool get isPendingVerification =>
      status.toLowerCase() == 'pending_verification';
  bool get isLiveVerified =>
      (status.toLowerCase() == 'open') && isEscrowVerified;

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
    double? escrowAmount,
    String? paymentMethodUsed,
    String? transactionId,
    String? paymentReceiptUrl,
    bool? isEscrowVerified,
    String? verifiedAt,
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
      escrowAmount: escrowAmount ?? this.escrowAmount,
      paymentMethodUsed: paymentMethodUsed ?? this.paymentMethodUsed,
      transactionId: transactionId ?? this.transactionId,
      paymentReceiptUrl: paymentReceiptUrl ?? this.paymentReceiptUrl,
      isEscrowVerified: isEscrowVerified ?? this.isEscrowVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills_required'] ?? json['skills'];
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
      additionalInstructions:
          (json['additional_instructions'] ?? '').toString(),
      companyName: (json['company_name'] ?? '').toString(),
      companyId: (json['company_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending_payment').toString(),
      duration: (json['duration'] ?? '3-4 weeks').toString(),
      applicantsCount: (json['applicants_count'] as num?)?.toInt() ?? 0,
      assignedStudent: json['assigned_student']?.toString(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['created_at'] ?? 'Recently').toString(),
      escrowAmount: (json['escrow_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethodUsed: json['payment_method_used']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      paymentReceiptUrl: json['payment_receipt_url']?.toString(),
      isEscrowVerified: json['is_escrow_verified'] == true,
      verifiedAt: json['verified_at']?.toString(),
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
      'escrow_amount': escrowAmount,
      'payment_method_used': paymentMethodUsed,
      'transaction_id': transactionId,
      'payment_receipt_url': paymentReceiptUrl,
      'is_escrow_verified': isEscrowVerified,
      'verified_at': verifiedAt,
    };
  }
}
