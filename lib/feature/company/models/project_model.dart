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
  final String status; // 'Draft', 'Open', 'In Progress', 'Completed', 'Closed', 'Cancelled'
  final String duration;
  final String budget; // Strictly excluded from UI
  final int applicantsCount;
  final String? assignedStudent;
  final double progress;
  final String createdAt;

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
    this.companyId = 'comp_01',
    required this.status,
    this.duration = '3-4 weeks',
    this.budget = '',
    this.applicantsCount = 0,
    this.assignedStudent,
    this.progress = 0.0,
    this.createdAt = 'Just now',
  });

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
    String? budget,
    int? applicantsCount,
    String? assignedStudent,
    double? progress,
    String? createdAt,
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
      budget: budget ?? this.budget,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      assignedStudent: assignedStudent ?? this.assignedStudent,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Mobile Dev',
      description: json['description'] ?? '',
      requirements: json['requirements'] ?? '',
      skillsRequired: (json['skills_required'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      deliverables: json['deliverables'] ?? '',
      deadline: json['deadline'] ?? 'Flexible',
      projectType: json['project_type'] ?? 'Remote',
      openings: (json['openings'] as num?)?.toInt() ?? 1,
      additionalInstructions: json['additional_instructions'] ?? '',
      companyName: json['company_name'] ?? 'TechVista Innovations',
      companyId: json['company_id'] ?? 'comp_01',
      status: json['status'] ?? 'Open',
      duration: json['duration'] ?? '3-4 weeks',
      budget: json['budget'] ?? '',
      applicantsCount: (json['applicants_count'] as num?)?.toInt() ?? 0,
      assignedStudent: json['assigned_student'],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] ?? 'Recently',
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
      'budget': budget,
      'applicants_count': applicantsCount,
      'assigned_student': assignedStudent,
      'progress': progress,
      'created_at': createdAt,
    };
  }
}
