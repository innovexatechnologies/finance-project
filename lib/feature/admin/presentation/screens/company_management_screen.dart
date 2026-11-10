import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_company_model.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_settings_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enterprise Company Management Module for CampusConnect Admin Panel (Screen 36)
/// Provides corporate registry overview, advanced multi-parameter filtering,
/// SECP document authentication, project auditing, suspension controls, and audit trails.
class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminCompanyService _companyService = AdminCompanyService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedIndustry = 'All Industries';
  String _selectedLocation = 'All Locations';
  String _selectedVerificationStatus =
      'All'; // 'All', 'Verified', 'Pending', 'Rejected'
  String _selectedAccountStatus = 'All'; // 'All', 'Active', 'Suspended'
  String _sortBy = 'Newest First'; // 'Newest First', 'Oldest First', 'Most Projects', 'Company Name (A-Z)'

  bool _isSidebarCollapsed = false;

  // Pagination controls
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<String> _verificationFilters = [
    'All',
    'Verified',
    'Pending',
    'Rejected',
  ];
  final List<String> _accountFilters = ['All', 'Active', 'Suspended'];
  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Most Projects',
    'Company Name (A-Z)',
  ];

  List<String> _buildIndustryOptions(List<AdminCompanyModel> companies) {
    final set = <String>{'All Industries'};
    for (final c in companies) {
      final ind = c.industry.trim();
      if (ind.isNotEmpty) set.add(ind);
    }
    return set.toList();
  }

  List<String> _buildLocationOptions(List<AdminCompanyModel> companies) {
    final set = <String>{'All Locations'};
    for (final c in companies) {
      final city = c.city.trim();
      if (city.isNotEmpty) set.add(city);
    }
    return set.toList();
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

  Future<void> _refreshCompanies() async {
    await Future.wait([
      _companyService.loadFromSupabase(),
      AdminProjectService().loadFromSupabase(),
    ]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Company registry refreshed from Supabase.'),
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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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

  void _onRouteSelected(String routeId) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (routeId == 'company_management') return;

    Widget? target;
    if (routeId == 'dashboard') {
      target = const AdminDashboardScreen();
    } else if (routeId == 'company_verifications') {
      target = const CompanyVerificationsScreen();
    } else if (routeId == 'student_verifications') {
      target = const StudentManagementScreen();
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      target = const ProjectManagementScreen();
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      target = const ApplicationMonitoringScreen();
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      target = const CertificateManagementScreen();
    } else if (routeId == 'analytics' || routeId == 'reports') {
      target = const ReportsAnalyticsScreen();
    } else if (routeId == 'settings') {
      target = const AdminSettingsScreen();
    }

    if (target != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target!),
      );
    }
  }

  // Filter & Sort Logic
  List<AdminCompanyModel> _getFilteredCompanies(
    List<AdminCompanyModel> companies, {
    required String effectiveIndustry,
    required String effectiveLocation,
  }) {
    return companies.where((c) {
      // 1. Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = c.companyName.toLowerCase().contains(query);
        final matchesEmail = c.officialEmail.toLowerCase().contains(query);
        final matchesContact = c.contactPersonName.toLowerCase().contains(
          query,
        );
        final matchesReg = c.registrationNumber.toLowerCase().contains(query);
        if (!matchesName && !matchesEmail && !matchesContact && !matchesReg) {
          return false;
        }
      }

      // 2. Industry filter
      if (effectiveIndustry != 'All Industries' &&
          c.industry != effectiveIndustry) {
        return false;
      }

      // 3. Location filter
      if (effectiveLocation != 'All Locations' && c.city != effectiveLocation) {
        return false;
      }

      // 4. Verification status
      if (_selectedVerificationStatus != 'All') {
        if (_selectedVerificationStatus == 'Verified' &&
            c.verificationStatus != CompanyVerificationState.verified) {
          return false;
        }
        if (_selectedVerificationStatus == 'Pending' &&
            c.verificationStatus != CompanyVerificationState.pending) {
          return false;
        }
        if (_selectedVerificationStatus == 'Rejected' &&
            c.verificationStatus != CompanyVerificationState.rejected) {
          return false;
        }
      }

      // 5. Account status
      if (_selectedAccountStatus != 'All') {
        if (_selectedAccountStatus == 'Active' &&
            c.accountStatus != CompanyAccountState.active) {
          return false;
        }
        if (_selectedAccountStatus == 'Suspended' &&
            c.accountStatus != CompanyAccountState.suspended) {
          return false;
        }
      }

      return true;
    }).toList()..sort((a, b) {
      if (_sortBy == 'Newest First') {
        return b.registrationDateTime.compareTo(a.registrationDateTime);
      } else if (_sortBy == 'Oldest First') {
        return a.registrationDateTime.compareTo(b.registrationDateTime);
      } else if (_sortBy == 'Most Projects') {
        return b.postedProjectsCount.compareTo(a.postedProjectsCount);
      } else {
        return a.companyName.compareTo(b.companyName);
      }
    });
  }

  // 4. Company Profile Detailed Drawer
  void _openCompanyProfileDrawer(AdminCompanyModel company) {
    final List<AdminProjectModel> postedProjects = AdminProjectService()
        .allProjects
        .where((p) => p.companyId == company.id)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.90,
        maxChildSize: 0.96,
        minChildSize: 0.50,
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
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkNavy.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              company.logoInitial,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      company.companyName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNavy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (company.isEmailVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.accentTeal,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'Reg No: ${company.registrationNumber} • ${company.city}',
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
                    label:
                        company.verificationStatus ==
                            CompanyVerificationState.verified
                        ? 'Verified Partner'
                        : company.verificationStatus ==
                              CompanyVerificationState.pending
                        ? 'Verification Pending'
                        : 'Verification Rejected',
                    color:
                        company.verificationStatus ==
                            CompanyVerificationState.verified
                        ? AppColors.success
                        : company.verificationStatus ==
                              CompanyVerificationState.pending
                        ? AppColors.warning
                        : AppColors.error,
                    bgColor:
                        company.verificationStatus ==
                            CompanyVerificationState.verified
                        ? AppColors.successBg
                        : company.verificationStatus ==
                              CompanyVerificationState.pending
                        ? AppColors.warningBg
                        : AppColors.errorBg,
                  ),
                  _buildStatusPill(
                    label: company.accountStatus == CompanyAccountState.active
                        ? 'Account Active'
                        : 'Account Suspended',
                    color: company.accountStatus == CompanyAccountState.active
                        ? AppColors.primary
                        : AppColors.error,
                    bgColor: company.accountStatus == CompanyAccountState.active
                        ? AppColors.lightIceBlue
                        : AppColors.errorBg,
                  ),
                  _buildStatusPill(
                    label: '${company.postedProjectsCount} Projects Posted',
                    color: AppColors.darkNavy,
                    bgColor: AppColors.background,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Corporate Profile & Overview
              _buildSectionHeader('1. Corporate Profile & Description'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  company.description.isEmpty
                      ? 'No company description provided.'
                      : company.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Organization & Registration Details
              _buildSectionHeader('2. Corporate Registry & Address'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.business_rounded,
                'Industry Vertical',
                company.industry,
              ),
              _buildInfoRow(
                Icons.numbers_rounded,
                'Registration Number',
                company.registrationNumber,
              ),
              _buildInfoRow(Icons.location_on_rounded, 'City', company.city),
              _buildInfoRow(
                Icons.home_work_rounded,
                'Physical Headquarters',
                company.completeAddress,
              ),
              _buildInfoRow(
                Icons.link_rounded,
                'Official Website',
                company.websiteUrl,
              ),
              _buildInfoRow(
                Icons.calendar_today_rounded,
                'Registered On',
                company.registrationDate,
              ),
              const SizedBox(height: 20),

              // 3. Official Contact Person
              _buildSectionHeader('3. Authorized Corporate Liaison'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.person_outline_rounded,
                'Contact Person',
                company.contactPersonName,
              ),
              _buildInfoRow(
                Icons.email_outlined,
                'Official Email',
                company.officialEmail,
              ),
              _buildInfoRow(
                Icons.phone_outlined,
                'Official Phone',
                company.phoneNumber,
              ),
              const SizedBox(height: 20),

              // 4. Verification Evidence Document
              _buildSectionHeader('4. Submitted Verification Document'),
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
                                company.evidenceFileName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${company.evidenceFileType} • ${company.evidenceFileSize}',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text(
                        'Inspect Evidence',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      onPressed: () => _openDocumentPreviewModal(company),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Posted Collaboration Projects (Strictly Non-Financial)
              _buildSectionHeader(
                '5. Posted Collaboration Projects (${postedProjects.length})',
              ),
              const SizedBox(height: 8),
              if (postedProjects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No projects posted by this company yet.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...postedProjects.map((project) {
                  final isOpen =
                      project.status == AdminProjectStatus.published ||
                      project.status == AdminProjectStatus.active;
                  final isPendingReview =
                      project.status == AdminProjectStatus.pendingReview;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${project.category} • ${project.projectType} • Duration: ${project.duration}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppColors.successBg
                                : isPendingReview
                                ? AppColors.warningBg
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOpen
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : isPendingReview
                                  ? AppColors.warning.withValues(alpha: 0.3)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            project.statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOpen
                                  ? AppColors.success
                                  : isPendingReview
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // 6. Suspension Notice if Suspended
              if (company.accountStatus == CompanyAccountState.suspended &&
                  company.suspensionReason != null) ...[
                _buildSectionHeader('Account Suspension Details'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Suspension Reason: "${company.suspensionReason}"',
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
              _buildSectionHeader('6. Governance & Verification Audit History'),
              const SizedBox(height: 8),
              if (company.auditHistory.isEmpty)
                const Text(
                  'No prior governance actions recorded.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                )
              else
                ...company.auditHistory.map((audit) {
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              audit.timestamp,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Recorded by: ${audit.adminName}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  if (company.verificationStatus ==
                      CompanyVerificationState.pending) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Reject Verification'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _promptRejectCompanyVerification(company);
                          },
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.contact_support_outlined,
                            size: 16,
                          ),
                          label: const Text('Request Docs'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _promptRequestAdditionalDocs(company);
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Approve Verification'),
                          onPressed: () async {
                            final admin =
                                _authService.currentAdmin?.fullName ??
                                'Executive Administrator';
                            await _companyService.approveCompanyVerification(
                              companyId: company.id,
                              adminName: admin,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Verification approved for ${company.companyName}!',
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                  if (company.accountStatus == CompanyAccountState.active) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.block_rounded, size: 16),
                        label: const Text('Suspend Account'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _promptSuspendCompany(company);
                        },
                      ),
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 16),
                      label: const Text('Reactivate Account'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _promptReactivateCompany(company);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Document Inspection Modal
  void _openDocumentPreviewModal(AdminCompanyModel company) {
    final evidenceUrl = (company.evidenceUrl ?? '').trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.accentTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification Evidence: ${company.companyName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Submitted Corporate Registration & Compliance Metadata',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.darkNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.apartment_rounded,
                        'Company',
                        company.companyName,
                      ),
                      _buildInfoRow(
                        Icons.numbers_rounded,
                        'Registration No',
                        company.registrationNumber,
                      ),
                      _buildInfoRow(
                        Icons.business_center_outlined,
                        'Sector & City',
                        '${company.industry} • ${company.city}',
                      ),
                      _buildInfoRow(
                        Icons.person_outline_rounded,
                        'Liaison',
                        '${company.contactPersonName} (${company.officialEmail})',
                      ),
                      _buildInfoRow(
                        Icons.attach_file_rounded,
                        'Uploaded File',
                        company.evidenceFileName,
                      ),
                      _buildInfoRow(
                        Icons.sd_storage_outlined,
                        'Format & Size',
                        '${company.evidenceFileType} • ${company.evidenceFileSize}',
                      ),
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Submitted On',
                        company.registrationDate,
                      ),
                      _buildInfoRow(
                        Icons.cloud_done_outlined,
                        'Storage Link',
                        evidenceUrl.isNotEmpty
                            ? 'Uploaded file attached in cloud storage'
                            : 'No external file URL attached yet',
                      ),
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
            child: const Text('Close Preview'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Reg Number'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: company.registrationNumber),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Copied ${company.registrationNumber} to clipboard!',
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (evidenceUrl.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Uploaded File'),
              onPressed: () => _launchExternalUrl(evidenceUrl),
            ),
        ],
      ),
    );
  }

  // 5. Mandatory Reason Prompt for Verification Rejection
  void _promptRejectCompanyVerification(AdminCompanyModel company) {
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
                'Reject Verification: ${company.companyName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                'A mandatory rejection reason is required so corporate liaisons can rectify their registration filing.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Uploaded registration certificate has expired or number mismatch...',
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
                  _authService.currentAdmin?.fullName ??
                  'Executive Administrator';
              await _companyService.rejectCompanyVerification(
                companyId: company.id,
                reason: reason,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Verification rejected for ${company.companyName}. Reason recorded.',
                  ),
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

  // 5. Request Additional Verification Documents Prompt
  void _promptRequestAdditionalDocs(AdminCompanyModel company) {
    final instructionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.contact_support_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request Documents: ${company.companyName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                'Specify what supplementary filings or documents the company must submit to satisfy verification.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Document Instructions *',
                  hintText: 'e.g. Please provide Incorporation Certificate alongside official letterhead confirmation...',
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
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final instructions = instructionsController.text.trim();
              if (instructions.isEmpty) return;

              final admin =
                  _authService.currentAdmin?.fullName ??
                  'Executive Administrator';
              await _companyService.requestAdditionalDocuments(
                companyId: company.id,
                instructions: instructions,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Additional document request dispatched to ${company.companyName}.',
                  ),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Dispatch Request'),
          ),
        ],
      ),
    );
  }

  // 6. Mandatory Reason Prompt for Company Account Suspension
  void _promptSuspendCompany(AdminCompanyModel company) {
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
                'Suspend Account: ${company.companyName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                'Suspending this corporate partner will immediately unlist their active projects and prevent student hiring.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Suspension Reason *',
                  hintText: 'e.g. Policy breach or commercial solicitation violating platform guidelines...',
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
                  _authService.currentAdmin?.fullName ??
                  'Executive Administrator';
              await _companyService.suspendCompanyAccount(
                companyId: company.id,
                reason: reason,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${company.companyName} corporate account has been suspended.',
                  ),
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

  // 6. Reactivate Company Account Prompt
  void _promptReactivateCompany(AdminCompanyModel company) {
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
                'Reactivate Account: ${company.companyName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to restore full platform privileges for this corporate partner? Posted sprints will resume visibility.',
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
                  _authService.currentAdmin?.fullName ??
                  'Executive Administrator';
              await _companyService.reactivateCompanyAccount(
                companyId: company.id,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${company.companyName} account has been reactivated.',
                  ),
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

  // 7. Export Records to CSV Dialog
  void _exportCsvRecords(List<AdminCompanyModel> companies) {
    final csv = _companyService.exportCompaniesCsv(companies);

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
                'Export Permitted Corporate Records',
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
                'The authorized corporate roster has been generated in CSV format per platform data governance:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
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
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
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
                  content: Text('Corporate CSV records copied to clipboard!'),
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
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
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
                    activeRouteId: 'company_verifications',
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
                  activeRouteId: 'company_verifications',
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
                      pageTitle: 'Company Management & Verification',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openDrawer(),
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
                      child: ValueListenableBuilder<List<AdminCompanyModel>>(
                        valueListenable: _companyService.companiesNotifier,
                        builder: (context, companies, _) {
                          final industries = _buildIndustryOptions(companies);
                          final effectiveIndustry =
                              industries.contains(_selectedIndustry)
                              ? _selectedIndustry
                              : 'All Industries';
                          final locations = _buildLocationOptions(companies);
                          final effectiveLocation =
                              locations.contains(_selectedLocation)
                              ? _selectedLocation
                              : 'All Locations';

                          final filtered = _getFilteredCompanies(
                            companies,
                            effectiveIndustry: effectiveIndustry,
                            effectiveLocation: effectiveLocation,
                          );

                          final totalPages = (filtered.length / _itemsPerPage)
                              .ceil()
                              .clamp(1, 999);
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
                                // 1. Overview Metric Cards
                                _buildCompanyOverviewMetrics(),
                                const SizedBox(height: 20),

                                // 2. Search, Multi-Filter & Action Bar
                                _buildFilterAndActionCard(
                                  industries: industries,
                                  selectedIndustry: effectiveIndustry,
                                  locations: locations,
                                  selectedLocation: effectiveLocation,
                                  filteredCompanies: filtered,
                                ),
                                const SizedBox(height: 20),

                                // 3. Company Data Table Card with Pagination
                                _buildCompanyTableCard(
                                  pageCompanies: pageItems,
                                  totalCount: filtered.length,
                                  safePage: safePage,
                                  totalPages: totalPages,
                                  hasAnyCompanies: companies.isNotEmpty,
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

  // 1. 5 Company Overview Metric Cards
  Widget _buildCompanyOverviewMetrics() {
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
              title: 'Total Companies',
              value: '${_companyService.totalCount}',
              subtitle: 'Corporate partners registered',
              icon: Icons.apartment_rounded,
              color: AppColors.primary,
              bgColor: AppColors.lightIceBlue,
            ),
            _buildMetricTile(
              title: 'Verified Companies',
              value: '${_companyService.verifiedCount}',
              subtitle: 'Corporate registration authenticated',
              icon: Icons.verified_rounded,
              color: AppColors.success,
              bgColor: AppColors.successBg,
            ),
            _buildMetricTile(
              title: 'Pending Verification',
              value: '${_companyService.pendingCount}',
              subtitle: 'Awaiting registration review',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              bgColor: AppColors.warningBg,
            ),
            _buildMetricTile(
              title: 'Rejected Companies',
              value: '${_companyService.rejectedCount}',
              subtitle: 'Documentation non-compliant',
              icon: Icons.cancel_outlined,
              color: const Color(0xFF64748B),
              bgColor: AppColors.background,
            ),
            _buildMetricTile(
              title: 'Suspended Companies',
              value: '${_companyService.suspendedCount}',
              subtitle: 'Sponsorship privileges revoked',
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
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. Search, Multi-Filter & Action Bar
  Widget _buildFilterAndActionCard({
    required List<String> industries,
    required String selectedIndustry,
    required List<String> locations,
    required String selectedLocation,
    required List<AdminCompanyModel> filteredCompanies,
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
          // Top Row: Title, Summary & Quick Actions
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
                          ? constraints.maxWidth - 460
                          : constraints.maxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corporate Registry & Verification Directory',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Search, filter, inspect registration credentials, and regulate company account status',
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
                        onPressed: _refreshCompanies,
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkNavy,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: const Text('Verification Queue'),
                        onPressed: () =>
                            _onRouteSelected('company_verifications'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkNavy,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                        ),
                        label: const Text('Export CSV'),
                        onPressed: () => _exportCsvRecords(filteredCompanies),
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

          // Filters Row 1: Industry Dropdown & Location Dropdown & Sort
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
                      initialValue: selectedIndustry,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Industry Sector',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: industries
                          .map(
                            (ind) => DropdownMenuItem(
                              value: ind,
                              child: Text(
                                ind,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedIndustry = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedLocation,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Headquarters Location',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: locations
                          .map(
                            (loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(
                                loc,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLocation = val;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _sortOptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
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
                        borderRadius: BorderRadius.circular(6),
                      ),
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
                        borderRadius: BorderRadius.circular(6),
                      ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChip(AdminCompanyModel company) {
    final isVerified =
        company.verificationStatus == CompanyVerificationState.verified;
    final isPending =
        company.verificationStatus == CompanyVerificationState.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.successBg
            : isPending
            ? AppColors.warningBg
            : AppColors.errorBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified
                ? Icons.verified_rounded
                : isPending
                ? Icons.hourglass_top_rounded
                : Icons.cancel_outlined,
            size: 13,
            color: isVerified
                ? AppColors.success
                : isPending
                ? AppColors.warning
                : AppColors.error,
          ),
          const SizedBox(width: 5),
          Text(
            isVerified
                ? 'Verified'
                : isPending
                ? 'Pending'
                : 'Rejected',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isVerified
                  ? const Color(0xFF166534)
                  : isPending
                  ? const Color(0xFF92400E)
                  : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChip(bool isSuspended) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isSuspended ? AppColors.errorBg : AppColors.lightIceBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isSuspended ? 'Suspended' : 'Active',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSuspended ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCompanyActionMenu(
    AdminCompanyModel company, {
    required bool isPending,
    required bool isSuspended,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (val) {
        if (val == 'inspect_doc') {
          _openDocumentPreviewModal(company);
        } else if (val == 'approve') {
          final admin =
              _authService.currentAdmin?.fullName ?? 'Executive Administrator';
          _companyService.approveCompanyVerification(
            companyId: company.id,
            adminName: admin,
          );
        } else if (val == 'reject') {
          _promptRejectCompanyVerification(company);
        } else if (val == 'request_docs') {
          _promptRequestAdditionalDocs(company);
        } else if (val == 'suspend') {
          _promptSuspendCompany(company);
        } else if (val == 'reactivate') {
          _promptReactivateCompany(company);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'inspect_doc',
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 16),
              SizedBox(width: 8),
              Text('Inspect Evidence Document', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        if (isPending) ...[
          const PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Text(
                  'Approve Verification',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Reject Verification',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'request_docs',
            child: Row(
              children: [
                Icon(
                  Icons.contact_support_outlined,
                  size: 16,
                  color: AppColors.warning,
                ),
                SizedBox(width: 8),
                Text(
                  'Request Additional Docs',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ],
            ),
          ),
        ],
        if (!isSuspended)
          const PopupMenuItem(
            value: 'suspend',
            child: Row(
              children: [
                Icon(Icons.block_rounded, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Suspend Account',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          )
        else
          const PopupMenuItem(
            value: 'reactivate',
            child: Row(
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Text(
                  'Reactivate Account',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 3. Company Data Table Card with Pagination
  Widget _buildCompanyTableCard({
    required List<AdminCompanyModel> pageCompanies,
    required int totalCount,
    required int safePage,
    required int totalPages,
    required bool hasAnyCompanies,
  }) {
    if (pageCompanies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: AppEmptyState(
          icon: Icons.domain_disabled_rounded,
          title: hasAnyCompanies
              ? 'No corporate partners match the active criteria'
              : 'No corporate partners registered yet',
          subtitle: hasAnyCompanies
              ? 'Try adjusting the sector, location, or verification status filter.'
              : 'Registered companies from Supabase will appear here automatically once onboarded.',
          actionLabel: hasAnyCompanies ? 'Reset Filters' : 'Refresh',
          onAction: hasAnyCompanies
              ? () {
                  setState(() {
                    _searchQuery = '';
                    _selectedIndustry = 'All Industries';
                    _selectedLocation = 'All Locations';
                    _selectedVerificationStatus = 'All';
                    _selectedAccountStatus = 'All';
                    _currentPage = 1;
                  });
                }
              : _refreshCompanies,
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
                itemCount: pageCompanies.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final company = pageCompanies[index];
                  final isPending =
                      company.verificationStatus ==
                      CompanyVerificationState.pending;
                  final isSuspended =
                      company.accountStatus == CompanyAccountState.suspended;

                  if (isCompact) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.darkNavy,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    company.logoInitial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            company.companyName,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.darkNavy,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (company.isEmailVerified) ...[
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: AppColors.accentTeal,
                                            size: 15,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${company.officialEmail} • Reg: ${company.registrationNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              _buildCompanyActionMenu(
                                company,
                                isPending: isPending,
                                isSuspended: isSuspended,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${company.industry} • ${company.city} • ${company.registrationDate}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildVerificationChip(company),
                              _buildAccountChip(isSuspended),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.assignment_ind_outlined,
                                  size: 15,
                                ),
                                label: const Text(
                                  'View Profile',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                onPressed: () =>
                                    _openCompanyProfileDrawer(company),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              company.logoInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      company.companyName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: AppColors.darkNavy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (company.isEmailVerified) ...[
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.accentTeal,
                                      size: 15,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${company.officialEmail} • Reg: ${company.registrationNumber}',
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
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.industry,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                company.city,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildVerificationChip(company),
                        const SizedBox(width: 12),
                        _buildAccountChip(isSuspended),
                        const SizedBox(width: 12),
                        Text(
                          company.registrationDate,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(
                            Icons.assignment_ind_outlined,
                            size: 15,
                          ),
                          label: const Text(
                            'View Profile',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () => _openCompanyProfileDrawer(company),
                        ),
                        const SizedBox(width: 6),
                        _buildCompanyActionMenu(
                          company,
                          isPending: isPending,
                          isSuspended: isSuspended,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Pagination Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Showing ${pageCompanies.length} of $totalCount companies (Page $safePage of $totalPages)',
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
                              ? () =>
                                    setState(() => _currentPage = safePage - 1)
                              : null,
                        ),
                        Text(
                          '$safePage',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: safePage < totalPages
                              ? () =>
                                    setState(() => _currentPage = safePage + 1)
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
