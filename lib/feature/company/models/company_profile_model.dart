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
    this.logoInitial = 'CO',
    this.isVerified = false,
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
    final name = (json['company_name'] ?? '').toString();
    final derivedInitial = name.trim().length >= 2
        ? name.trim().substring(0, 2).toUpperCase()
        : (name.trim().isNotEmpty ? name.trim().toUpperCase() : 'CO');
    return CompanyProfileModel(
      id: (json['id'] ?? '').toString(),
      companyName: name,
      industry: (json['industry'] ?? 'Software & Cloud Services').toString(),
      description: (json['description'] ?? '').toString(),
      officialEmail: (json['official_email'] ?? json['email'] ?? '').toString(),
      websiteUrl: (json['website_url'] ?? json['website'] ?? '').toString(),
      contactPersonName:
          (json['contact_person_name'] ?? json['contact_person'] ?? '')
              .toString(),
      phoneNumber: (json['phone_number'] ?? json['phone'] ?? '').toString(),
      city: (json['city'] ?? json['location'] ?? '').toString(),
      completeAddress:
          (json['complete_address'] ?? json['address'] ?? '').toString(),
      logoUrl: json['logo_url']?.toString(),
      logoInitial: (json['logo_initial']?.toString().trim().isNotEmpty == true)
          ? json['logo_initial'].toString()
          : derivedInitial,
      isVerified: json['is_verified'] ??
          (json['verification_status']?.toString() == 'verified'),
      lastUpdated: (json['last_updated'] ?? json['updated_at'] ?? 'Recently')
          .toString(),
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

