import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/admin_settings_model.dart';
import 'package:link_vibe/feature/admin/models/admin_user_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/application_monitoring_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/certificate_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/company_verifications_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/project_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/reports_analytics_screen.dart';
import 'package:link_vibe/feature/admin/presentation/screens/student_management_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';

/// Enterprise Admin Settings, Taxonomies, Support & RBAC Console.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  final AdminSettingsService _settingsService = AdminSettingsService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  bool _isSidebarCollapsed = false;
  bool _isRefreshing = false;
  bool _isUpdatingPassword = false;

  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  String _taxonomySearch = '';
  String _universitySearch = '';
  String _supportSearch = '';
  HelpRequestStatus? _supportStatusFilter;
  String _complaintSearch = '';
  ComplaintStatus? _complaintStatusFilter;
  String _auditLogSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshSettings() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _settingsService.loadFromSupabase();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Governance settings & logs synchronized with Supabase.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onRouteSelected(String routeId) {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (routeId == 'settings') {
      return;
    }
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
    } else if (routeId == 'company_verifications') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyVerificationsScreen()),
      );
    } else if (routeId == 'company_management') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyManagementScreen()),
      );
    } else if (routeId == 'projects_audit' || routeId == 'projects') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
      );
    } else if (routeId == 'compliance' || routeId == 'application_monitoring') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ApplicationMonitoringScreen(),
        ),
      );
    } else if (routeId == 'audit_logs' || routeId == 'certificates') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CertificateManagementScreen(),
        ),
      );
    } else if (routeId == 'analytics' || routeId == 'reports') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ValueListenableBuilder<AdminUserModel?>(
      valueListenable: _authService.currentAdminNotifier,
      builder: (context, authAdmin, _) {
        final currentAdmin = authAdmin ??
            const AdminUserModel(
              id: 'adm_root_001',
              fullName: 'Executive Administrator',
              email: 'admin@skillbridge.edu.pk',
              role: 'SUPER_ADMIN',
              roleDisplayName: 'Executive Super Administrator',
              department: 'SkillBridge Governance Council',
              avatarInitial: 'EA',
              permissions: ['all'],
              lastLoginAt: 'Active Session',
            );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: 'settings',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'settings',
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
                      pageTitle: 'Platform Settings & Governance',
                      breadcrumb: 'Configuration Hub',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                    ),
                    Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'System Administration & Support Desk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Logged in as ${currentAdmin.fullName} (${currentAdmin.roleDisplayName})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      icon: _isRefreshing
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.refresh_rounded,
                                              size: 16,
                                            ),
                                      label: Text(
                                        _isRefreshing ? 'Syncing...' : 'Refresh',
                                      ),
                                      onPressed:
                                          _isRefreshing ? null : _refreshSettings,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.shield_outlined,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            currentAdmin.role,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textMuted,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            unselectedLabelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: const [
                              Tab(icon: Icon(Icons.category_outlined, size: 16), text: 'Taxonomies'),
                              Tab(icon: Icon(Icons.school_outlined, size: 16), text: 'Universities'),
                              Tab(icon: Icon(Icons.support_agent_outlined, size: 16), text: 'Help Desk'),
                              Tab(icon: Icon(Icons.gavel_outlined, size: 16), text: 'Complaints'),
                              Tab(icon: Icon(Icons.policy_outlined, size: 16), text: 'Policies & Legal'),
                              Tab(icon: Icon(Icons.admin_panel_settings_outlined, size: 16), text: 'Admin RBAC'),
                              Tab(icon: Icon(Icons.security_outlined, size: 16), text: 'Security & Audit'),
                              Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Profile & Sessions'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTaxonomiesTab(currentAdmin),
                          _buildUniversitiesTab(currentAdmin),
                          _buildHelpDeskTab(currentAdmin),
                          _buildComplaintsTab(currentAdmin),
                          _buildPoliciesTab(currentAdmin),
                          _buildAdminRbacTab(currentAdmin),
                          _buildSecurityAuditTab(currentAdmin),
                          _buildProfileSessionsTab(currentAdmin),
                        ],
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

  // ===========================================================================
  // TAB 1: TAXONOMIES (CATEGORIES & SKILLS)
  // ===========================================================================
  Widget _buildTaxonomiesTab(AdminUserModel currentAdmin) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                const subTabs = TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: 'Project Categories'),
                    Tab(text: 'Skill Competencies'),
                  ],
                );
                final searchBox = SizedBox(
                  width: isNarrow ? double.infinity : 240,
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search taxonomy...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) =>
                        setState(() => _taxonomySearch = val.toLowerCase()),
                  ),
                );
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      subTabs,
                      const SizedBox(height: 8),
                      searchBox,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [subTabs, searchBox],
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCategoriesList(currentAdmin),
                _buildSkillsList(currentAdmin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<CategorySettingItem>>(
      valueListenable: _settingsService.categoriesNotifier,
      builder: (context, categories, _) {
        final filtered = categories.where((c) {
          if (_taxonomySearch.isEmpty) return true;
          return c.name.toLowerCase().contains(_taxonomySearch) ||
              c.description.toLowerCase().contains(_taxonomySearch);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Active Categories (${categories.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCategoryModal(currentAdmin),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.category_outlined,
                  title: 'No Project Categories Yet',
                  subtitle: categories.isEmpty
                      ? 'Add domain categories so companies can classify projects across engineering disciplines.'
                      : 'No categories match your current search filter.',
                  actionLabel:
                      categories.isEmpty ? 'Add Category' : 'Clear Search',
                  actionIcon:
                      categories.isEmpty ? Icons.add : Icons.clear_rounded,
                  onAction: categories.isEmpty
                      ? () => _showAddCategoryModal(currentAdmin)
                      : () => setState(() => _taxonomySearch = ''),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final cat = filtered[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(top: 4, right: 12),
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${cat.projectCount} Projects',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.description.isNotEmpty
                                      ? cat.description
                                      : 'No description provided.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: cat.isActive,
                                activeThumbColor: AppColors.success,
                                onChanged: (_) {
                                  _settingsService.toggleCategoryActive(
                                    cat.id,
                                    currentAdmin.email,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () =>
                                    _showEditCategoryModal(cat, currentAdmin),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillsList(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<SkillSettingItem>>(
      valueListenable: _settingsService.skillsNotifier,
      builder: (context, skills, _) {
        final filtered = skills.where((s) {
          if (_taxonomySearch.isEmpty) return true;
          return s.name.toLowerCase().contains(_taxonomySearch) ||
              s.categoryName.toLowerCase().contains(_taxonomySearch);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Skill Competencies (${skills.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSkillModal(currentAdmin),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Skill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.psychology_outlined,
                  title: 'No Technical Skills Registered',
                  subtitle: skills.isEmpty
                      ? 'Add standardized technical skill competencies for student profiles and project listings.'
                      : 'No skills match your active search query.',
                  actionLabel: skills.isEmpty ? 'Add Skill' : 'Clear Search',
                  actionIcon: skills.isEmpty ? Icons.add : Icons.clear_rounded,
                  onAction: skills.isEmpty
                      ? () => _showAddSkillModal(currentAdmin)
                      : () => setState(() => _taxonomySearch = ''),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 56,
                    columns: const [
                      DataColumn(label: Text('Skill Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Taxonomy Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Usage Count', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Active State', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((s) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.categoryName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          DataCell(Text('${s.usageCount} projects')),
                          DataCell(
                            Switch(
                              value: s.isActive,
                              activeThumbColor: AppColors.success,
                              onChanged: (_) {
                                _settingsService.toggleSkillActive(
                                  s.id,
                                  currentAdmin.email,
                                );
                              },
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () =>
                                      _showEditSkillModal(s, currentAdmin),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    _settingsService.deleteSkill(
                                      s.id,
                                      currentAdmin.email,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 2: ACCREDITED UNIVERSITIES
  // ===========================================================================
  Widget _buildUniversitiesTab(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<UniversitySettingItem>>(
      valueListenable: _settingsService.universitiesNotifier,
      builder: (context, universities, _) {
        final filtered = universities.where((u) {
          if (_universitySearch.isEmpty) return true;
          return u.name.toLowerCase().contains(_universitySearch) ||
              u.shortName.toLowerCase().contains(_universitySearch) ||
              u.city.toLowerCase().contains(_universitySearch) ||
              u.domain.toLowerCase().contains(_universitySearch);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accredited University Institutions (${universities.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Recognized universities and faculties authorized for student onboarding.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUniversityModal(currentAdmin),
                    icon: const Icon(Icons.account_balance, size: 16),
                    label: const Text('Add University'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by university name, city, domain...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) =>
                        setState(() => _universitySearch = val.toLowerCase()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.school_outlined,
                  title: 'No Accredited Universities Yet',
                  subtitle: universities.isEmpty
                      ? 'Accredit universities and academic domains for student credential verification.'
                      : 'No institutions match your active search query.',
                  actionLabel:
                      universities.isEmpty ? 'Add University' : 'Clear Search',
                  actionIcon: universities.isEmpty
                      ? Icons.add
                      : Icons.clear_rounded,
                  onAction: universities.isEmpty
                      ? () => _showAddUniversityModal(currentAdmin)
                      : () => setState(() => _universitySearch = ''),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columns: const [
                      DataColumn(label: Text('Institution', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acronym', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Email Domain', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Students', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((u) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.school,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  u.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              u.shortName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              [
                                if (u.city.isNotEmpty) u.city,
                                if (u.province.isNotEmpty) u.province,
                              ].join(', '),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              u.domain.isNotEmpty ? '@${u.domain}' : '—',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          DataCell(Text('${u.studentCount}')),
                          DataCell(
                            Switch(
                              value: u.isActive,
                              activeThumbColor: AppColors.success,
                              onChanged: (_) {
                                _settingsService.toggleUniversityActive(
                                  u.id,
                                  currentAdmin.email,
                                );
                              },
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () =>
                                  _showEditUniversityModal(u, currentAdmin),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: HELP & SUPPORT DESK
  // ===========================================================================
  Widget _buildHelpDeskTab(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<HelpRequestItem>>(
      valueListenable: _settingsService.helpRequestsNotifier,
      builder: (context, tickets, _) {
        final pendingCount =
            tickets.where((t) => t.status == HelpRequestStatus.pending).length;
        final inProgressCount = tickets
            .where((t) => t.status == HelpRequestStatus.inProgress)
            .length;
        final resolvedCount =
            tickets.where((t) => t.status == HelpRequestStatus.resolved).length;

        final filtered = tickets.where((t) {
          if (_supportStatusFilter != null && t.status != _supportStatusFilter) {
            return false;
          }
          if (_supportSearch.isEmpty) return true;
          return t.subject.toLowerCase().contains(_supportSearch) ||
              t.senderName.toLowerCase().contains(_supportSearch) ||
              t.senderEmail.toLowerCase().contains(_supportSearch) ||
              t.id.toLowerCase().contains(_supportSearch);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  int cols = 4;
                  if (constraints.maxWidth < 520) {
                    cols = 1;
                  } else if (constraints.maxWidth < 960) {
                    cols = 2;
                  }
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: cols == 1 ? 3.2 : 2.1,
                    children: [
                      _buildHelpDeskKpiCard(
                        'Total Tickets',
                        '${tickets.length}',
                        Icons.confirmation_number_outlined,
                        AppColors.primary,
                      ),
                      _buildHelpDeskKpiCard(
                        'Pending Action',
                        '$pendingCount',
                        Icons.pending_actions_outlined,
                        AppColors.error,
                      ),
                      _buildHelpDeskKpiCard(
                        'In Progress',
                        '$inProgressCount',
                        Icons.autorenew_rounded,
                        AppColors.warning,
                      ),
                      _buildHelpDeskKpiCard(
                        'Resolved Tickets',
                        '$resolvedCount',
                        Icons.task_alt_rounded,
                        AppColors.success,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search tickets by subject, user, email...',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (val) =>
                            setState(() => _supportSearch = val.toLowerCase()),
                      ),
                    ),
                  ),
                  DropdownButton<HelpRequestStatus?>(
                    value: _supportStatusFilter,
                    hint: const Text('All Statuses'),
                    onChanged: (val) =>
                        setState(() => _supportStatusFilter = val),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Statuses')),
                      DropdownMenuItem(
                        value: HelpRequestStatus.pending,
                        child: Text('Pending Only'),
                      ),
                      DropdownMenuItem(
                        value: HelpRequestStatus.inProgress,
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: HelpRequestStatus.resolved,
                        child: Text('Resolved'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.support_agent_outlined,
                  title: 'No Support Tickets Found',
                  subtitle: tickets.isEmpty
                      ? 'No student or company support requests are currently open.'
                      : 'Try clearing your ticket search or status filter.',
                  actionLabel: tickets.isEmpty ? 'Refresh' : 'Reset Filters',
                  actionIcon: tickets.isEmpty
                      ? Icons.refresh_rounded
                      : Icons.filter_alt_off_rounded,
                  onAction: tickets.isEmpty
                      ? _refreshSettings
                      : () => setState(() {
                            _supportSearch = '';
                            _supportStatusFilter = null;
                          }),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columns: const [
                      DataColumn(label: Text('Ticket ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('User / Sender', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((t) {
                      Color priorityColor;
                      if (t.priority == HelpRequestPriority.urgent) {
                        priorityColor = AppColors.error;
                      } else if (t.priority == HelpRequestPriority.high) {
                        priorityColor = AppColors.warning;
                      } else {
                        priorityColor = AppColors.textMuted;
                      }

                      Color statusColor;
                      String statusText;
                      if (t.status == HelpRequestStatus.resolved) {
                        statusColor = AppColors.success;
                        statusText = 'RESOLVED';
                      } else if (t.status == HelpRequestStatus.inProgress) {
                        statusColor = AppColors.warning;
                        statusText = 'IN PROGRESS';
                      } else {
                        statusColor = AppColors.error;
                        statusText = 'PENDING';
                      }

                      final shortId = t.id.length > 8
                          ? '${t.id.substring(0, 8)}...'
                          : t.id;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              shortId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  t.senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  t.senderEmail,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (t.userType == 'student'
                                        ? AppColors.primary
                                        : AppColors.accentTeal)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.userType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: t.userType == 'student'
                                      ? AppColors.primary
                                      : AppColors.accentTeal,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                t.subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.priority.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: priorityColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () =>
                                  _showHelpRequestDetailModal(t, currentAdmin),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'View & Respond',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpDeskKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: COMPLAINTS & GRIEVANCES
  // ===========================================================================
  Widget _buildComplaintsTab(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<ComplaintItem>>(
      valueListenable: _settingsService.complaintsNotifier,
      builder: (context, complaints, _) {
        final filtered = complaints.where((c) {
          if (_complaintStatusFilter != null &&
              c.status != _complaintStatusFilter) {
            return false;
          }
          if (_complaintSearch.isEmpty) return true;
          return c.subject.toLowerCase().contains(_complaintSearch) ||
              c.complainantName.toLowerCase().contains(_complaintSearch) ||
              c.reportedEntityName.toLowerCase().contains(_complaintSearch) ||
              c.id.toLowerCase().contains(_complaintSearch);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Grievances & Complaints (${complaints.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Review misconduct, deliverable integrity concerns, and unresponsive partner reports.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search complaints by subject, entity, ID...',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (val) =>
                            setState(() => _complaintSearch = val.toLowerCase()),
                      ),
                    ),
                  ),
                  DropdownButton<ComplaintStatus?>(
                    value: _complaintStatusFilter,
                    hint: const Text('All Grievance Statuses'),
                    onChanged: (val) =>
                        setState(() => _complaintStatusFilter = val),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Grievance Statuses'),
                      ),
                      DropdownMenuItem(
                        value: ComplaintStatus.newComplaint,
                        child: Text('New Only'),
                      ),
                      DropdownMenuItem(
                        value: ComplaintStatus.underInvestigation,
                        child: Text('Under Investigation'),
                      ),
                      DropdownMenuItem(
                        value: ComplaintStatus.resolved,
                        child: Text('Resolved'),
                      ),
                      DropdownMenuItem(
                        value: ComplaintStatus.dismissed,
                        child: Text('Dismissed'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.gavel_outlined,
                  title: 'No Complaints Recorded',
                  subtitle: complaints.isEmpty
                      ? 'No compliance grievances or dispute escalations have been filed.'
                      : 'Try resetting your complaint search or status filter.',
                  actionLabel:
                      complaints.isEmpty ? 'Refresh' : 'Reset Filters',
                  actionIcon: complaints.isEmpty
                      ? Icons.refresh_rounded
                      : Icons.filter_alt_off_rounded,
                  onAction: complaints.isEmpty
                      ? _refreshSettings
                      : () => setState(() {
                            _complaintSearch = '';
                            _complaintStatusFilter = null;
                          }),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final cmp = filtered[i];
                    Color severityColor;
                    if (cmp.severity == ComplaintSeverity.critical) {
                      severityColor = AppColors.error;
                    } else if (cmp.severity == ComplaintSeverity.high) {
                      severityColor = const Color(0xFFE11D48);
                    } else if (cmp.severity == ComplaintSeverity.medium) {
                      severityColor = AppColors.warning;
                    } else {
                      severityColor = AppColors.textMuted;
                    }

                    Color statusColor;
                    if (cmp.status == ComplaintStatus.resolved) {
                      statusColor = AppColors.success;
                    } else if (cmp.status ==
                        ComplaintStatus.underInvestigation) {
                      statusColor = AppColors.warning;
                    } else if (cmp.status == ComplaintStatus.dismissed) {
                      statusColor = AppColors.textMuted;
                    } else {
                      statusColor = AppColors.error;
                    }

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    cmp.id.length > 10
                                        ? '${cmp.id.substring(0, 8)}...'
                                        : cmp.id,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: severityColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${cmp.severity.name.toUpperCase()} SEVERITY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: severityColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      cmp.status.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                cmp.submittedAt
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cmp.subject,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cmp.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Filed by: ${cmp.complainantName}  •  Entity: ${cmp.reportedEntityName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showComplaintInvestigationModal(
                                      cmp,
                                      currentAdmin,
                                    ),
                                icon: const Icon(Icons.search, size: 14),
                                label: const Text('Investigate & Resolve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 5: PLATFORM POLICIES & GUIDELINES
  // ===========================================================================
  Widget _buildPoliciesTab(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<PlatformPolicyItem>>(
      valueListenable: _settingsService.policiesNotifier,
      builder: (context, policies, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Policy Governance & Legal Charters',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Manage collaboration guidelines, data privacy regulations, and code of conduct standards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePolicyModal(currentAdmin),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Policy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (policies.isEmpty)
                AppEmptyState(
                  icon: Icons.policy_outlined,
                  title: 'No Governance Policies Published',
                  subtitle:
                      'Publish Terms of Service, Privacy Policy, or Academic Collaboration Guidelines for platform users.',
                  actionLabel: 'Create First Policy',
                  actionIcon: Icons.add,
                  onAction: () => _showCreatePolicyModal(currentAdmin),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: policies.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final pol = policies[i];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    pol.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      pol.version,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showEditPolicyModal(pol, currentAdmin),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Edit Policy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated ${pol.lastUpdatedAt.toLocal().toString().substring(0, 10)} by ${pol.updatedByAdmin}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pol.content,
                              style: const TextStyle(fontSize: 12, height: 1.5),
                            ),
                          ),
                          if (pol.history.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Version History:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...pol.history.map(
                              (h) => Text(
                                '• ${h.version} (${h.updatedAt.toString().substring(0, 10)}) - ${h.changeSummary}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 6: ADMIN ACCESS & RBAC
  // ===========================================================================
  Widget _buildAdminRbacTab(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<AdminUserModel>>(
      valueListenable: _settingsService.adminsNotifier,
      builder: (context, admins, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorized Administrative Directory (${admins.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Administrator accounts registered in the Governance profile table.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (currentAdmin.isSuperAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showProvisionAdminModal(currentAdmin),
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text('Provision Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (admins.isEmpty)
                const AppEmptyState(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'No Admin Records Loaded',
                  subtitle:
                      'Sign in as an authorized administrator or refresh settings from Supabase.',
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columns: const [
                      DataColumn(label: Text('Administrator', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Role Scope', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Last Active', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Account State', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: admins.map((adm) {
                      final isSuper = adm.role == 'SUPER_ADMIN';
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSuper
                                      ? AppColors.darkNavy
                                      : AppColors.primary,
                                  child: Text(
                                    adm.avatarInitial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      adm.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      adm.email,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (isSuper
                                        ? AppColors.darkNavy
                                        : AppColors.primary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                adm.roleDisplayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSuper
                                      ? AppColors.darkNavy
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(adm.department, style: const TextStyle(fontSize: 12)),
                          ),
                          DataCell(
                            Text(adm.lastLoginAt, style: const TextStyle(fontSize: 12)),
                          ),
                          DataCell(
                            isSuper
                                ? const Text(
                                    'ROOT SECURED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  )
                                : Switch(
                                    value: adm.isActive,
                                    activeThumbColor: AppColors.success,
                                    onChanged: (_) {
                                      _settingsService.toggleAdminActive(
                                        adm.id,
                                        currentAdmin.email,
                                      );
                                    },
                                  ),
                          ),
                          DataCell(
                            Text(
                              adm.permissions.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 7: SECURITY POLICIES & AUDIT LOGS
  // ===========================================================================
  Widget _buildSecurityAuditTab(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<AdminAuditLogItem>>(
      valueListenable: _settingsService.auditLogsNotifier,
      builder: (context, logs, _) {
        final filtered = logs.where((l) {
          if (_auditLogSearch.isEmpty) return true;
          return l.action.toLowerCase().contains(_auditLogSearch) ||
              l.adminEmail.toLowerCase().contains(_auditLogSearch) ||
              l.target.toLowerCase().contains(_auditLogSearch);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _buildSecurityPill(
                      'Authentication',
                      'Supabase JWT Session',
                      Icons.lock_clock,
                    ),
                    _buildSecurityPill(
                      'Access Governance',
                      'Postgres Row-Level Security',
                      Icons.password,
                    ),
                    _buildSecurityPill(
                      'Session Defense',
                      'Instant Token Revocation',
                      Icons.vpn_key,
                    ),
                    _buildSecurityPill(
                      'Audit Ledger',
                      'Persistent Supabase Trail',
                      Icons.history_edu,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Administrative Activity Audit Log (${logs.length} Events)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Filter log entries...',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (val) =>
                            setState(() => _auditLogSearch = val.toLowerCase()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: Icons.history_edu_outlined,
                  title: 'No Audit Log Events Found',
                  subtitle: logs.isEmpty
                      ? 'Administrative governance actions will automatically log to this vault.'
                      : 'No audit log entries match your current filter.',
                  actionLabel: logs.isEmpty ? 'Refresh Logs' : 'Clear Filter',
                  actionIcon:
                      logs.isEmpty ? Icons.refresh_rounded : Icons.clear_rounded,
                  onAction: logs.isEmpty
                      ? _refreshSettings
                      : () => setState(() => _auditLogSearch = ''),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final log = filtered[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          log.action,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          'Target: ${log.target}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      log.timestamp
                                          .toLocal()
                                          .toString()
                                          .substring(0, 16),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log.details,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Admin: ${log.adminEmail}  •  Source: ${log.ipAddress}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityPill(String title, String subtitle, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accentTeal, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 8: PROFILE & SESSIONS
  // ===========================================================================
  Widget _buildProfileSessionsTab(AdminUserModel currentAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.darkNavy,
                      child: Text(
                        currentAdmin.avatarInitial,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAdmin.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentAdmin.email}  •  ${currentAdmin.department}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentAdmin.roleDisplayName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileModal(currentAdmin),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Update Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildChangePasswordCard(currentAdmin),
          const SizedBox(height: 24),
          _buildActiveSessionsCard(currentAdmin),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard(AdminUserModel currentAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Credentials & Password Rotation',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Update your administrator Supabase password regularly to maintain account security.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final currentField = TextField(
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              final newField = TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              final confirmField = TextField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    currentField,
                    const SizedBox(height: 12),
                    newField,
                    const SizedBox(height: 12),
                    confirmField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: currentField),
                  const SizedBox(width: 14),
                  Expanded(child: newField),
                  const SizedBox(width: 14),
                  Expanded(child: confirmField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isUpdatingPassword
                ? null
                : () async {
                    final newP = _newPasswordCtrl.text;
                    final confP = _confirmPasswordCtrl.text;
                    if (newP.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a new password.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (newP != confP) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'New password and confirmation do not match.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    setState(() => _isUpdatingPassword = true);
                    final success = await _settingsService.changePassword(
                      currentPassword: _currentPasswordCtrl.text,
                      newPassword: newP,
                      adminEmail: currentAdmin.email,
                    );
                    if (!mounted) return;
                    setState(() => _isUpdatingPassword = false);
                    if (success) {
                      _currentPasswordCtrl.clear();
                      _newPasswordCtrl.clear();
                      _confirmPasswordCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Administrative password successfully updated and rotated.',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to update password. Ensure your session is active.',
                          ),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _isUpdatingPassword ? 'Updating...' : 'Update Password',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsCard(AdminUserModel currentAdmin) {
    return ValueListenableBuilder<List<AdminSessionItem>>(
      valueListenable: _settingsService.sessionsNotifier,
      builder: (context, sessions, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Active Administrator Login Sessions',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sessions.length > 1)
                    TextButton.icon(
                      onPressed: () {
                        for (final s in sessions) {
                          if (!s.isCurrent) {
                            _settingsService.terminateSession(
                              s.sessionId,
                              currentAdmin.email,
                            );
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'All secondary administrative sessions terminated.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.logout,
                        size: 14,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Terminate Other Sessions',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                const AppEmptyState(
                  compact: true,
                  icon: Icons.devices_other_rounded,
                  title: 'No Active Authenticated Session Info',
                  subtitle: 'Sign in with Supabase Auth to view session details.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, index) =>
                      const Divider(color: AppColors.border),
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return Row(
                      children: [
                        Icon(
                          s.isCurrent ? Icons.computer : Icons.devices,
                          color: s.isCurrent
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    s.device,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (s.isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'THIS WORKSTATION',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${s.browser}  •  ${s.ipAddress} (${s.location})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!s.isCurrent)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.error,
                            ),
                            tooltip: 'Revoke Session',
                            onPressed: () {
                              _settingsService.terminateSession(
                                s.sessionId,
                                currentAdmin.email,
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODALS & ACTIONS
  // ===========================================================================

  void _showAddCategoryModal(AdminUserModel currentAdmin) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Color selectedColor = AppColors.primary;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              title: const Text('Add New Project Category'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Scope Description',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Theme Color: '),
                        ...[
                          const Color(0xFF6366F1),
                          const Color(0xFF0D9488),
                          const Color(0xFF3B82F6),
                          const Color(0xFF10B981),
                          const Color(0xFFF59E0B),
                          const Color(0xFFEC4899),
                        ].map((c) {
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = c),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == c
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
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
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final success = _settingsService.addCategory(
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      color: selectedColor,
                      adminEmail: currentAdmin.email,
                    );
                    if (success) {
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category with this title already exists.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryModal(
    CategorySettingItem cat,
    AdminUserModel currentAdmin,
  ) {
    final nameCtrl = TextEditingController(text: cat.name);
    final descCtrl = TextEditingController(text: cat.description);
    Color selectedColor = cat.color;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              title: const Text('Edit Project Category'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Scope Description',
                      ),
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
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final success = _settingsService.updateCategory(
                      id: cat.id,
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      color: selectedColor,
                      adminEmail: currentAdmin.email,
                    );
                    if (success) {
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Duplicate category name detected.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSkillModal(AdminUserModel currentAdmin) {
    final nameCtrl = TextEditingController();
    final catNames = _settingsService.categoriesNotifier.value
        .map((c) => c.name.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    if (catNames.isEmpty) {
      catNames.add('General');
    }
    String selectedCat = catNames.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              title: const Text('Add Technical Skill'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Skill Competency Name',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assign to Category',
                      ),
                      items: catNames
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCat = val);
                      },
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
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final success = _settingsService.addSkill(
                      name: nameCtrl.text,
                      categoryName: selectedCat,
                      adminEmail: currentAdmin.email,
                    );
                    if (success) {
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Duplicate skill name detected.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Skill'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSkillModal(
    SkillSettingItem skill,
    AdminUserModel currentAdmin,
  ) {
    final nameCtrl = TextEditingController(text: skill.name);
    final catNames = <String>{
      if (skill.categoryName.trim().isNotEmpty) skill.categoryName.trim(),
      ..._settingsService.categoriesNotifier.value
          .map((c) => c.name.trim())
          .where((n) => n.isNotEmpty),
    }.toList();
    if (catNames.isEmpty) catNames.add('General');
    String selectedCat = catNames.contains(skill.categoryName.trim())
        ? skill.categoryName.trim()
        : catNames.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              title: const Text('Edit Skill'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Skill Name'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Taxonomy Category',
                      ),
                      items: catNames
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCat = val);
                      },
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
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final success = _settingsService.updateSkill(
                      id: skill.id,
                      name: nameCtrl.text,
                      categoryName: selectedCat,
                      adminEmail: currentAdmin.email,
                    );
                    if (success) {
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Duplicate skill name detected.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddUniversityModal(AdminUserModel currentAdmin) {
    final nameCtrl = TextEditingController();
    final shortNameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final provinceCtrl = TextEditingController();
    final domainCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Accredit New University'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Official University Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: shortNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Acronym',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: domainCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Domain (edu.pk)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: provinceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Province / Region',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final success = _settingsService.addUniversity(
                  name: nameCtrl.text,
                  shortName: shortNameCtrl.text,
                  city: cityCtrl.text,
                  province: provinceCtrl.text,
                  domain: domainCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                if (success) {
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'University with this name or domain already accredited.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Accredit Institution'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUniversityModal(
    UniversitySettingItem uni,
    AdminUserModel currentAdmin,
  ) {
    final nameCtrl = TextEditingController(text: uni.name);
    final shortNameCtrl = TextEditingController(text: uni.shortName);
    final cityCtrl = TextEditingController(text: uni.city);
    final provinceCtrl = TextEditingController(text: uni.province);
    final domainCtrl = TextEditingController(text: uni.domain);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit University Details'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'University Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: shortNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Acronym',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: domainCtrl,
                          decoration: const InputDecoration(labelText: 'Domain'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: provinceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Province',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final success = _settingsService.updateUniversity(
                  id: uni.id,
                  name: nameCtrl.text,
                  shortName: shortNameCtrl.text,
                  city: cityCtrl.text,
                  province: provinceCtrl.text,
                  domain: domainCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                if (success) {
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Duplicate university records detected.'),
                    ),
                  );
                }
              },
              child: const Text('Save Details'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpRequestDetailModal(
    HelpRequestItem ticket,
    AdminUserModel currentAdmin,
  ) {
    final responseCtrl = TextEditingController(text: ticket.adminResponse ?? '');
    final resolutionCtrl =
        TextEditingController(text: ticket.resolutionNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Ticket ${ticket.id}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject: ${ticket.subject}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From: ${ticket.senderName} (${ticket.senderEmail}) • ${ticket.userType.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      ticket.message,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Administrative Response:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: responseCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Enter formal administrative guidance or resolution instructions...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Resolution Notes (Optional for closing):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resolutionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Internal notes regarding actions taken to resolve ticket...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                _settingsService.addAdminResponse(
                  ticketId: ticket.id,
                  responseText: responseCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Administrative response delivered.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Response'),
            ),
            ElevatedButton(
              onPressed: () {
                _settingsService.addAdminResponse(
                  ticketId: ticket.id,
                  responseText: responseCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                _settingsService.resolveHelpRequest(
                  ticketId: ticket.id,
                  resolutionNotes: resolutionCtrl.text.isNotEmpty
                      ? resolutionCtrl.text
                      : 'Ticket addressed by admin.',
                  adminEmail: currentAdmin.email,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help request marked as RESOLVED.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Resolved'),
            ),
          ],
        );
      },
    );
  }

  void _showComplaintInvestigationModal(
    ComplaintItem cmp,
    AdminUserModel currentAdmin,
  ) {
    final noteCtrl = TextEditingController(text: cmp.investigationNotes ?? '');
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Complaint Investigation (${cmp.id})',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject: ${cmp.subject}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${cmp.category}  •  Filed: ${cmp.submittedAt.toString().substring(0, 16)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cmp.description,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Investigation Findings & Observations:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Record audit findings, discussions, verification checks...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mandatory Resolution / Dismissal Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Mandatory reason required to resolve or dismiss complaint...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mandatory reason required to dismiss complaint.',
                      ),
                    ),
                  );
                  return;
                }
                _settingsService.dismissComplaint(
                  complaintId: cmp.id,
                  reason: reasonCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Dismiss Complaint',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mandatory reason required to resolve complaint.',
                      ),
                    ),
                  );
                  return;
                }
                if (noteCtrl.text.trim().isNotEmpty) {
                  _settingsService.updateInvestigationNotes(
                    complaintId: cmp.id,
                    notes: noteCtrl.text,
                    adminEmail: currentAdmin.email,
                  );
                }
                _settingsService.resolveComplaint(
                  complaintId: cmp.id,
                  reason: reasonCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Grievance marked as Resolved with formal outcome.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resolve Grievance'),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePolicyModal(AdminUserModel currentAdmin) {
    final keyCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Publish Platform Governance Policy'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Policy Document Title *',
                      hintText: 'e.g. Terms of Service / Privacy Policy',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Policy Identifier Key *',
                      hintText: 'e.g. privacy_policy',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Policy Content *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();
                final key = keyCtrl.text.trim().isNotEmpty
                    ? keyCtrl.text.trim().toLowerCase().replaceAll(' ', '_')
                    : title.toLowerCase().replaceAll(' ', '_');
                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Title and policy content are required.'),
                    ),
                  );
                  return;
                }
                _settingsService.createPolicy(
                  policyKey: key,
                  title: title,
                  content: content,
                  adminEmail: currentAdmin.email,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Governance policy published successfully.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Publish Policy'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPolicyModal(
    PlatformPolicyItem policy,
    AdminUserModel currentAdmin,
  ) {
    final titleCtrl = TextEditingController(text: policy.title);
    final contentCtrl = TextEditingController(text: policy.content);
    final changelogCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Update ${policy.title}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Policy Document Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Policy Content (Markdown/Text)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: changelogCtrl,
                    decoration: const InputDecoration(
                      labelText:
                          'Changelog Summary (e.g. Updated data privacy clause)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (changelogCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Changelog summary required for version audit.',
                      ),
                    ),
                  );
                  return;
                }
                _settingsService.updatePolicy(
                  policyKey: policy.policyKey,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  changeSummary: changelogCtrl.text,
                  adminEmail: currentAdmin.email,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Policy version successfully bumped and updated.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Publish Version Update'),
            ),
          ],
        );
      },
    );
  }

  void _showProvisionAdminModal(AdminUserModel currentAdmin) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController(
      text: 'SkillBridge Governance Council',
    );
    String selectedRole = 'OPERATIONS_ADMIN';
    String roleDisplayName = 'Operations Administrator';
    final List<String> permissions = [
      'manage_categories',
      'manage_skills',
      'manage_support',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              title: const Text('Provision Authorized Admin Account'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Security Notice: Admin accounts can only be provisioned through trusted administrative setup.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Institutional Email',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: deptCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Department / Council',
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Predefined Admin Role',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'OPERATIONS_ADMIN',
                            child: Text('Operations Administrator'),
                          ),
                          DropdownMenuItem(
                            value: 'AUDIT_ADMIN',
                            child: Text('Compliance & Audit Administrator'),
                          ),
                          DropdownMenuItem(
                            value: 'SUPPORT_ADMIN',
                            child: Text('Helpdesk & Support Officer'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedRole = val;
                              if (val == 'OPERATIONS_ADMIN') {
                                roleDisplayName = 'Operations Administrator';
                              } else if (val == 'AUDIT_ADMIN') {
                                roleDisplayName =
                                    'Compliance & Audit Administrator';
                              } else {
                                roleDisplayName = 'Helpdesk & Support Officer';
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty ||
                        emailCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final success = _settingsService.provisionAdminAccount(
                      fullName: nameCtrl.text,
                      email: emailCtrl.text,
                      role: selectedRole,
                      roleDisplayName: roleDisplayName,
                      department: deptCtrl.text,
                      permissions: permissions,
                      adminEmail: currentAdmin.email,
                    );
                    if (success) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin account provisioned successfully.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Administrator with this email already exists.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Provision Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileModal(AdminUserModel currentAdmin) {
    final nameCtrl = TextEditingController(text: currentAdmin.fullName);
    final deptCtrl = TextEditingController(text: currentAdmin.department);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Administrative Profile'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department / Council',
                  ),
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
              onPressed: () {
                _settingsService.updateProfile(
                  fullName: nameCtrl.text,
                  department: deptCtrl.text,
                );
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile information updated.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Profile'),
            ),
          ],
        );
      },
    );
  }
}
