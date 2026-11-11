import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enterprise Student Management Screen (Screen 35)
/// Features student registry overview, multi-tier filters, detailed profile inspection,
/// document authentication, suspension controls, bulk batch verification, and CSV export.
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminStudentService _studentService = AdminStudentService();
  final AdminSettingsService _settingsService = AdminSettingsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedUniversity = 'All Universities';
  String _selectedDepartment = 'All Departments';
  String _selectedVerificationStatus = 'All'; // 'All', 'Verified', 'Pending', 'Rejected'
  String _selectedAccountStatus = 'All'; // 'All', 'Active', 'Suspended'
  String _selectedEngagement = 'All'; // 'All', 'Engaged in Projects', 'Active Projects', 'Completed'
  String _sortBy = 'Newest First'; // 'Newest First', 'Oldest First', 'Most Engaged', 'Highest CGPA'

  bool _isSidebarCollapsed = false;
  final Set<String> _selectedStudentIds = {};

  // Pagination controls
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _verificationFilters = ['All', 'Verified', 'Pending', 'Rejected'];
  final List<String> _accountFilters = ['All', 'Active', 'Suspended'];
  final List<String> _engagementFilters = [
    'All',
    'Engaged in Projects',
    'Active Projects',
    'Completed',
  ];
  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Most Engaged',
    'Highest CGPA',
  ];

  List<String> _buildUniversityOptions(List<AdminStudentModel> students) {
    final set = <String>{'All Universities'};
    for (final uni in _settingsService.universitiesNotifier.value) {
      final name = uni.name.trim();
      if (name.isNotEmpty) set.add(name);
    }
    for (final s in students) {
      final name = s.university.trim();
      if (name.isNotEmpty) set.add(name);
    }
    return set.toList();
  }

  List<String> _buildDepartmentOptions(List<AdminStudentModel> students) {
    final set = <String>{'All Departments'};
    for (final s in students) {
      final dept = s.department.trim();
      if (dept.isNotEmpty) set.add(dept);
    }
    return set.toList();
  }

  Future<void> _refreshStudents() async {
    await _studentService.loadFromSupabase();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student directory synced from Supabase.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchExternalUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or incomplete document URL.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the uploaded document.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to launch document link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out Console'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your active administrative session? Session credentials will be invalidated securely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  void _onRouteSelected(String routeId) {
    AdminSidebar.navigateToRoute(
      context,
      scaffoldKey: _scaffoldKey,
      currentRouteId: 'student_verifications',
      targetRouteId: routeId,
    );
  }

  void _openStudentProfileDrawer(AdminStudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            student.avatarInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                student.email,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Status Summary Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusPill(
                    label: student.verificationStatus == StudentVerificationStatus.verified
                        ? 'Education Verified'
                        : student.verificationStatus == StudentVerificationStatus.pending
                            ? 'Verification Pending'
                            : 'Verification Rejected',
                    color: student.verificationStatus == StudentVerificationStatus.verified
                        ? AppColors.success
                        : student.verificationStatus == StudentVerificationStatus.pending
                            ? AppColors.warning
                            : AppColors.error,
                    bgColor: student.verificationStatus == StudentVerificationStatus.verified
                        ? AppColors.successBg
                        : student.verificationStatus == StudentVerificationStatus.pending
                            ? AppColors.warningBg
                            : AppColors.errorBg,
                  ),
                  _buildStatusPill(
                    label: student.accountStatus == StudentAccountStatus.active
                        ? 'Account Active'
                        : 'Account Suspended',
                    color: student.accountStatus == StudentAccountStatus.active
                        ? AppColors.primary
                        : AppColors.error,
                    bgColor: student.accountStatus == StudentAccountStatus.active
                        ? AppColors.lightIceBlue
                        : AppColors.errorBg,
                  ),
                  _buildStatusPill(
                    label: 'CGPA: ${student.cgpa}',
                    color: AppColors.darkNavy,
                    bgColor: AppColors.background,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Personal & Biography
              _buildSectionHeader('1. Personal Profile & Bio'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  student.bio.isEmpty ? 'No biography provided yet.' : student.bio,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Academic & Education Credentials
              _buildSectionHeader('2. Institutional Academic Enrollment'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.school_rounded, 'University', student.university),
              _buildInfoRow(Icons.domain_rounded, 'Department', student.department),
              _buildInfoRow(Icons.workspace_premium_rounded, 'Degree Program', student.degree),
              _buildInfoRow(Icons.timeline_rounded, 'Current Semester', student.semester),
              _buildInfoRow(Icons.calendar_today_rounded, 'Registered On', student.registrationDate),
              const SizedBox(height: 20),

              // 3. Technical Skills
              _buildSectionHeader('3. Technical Skillset'),
              const SizedBox(height: 8),
              if (student.skills.isEmpty)
                Text(
                  'No skills listed by student.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: student.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lightIceBlue,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        skill,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // 4. Portfolio & Online Profiles
              _buildSectionHeader('4. Portfolio & Project Participation'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.link_rounded, 'Portfolio Link', student.portfolioUrl),
              _buildInfoRow(Icons.code_rounded, 'GitHub Profile', student.githubUrl),
              _buildInfoRow(
                Icons.task_alt_rounded,
                'Project Activity',
                '${student.projectsCompletedCount} Sprints Completed • ${student.activeProjectsCount} Active',
              ),
              const SizedBox(height: 20),

              // 5. Verification Document Attachment
              _buildSectionHeader('5. Uploaded Academic Evidence Document'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.verificationDocumentName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${student.verificationDocumentType} • ${student.verificationDocumentSize}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Inspect Document', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => _openDocumentPreviewModal(student),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. Suspension Notice if Suspended
              if (student.accountStatus == StudentAccountStatus.suspended &&
                  student.suspensionReason != null) ...[
                _buildSectionHeader('Account Suspension Details'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Suspension Reason: "${student.suspensionReason}"',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF991B1B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 7. Administrative Audit History
              _buildSectionHeader('6. Administrative Audit History'),
              const SizedBox(height: 8),
              if (student.auditHistory.isEmpty)
                const Text(
                  'No prior administrative actions recorded.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                )
              else
                ...student.auditHistory.map((audit) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                audit.action,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ),
                            Text(
                              audit.timestamp,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Recorded by: ${audit.adminName}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        if (audit.note != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Note: "${audit.note}"',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Primary Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (student.verificationStatus == StudentVerificationStatus.pending) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject Verification'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptRejectStudentVerification(student);
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Approve Credentials'),
                      onPressed: () async {
                        final admin =
                            _authService.currentAdmin?.fullName ?? 'Executive Administrator';
                        await _studentService.approveStudentVerification(
                          studentId: student.id,
                          adminName: admin,
                        );
                        if (!mounted || !ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${student.name} is now verified!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: student.accountStatus == StudentAccountStatus.active
                          ? AppColors.error
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: Icon(
                      student.accountStatus == StudentAccountStatus.active
                          ? Icons.block_rounded
                          : Icons.lock_open_rounded,
                      size: 16,
                    ),
                    label: Text(
                      student.accountStatus == StudentAccountStatus.active
                          ? 'Suspend Account'
                          : 'Reactivate Account',
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (student.accountStatus == StudentAccountStatus.active) {
                        _promptSuspendStudent(student);
                      } else {
                        _promptReactivateStudent(student);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openDocumentPreviewModal(AdminStudentModel student) {
    final docUrl = (student.verificationDocumentUrl ?? '').trim();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      student.verificationDocumentName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow(
                    Icons.person_outline_rounded,
                    'Student',
                    student.name,
                  ),
                  _buildInfoRow(
                    Icons.school_rounded,
                    'Institution',
                    student.university,
                  ),
                  _buildInfoRow(
                    Icons.workspace_premium_outlined,
                    'Degree',
                    '${student.degree} (${student.semester})',
                  ),
                  _buildInfoRow(
                    Icons.attach_file_rounded,
                    'Document Name',
                    student.verificationDocumentName,
                  ),
                  _buildInfoRow(
                    Icons.insert_drive_file_outlined,
                    'Type & Size',
                    '${student.verificationDocumentType} • ${student.verificationDocumentSize}',
                  ),
                  _buildInfoRow(
                    Icons.cloud_done_outlined,
                    'Cloud Attachment',
                    docUrl.isNotEmpty
                        ? 'Document URL available in storage'
                        : 'No uploaded file URL attached yet',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          if (docUrl.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Uploaded File'),
              onPressed: () => _launchExternalUrl(docUrl),
            ),
        ],
      ),
    );
  }

  void _promptRejectStudentVerification(AdminStudentModel student) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reject Verification: ${student.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A mandatory reason is required to notify the student why their credential could not be authenticated.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Uploaded card is expired or university name is not visible...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _studentService.rejectStudentVerification(
                studentId: student.id,
                reason: reason,
                adminName: admin,
              );

              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification rejected for ${student.name}. Reason logged in audit vault.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Submit Rejection'),
          ),
        ],
      ),
    );
  }

  void _promptSuspendStudent(AdminStudentModel student) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.block_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Suspend Student: ${student.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suspending an account revokes the student\'s ability to apply for company projects or submit work.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Suspension Reason *',
                  hintText: 'e.g. Plagiarism infraction reported by corporate sponsor...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _studentService.suspendStudentAccount(
                studentId: student.id,
                reason: reason,
                adminName: admin,
              );

              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student.name} account has been suspended.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Suspension'),
          ),
        ],
      ),
    );
  }

  void _promptReactivateStudent(AdminStudentModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reactivate Account: ${student.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to reactivate this student\'s account? Platform access will be restored.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final admin =
                  _authService.currentAdmin?.fullName ?? 'Executive Administrator';
              await _studentService.reactivateStudentAccount(
                studentId: student.id,
                adminName: admin,
              );

              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student.name} account is reactivated.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Reactivation'),
          ),
        ],
      ),
    );
  }

  void _handleBulkVerify() async {
    if (_selectedStudentIds.isEmpty) return;

    final count = _selectedStudentIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bulk Verify $count Students?'),
        content: Text(
          'This will approve institutional credentials for all $count selected students simultaneously.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve All Selected'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final admin = _authService.currentAdmin?.fullName ?? 'Executive Administrator';
      await _studentService.bulkApproveStudents(
        studentIds: _selectedStudentIds.toList(),
        adminName: admin,
      );
      setState(() => _selectedStudentIds.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully batch-verified $count student profiles!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportCsvRecords(List<AdminStudentModel> students) {
    final csv = _studentService.exportPermittedStudentsCsv(students);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Export Permitted Student Records',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The authorized student roster has been compiled in CSV format according to institutional compliance policies:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV copied to clipboard!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.darkNavy,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: 'student_verifications',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'student_verifications',
                  onRouteSelected: _onRouteSelected,
                  onSignOut: _handleSignOut,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopNavbar(
                      pageTitle: 'Student',
                      breadcrumb: 'Platform Directory',
                      onOpenDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (q) => setState(() {
                        _searchQuery = q;
                        _currentPage = 1;
                      }),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<List<AdminStudentModel>>(
                        valueListenable: _studentService.studentsNotifier,
                        builder: (context, students, _) {
                          final universities = _buildUniversityOptions(students);
                          final effectiveUniversity =
                              universities.contains(_selectedUniversity)
                                  ? _selectedUniversity
                                  : 'All Universities';
                          final departments = _buildDepartmentOptions(students);
                          final effectiveDepartment =
                              departments.contains(_selectedDepartment)
                                  ? _selectedDepartment
                                  : 'All Departments';

                          // Filter Logic
                          var filtered = students.where((s) {
                            if (effectiveUniversity != 'All Universities' &&
                                s.university != effectiveUniversity) {
                              return false;
                            }
                            if (effectiveDepartment != 'All Departments' &&
                                s.department != effectiveDepartment) {
                              return false;
                            }
                            if (_selectedVerificationStatus == 'Verified' &&
                                s.verificationStatus !=
                                    StudentVerificationStatus.verified) {
                              return false;
                            }
                            if (_selectedVerificationStatus == 'Pending' &&
                                s.verificationStatus !=
                                    StudentVerificationStatus.pending) {
                              return false;
                            }
                            if (_selectedVerificationStatus == 'Rejected' &&
                                s.verificationStatus !=
                                    StudentVerificationStatus.rejected) {
                              return false;
                            }
                            if (_selectedAccountStatus == 'Active' &&
                                s.accountStatus != StudentAccountStatus.active) {
                              return false;
                            }
                            if (_selectedAccountStatus == 'Suspended' &&
                                s.accountStatus !=
                                    StudentAccountStatus.suspended) {
                              return false;
                            }
                            if (_selectedEngagement == 'Engaged in Projects' &&
                                !s.isEngagedInProjects) {
                              return false;
                            }
                            if (_selectedEngagement == 'Active Projects' &&
                                s.activeProjectsCount <= 0) {
                              return false;
                            }
                            if (_selectedEngagement == 'Completed' &&
                                s.projectsCompletedCount <= 0) {
                              return false;
                            }

                            if (_searchQuery.isNotEmpty) {
                              final query = _searchQuery.toLowerCase();
                              return s.name.toLowerCase().contains(query) ||
                                  s.email.toLowerCase().contains(query) ||
                                  s.university.toLowerCase().contains(query) ||
                                  s.degree.toLowerCase().contains(query);
                            }
                            return true;
                          }).toList();

                          // Sorting Logic
                          if (_sortBy == 'Newest First') {
                            filtered.sort((a, b) => b.registrationDateTime
                                .compareTo(a.registrationDateTime));
                          } else if (_sortBy == 'Oldest First') {
                            filtered.sort((a, b) => a.registrationDateTime
                                .compareTo(b.registrationDateTime));
                          } else if (_sortBy == 'Most Engaged') {
                            filtered.sort((a, b) {
                              final scoreA = a.applicationsCount +
                                  a.activeProjectsCount * 2 +
                                  a.projectsCompletedCount * 3;
                              final scoreB = b.applicationsCount +
                                  b.activeProjectsCount * 2 +
                                  b.projectsCompletedCount * 3;
                              return scoreB.compareTo(scoreA);
                            });
                          } else if (_sortBy == 'Highest CGPA') {
                            filtered.sort((a, b) => b.cgpa.compareTo(a.cgpa));
                          }

                          // Pagination slice
                          final totalPages =
                              (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
                          final safePage = _currentPage.clamp(1, totalPages);
                          final startIndex = (safePage - 1) * _itemsPerPage;
                          final pageItems = filtered
                              .skip(startIndex)
                              .take(_itemsPerPage)
                              .toList();

                          return SingleChildScrollView(
                            padding: EdgeInsets.all(isDesktop ? 24 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStudentOverviewMetrics(),
                                const SizedBox(height: 20),
                                _buildFilterAndActionCard(
                                  universities: universities,
                                  selectedUniversity: effectiveUniversity,
                                  departments: departments,
                                  selectedDepartment: effectiveDepartment,
                                  filteredStudents: filtered,
                                ),
                                const SizedBox(height: 20),
                                _buildStudentTableCard(
                                  pageStudents: pageItems,
                                  totalCount: filtered.length,
                                  safePage: safePage,
                                  totalPages: totalPages,
                                  hasAnyStudents: students.isNotEmpty,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. 5 Student Overview Metric Cards
  Widget _buildStudentOverviewMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 5;
        if (constraints.maxWidth < 650) {
          count = 1;
        } else if (constraints.maxWidth < 1100) {
          count = 3;
        }

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: count == 1 ? 2.7 : 1.55,
          children: [
            _buildMetricTile(
              title: 'Total Students',
              value: '${_studentService.totalCount}',
              subtitle: 'Registered on SkillBridge',
              icon: Icons.school_rounded,
              color: AppColors.primary,
              bgColor: AppColors.lightIceBlue,
            ),
            _buildMetricTile(
              title: 'Engaged in Projects',
              value: '${_studentService.engagedCount}',
              subtitle: 'Students with project activity',
              icon: Icons.work_history_rounded,
              color: AppColors.accentTeal,
              bgColor: const Color(0xFFCCFBF1),
            ),
            _buildMetricTile(
              title: 'Active Accounts',
              value: '${_studentService.activeAccountCount}',
              subtitle: 'Currently active on platform',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
            ),
            _buildMetricTile(
              title: 'Verified Students',
              value: '${_studentService.verifiedCount}',
              subtitle: 'Credentials authenticated',
              icon: Icons.verified_rounded,
              color: AppColors.success,
              bgColor: AppColors.successBg,
            ),
            _buildMetricTile(
              title: 'Pending Review',
              value: '${_studentService.pendingCount}',
              subtitle: 'Awaiting verification review',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              bgColor: AppColors.warningBg,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. Search, Multi-Filter & Action Bar
  Widget _buildFilterAndActionCard({
    required List<String> universities,
    required String selectedUniversity,
    required List<String> departments,
    required String selectedDepartment,
    required List<AdminStudentModel> filteredStudents,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Bulk Actions & Export
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 680
                          ? constraints.maxWidth - 440
                          : constraints.maxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Engaged Students Directory',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All students enrolled & engaged in projects across SkillBridge',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh'),
                        onPressed: _refreshStudents,
                      ),
                      if (_selectedStudentIds.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label:
                              Text('Bulk Verify (${_selectedStudentIds.length})'),
                          onPressed: _handleBulkVerify,
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkNavy,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export CSV'),
                        onPressed: () => _exportCsvRecords(filteredStudents),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Filters Row 1: University Dropdown & Department Dropdown & Sort
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: compact ? constraints.maxWidth : 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUniversity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'University Institution',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: universities
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedUniversity = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedDepartment,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Academic Department',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: departments
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDepartment = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _sortOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Filters Row 2: Verification Status Chips & Account Status Chips
          Wrap(
            spacing: 20,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Verification:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  ..._verificationFilters.map((vf) {
                    final isSel = _selectedVerificationStatus == vf;
                    return ChoiceChip(
                      label: Text(vf),
                      selected: isSel,
                      selectedColor: AppColors.darkNavy,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedVerificationStatus = vf;
                            _currentPage = 1;
                          });
                        }
                      },
                    );
                  }),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Account:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  ..._accountFilters.map((af) {
                    final isSel = _selectedAccountStatus == af;
                    return ChoiceChip(
                      label: Text(af),
                      selected: isSel,
                      selectedColor: AppColors.darkNavy,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedAccountStatus = af;
                            _currentPage = 1;
                          });
                        }
                      },
                    );
                  }),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Engagement:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  ..._engagementFilters.map((ef) {
                    final isSel = _selectedEngagement == ef;
                    return ChoiceChip(
                      label: Text(ef),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedEngagement = ef;
                            _currentPage = 1;
                          });
                        }
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(AdminStudentModel student) {
    final isVerified =
        student.verificationStatus == StudentVerificationStatus.verified;
    final isPending =
        student.verificationStatus == StudentVerificationStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.successBg
            : isPending
                ? AppColors.warningBg
                : AppColors.errorBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isVerified
            ? 'Verified'
            : isPending
                ? 'Pending'
                : 'Rejected',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isVerified
              ? const Color(0xFF166534)
              : isPending
                  ? const Color(0xFF92400E)
                  : const Color(0xFF991B1B),
        ),
      ),
    );
  }

  Widget _buildEngagementBadge(AdminStudentModel student) {
    final engaged = student.isEngagedInProjects;
    final label = engaged
        ? '${student.applicationsCount} Apps • ${student.activeProjectsCount} Active • ${student.projectsCompletedCount} Done'
        : 'Joined ${student.registrationDate}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: engaged ? const Color(0xFFCCFBF1) : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: engaged
              ? AppColors.accentTeal.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: engaged ? const Color(0xFF0F766E) : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAccountBadge(bool isSuspended) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuspended ? AppColors.errorBg : AppColors.lightIceBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isSuspended ? 'Suspended' : 'Active',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isSuspended ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }

  // 3. Student Data Table Card with Pagination
  Widget _buildStudentTableCard({
    required List<AdminStudentModel> pageStudents,
    required int totalCount,
    required int safePage,
    required int totalPages,
    required bool hasAnyStudents,
  }) {
    if (pageStudents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: AppEmptyState(
          icon: Icons.person_search_rounded,
          title: hasAnyStudents
              ? 'No student records match the active criteria'
              : 'No student accounts registered yet',
          subtitle: hasAnyStudents
              ? 'Try adjusting the university, department, or verification filter.'
              : 'Registered university students from Supabase will appear here automatically.',
          actionLabel: hasAnyStudents ? 'Reset Filters' : 'Refresh',
          onAction: hasAnyStudents
              ? () {
                  setState(() {
                    _searchQuery = '';
                    _selectedUniversity = 'All Universities';
                    _selectedDepartment = 'All Departments';
                    _selectedVerificationStatus = 'All';
                    _selectedAccountStatus = 'All';
                    _selectedEngagement = 'All';
                    _currentPage = 1;
                  });
                }
              : _refreshStudents,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 820;

          return Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageStudents.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = pageStudents[index];
                  final isChecked = _selectedStudentIds.contains(student.id);
                  final isSuspended =
                      student.accountStatus == StudentAccountStatus.suspended;

                  if (isCompact) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedStudentIds.add(student.id);
                                    } else {
                                      _selectedStudentIds.remove(student.id);
                                    }
                                  });
                                },
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isSuspended
                                    ? AppColors.textMuted
                                    : AppColors.primary,
                                child: Text(
                                  student.avatarInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSuspended
                                            ? AppColors.textMuted
                                            : AppColors.darkNavy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      student.email,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${student.university.isNotEmpty ? student.university : 'University'} • ${student.degree} (${student.semester})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildEngagementBadge(student),
                              _buildVerificationBadge(student),
                              _buildAccountBadge(isSuspended),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onPressed: () =>
                                    _openStudentProfileDrawer(student),
                                child: const Text('View Profile',
                                    style: TextStyle(fontSize: 11.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStudentIds.add(student.id);
                              } else {
                                _selectedStudentIds.remove(student.id);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              isSuspended ? AppColors.textMuted : AppColors.primary,
                          child: Text(
                            student.avatarInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSuspended
                                      ? AppColors.textMuted
                                      : AppColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student.email,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.university,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${student.degree} (${student.semester})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _buildEngagementBadge(student),
                        const SizedBox(width: 10),
                        _buildVerificationBadge(student),
                        const SizedBox(width: 10),
                        _buildAccountBadge(isSuspended),
                        const SizedBox(width: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _openStudentProfileDrawer(student),
                          child: const Text('View Profile',
                              style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Pagination Controls Row
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Showing ${((safePage - 1) * _itemsPerPage) + 1} to ${((safePage - 1) * _itemsPerPage) + pageStudents.length} of $totalCount students',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: safePage > 1
                              ? () => setState(() => _currentPage = safePage - 1)
                              : null,
                        ),
                        Text(
                          'Page $safePage of $totalPages',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: safePage < totalPages
                              ? () => setState(() => _currentPage = safePage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

