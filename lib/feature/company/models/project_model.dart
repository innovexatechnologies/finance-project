class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String budget;
  final String companyName;
  final String status;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.companyName,
    required this.status,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      budget: json['budget'] ?? '',
      companyName: json['company_name'] ?? 'Innovexa Technologies',
      status: json['status'] ?? 'Open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'budget': budget,
      'company_name': companyName,
      'status': status,
    };
  }
}