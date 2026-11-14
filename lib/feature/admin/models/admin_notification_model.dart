class AdminNotificationModel {
  final String id;
  final String projectId;
  final String title;
  final String message;
  final String notificationType; // 'company_approval', 'auto_release_5_days', 'dispute_raised', 'payout_ready'
  final bool isRead;
  final String createdAt;

  const AdminNotificationModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.isRead = false,
    required this.createdAt,
  });

  AdminNotificationModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? message,
    String? notificationType,
    bool? isRead,
    String? createdAt,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: (json['id'] ?? '').toString(),
      projectId: (json['project_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      notificationType: (json['notification_type'] ?? 'payout_ready').toString(),
      isRead: json['is_read'] == true,
      createdAt: (json['created_at'] ?? 'Just now').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}

