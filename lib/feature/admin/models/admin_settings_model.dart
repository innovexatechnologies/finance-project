import 'package:flutter/material.dart';

/// Project Category Configuration Item
class CategorySettingItem {
  final String id;
  final String name;
  final String description;
  final Color color;
  final int projectCount;
  final bool isActive;
  final DateTime createdAt;

  const CategorySettingItem({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.projectCount,
    this.isActive = true,
    required this.createdAt,
  });

  CategorySettingItem copyWith({
    String? name,
    String? description,
    Color? color,
    int? projectCount,
    bool? isActive,
  }) {
    return CategorySettingItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      projectCount: projectCount ?? this.projectCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Skill Taxonomy Configuration Item
class SkillSettingItem {
  final String id;
  final String name;
  final String categoryName;
  final int usageCount;
  final bool isActive;
  final DateTime createdAt;

  const SkillSettingItem({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.usageCount,
    this.isActive = true,
    required this.createdAt,
  });

  SkillSettingItem copyWith({
    String? name,
    String? categoryName,
    int? usageCount,
    bool? isActive,
  }) {
    return SkillSettingItem(
      id: id,
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Accredited University Institution Item
class UniversitySettingItem {
  final String id;
  final String name;
  final String shortName;
  final String city;
  final String province;
  final String domain;
  final int studentCount;
  final bool isActive;
  final DateTime createdAt;

  const UniversitySettingItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
    required this.province,
    required this.domain,
    required this.studentCount,
    this.isActive = true,
    required this.createdAt,
  });

  UniversitySettingItem copyWith({
    String? name,
    String? shortName,
    String? city,
    String? province,
    String? domain,
    int? studentCount,
    bool? isActive,
  }) {
    return UniversitySettingItem(
      id: id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      city: city ?? this.city,
      province: province ?? this.province,
      domain: domain ?? this.domain,
      studentCount: studentCount ?? this.studentCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Support Ticket / Help Request Item
enum HelpRequestStatus { pending, inProgress, resolved }
enum HelpRequestPriority { normal, high, urgent }

class HelpRequestItem {
  final String id;
  final String senderName;
  final String senderEmail;
  final String userType; // 'student' or 'company'
  final String subject;
  final String message;
  final String category;
  final HelpRequestStatus status;
  final HelpRequestPriority priority;
  final DateTime submittedAt;
  final String? adminResponse;
  final String? respondedByAdmin;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const HelpRequestItem({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.userType,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.priority,
    required this.submittedAt,
    this.adminResponse,
    this.respondedByAdmin,
    this.resolvedAt,
    this.resolutionNotes,
  });

  HelpRequestItem copyWith({
    HelpRequestStatus? status,
    HelpRequestPriority? priority,
    String? adminResponse,
    String? respondedByAdmin,
    DateTime? resolvedAt,
    String? resolutionNotes,
  }) {
    return HelpRequestItem(
      id: id,
      senderName: senderName,
      senderEmail: senderEmail,
      userType: userType,
      subject: subject,
      message: message,
      category: category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      submittedAt: submittedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedByAdmin: respondedByAdmin ?? this.respondedByAdmin,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}

/// Complaint & Grievance Item
enum ComplaintStatus { newComplaint, underInvestigation, resolved, dismissed }
enum ComplaintSeverity { low, medium, high, critical }

class ComplaintHistoryEvent {
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String notes;

  const ComplaintHistoryEvent({
    required this.action,
    required this.performedBy,
    required this.timestamp,
    required this.notes,
  });
}

class ComplaintItem {
  final String id;
  final String complainantName;
  final String complainantEmail;
  final String reportedEntityName;
  final String reportedEntityType; // 'student', 'company', 'project'
  final String category;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final ComplaintSeverity severity;
  final DateTime submittedAt;
  final String? investigationNotes;
  final String? resolutionReason;
  final String? resolvedByAdmin;
  final DateTime? resolvedAt;
  final List<ComplaintHistoryEvent> history;

  const ComplaintItem({
    required this.id,
    required this.complainantName,
    required this.complainantEmail,
    required this.reportedEntityName,
    required this.reportedEntityType,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.severity,
    required this.submittedAt,
    this.investigationNotes,
    this.resolutionReason,
    this.resolvedByAdmin,
    this.resolvedAt,
    this.history = const [],
  });

  ComplaintItem copyWith({
    ComplaintStatus? status,
    ComplaintSeverity? severity,
    String? investigationNotes,
    String? resolutionReason,
    String? resolvedByAdmin,
    DateTime? resolvedAt,
    List<ComplaintHistoryEvent>? history,
  }) {
    return ComplaintItem(
      id: id,
      complainantName: complainantName,
      complainantEmail: complainantEmail,
      reportedEntityName: reportedEntityName,
      reportedEntityType: reportedEntityType,
      category: category,
      subject: subject,
      description: description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      submittedAt: submittedAt,
      investigationNotes: investigationNotes ?? this.investigationNotes,
      resolutionReason: resolutionReason ?? this.resolutionReason,
      resolvedByAdmin: resolvedByAdmin ?? this.resolvedByAdmin,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      history: history ?? this.history,
    );
  }
}

/// Platform Policy & Guidelines Item
class PolicyVersionRecord {
  final String version;
  final DateTime updatedAt;
  final String updatedByAdmin;
  final String changeSummary;

  const PolicyVersionRecord({
    required this.version,
    required this.updatedAt,
    required this.updatedByAdmin,
    required this.changeSummary,
  });
}

class PlatformPolicyItem {
  final String id;
  final String title;
  final String policyKey; // 'terms', 'privacy', 'community', 'studentCode', 'companySla'
  final String version;
  final DateTime lastUpdatedAt;
  final String updatedByAdmin;
  final String content;
  final List<PolicyVersionRecord> history;

  const PlatformPolicyItem({
    required this.id,
    required this.title,
    required this.policyKey,
    required this.version,
    required this.lastUpdatedAt,
    required this.updatedByAdmin,
    required this.content,
    this.history = const [],
  });

  PlatformPolicyItem copyWith({
    String? title,
    String? version,
    DateTime? lastUpdatedAt,
    String? updatedByAdmin,
    String? content,
    List<PolicyVersionRecord>? history,
  }) {
    return PlatformPolicyItem(
      id: id,
      title: title ?? this.title,
      policyKey: policyKey,
      version: version ?? this.version,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      updatedByAdmin: updatedByAdmin ?? this.updatedByAdmin,
      content: content ?? this.content,
      history: history ?? this.history,
    );
  }
}

/// Admin Login Session Item
class AdminSessionItem {
  final String sessionId;
  final String device;
  final String browser;
  final String ipAddress;
  final String location;
  final DateTime loginAt;
  final bool isCurrent;

  const AdminSessionItem({
    required this.sessionId,
    required this.device,
    required this.browser,
    required this.ipAddress,
    required this.location,
    required this.loginAt,
    this.isCurrent = false,
  });
}

/// Immutable Administrative Audit Log Entry
class AdminAuditLogItem {
  final String id;
  final String adminEmail;
  final String action;
  final String target;
  final DateTime timestamp;
  final String details;
  final String ipAddress;

  const AdminAuditLogItem({
    required this.id,
    required this.adminEmail,
    required this.action,
    required this.target,
    required this.timestamp,
    required this.details,
    required this.ipAddress,
  });
}

