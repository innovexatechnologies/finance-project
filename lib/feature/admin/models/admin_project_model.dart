enum AdminProjectStatus {
  draft,
  pendingReview,
  published,
  active,
  completed,
  closed,
  rejected,
  removed,
}

enum AdminPublicationStatus {
  published,
  unpublished,
  pendingModeration,
  rejected,
  removed,
}

class ProjectModerationRecord {
  final String id;
  final String action;
  final String moderatorName;
  final String timestamp;
  final String? reason;

  const ProjectModerationRecord({
    required this.id,
    required this.action,
    required this.moderatorName,
    required this.timestamp,
    this.reason,
  });
}

class AdminProjectModel {
  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String category;
  final String description;
  final String requirements;
  final List<String> skillsRequired;
  final String deliverables;
  final String deadline;
  final DateTime deadlineDateTime;
  final String projectType; // 'Remote', 'Hybrid', 'On-site'
  final String duration;
  final int openings;
  final String additionalInstructions;
  final int applicantsCount;
  final String? assignedStudent;
  final double progress;
  final AdminProjectStatus status;
  final AdminPublicationStatus publicationStatus;
  final String createdAt;
  final DateTime createdDateTime;
  final String? moderationReason;
  final List<ProjectModerationRecord> moderationHistory;
  final bool isArchived; // Soft-retention flag to prevent unauthorized permanent destruction

  const AdminProjectModel({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    required this.category,
    required this.description,
    required this.requirements,
    required this.skillsRequired,
    required this.deliverables,
    required this.deadline,
    required this.deadlineDateTime,
    this.projectType = 'Remote',
    this.duration = '3-4 weeks',
    this.openings = 1,
    this.additionalInstructions = '',
    this.applicantsCount = 0,
    this.assignedStudent,
    this.progress = 0.0,
    required this.status,
    required this.publicationStatus,
    required this.createdAt,
    required this.createdDateTime,
    this.moderationReason,
    required this.moderationHistory,
    this.isArchived = false,
  });

  AdminProjectModel copyWith({
    String? id,
    String? title,
    String? companyId,
    String? companyName,
    String? category,
    String? description,
    String? requirements,
    List<String>? skillsRequired,
    String? deliverables,
    String? deadline,
    DateTime? deadlineDateTime,
    String? projectType,
    String? duration,
    int? openings,
    String? additionalInstructions,
    int? applicantsCount,
    String? assignedStudent,
    double? progress,
    AdminProjectStatus? status,
    AdminPublicationStatus? publicationStatus,
    String? createdAt,
    DateTime? createdDateTime,
    String? moderationReason,
    List<ProjectModerationRecord>? moderationHistory,
    bool? isArchived,
  }) {
    return AdminProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      deliverables: deliverables ?? this.deliverables,
      deadline: deadline ?? this.deadline,
      deadlineDateTime: deadlineDateTime ?? this.deadlineDateTime,
      projectType: projectType ?? this.projectType,
      duration: duration ?? this.duration,
      openings: openings ?? this.openings,
      additionalInstructions:
          additionalInstructions ?? this.additionalInstructions,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      assignedStudent: assignedStudent ?? this.assignedStudent,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      createdAt: createdAt ?? this.createdAt,
      createdDateTime: createdDateTime ?? this.createdDateTime,
      moderationReason: moderationReason ?? this.moderationReason,
      moderationHistory: moderationHistory ?? this.moderationHistory,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  String get statusDisplay {
    switch (status) {
      case AdminProjectStatus.draft:
        return 'Draft';
      case AdminProjectStatus.pendingReview:
        return 'Pending Review';
      case AdminProjectStatus.published:
        return 'Published';
      case AdminProjectStatus.active:
        return 'Active';
      case AdminProjectStatus.completed:
        return 'Completed';
      case AdminProjectStatus.closed:
        return 'Closed';
      case AdminProjectStatus.rejected:
        return 'Rejected';
      case AdminProjectStatus.removed:
        return 'Removed';
    }
  }

  String get publicationStatusDisplay {
    switch (publicationStatus) {
      case AdminPublicationStatus.published:
        return 'Published';
      case AdminPublicationStatus.unpublished:
        return 'Unpublished';
      case AdminPublicationStatus.pendingModeration:
        return 'Pending Moderation';
      case AdminPublicationStatus.rejected:
        return 'Rejected';
      case AdminPublicationStatus.removed:
        return 'Removed Listing';
    }
  }
}

