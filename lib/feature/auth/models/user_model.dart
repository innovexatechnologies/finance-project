class UserModel {
  final String uid;
  final String name;
  final String email;
  final String userType; // 'Admin', 'Company', or 'Student'

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'Student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'user_type': userType,
    };
  }
}
