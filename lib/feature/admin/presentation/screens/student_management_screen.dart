import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_student_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_student_service.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedUniversity = 'All Universities';
  String _selectedDepartment = 'All Departments';
  String _selectedVerificationStatus = 'All'; // 'All', 'Verified', 'Pending', 'Rejected'
  String _selectedAccountStatus = 'All'; // 'All', 'Active', 'Suspended'
  String _sortBy = 'Newest First'; // 'Newest First', 'Oldest First', 'Highest CGPA'

  bool _isSidebarCollapsed = false;
  final Set<String> _selectedStudentIds = {};

  // Pagination controls
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _universities = [
    'All Universities',
    'FAST-NUCES Islamabad',
    'GIKI Swabi',
    'UET Taxila',
    'PUCIT Lahore',
    'NUST Islamabad',
    'COMSATS Islamabad',
    'LUMS Lahore',
  ];

  final List<String> _departments = [
    'All Departments',
    'Department of Computer Science',
    'Department of Computer Engineering',
    'Department of Data Science & AI',
    'School of Electrical Engineering & CS',
    'Syed Babar Ali School of Science & Eng',
  ];

  final List<String> _verificationFilters = ['All', 'Verified', 'Pending', 'Rejected'];
  final List<String> _accountFilters = ['All', 'Active', 'Suspended'];
  final List<String> _sortOptions = ['Newest First', 'Oldest First', 'Highest CGPA'];

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
    if (routeId == 'dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (routeId == 'company_verifications' || routeId == 'company_management') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
      );
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
      );
    }
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
                children: [
                  Row(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          Text(
                            student.email,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
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
              Row(
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
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
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
                  student.bio,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
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
              _buildSectionHeader('3. Verified Technical Skillset'),
              const SizedBox(height: 8),
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
                      style: const TextStyle(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.verificationDocumentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${student.verificationDocumentType} • ${student.verificationDocumentSize}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
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
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B), fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 7. Administrative Audit History
              _buildSectionHeader('6. Administrative Audit History'),
              const SizedBox(height: 8),
              if (student.auditHistory.isEmpty)
                const Text('No prior administrative actions recorded.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
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
                            Text(
                              audit.action,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.darkNavy),
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
                            style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.darkNavy),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Primary Action Buttons
              Row(
                children: [
                  // Verification Decision
                  if (student.verificationStatus == StudentVerificationStatus.pending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Reject Verification'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _promptRejectStudentVerification(student);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Approve Credentials'),
                        onPressed: () async {
                          final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
                          await _studentService.approveStudentVerification(
                            studentId: student.id,
                            adminName: admin,
                          );
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${student.name} is now university-verified!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Account Suspension / Reactivation Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: student.accountStatus == StudentAccountStatus.active
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(student.verificationDocumentName, style: const TextStyle(fontSize: 14)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
        content: Container(
          width: 480,
          height: 340,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                student.verificationDocumentType,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Institution: ${student.university}\nStudent: ${student.name} • ${student.degree}\nRoll / Reg Identifier: ${student.id.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'University Registrar Digital Signature Authenticated',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
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
            Text('Reject Verification: ${student.name}'),
          ],
        ),
        content: Column(
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

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _studentService.rejectStudentVerification(
                studentId: student.id,
                reason: reason,
                adminName: admin,
              );

              if (!mounted) return;
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
            Text('Suspend Student: ${student.name}'),
          ],
        ),
        content: Column(
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

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _studentService.suspendStudentAccount(
                studentId: student.id,
                reason: reason,
                adminName: admin,
              );

              if (!mounted) return;
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
            Text('Reactivate Account: ${student.name}'),
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
              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _studentService.reactivateStudentAccount(
                studentId: student.id,
                adminName: admin,
              );

              if (!mounted) return;
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
      final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
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
            Text('Export Permitted Student Records'),
          ],
        ),
        content: Column(
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
          drawer: isDesktop
              ? null
              : Drawer(
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
                      pageTitle: 'Student Credentials & Directory',
                      breadcrumb: 'Governance',
                      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (q) => setState(() => _searchQuery = q),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<List<AdminStudentModel>>(
                        valueListenable: _studentService.studentsNotifier,
                        builder: (context, students, _) {
                          // Filter Logic
                          var filtered = students.where((s) {
                            if (_selectedUniversity != 'All Universities' &&
                                s.university != _selectedUniversity) {
                              return false;
                            }
                            if (_selectedDepartment != 'All Departments' &&
                                s.department != _selectedDepartment) {
                              return false;
                            }
                            if (_selectedVerificationStatus == 'Verified' &&
                                s.verificationStatus != StudentVerificationStatus.verified) {
                              return false;
                            }
                            if (_selectedVerificationStatus == 'Pending' &&
                                s.verificationStatus != StudentVerificationStatus.pending) {
                              return false;
                            }
                            if (_selectedVerificationStatus == 'Rejected' &&
                                s.verificationStatus != StudentVerificationStatus.rejected) {
                              return false;
                            }
                            if (_selectedAccountStatus == 'Active' &&
                                s.accountStatus != StudentAccountStatus.active) {
                              return false;
                            }
                            if (_selectedAccountStatus == 'Suspended' &&
                                s.accountStatus != StudentAccountStatus.suspended) {
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
                            filtered.sort((a, b) => b.registrationDateTime.compareTo(a.registrationDateTime));
                          } else if (_sortBy == 'Oldest First') {
                            filtered.sort((a, b) => a.registrationDateTime.compareTo(b.registrationDateTime));
                          } else if (_sortBy == 'Highest CGPA') {
                            filtered.sort((a, b) => b.cgpa.compareTo(a.cgpa));
                          }

                          // Pagination slice
                          final totalPages = (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
                          final startIndex = (_currentPage - 1) * _itemsPerPage;
                          final pageItems = filtered.skip(startIndex).take(_itemsPerPage).toList();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. 5 Overview Metric Cards
                                _buildStudentOverviewMetrics(),
                                const SizedBox(height: 20),

                                // 2. Search, Multi-Filter & Action Bar
                                _buildFilterAndActionCard(filtered),
                                const SizedBox(height: 20),

                                // 3. Student Data Table Card with Pagination
                                _buildStudentTableCard(pageItems, filtered.length, totalPages),
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
          childAspectRatio: count == 1 ? 3.0 : 1.7,
          children: [
            _buildMetricTile(
              title: 'Total Students',
              value: '${_studentService.totalCount}',
              subtitle: 'Registered university students',
              icon: Icons.school_rounded,
              color: AppColors.primary,
              bgColor: AppColors.lightIceBlue,
            ),
            _buildMetricTile(
              title: 'Verified Students',
              value: '${_studentService.verifiedCount}',
              subtitle: 'Degree authenticated',
              icon: Icons.verified_rounded,
              color: AppColors.success,
              bgColor: AppColors.successBg,
            ),
            _buildMetricTile(
              title: 'Pending Verification',
              value: '${_studentService.pendingCount}',
              subtitle: 'Awaiting credential review',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              bgColor: AppColors.warningBg,
            ),
            _buildMetricTile(
              title: 'Rejected Verification',
              value: '${_studentService.rejectedCount}',
              subtitle: 'Discrepancies found',
              icon: Icons.cancel_outlined,
              color: const Color(0xFF64748B),
              bgColor: AppColors.background,
            ),
            _buildMetricTile(
              title: 'Suspended Accounts',
              value: '${_studentService.suspendedCount}',
              subtitle: 'Platform access revoked',
              icon: Icons.block_rounded,
              color: AppColors.error,
              bgColor: AppColors.errorBg,
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
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. Search, Multi-Filter & Action Bar
  Widget _buildFilterAndActionCard(List<AdminStudentModel> filteredStudents) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Roster & Verification Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Search, filter, authenticate credentials, and regulate student account states',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (_selectedStudentIds.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text('Bulk Verify (${_selectedStudentIds.length})'),
                      onPressed: _handleBulkVerify,
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkNavy,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Records (CSV)'),
                    onPressed: () => _exportCsvRecords(filteredStudents),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Filters Row 1: University Dropdown & Department Dropdown & Sort
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // University Selector
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUniversity,
                  decoration: InputDecoration(
                    labelText: 'University Institution',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _universities
                      .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12.5))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUniversity = val);
                  },
                ),
              ),

              // Department Selector
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: 'Academic Department',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDepartment = val);
                  },
                ),
              ),

              // Sort Dropdown
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _sortOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filters Row 2: Verification Status Chips & Account Status Chips
          Row(
            children: [
              const Text('Verification: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
              Wrap(
                spacing: 6,
                children: _verificationFilters.map((vf) {
                  final isSel = _selectedVerificationStatus == vf;
                  return ChoiceChip(
                    label: Text(vf),
                    selected: isSel,
                    selectedColor: AppColors.darkNavy,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textSecondary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    onSelected: (val) {
                      if (val) setState(() => _selectedVerificationStatus = vf);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(width: 24),
              const Text('Account: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
              Wrap(
                spacing: 6,
                children: _accountFilters.map((af) {
                  final isSel = _selectedAccountStatus == af;
                  return ChoiceChip(
                    label: Text(af),
                    selected: isSel,
                    selectedColor: AppColors.darkNavy,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textSecondary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    onSelected: (val) {
                      if (val) setState(() => _selectedAccountStatus = af);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Student Data Table Card with Pagination
  Widget _buildStudentTableCard(List<AdminStudentModel> pageStudents, int totalCount, int totalPages) {
    if (pageStudents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.person_search_rounded, size: 44, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No student records match the active criteria',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
              ),
              SizedBox(height: 4),
              Text(
                'Try adjusting the university, department, or verification filter.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
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
      child: Column(
        children: [
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageStudents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = pageStudents[index];
              final isChecked = _selectedStudentIds.contains(student.id);
              final isVerified = student.verificationStatus == StudentVerificationStatus.verified;
              final isPending = student.verificationStatus == StudentVerificationStatus.pending;
              final isSuspended = student.accountStatus == StudentAccountStatus.suspended;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Checkbox for bulk actions
                    Checkbox(
                      value: isChecked,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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

                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSuspended ? AppColors.textMuted : AppColors.primary,
                      child: Text(
                        student.avatarInitial,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name & Email
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSuspended ? AppColors.textMuted : AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(student.email, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),

                    // University & Degree
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.university, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            '${student.degree} (${student.semester})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Verification Badge
                    Container(
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
                    ),
                    const SizedBox(width: 10),

                    // Account Status Badge
                    Container(
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
                    ),
                    const SizedBox(width: 14),

                    // View Profile Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _openStudentProfileDrawer(student),
                      child: const Text('View Profile', style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
              );
            },
          ),

          // Pagination Controls Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${((_currentPage - 1) * _itemsPerPage) + 1} to ${((_currentPage - 1) * _itemsPerPage) + pageStudents.length} of $totalCount students',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Page $_currentPage of $totalPages',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

