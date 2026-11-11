class AdminUserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String roleDisplayName;
  final String department;
  final String avatarInitial;
  final List<String> permissions;
  final String lastLoginAt;
  final String? sessionToken;
  final bool isTwoFactorEnabled;
  final bool isActive;

  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.roleDisplayName,
    required this.department,
    required this.avatarInitial,
    required this.permissions,
    required this.lastLoginAt,
    this.sessionToken,
    this.isTwoFactorEnabled = true,
    this.isActive = true,
  });

  bool get isSuperAdmin => role == 'SUPER_ADMIN' || permissions.contains('all');
  bool get canVerifyCompanies => permissions.contains('verify_companies') || isSuperAdmin;
  bool get canVerifyStudents => permissions.contains('verify_students') || isSuperAdmin;
  bool get canAuditProjects => permissions.contains('audit_projects') || isSuperAdmin;
  bool get canManageSettings => permissions.contains('manage_settings') || isSuperAdmin;

  AdminUserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? roleDisplayName,
    String? department,
    String? avatarInitial,
    List<String>? permissions,
    String? lastLoginAt,
    String? sessionToken,
    bool? isTwoFactorEnabled,
    bool? isActive,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      roleDisplayName: roleDisplayName ?? this.roleDisplayName,
      department: department ?? this.department,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      permissions: permissions ?? this.permissions,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      sessionToken: sessionToken ?? this.sessionToken,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      roleDisplayName: json['role_display_name'] as String,
      department: json['department'] as String? ?? 'SkillBridge Executive Council',
      avatarInitial: json['avatar_initial'] as String? ?? 'AD',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['all'],
      lastLoginAt: json['last_login_at'] as String? ?? 'Recently',
      sessionToken: json['session_token'] as String?,
      isTwoFactorEnabled: json['is_two_factor_enabled'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'role_display_name': roleDisplayName,
      'department': department,
      'avatar_initial': avatarInitial,
      'permissions': permissions,
      'last_login_at': lastLoginAt,
      'session_token': sessionToken,
      'is_two_factor_enabled': isTwoFactorEnabled,
      'is_active': isActive,
    };
  }
}

