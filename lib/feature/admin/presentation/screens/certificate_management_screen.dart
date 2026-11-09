import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/admin/models/admin_certificate_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_certificate_service.dart';

/// Enterprise Certificate Management & Verification Desk for CampusConnect (Screen 39)
/// Provides credential administration, FIPS-compliant cryptographic verification,
/// high-fidelity document inspection, and tamper-recorded revocation workflows.
class CertificateManagementScreen extends StatefulWidget {
  const CertificateManagementScreen({super.key});

  @override
  State<CertificateManagementScreen> createState() =>
      _CertificateManagementScreenState();
}

class _CertificateManagementScreenState
    extends State<CertificateManagementScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminCertificateService _certService = AdminCertificateService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _lookupController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All Statuses';
  String _selectedDateFilter = 'All Time';
  String _sortBy = 'Newest Issue Date';

  bool _isSidebarCollapsed = false;

  // Pagination controls
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _statusFilters = [
    'All Statuses',
    'Valid',
    'Requires Review',
    'Revoked',
  ];

  final List<String> _dateFilters = [
    'All Time',
    'Today',
    'Last 30 Days',
    'Last 90 Days',
  ];

  final List<String> _sortOptions = [
    'Newest Issue Date',
    'Oldest Issue Date',
    'Certificate ID (Asc)',
    'Student Name (A-Z)',
  ];

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
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
    if (routeId == 'dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (routeId == 'student_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
      );
    } else if (routeId == 'company_verifications' ||
        routeId == 'company_management') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
      );
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
      );
    } else if (routeId == 'compliance' ||
        routeId == 'application_monitoring') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const ApplicationMonitoringScreen()),
      );
    } else if (routeId == 'analytics' || routeId == 'reports') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const ReportsAnalyticsScreen()),
      );
    } else if (routeId == 'settings') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const AdminSettingsScreen()),
      );
    }
    // If routeId is 'audit_logs' or 'certificates', we are already on this screen.
  }

  // Filter & Sort Logic
  List<AdminCertificateModel> _getFilteredCertificates(
      List<AdminCertificateModel> certificates) {
    return certificates.where((c) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = c.id.toLowerCase().contains(query);
        final matchesCredential = c.credentialId.toLowerCase().contains(query);
        final matchesStudent = c.studentName.toLowerCase().contains(query);
        final matchesProject = c.projectTitle.toLowerCase().contains(query);
        final matchesCompany = c.companyName.toLowerCase().contains(query);
        if (!matchesId &&
            !matchesCredential &&
            !matchesStudent &&
            !matchesProject &&
            !matchesCompany) {
          return false;
        }
      }

      // 2. Status Filter
      if (_selectedStatus != 'All Statuses' &&
          c.statusDisplay != _selectedStatus) {
        return false;
      }

      // 3. Date Filter
      if (_selectedDateFilter != 'All Time') {
        final now = DateTime.now();
        if (_selectedDateFilter == 'Today') {
          if (c.issueDateTime.day != now.day ||
              c.issueDateTime.month != now.month ||
              c.issueDateTime.year != now.year) {
            return false;
          }
        } else if (_selectedDateFilter == 'Last 30 Days') {
          if (now.difference(c.issueDateTime).inDays > 30) {
            return false;
          }
        } else if (_selectedDateFilter == 'Last 90 Days') {
          if (now.difference(c.issueDateTime).inDays > 90) {
            return false;
          }
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'Newest Issue Date') {
          return b.issueDateTime.compareTo(a.issueDateTime);
        } else if (_sortBy == 'Oldest Issue Date') {
          return a.issueDateTime.compareTo(b.issueDateTime);
        } else if (_sortBy == 'Certificate ID (Asc)') {
          return a.id.compareTo(b.id);
        } else {
          return a.studentName.compareTo(b.studentName);
        }
      });
  }

  // 5. Instant Lookup / Verify Dialog
  void _executeCertificateLookup() {
    final query = _lookupController.text.trim();
    if (query.isEmpty) return;

    final result = _certService.verifyCertificate(query);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result != null
                  ? (result.status == AdminCertificateStatus.valid
                      ? Icons.verified_rounded
                      : result.status == AdminCertificateStatus.revoked
                          ? Icons.cancel_outlined
                          : Icons.hourglass_top_rounded)
                  : Icons.help_outline_rounded,
              color: result != null
                  ? (result.status == AdminCertificateStatus.valid
                      ? AppColors.success
                      : result.status == AdminCertificateStatus.revoked
                          ? AppColors.error
                          : AppColors.warning)
                  : AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result != null
                    ? 'Ledger Match: ${result.id}'
                    : 'Unregistered Credential',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: result == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gpp_bad_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'No record matching "$query" exists in the CampusConnect Administrative Ledger.',
                      style: const TextStyle(fontSize: 13, color: AppColors.darkNavy),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This credential may be counterfeit, invalid, or belongs to an unaccredited institution.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: result.status == AdminCertificateStatus.valid
                            ? AppColors.successBg
                            : result.status == AdminCertificateStatus.revoked
                                ? AppColors.errorBg
                                : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            result.status == AdminCertificateStatus.valid
                                ? Icons.verified_user_rounded
                                : Icons.warning_rounded,
                            color: result.status == AdminCertificateStatus.valid
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.status == AdminCertificateStatus.valid
                                  ? 'AUTHENTIC CREDENTIAL VERIFIED ON LEDGER'
                                  : result.status == AdminCertificateStatus.revoked
                                      ? 'CREDENTIAL REVOKED & NULLIFIED'
                                      : 'CREDENTIAL PLACED UNDER ADMINISTRATIVE HOLD',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: result.status == AdminCertificateStatus.valid
                                    ? const Color(0xFF166534)
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(Icons.person_rounded, 'Student Holder',
                        '${result.studentName} (${result.studentUniversity})'),
                    _buildInfoRow(Icons.workspace_premium_rounded, 'Certificate Title',
                        result.certificateTitle),
                    _buildInfoRow(Icons.assignment_outlined, 'Project Scope',
                        result.projectTitle),
                    _buildInfoRow(Icons.apartment_rounded, 'Issuing Corporate',
                        result.companyName),
                    _buildInfoRow(Icons.calendar_today_rounded, 'Issued On',
                        result.issueDate),
                    const SizedBox(height: 8),
                    const Text('Cryptographic Integrity Hash:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        result.cryptographicHash,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5),
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
          if (result != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _openCertificatePreviewDialog(result);
              },
              child: const Text('Inspect Full Document'),
            ),
        ],
      ),
    );
  }

  // 4. Secure Digital Certificate Document Preview
  void _openCertificatePreviewDialog(AdminCertificateModel cert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.accentTeal),
                const SizedBox(width: 10),
                Text(
                  'Authenticity Preview: ${cert.id}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // High-Fidelity Certificate View
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Gold border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Crest & CampusConnect Branding
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.school_rounded, color: AppColors.darkNavy, size: 36),
                          Column(
                            children: [
                              Text(
                                'CAMPUSCONNECT CENTRAL GOVERNANCE',
                                style: TextStyle(
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              Text(
                                'Student–Corporate Collaboration Credential Registry',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Icon(Icons.military_tech_rounded, color: Color(0xFFD4AF37), size: 36),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFD4AF37), thickness: 1),
                      const SizedBox(height: 12),

                      // Certificate Type
                      Text(
                        cert.certificateTitle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'THIS IS PROUDLY CONFERRED UPON',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Student Name
                      Text(
                        cert.studentName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${cert.studentDegree} • ${cert.studentUniversity}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),

                      // Recognition Body
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'In formal recognition of successful completion and outstanding performance delivered during the "${cert.projectTitle}" sprint sponsored by ${cert.companyName}.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.darkNavy,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Performance Ratings Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: cert.performanceRatings.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.lightIceBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${e.key}: ${e.value} ★',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Signatories & Verification QR Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert.signatoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              Text(
                                cert.signatoryTitle,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                              Text(
                                cert.companyName,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),

                          // Tamper-proof Status Seal
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cert.status == AdminCertificateStatus.valid
                                  ? AppColors.successBg
                                  : cert.status == AdminCertificateStatus.revoked
                                      ? AppColors.errorBg
                                      : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: cert.status == AdminCertificateStatus.valid
                                    ? AppColors.success
                                    : cert.status == AdminCertificateStatus.revoked
                                        ? AppColors.error
                                        : AppColors.warning,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  cert.status == AdminCertificateStatus.valid
                                      ? 'LEDGER VERIFIED'
                                      : cert.status == AdminCertificateStatus.revoked
                                          ? 'NULL & REVOKED'
                                          : 'REVIEW HOLD',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: cert.status == AdminCertificateStatus.valid
                                        ? AppColors.success
                                        : cert.status == AdminCertificateStatus.revoked
                                            ? AppColors.error
                                            : AppColors.warning,
                                  ),
                                ),
                                Text(
                                  cert.credentialId,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5),
                                ),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Dr. Tariq Mahmood',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const Text(
                                'Executive Governance Council',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Issued: ${cert.issueDate}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),

                      // Cryptographic Hash Footnote
                      SelectableText(
                        'Cryptographic Vault Hash: ${cert.cryptographicHash}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Audit History Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credential Audit Trail & Verification Events',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkNavy),
                      ),
                      const SizedBox(height: 8),
                      ...cert.verificationHistory.map((audit) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${audit.timestamp} • ${audit.action} by ${audit.adminName}${audit.reason != null ? " (Note: ${audit.reason})" : ""}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Credential ID'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: cert.credentialId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied ${cert.credentialId} to clipboard!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 6. Mandatory Reason Prompt for Revocation
  void _promptRevokeCertificate(AdminCertificateModel cert) {
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
                'Revoke Credential: ${cert.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revoking a certificate invalidates public verification and permanently logs administrator identity.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Mandatory Revocation Reason *',
                hintText: 'e.g. Plagiarism infraction confirmed or academic registrar audit discrepancy...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _certService.revokeCertificate(
                certificateId: cert.id,
                reason: reason,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cert.id} revoked. Audit ledger updated.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Revocation'),
          ),
        ],
      ),
    );
  }

  // 6. Mark For Review Prompt
  void _promptMarkForReview(AdminCertificateModel cert) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification Hold: ${cert.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imposing an administrative review hold temporarily suspends external authenticity verification.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Review Hold Reason *',
                hintText: 'e.g. Student conduct grievance under review...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _certService.markCertificateForReview(
                certificateId: cert.id,
                reason: reason,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cert.id} placed under verification review hold.'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Impose Hold'),
          ),
        ],
      ),
    );
  }

  // 6. Reinstate Certificate Prompt
  void _promptReinstateCertificate(AdminCertificateModel cert) {
    final justificationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reinstate Credential: ${cert.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restores valid status and re-enables public verification on the administrative ledger.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: justificationController,
              decoration: const InputDecoration(
                labelText: 'Reinstatement Justification *',
                hintText: 'e.g. Proctor clarification confirmed; all criteria satisfied...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final just = justificationController.text.trim();
              if (just.isEmpty) return;

              final admin = _authService.currentAdmin?.fullName ?? 'Executive SuperAdmin';
              await _certService.reinstateCertificate(
                certificateId: cert.id,
                justification: just,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cert.id} successfully reinstated to Valid status.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Reinstatement'),
          ),
        ],
      ),
    );
  }

  // 7. CSV Export Dialog
  void _exportCsvRecords(List<AdminCertificateModel> certificates) {
    final csv = _certService.exportCertificatesCsv(certificates);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Export Certificate Registry (CSV)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The authorized academic certificate registry has been compiled into CSV format:',
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Certificate CSV copied to clipboard!'),
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

  Color _getStatusColor(AdminCertificateStatus status) {
    switch (status) {
      case AdminCertificateStatus.valid:
        return AppColors.success;
      case AdminCertificateStatus.revoked:
        return AppColors.error;
      case AdminCertificateStatus.pendingReview:
        return const Color(0xFFD97706);
      case AdminCertificateStatus.draft:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(AdminCertificateStatus status) {
    switch (status) {
      case AdminCertificateStatus.valid:
        return AppColors.successBg;
      case AdminCertificateStatus.revoked:
        return AppColors.errorBg;
      case AdminCertificateStatus.pendingReview:
        return AppColors.warningBg;
      case AdminCertificateStatus.draft:
        return AppColors.background;
    }
  }

  IconData _getStatusIcon(AdminCertificateStatus status) {
    switch (status) {
      case AdminCertificateStatus.valid:
        return Icons.verified_user_rounded;
      case AdminCertificateStatus.revoked:
        return Icons.cancel_outlined;
      case AdminCertificateStatus.pendingReview:
        return Icons.hourglass_top_rounded;
      case AdminCertificateStatus.draft:
        return Icons.edit_note_rounded;
    }
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
                    activeRouteId: 'audit_logs',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              // Persistent Sidebar on Desktop
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'audit_logs',
                  onRouteSelected: _onRouteSelected,
                  onSignOut: _handleSignOut,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),

              // Main Work Area
              Expanded(
                child: Column(
                  children: [
                    // Top Navigation Bar
                    AdminTopNavbar(
                      pageTitle: 'Certificate Administration & Verification',
                      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (query) {
                        setState(() {
                          _searchQuery = query;
                          _currentPage = 1;
                        });
                      },
                    ),

                    // Content Scroll Area
                    Expanded(
                      child: ValueListenableBuilder<List<AdminCertificateModel>>(
                        valueListenable: _certService.certificatesNotifier,
                        builder: (context, certificates, _) {
                          final filtered = _getFilteredCertificates(certificates);

                          // Pagination slice
                          final totalPages =
                              (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
                          final startIndex = (_currentPage - 1) * _itemsPerPage;
                          final pageItems =
                              filtered.skip(startIndex).take(_itemsPerPage).toList();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. 5 Certificate Overview Metric Cards
                                _buildCertificateOverviewMetrics(),
                                const SizedBox(height: 20),

                                // 2. Instant Certificate Authenticity Checker Bar
                                _buildInstantVerificationBar(),
                                const SizedBox(height: 20),

                                // 3. Search, Multi-Filter & Action Bar
                                _buildFilterAndActionCard(filtered),
                                const SizedBox(height: 20),

                                // 4. Certificate Data Table Card with Pagination
                                _buildCertificateTableCard(
                                    pageItems, filtered.length, totalPages),
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

  // 1. 5 Certificate Overview Metric Cards
  Widget _buildCertificateOverviewMetrics() {
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
              title: 'Total Certificates',
              value: '${_certService.totalCount}',
              subtitle: 'Registered credentials ledger',
              icon: Icons.workspace_premium_rounded,
              color: AppColors.primary,
              bgColor: AppColors.lightIceBlue,
            ),
            _buildMetricTile(
              title: 'Issued Certificates',
              value: '${_certService.issuedCount}',
              subtitle: 'Officially conferred to students',
              icon: Icons.card_membership_rounded,
              color: AppColors.accentTeal,
              bgColor: AppColors.accentTeal.withValues(alpha: 0.12),
            ),
            _buildMetricTile(
              title: 'Valid Credentials',
              value: '${_certService.validCount}',
              subtitle: 'Active tamper-proof standing',
              icon: Icons.verified_user_rounded,
              color: AppColors.success,
              bgColor: AppColors.successBg,
            ),
            _buildMetricTile(
              title: 'Revoked Certificates',
              value: '${_certService.revokedCount}',
              subtitle: 'Nullified due to infractions',
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              bgColor: AppColors.errorBg,
            ),
            _buildMetricTile(
              title: 'Requires Review',
              value: '${_certService.requiringReviewCount}',
              subtitle: 'Under administrative hold',
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFFD97706),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
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

  // 2. Instant Certificate Authenticity Checker Bar
  Widget _buildInstantVerificationBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentTeal, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant Certificate Authenticity Verification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Verify any Certificate ID or Credential Hash directly against the FIPS administrative vault',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lookupController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter Certificate ID (e.g. CERT-2026-8001)...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                    onSubmitted: (_) => _executeCertificateLookup(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    foregroundColor: AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Verify Credential', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _executeCertificateLookup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Search, Multi-Filter & Action Bar
  Widget _buildFilterAndActionCard(List<AdminCertificateModel> filteredCertificates) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Certificate Administration Registry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Inspect issued credentials, manage verification holds, and execute authorized revocations',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkNavy,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Export Records (CSV)'),
                onPressed: () => _exportCsvRecords(filteredCertificates),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Status Filter
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Certificate Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _statusFilters
                      .map((st) => DropdownMenuItem(
                            value: st,
                            child: Text(st, style: const TextStyle(fontSize: 12.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),

              // Date Filter
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDateFilter,
                  decoration: InputDecoration(
                    labelText: 'Issue Date Range',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _dateFilters
                      .map((df) => DropdownMenuItem(
                            value: df,
                            child: Text(df, style: const TextStyle(fontSize: 12.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDateFilter = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),

              // Sort Dropdown
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _sortOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 12.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Certificate Data Table Card with Pagination
  Widget _buildCertificateTableCard(
    List<AdminCertificateModel> pageCertificates,
    int totalCount,
    int totalPages,
  ) {
    if (pageCertificates.isEmpty) {
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
              Icon(Icons.workspace_premium_outlined, size: 44, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No certificates match the active criteria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try adjusting the search query, verification status, or issue date filter.',
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
            itemCount: pageCertificates.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cert = pageCertificates[index];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Certificate ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            cert.id,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Certificate Title & Type
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.certificateTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.darkNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Type: ${cert.typeDisplay} • Credential ID: ${cert.credentialId}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Student Information
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.darkNavy,
                            child: Text(
                              cert.studentName.isNotEmpty ? cert.studentName[0] : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cert.studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.darkNavy,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${cert.studentUniversity} • ${cert.studentDegree}',
                                  style: const TextStyle(
                                    fontSize: 11,
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

                    // Project Title & Sponsoring Company
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.projectTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: AppColors.darkNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            cert.companyName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Issue Date
                    SizedBox(
                      width: 90,
                      child: Text(
                        cert.issueDate,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),

                    // Verification Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(cert.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(cert.status),
                            size: 13,
                            color: _getStatusColor(cert.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cert.statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(cert.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Action: Inspect / Verify
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 15),
                      label: const Text('Inspect / Verify', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => _openCertificatePreviewDialog(cert),
                    ),
                    const SizedBox(width: 6),

                    // Context Menu for Revocation / Administration
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (val) {
                        if (val == 'preview') {
                          _openCertificatePreviewDialog(cert);
                        } else if (val == 'hold') {
                          _promptMarkForReview(cert);
                        } else if (val == 'revoke') {
                          _promptRevokeCertificate(cert);
                        } else if (val == 'reinstate') {
                          _promptReinstateCertificate(cert);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Inspect Full Document', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        if (cert.status == AdminCertificateStatus.valid) ...[
                          const PopupMenuItem(
                            value: 'hold',
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.warning),
                                SizedBox(width: 8),
                                Text('Place on Review Hold',
                                    style: TextStyle(fontSize: 12, color: AppColors.warning)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'revoke',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Revoke Credential',
                                    style: TextStyle(fontSize: 12, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                        if (cert.status == AdminCertificateStatus.pendingReview) ...[
                          const PopupMenuItem(
                            value: 'reinstate',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 16, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Reinstate to Valid',
                                    style: TextStyle(fontSize: 12, color: AppColors.success)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'revoke',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Revoke Credential',
                                    style: TextStyle(fontSize: 12, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                        if (cert.status == AdminCertificateStatus.revoked)
                          const PopupMenuItem(
                            value: 'reinstate',
                            child: Row(
                              children: [
                                Icon(Icons.restore_page_outlined, size: 16, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Authorize Reinstatement',
                                    style: TextStyle(fontSize: 12, color: AppColors.success)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${pageCertificates.length} of $totalCount certificates (Page $_currentPage of $totalPages)',
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
                      '$_currentPage',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
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
