class ApplicantModel {
  final String id;
  final String projectId;
  final String projectTitle;
  final String name;
  final String email;
  final String university;
  final String degree;
  final double cgpa;
  final List<String> skills;
  final String appliedDate;
  final String proposalSummary;
  final String status; // 'Pending', 'Under Review', 'Shortlisted', 'Accepted', 'Rejected'
  final String avatarInitial;
  final String? profilePictureUrl;
  final String portfolioUrl;
  final double rating;

  ApplicantModel({
    required this.id,
    required this.projectId,
    this.projectTitle = 'Project Challenge',
    required this.name,
    required this.email,
    required this.university,
    required this.degree,
    required this.cgpa,
    required this.skills,
    required this.appliedDate,
    required this.proposalSummary,
    this.status = 'Pending',
    this.avatarInitial = 'AK',
    this.profilePictureUrl,
    this.portfolioUrl = '',
    this.rating = 4.8,
  });

  ApplicantModel copyWith({
    String? id,
    String? projectId,
    String? projectTitle,
    String? name,
    String? email,
    String? university,
    String? degree,
    double? cgpa,
    List<String>? skills,
    String? appliedDate,
    String? proposalSummary,
    String? status,
    String? avatarInitial,
    String? profilePictureUrl,
    String? portfolioUrl,
    double? rating,
  }) {
    return ApplicantModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      name: name ?? this.name,
      email: email ?? this.email,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      cgpa: cgpa ?? this.cgpa,
      skills: skills ?? this.skills,
      appliedDate: appliedDate ?? this.appliedDate,
      proposalSummary: proposalSummary ?? this.proposalSummary,
      status: status ?? this.status,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      rating: rating ?? this.rating,
    );
  }

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      projectTitle: json['project_title'] ?? 'Project Challenge',
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
      proposalSummary:
          json['proposal_summary'] ?? json['cover_letter'] ?? 'Student proposal submitted for project evaluation.',
      status: json['status'] ?? 'Pending',
      avatarInitial: json['avatar_initial'] ??
          (json['name'] != null && (json['name'] as String).length >= 2
              ? (json['name'] as String).substring(0, 2).toUpperCase()
              : 'ST'),
      profilePictureUrl: json['profile_picture_url'],
      portfolioUrl: json['portfolio_url'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_title': projectTitle,
      'name': name,
      'email': email,
      'university': university,
      'degree': degree,
      'cgpa': cgpa,
      'skills': skills,
      'applied_date': appliedDate,
      'proposal_summary': proposalSummary,
      'status': status,
      'avatar_initial': avatarInitial,
      'profile_picture_url': profilePictureUrl,
      'portfolio_url': portfolioUrl,
      'rating': rating,
    };
  }
}
