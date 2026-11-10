enum CompanyActivityType {
  application,
  submission,
  statusUpdate,
  projectActivity,
}

class CompanyActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final CompanyActivityType type;
  final String? projectId;

  const CompanyActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
    this.projectId,
  });
}

class CompanyDashboardStats {
  final int totalPostedProjects;
  final int activeProjects;
  final int completedProjects;
  final int pendingApplications;

  const CompanyDashboardStats({
    required this.totalPostedProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.pendingApplications,
  });
}

class CompanyProfileInfo {
  final String companyName;
  final String tagline;
  final String industry;
  final bool isVerified;
  final int unreadNotificationsCount;

  const CompanyProfileInfo({
    required this.companyName,
    required this.tagline,
    required this.industry,
    this.isVerified = false,
    this.unreadNotificationsCount = 0,
  });
}

