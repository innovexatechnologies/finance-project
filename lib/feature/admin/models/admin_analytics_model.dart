import 'package:flutter/material.dart';

/// Timeframe selection for BI Analytics filtering
enum AnalyticsTimeframe {
  last7Days('Last 7 Days', 'Daily breakdown over previous 7 days'),
  last30Days('Last 30 Days', 'Weekly progression over 30 days'),
  thisQuarter('This Quarter', 'Monthly cadence across current quarter'),
  thisYear('This Year', 'Full annual metric performance'),
  allTime('All-Time', 'Historical cumulative ledger');

  final String label;
  final String description;
  const AnalyticsTimeframe(this.label, this.description);
}

/// Registration Trend Data Point for multi-line and bar charts
class RegistrationTrendPoint {
  final String label;
  final DateTime date;
  final int studentRegistrations;
  final int companyRegistrations;
  final int cumulativeStudents;
  final int cumulativeCompanies;
  final double growthRatePercentage;

  const RegistrationTrendPoint({
    required this.label,
    required this.date,
    required this.studentRegistrations,
    required this.companyRegistrations,
    required this.cumulativeStudents,
    required this.cumulativeCompanies,
    required this.growthRatePercentage,
  });
}

/// Project & Completion Trend Point
class ProjectTrendPoint {
  final String label;
  final DateTime date;
  final int projectsCreated;
  final int projectsPublished;
  final int projectsActive;
  final int projectsCompleted;
  final int projectsClosed;
  final double completionRatePercentage;

  const ProjectTrendPoint({
    required this.label,
    required this.date,
    required this.projectsCreated,
    required this.projectsPublished,
    required this.projectsActive,
    required this.projectsCompleted,
    required this.projectsClosed,
    required this.completionRatePercentage,
  });
}

/// Category Performance Item
class CategoryDistributionItem {
  final String categoryName;
  final int projectCount;
  final int studentParticipants;
  final int companyCount;
  final double percentage;
  final Color color;
  final int completedProjects;

  const CategoryDistributionItem({
    required this.categoryName,
    required this.projectCount,
    required this.studentParticipants,
    required this.companyCount,
    required this.percentage,
    required this.color,
    required this.completedProjects,
  });
}

/// Market Demand for Skills Analytics
class SkillDemandItem {
  final String skillName;
  final int projectRequirementCount;
  final int certifiedStudentCount;
  final String primaryCategory;
  final double demandGrowthRate;

  const SkillDemandItem({
    required this.skillName,
    required this.projectRequirementCount,
    required this.certifiedStudentCount,
    required this.primaryCategory,
    required this.demandGrowthRate,
  });
}

/// Verification Analytics Summary
class VerificationAnalyticsSummary {
  final int totalRequests;
  final int approvedCount;
  final int rejectedCount;
  final int pendingCount;
  final double approvalRatePercentage;
  final double averageTurnaroundHours;
  final int studentVerificationsTotal;
  final int companyVerificationsTotal;

  const VerificationAnalyticsSummary({
    required this.totalRequests,
    required this.approvedCount,
    required this.rejectedCount,
    required this.pendingCount,
    required this.approvalRatePercentage,
    required this.averageTurnaroundHours,
    required this.studentVerificationsTotal,
    required this.companyVerificationsTotal,
  });
}

/// User Engagement & Application Metrics
class UserEngagementSummary {
  final int activeStudents;
  final int totalStudents;
  final int activeCompanies;
  final int totalCompanies;
  final int totalApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final int pendingApplications;
  final double applicationAcceptanceRate;
  final double averageApplicationsPerProject;
  final double engagementIndex; // 0.0 - 100.0 score

  const UserEngagementSummary({
    required this.activeStudents,
    required this.totalStudents,
    required this.activeCompanies,
    required this.totalCompanies,
    required this.totalApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.pendingApplications,
    required this.applicationAcceptanceRate,
    required this.averageApplicationsPerProject,
    required this.engagementIndex,
  });
}

/// Executive BI Generated Report Metadata
class AnalyticsReportModel {
  final String reportId;
  final String title;
  final AnalyticsTimeframe timeframe;
  final String categoryFilter;
  final DateTime generatedAt;
  final String generatedByAdmin;
  final String reportStatus; // 'Ready', 'Exported', 'Processing'
  final String executiveSummary;
  final String cryptographicChecksum;

  const AnalyticsReportModel({
    required this.reportId,
    required this.title,
    required this.timeframe,
    required this.categoryFilter,
    required this.generatedAt,
    required this.generatedByAdmin,
    required this.reportStatus,
    required this.executiveSummary,
    required this.cryptographicChecksum,
  });

  AnalyticsReportModel copyWith({
    String? reportStatus,
  }) {
    return AnalyticsReportModel(
      reportId: reportId,
      title: title,
      timeframe: timeframe,
      categoryFilter: categoryFilter,
      generatedAt: generatedAt,
      generatedByAdmin: generatedByAdmin,
      reportStatus: reportStatus ?? this.reportStatus,
      executiveSummary: executiveSummary,
      cryptographicChecksum: cryptographicChecksum,
    );
  }
}

/// Detailed Data Table Row for tabular breakdown
class AnalyticsTableRow {
  final String periodLabel;
  final int studentRegistrations;
  final int companyRegistrations;
  final int projectsPublished;
  final int projectsCompleted;
  final int applicationsSubmitted;
  final double completionRate;
  final double growthRate;
  final String healthStatus; // 'Optimal', 'Expanding', 'Stable'

  const AnalyticsTableRow({
    required this.periodLabel,
    required this.studentRegistrations,
    required this.companyRegistrations,
    required this.projectsPublished,
    required this.projectsCompleted,
    required this.applicationsSubmitted,
    required this.completionRate,
    required this.growthRate,
    required this.healthStatus,
  });
}

