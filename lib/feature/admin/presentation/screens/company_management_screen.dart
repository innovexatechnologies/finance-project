import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_company_model.dart';
import 'package:link_vibe/feature/admin/models/admin_project_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_company_service.dart';
import 'package:link_vibe/feature/admin/services/admin_project_service.dart';
/// Enterprise Company Management Module for SkillBridge Admin Panel (Screen 36)
/// Provides corporate registry overview, search filtering,
/// project auditing, suspension controls, and audit trails.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _companyService.loadFromSupabase();
      AdminProjectService().loadFromSupabase();
    });
  }

  void _showActionResult(
    bool ok,
    String successMessage, {
    Color successColor = AppColors.success,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? successMessage
              : 'Unable to save changes to Supabase. Check connection or permissions.',
        ),
        backgroundColor: ok ? successColor : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isSidebarCollapsed = false;

  // Pagination controls
  int _currentPage = 1;
  final int _itemsPerPage = 5;

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

  void _onRouteSelected(String routeId) {
    AdminSidebar.navigateToRoute(
      context,
      scaffoldKey: _scaffoldKey,
      currentRouteId: 'company_management',
      targetRouteId: routeId,
    );
  }

  // Filter & Sort Logic
  List<AdminCompanyModel> _getFilteredCompanies(
    List<AdminCompanyModel> companies,
  ) {
    return companies.where((c) {
      // Search query
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

      return true;
    }).toList()..sort(
      (a, b) => b.registrationDateTime.compareTo(a.registrationDateTime),
    );
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

              // 4. Posted Collaboration Projects (Strictly Non-Financial)
              _buildSectionHeader(
                '4. Posted Collaboration Projects (${postedProjects.length})',
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

              // 5. Administrative Audit History
              _buildSectionHeader('5. Governance Audit History'),
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

  // 5. Mandatory Reason Prompt for Company Account Suspension
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
              final ok = await _companyService.suspendCompanyAccount(
                companyId: company.id,
                reason: reason,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              _showActionResult(
                ok,
                '${company.companyName} corporate account has been suspended.',
                successColor: AppColors.error,
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
              final ok = await _companyService.reactivateCompanyAccount(
                companyId: company.id,
                adminName: admin,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              _showActionResult(
                ok,
                '${company.companyName} account has been reactivated.',
              );
            },
            child: const Text('Confirm Reactivation'),
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
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: 'company_management',
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
                  activeRouteId: 'company_management',
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
                      pageTitle: 'Company',
                      breadcrumb: 'Platform Directory',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
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
                          final filtered = _getFilteredCompanies(companies);

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

                                // 2. Company Data Table Card with Pagination
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

  // 1. Company Overview Metric Cards
  Widget _buildCompanyOverviewMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 3;
        if (constraints.maxWidth < 650) {
          count = 1;
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
              title: 'Active Accounts',
              value: '${_companyService.activeAccountCount}',
              subtitle: 'Currently active on platform',
              icon: Icons.business_center_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
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
    required bool isSuspended,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (val) {
        if (val == 'suspend') {
          _promptSuspendCompany(company);
        } else if (val == 'reactivate') {
          _promptReactivateCompany(company);
        }
      },
      itemBuilder: (context) => [
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
              ? 'No corporate partners match your search'
              : 'No corporate partners registered yet',
          subtitle: hasAnyCompanies
              ? 'Try adjusting or clearing your search query.'
              : 'Registered companies from Supabase will appear here automatically once onboarded.',
          actionLabel: hasAnyCompanies ? 'Clear Search' : 'Refresh',
          onAction: hasAnyCompanies
              ? () {
                  setState(() {
                    _searchQuery = '';
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
                                      ],
                                    ),
                                    Text(
                                      company.registrationNumber.isNotEmpty
                                          ? '${company.officialEmail} • Reg: ${company.registrationNumber}'
                                          : company.officialEmail,
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
                                isSuspended: isSuspended,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${company.industry}${company.city.isNotEmpty ? ' • ${company.city}' : ''} • Registered ${company.registrationDate} • ${company.postedProjectsCount} Projects',
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
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                company.registrationNumber.isNotEmpty
                                    ? '${company.officialEmail} • Reg: ${company.registrationNumber}'
                                    : company.officialEmail,
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
                                '${company.city.isNotEmpty ? '${company.city} • ' : ''}${company.postedProjectsCount} Projects',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
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
