import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/presentation/widgets/company_executive_app_bar.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

import 'applicants_screen.dart';
import 'company_project_detail_screen.dart';
import 'post_project_screen.dart';

class CompanyProjectsListScreen extends StatefulWidget {
  final String initialFilter;
  final Function(int)? onTabChange;
  final VoidCallback? onOpenDrawer;
  final bool isDrawerOpen;

  const CompanyProjectsListScreen({
    super.key,
    this.initialFilter = 'All',
    this.onTabChange,
    this.onOpenDrawer,
    this.isDrawerOpen = false,
  });

  @override
  State<CompanyProjectsListScreen> createState() =>
      _CompanyProjectsListScreenState();
}

class _CompanyProjectsListScreenState extends State<CompanyProjectsListScreen> {
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  late String _selectedStatus;
  bool _showPaidProjects = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _statusFilters = [
    'All',
    'Open',
    'In Progress',
    'Completed',
    'Draft',
    'Closed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statusFilters.contains(widget.initialFilter)
        ? widget.initialFilter
        : 'All';
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshProjects() async {
    await CompanyProfileService.loadAllCompanyPanelData();
  }

  Future<void> _navigateToPostProject() async {
    if (widget.onTabChange != null) {
      widget.onTabChange!(2);
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostProjectScreen()),
    );
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project list updated.'),
          backgroundColor: AppColors.statusOpen,
        ),
      );
    }
  }

  void _navigateToApplicants(String projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicantsScreen(projectId: projectId),
      ),
    );
  }

  void _openProjectDetails(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProjectDetailScreen(project: project),
      ),
    );
  }

  Future<void> _confirmDeleteDraft(ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft Listing?'),
        content: Text(
          'Are you sure you want to permanently remove draft "${project.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusClosed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Draft'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _projectService.deleteProject(project.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft project removed.'),
          backgroundColor: AppColors.deepNavy,
        ),
      );
    }
  }

  Future<void> _confirmStatusChange(
    ProjectModel project,
    String newStatus,
  ) async {
    final isClose = newStatus == 'Closed';
    final actionName = isClose ? 'Close Project' : 'Cancel Project';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isClose ? Icons.lock_outline : Icons.cancel_outlined,
                color: isClose ? AppColors.deepNavy : AppColors.statusClosed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$actionName?',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isClose
                ? 'Mark "${project.title}" as Closed? Students will no longer be able to apply.'
                : 'Cancel "${project.title}"? This listing will be marked as cancelled.',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isClose
                    ? AppColors.deepNavy
                    : AppColors.statusClosed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(actionName),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _projectService.updateProjectStatus(project.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project status updated to "$newStatus".'),
          backgroundColor: isClose
              ? AppColors.deepNavy
              : AppColors.statusClosed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = _profileService.currentProfile;
    final canPopModal = widget.onTabChange == null && Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: canPopModal ? 56 : null,
        leading: canPopModal
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.deepNavy,
                ),
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        titleSpacing: canPopModal ? 4 : 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Company Projects',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Challenge Portfolio & Pipeline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onOpenDrawer != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: CompanyDrawerMenuButton(
                  onPressed: widget.onOpenDrawer,
                  isDrawerOpen: widget.isDrawerOpen,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.lightGray.withValues(alpha: 0.75),
          ),
        ),
      ),
      body: ValueListenableBuilder<List<ProjectModel>>(
        valueListenable: _projectService.projectsNotifier,
        builder: (context, allProjects, _) {
          final companyProjects = allProjects
              .where(
                (p) =>
                    company.id.isEmpty ||
                    p.companyId.isEmpty ||
                    p.companyId == company.id,
              )
              .toList();

          final paymentFiltered = companyProjects
              .where((project) => project.paymentSent == _showPaidProjects)
              .toList();

          final statusFiltered = _selectedStatus == 'All'
              ? paymentFiltered
              : paymentFiltered
                    .where(
                      (p) =>
                          p.status.toLowerCase() ==
                          _selectedStatus.toLowerCase(),
                    )
                    .toList();

          final displayedProjects = _searchQuery.isEmpty
              ? statusFiltered
              : statusFiltered.where((p) {
                  return p.title.toLowerCase().contains(_searchQuery) ||
                      p.category.toLowerCase().contains(_searchQuery) ||
                      p.skillsRequired.any(
                        (s) => s.toLowerCase().contains(_searchQuery),
                      );
                }).toList();

          final activeCount = companyProjects
              .where(
                (p) =>
                    p.status.toLowerCase() == 'open' ||
                    p.status.toLowerCase() == 'in progress',
              )
              .length;
          final completedCount = companyProjects
              .where((p) => p.status.toLowerCase() == 'completed')
              .length;
          final totalApplicants = companyProjects.fold<int>(
            0,
            (sum, p) => sum + p.applicantsCount,
          );
          final hasActiveFilters =
              _selectedStatus != 'All' ||
              _searchQuery.isNotEmpty ||
              _showPaidProjects;

          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.lightGray.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AppColors.darkText,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by title, category, or skill...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.textMuted,
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.grayText,
                                      ),
                                      tooltip: 'Clear search',
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPaymentFilter(
                                  key: const Key(
                                    'company-payment-filter-pending',
                                  ),
                                  label: 'Payment Pending',
                                  isSelected: !_showPaidProjects,
                                  onPressed: () {
                                    setState(() => _showPaidProjects = false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPaymentFilter(
                                  key: const Key('company-payment-filter-paid'),
                                  label: 'Paid',
                                  isSelected: _showPaidProjects,
                                  onPressed: () {
                                    setState(() => _showPaidProjects = true);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            height: 36,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: _statusFilters.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final status = _statusFilters[index];
                                final isSelected = _selectedStatus == status;
                                final count = status == 'All'
                                    ? paymentFiltered.length
                                    : paymentFiltered
                                          .where(
                                            (p) =>
                                                p.status.toLowerCase() ==
                                                status.toLowerCase(),
                                          )
                                          .length;

                                return _buildFilterPill(
                                  status: status,
                                  count: count,
                                  isSelected: isSelected,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshProjects,
                  color: AppColors.primaryBlue,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: displayedProjects.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                36,
                              ),
                              children: [
                                _buildPortfolioBanner(
                                  totalCount: companyProjects.length,
                                  activeCount: activeCount,
                                  completedCount: completedCount,
                                  totalApplicants: totalApplicants,
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 520,
                                    ),
                                    child: _buildEmptyState(
                                      companyProjects.isEmpty,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                28,
                              ),
                              itemCount: displayedProjects.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildPortfolioBanner(
                                        totalCount: companyProjects.length,
                                        activeCount: activeCount,
                                        completedCount: completedCount,
                                        totalApplicants: totalApplicants,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${displayedProjects.length} ${displayedProjects.length == 1 ? 'Challenge' : 'Challenges'}${_selectedStatus == 'All' ? '' : ' • $_selectedStatus'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.deepNavy,
                                            ),
                                          ),
                                          if (hasActiveFilters)
                                            TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedStatus = 'All';
                                                  _showPaidProjects = false;
                                                  _searchController.clear();
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              icon: const Icon(
                                                Icons.restart_alt_rounded,
                                                size: 15,
                                                color: AppColors.primaryBlue,
                                              ),
                                              label: Text(
                                                'Reset',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  );
                                }
                                return _buildProjectCard(
                                  displayedProjects[index - 1],
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentFilter({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primaryBlue : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.grayText,
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String status,
    required int count,
    required bool isSelected,
  }) {
    final dotColor = StatusBadge.colorForStatus(status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isSelected) {
            setState(() {
              _selectedStatus = status;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.brandGradient : null,
            color: isSelected ? null : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: AppColors.borderLight),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != 'All') ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : dotColor,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.darkText,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.grayText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioBanner({
    required int totalCount,
    required int activeCount,
    required int completedCount,
    required int totalApplicants,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -26,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 54,
              bottom: -34,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              child: Row(
                children: [
                  _buildBannerMetric(value: '$totalCount', label: 'Total'),
                  _buildBannerDivider(),
                  _buildBannerMetric(value: '$activeCount', label: 'Active'),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$completedCount',
                    label: 'Completed',
                  ),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$totalApplicants',
                    label: 'Applicants',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerMetric({required String value, required String label}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 18.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final canCloseOrCancel =
        project.status == 'Open' || project.status == 'In Progress';
    final isDraft = project.status == 'Draft';
    final statusTone = StatusBadge.colorForStatus(project.status);
    final previewSkills = project.skillsRequired.take(3).toList();
    final remainingSkills =
        project.skillsRequired.length - previewSkills.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.9)),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openProjectDetails(project),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.5,
                  width: double.infinity,
                  color: statusTone,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightAqua.withValues(
                                  alpha: 0.7,
                                ),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _categoryIcon(project.category),
                                    size: 13.5,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      project.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppColors.primaryBlue,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StatusBadge(label: project.status),
                          if (canCloseOrCancel || isDraft) ...[
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 19,
                                color: AppColors.grayText,
                              ),
                              tooltip: 'Options',
                              onSelected: (val) {
                                if (val == 'Close') {
                                  _confirmStatusChange(project, 'Closed');
                                } else if (val == 'Cancel') {
                                  _confirmStatusChange(project, 'Cancelled');
                                } else if (val == 'PublishDraft') {
                                  _projectService.updateProjectStatus(
                                    project.id,
                                    'Open',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Draft project published.'),
                                      backgroundColor: AppColors.statusOpen,
                                    ),
                                  );
                                } else if (val == 'DeleteDraft') {
                                  _confirmDeleteDraft(project);
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (isDraft) ...[
                                  const PopupMenuItem(
                                    value: 'PublishDraft',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.rocket_launch_outlined,
                                          size: 18,
                                          color: AppColors.statusOpen,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Publish Listing'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'DeleteDraft',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppColors.statusClosed,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Delete Draft',
                                          style: TextStyle(
                                            color: AppColors.statusClosed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (canCloseOrCancel) ...[
                                  const PopupMenuItem(
                                    value: 'Close',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lock_outline,
                                          size: 18,
                                          color: AppColors.deepNavy,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Mark as Closed'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Cancel',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.cancel_outlined,
                                          size: 18,
                                          color: AppColors.statusClosed,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Cancel Project',
                                          style: TextStyle(
                                            color: AppColors.statusClosed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        project.description.isNotEmpty
                            ? project.description
                            : 'No description added yet.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.grayText,
                          height: 1.45,
                        ),
                      ),
                      if (previewSkills.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...previewSkills.map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                            ),
                            if (remainingSkills > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightAqua,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$remainingSkills more',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetaChip(
                            icon: _modeIcon(project.projectType),
                            label: project.projectType,
                          ),
                          _buildMetaChip(
                            icon: Icons.people_outline_rounded,
                            label:
                                '${project.openings} ${project.openings == 1 ? 'Seat' : 'Seats'}',
                          ),
                          _buildMetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Due ${project.deadline}',
                          ),
                          _buildPaymentStatusChip(project),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.surfaceAlt),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () => _navigateToApplicants(project.id),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: project.applicantsCount > 0
                                      ? AppColors.lightAqua.withValues(
                                          alpha: 0.75,
                                        )
                                      : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: project.applicantsCount > 0
                                        ? AppColors.primaryBlue.withValues(
                                            alpha: 0.22,
                                          )
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_alt_outlined,
                                      size: 15,
                                      color: project.applicantsCount > 0
                                          ? AppColors.primaryBlue
                                          : AppColors.grayText,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '${project.applicantsCount} ${project.applicantsCount == 1 ? 'Applicant' : 'Applicants'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: project.applicantsCount > 0
                                              ? AppColors.primaryBlue
                                              : AppColors.grayText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: project.applicantsCount > 0
                                          ? AppColors.primaryBlue
                                          : AppColors.grayText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(11),
                              onTap: () => _openProjectDetails(project),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.deepNavy,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Manage',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: AppColors.primaryBlue),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip(ProjectModel project) {
    final isAssigned = project.assignedStudent?.trim().isNotEmpty == true;
    final label = !isAssigned
        ? 'Unassigned'
        : project.paymentSent
        ? 'Paid'
        : 'Payment Pending';
    final color = !isAssigned
        ? AppColors.grayText
        : project.paymentSent
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);
    final background = !isAssigned
        ? AppColors.surfaceAlt
        : project.paymentSent
        ? AppColors.successBg
        : AppColors.warningBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !isAssigned
                ? Icons.person_outline_rounded
                : project.paymentSent
                ? Icons.check_circle_outline
                : Icons.pending_outlined,
            size: 13.5,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('mobile')) return Icons.phone_iphone_rounded;
    if (c.contains('web')) return Icons.language_rounded;
    if (c.contains('ai') || c.contains('machine') || c.contains('data')) {
      return Icons.psychology_outlined;
    }
    if (c.contains('ui') || c.contains('ux') || c.contains('design')) {
      return Icons.palette_outlined;
    }
    if (c.contains('cyber') || c.contains('security')) {
      return Icons.shield_outlined;
    }
    if (c.contains('cloud') || c.contains('devops')) {
      return Icons.cloud_queue_rounded;
    }
    if (c.contains('iot') || c.contains('embedded')) {
      return Icons.memory_rounded;
    }
    if (c.contains('blockchain')) return Icons.hub_rounded;
    return Icons.category_outlined;
  }

  IconData _modeIcon(String projectType) {
    final m = projectType.toLowerCase();
    if (m.contains('remote')) return Icons.laptop_mac_rounded;
    if (m.contains('on-site') || m.contains('onsite')) {
      return Icons.apartment_rounded;
    }
    if (m.contains('hybrid')) return Icons.sync_alt_rounded;
    return Icons.work_outline_rounded;
  }

  Widget _buildEmptyState(bool noProjectsAtAll) {
    if (noProjectsAtAll) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightAqua.withValues(alpha: 0.65),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.14),
                ),
              ),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    size: 27,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightAqua,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'PORTFOLIO READY',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Projects Posted Yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'Your organization has not created any student challenge listings yet. Post a project to start receiving applications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.grayText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _navigateToPostProject,
                child: Ink(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Post First Project',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppEmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: 'No Matching Projects',
      subtitle:
          'No projects match your current filter criteria or search query.',
      actionLabel: 'Reset Filters',
      actionIcon: Icons.restart_alt_rounded,
      onAction: () {
        setState(() {
          _selectedStatus = 'All';
          _searchController.clear();
        });
      },
    );
  }
}
