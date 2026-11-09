class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String budget;
  final String companyName;
  final String status; // 'Open', 'In Progress', 'Completed', 'Under Review'
  final String category;
  final List<String> skillsRequired;
  final String duration;
  final String deadline;
  final int applicantsCount;
  final String? assignedStudent;
  final double progress; // 0.0 to 1.0

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.companyName,
    required this.status,
    this.category = 'Development',
    this.skillsRequired = const [],
    this.duration = '2-4 weeks',
    this.deadline = 'Flexible',
    this.applicantsCount = 0,
    this.assignedStudent,
    this.progress = 0.0,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      budget: json['budget'] ?? '',
      companyName: json['company_name'] ?? 'TechCorp Inc.',
      status: json['status'] ?? 'Open',
      category: json['category'] ?? 'Development',
      skillsRequired: (json['skills_required'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      duration: json['duration'] ?? '2-4 weeks',
      deadline: json['deadline'] ?? 'Flexible',
      applicantsCount: json['applicants_count'] ?? 0,
      assignedStudent: json['assigned_student'],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'company_name': companyName,
      'status': status,
      'category': category,
      'skills_required': skillsRequired,
      'duration': duration,
      'deadline': deadline,
      'applicants_count': applicantsCount,
      'assigned_student': assignedStudent,
      'progress': progress,
    };
  }
}
