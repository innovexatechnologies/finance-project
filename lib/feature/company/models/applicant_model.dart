class ApplicantModel {
  final String id;
  final String projectId;
  final String name;
  final String email;
  final String university;
  final String degree;
  final double cgpa;
  final List<String> skills;
  final String appliedDate;
  final String status; // 'Pending', 'Shortlisted', 'Hired', 'Rejected'
  final String portfolioUrl;
  final String coverLetter;
  final double rating;

  ApplicantModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.email,
    required this.university,
    required this.degree,
    required this.cgpa,
    required this.skills,
    required this.appliedDate,
    this.status = 'Pending',
    this.portfolioUrl = '',
    this.coverLetter = '',
    this.rating = 4.8,
  });

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      university: json['university'] ?? '',
      degree: json['degree'] ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 3.5,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      appliedDate: json['applied_date'] ?? 'Recently',
      status: json['status'] ?? 'Pending',
      portfolioUrl: json['portfolio_url'] ?? '',
      coverLetter: json['cover_letter'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'email': email,
      'university': university,
      'degree': degree,
      'cgpa': cgpa,
      'skills': skills,
      'applied_date': appliedDate,
      'status': status,
      'portfolio_url': portfolioUrl,
      'cover_letter': coverLetter,
      'rating': rating,
    };
  }
}

