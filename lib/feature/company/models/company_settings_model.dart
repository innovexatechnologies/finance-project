class CompanySettingsModel {
  final bool privacyDirectoryVisible;
  final bool privacyShowContactPerson;
  final bool privacyShareAnalytics;

  const CompanySettingsModel({
    this.privacyDirectoryVisible = true,
    this.privacyShowContactPerson = true,
    this.privacyShareAnalytics = true,
  });

  CompanySettingsModel copyWith({
    bool? privacyDirectoryVisible,
    bool? privacyShowContactPerson,
    bool? privacyShareAnalytics,
  }) {
    return CompanySettingsModel(
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
      privacyDirectoryVisible: json['privacy_directory_visible'] ?? true,
      privacyShowContactPerson: json['privacy_show_contact_person'] ?? true,
      privacyShareAnalytics: json['privacy_share_analytics'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy_directory_visible': privacyDirectoryVisible,
      'privacy_show_contact_person': privacyShowContactPerson,
      'privacy_share_analytics': privacyShareAnalytics,
    };
  }
}

