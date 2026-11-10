enum ActivityType {
  studentRegistration,
  companyRegistration,
  verificationSubmission,
  newProject,
  projectCompletion,
  reportSubmission,
}

class TrendDataPoint {
  final String label;
  final int students;
  final int companies;
  final int projectsCreated;
  final int projectsCompleted;

  const TrendDataPoint({
    required this.label,
    required this.students,
    required this.companies,
    required this.projectsCreated,
    required this.projectsCompleted,
  });
}

class PlatformStatsModel {
  final int totalStudents;
  final int totalCompanies;
  final int pendingVerifications;
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int pendingReports;
  final double studentGrowth;
  final double companyGrowth;
  final double projectGrowth;
  final double completionRate;
  final Map<String, int> categoryDistribution;
  final List<TrendDataPoint> trends;

  const PlatformStatsModel({
    required this.totalStudents,
    required this.totalCompanies,
    required this.pendingVerifications,
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.pendingReports,
    this.studentGrowth = 0.0,
    this.companyGrowth = 0.0,
    this.projectGrowth = 0.0,
    this.completionRate = 0.0,
    required this.categoryDistribution,
    required this.trends,
  });

  PlatformStatsModel copyWith({
    int? totalStudents,
    int? totalCompanies,
    int? pendingVerifications,
    int? totalProjects,
    int? activeProjects,
    int? completedProjects,
    int? pendingReports,
    double? studentGrowth,
    double? companyGrowth,
    double? projectGrowth,
    double? completionRate,
    Map<String, int>? categoryDistribution,
    List<TrendDataPoint>? trends,
  }) {
    return PlatformStatsModel(
      totalStudents: totalStudents ?? this.totalStudents,
      totalCompanies: totalCompanies ?? this.totalCompanies,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      totalProjects: totalProjects ?? this.totalProjects,
      activeProjects: activeProjects ?? this.activeProjects,
      completedProjects: completedProjects ?? this.completedProjects,
      pendingReports: pendingReports ?? this.pendingReports,
      studentGrowth: studentGrowth ?? this.studentGrowth,
      companyGrowth: companyGrowth ?? this.companyGrowth,
      projectGrowth: projectGrowth ?? this.projectGrowth,
      completionRate: completionRate ?? this.completionRate,
      categoryDistribution: categoryDistribution ?? this.categoryDistribution,
      trends: trends ?? this.trends,
    );
  }
}

class AdminActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String timeAgo;
  final String actorName;
  final String actorRole;
  final String badgeText;

  const AdminActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.actorName,
    required this.actorRole,
    required this.badgeText,
  });
}

