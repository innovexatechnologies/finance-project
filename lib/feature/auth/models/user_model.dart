class UserModel {
  final String uid;
  final String name;
  final String email;
  final String userType; // 'Company' ya 'Professional'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
  });

  // Supabase ya database se JSON data ko object mein convert karne ke liye
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'Professional',
    );
  }

  // Database mein bhejne ke liye JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'user_type': userType,
    };
  }
}