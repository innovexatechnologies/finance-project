class CompanySettingsModel {
  final bool notifyNewApplications;
  final bool notifyMilestoneSubmissions;
  final bool notifyStatusChanges;
  final bool notifyWeeklyDigest;
  final bool privacyDirectoryVisible;
  final bool privacyShowContactPerson;
  final bool privacyShareAnalytics;

  const CompanySettingsModel({
    this.notifyNewApplications = true,
    this.notifyMilestoneSubmissions = true,
    this.notifyStatusChanges = true,
    this.notifyWeeklyDigest = false,
    this.privacyDirectoryVisible = true,
    this.privacyShowContactPerson = true,
    this.privacyShareAnalytics = true,
  });

  CompanySettingsModel copyWith({
    bool? notifyNewApplications,
    bool? notifyMilestoneSubmissions,
    bool? notifyStatusChanges,
    bool? notifyWeeklyDigest,
    bool? privacyDirectoryVisible,
    bool? privacyShowContactPerson,
    bool? privacyShareAnalytics,
  }) {
    return CompanySettingsModel(
      notifyNewApplications:
          notifyNewApplications ?? this.notifyNewApplications,
      notifyMilestoneSubmissions:
          notifyMilestoneSubmissions ?? this.notifyMilestoneSubmissions,
      notifyStatusChanges: notifyStatusChanges ?? this.notifyStatusChanges,
      notifyWeeklyDigest: notifyWeeklyDigest ?? this.notifyWeeklyDigest,
      privacyDirectoryVisible:
          privacyDirectoryVisible ?? this.privacyDirectoryVisible,
      privacyShowContactPerson:
          privacyShowContactPerson ?? this.privacyShowContactPerson,
      privacyShareAnalytics:
          privacyShareAnalytics ?? this.privacyShareAnalytics,
    );
  }

  factory CompanySettingsModel.fromJson(Map<String, dynamic> json) {
    return CompanySettingsModel(
      notifyNewApplications: json['notify_new_applications'] ?? true,
      notifyMilestoneSubmissions:
          json['notify_milestone_submissions'] ?? true,
      notifyStatusChanges: json['notify_status_changes'] ?? true,
      notifyWeeklyDigest: json['notify_weekly_digest'] ?? false,
      privacyDirectoryVisible: json['privacy_directory_visible'] ?? true,
      privacyShowContactPerson: json['privacy_show_contact_person'] ?? true,
      privacyShareAnalytics: json['privacy_share_analytics'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notify_new_applications': notifyNewApplications,
      'notify_milestone_submissions': notifyMilestoneSubmissions,
      'notify_status_changes': notifyStatusChanges,
      'notify_weekly_digest': notifyWeeklyDigest,
      'privacy_directory_visible': privacyDirectoryVisible,
      'privacy_show_contact_person': privacyShowContactPerson,
      'privacy_share_analytics': privacyShareAnalytics,
    };
  }
}

