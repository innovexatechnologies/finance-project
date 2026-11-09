class CompanyProfileModel {
  final String id;
  final String companyName;
  final String industry;
  final String description;
  final String officialEmail;
  final String websiteUrl;
  final String contactPersonName;
  final String phoneNumber;
  final String city;
  final String completeAddress;
  final String? logoUrl;
  final String logoInitial;
  final bool isVerified;
  final String lastUpdated;

  const CompanyProfileModel({
    required this.id,
    required this.companyName,
    required this.industry,
    required this.description,
    required this.officialEmail,
    required this.websiteUrl,
    required this.contactPersonName,
    required this.phoneNumber,
    required this.city,
    required this.completeAddress,
    this.logoUrl,
    this.logoInitial = 'TV',
    this.isVerified = true,
    this.lastUpdated = 'Recently',
  });

  CompanyProfileModel copyWith({
    String? id,
    String? companyName,
    String? industry,
    String? description,
    String? officialEmail,
    String? websiteUrl,
    String? contactPersonName,
    String? phoneNumber,
    String? city,
    String? completeAddress,
    String? logoUrl,
    String? logoInitial,
    bool? isVerified,
    String? lastUpdated,
  }) {
    return CompanyProfileModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      industry: industry ?? this.industry,
      description: description ?? this.description,
      officialEmail: officialEmail ?? this.officialEmail,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      completeAddress: completeAddress ?? this.completeAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      logoInitial: logoInitial ?? this.logoInitial,
      isVerified: isVerified ?? this.isVerified,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProfileModel(
      id: json['id'] ?? 'comp_01',
      companyName: json['company_name'] ?? '',
      industry: json['industry'] ?? 'Software & Cloud Services',
      description: json['description'] ?? '',
      officialEmail: json['official_email'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      contactPersonName: json['contact_person_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      city: json['city'] ?? '',
      completeAddress: json['complete_address'] ?? '',
      logoUrl: json['logo_url'],
      logoInitial: json['logo_initial'] ?? 'TV',
      isVerified: json['is_verified'] ?? true,
      lastUpdated: json['last_updated'] ?? 'Recently',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'industry': industry,
      'description': description,
      'official_email': officialEmail,
      'website_url': websiteUrl,
      'contact_person_name': contactPersonName,
      'phone_number': phoneNumber,
      'city': city,
      'complete_address': completeAddress,
      'logo_url': logoUrl,
      'logo_initial': logoInitial,
      'is_verified': isVerified,
      'last_updated': lastUpdated,
    };
  }
}

