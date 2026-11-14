import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/presentation/widgets/company_executive_app_bar.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicant_detail_screen.dart';

class ApplicantsScreen extends StatefulWidget {
  final String? projectId;
  final Function(int)? onTabChange;
  final VoidCallback? onOpenDrawer;
  final bool isDrawerOpen;

  const ApplicantsScreen({
    super.key,
    this.projectId,
    this.onTabChange,
    this.onOpenDrawer,
    this.isDrawerOpen = false,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final _applicantService = CompanyApplicantService();
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  late String? _currentProjectId;
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Under Review',
    'Shortlisted',
    'Accepted',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _currentProjectId = widget.projectId;
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

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await CompanyProfileService.loadAllCompanyPanelData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _openStudentProfileModal(ApplicantModel applicant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantDetailScreen(
          applicantId: applicant.id,
          projectId: applicant.projectId,
          initialApplicant: applicant,
        ),
      ),
    );
  }

  ProjectModel? _findProject(List<ProjectModel> projects, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _updateStatus(ApplicantModel applicant, String newStatus) async {
    if (newStatus == 'Accepted') {
      final project = _findProject(_projectService.allProjects, applicant.projectId);
      final openings = project?.openings ?? 1;
      final acceptedCount =
          _applicantService.getAcceptedCount(applicant.projectId);
      if (acceptedCount >= openings && applicant.status != 'Accepted') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All $openings opening(s) for "${applicant.projectTitle}" are already filled.',
            ),
            backgroundColor: AppColors.statusPending,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.statusOpen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accept & Assign Student?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Accept "${applicant.name}" for "${applicant.projectTitle}"? They will be assigned immediately and notified to begin project milestones.',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusOpen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Accept Student'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else if (newStatus == 'Rejected') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Decline Application?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          content: Text(
            'Decline the application from "${applicant.name}" for "${applicant.projectTitle}"?',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
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
              child: const Text('Decline'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await _applicantService.updateApplicantStatus(
      applicantId: applicant.id,
      newStatus: newStatus,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${applicant.name} marked as $newStatus.'),
          backgroundColor: StatusBadge.colorForStatus(newStatus),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = _profileService.currentProfile;
    final companyTitle = company.companyName.isNotEmpty
        ? company.companyName
        : 'Talent Recruitment Pipeline';
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
                Icons.people_alt_outlined,
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
                    'Student Applicants',
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
                    companyTitle,
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
          Padding(
            padding: EdgeInsets.only(
              right: widget.onOpenDrawer != null ? 8 : 14,
            ),
            child: Center(
              child: Tooltip(
                message: 'Sync Applicants',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isRefreshing ? null : _refreshData,
                    child: Ink(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Center(
                        child: _isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                size: 19,
                                color: AppColors.deepNavy,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
        builder: (context, projects, _) {
          return ValueListenableBuilder<List<ApplicantModel>>(
            valueListenable: _applicantService.applicantsNotifier,
            builder: (context, allApplicants, _) {
              final seenProjIds = <String>{};
              final uniqueProjects = projects
                  .where((p) => p.id.isNotEmpty && seenProjIds.add(p.id))
                  .toList();

              final hasValidProjectSelection =
                  _currentProjectId != null &&
                  uniqueProjects.any((p) => p.id == _currentProjectId);
              final effectiveProjectId =
                  hasValidProjectSelection ? _currentProjectId : null;

              final projectScoped = effectiveProjectId != null
                  ? allApplicants
                        .where((a) => a.projectId == effectiveProjectId)
                        .toList()
                  : allApplicants;

              final statusScoped = _selectedStatus == 'All'
                  ? projectScoped
                  : projectScoped
                        .where(
                          (a) =>
                              a.status.toLowerCase() ==
                              _selectedStatus.toLowerCase(),
                        )
                        .toList();

              final filtered = _searchQuery.isEmpty
                  ? statusScoped
                  : statusScoped.where((a) {
                      return a.name.toLowerCase().contains(_searchQuery) ||
                          a.university.toLowerCase().contains(_searchQuery) ||
                          a.degree.toLowerCase().contains(_searchQuery) ||
                          a.projectTitle.toLowerCase().contains(_searchQuery) ||
                          a.skills.any(
                            (s) => s.toLowerCase().contains(_searchQuery),
                          );
                    }).toList();

              final selectedProject = _findProject(
                projects,
                effectiveProjectId,
              );
              final reviewingCount = projectScoped
                  .where(
                    (a) =>
                        a.status.toLowerCase() == 'pending' ||
                        a.status.toLowerCase() == 'under review',
                  )
                  .length;
              final shortlistedCount = projectScoped
                  .where((a) => a.status.toLowerCase() == 'shortlisted')
                  .length;
              final acceptedCount = projectScoped
                  .where((a) => a.status.toLowerCase() == 'accepted')
                  .length;
              final hasActiveFilters =
                  _selectedStatus != 'All' ||
                  _searchQuery.isNotEmpty ||
                  effectiveProjectId != null;

              return RefreshIndicator(
                onRefresh: _refreshData,
                color: AppColors.primaryBlue,
                child: Column(
                  children: [
                    _buildTopFilters(
                      projects: uniqueProjects,
                      projectScoped: projectScoped,
                      effectiveProjectId: effectiveProjectId,
                      totalCount: projectScoped.length,
                      openingsProject: selectedProject,
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: filtered.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    36,
                                  ),
                                  children: [
                                    _buildRecruitmentBanner(
                                      totalCount: projectScoped.length,
                                      reviewingCount: reviewingCount,
                                      shortlistedCount: shortlistedCount,
                                      acceptedCount: acceptedCount,
                                    ),
                                    const SizedBox(height: 18),
                                    Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 520,
                                        ),
                                        child: _buildEmptyState(
                                          noApplicantsAtAll:
                                              allApplicants.isEmpty,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    28,
                                  ),
                                  itemCount: filtered.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _buildRecruitmentBanner(
                                            totalCount: projectScoped.length,
                                            reviewingCount: reviewingCount,
                                            shortlistedCount: shortlistedCount,
                                            acceptedCount: acceptedCount,
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Showing ${filtered.length} of ${projectScoped.length} ${projectScoped.length == 1 ? 'applicant' : 'applicants'}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.deepNavy,
                                                ),
                                              ),
                                              if (hasActiveFilters)
                                                TextButton.icon(
                                                  onPressed: _resetFilters,
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
                                                    color:
                                                        AppColors.primaryBlue,
                                                  ),
                                                  label: Text(
                                                    'Reset',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      );
                                    }
                                    return _buildApplicantCard(
                                      filtered[index - 1],
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = 'All';
      _currentProjectId = null;
      _searchController.clear();
    });
  }

  Widget _buildTopFilters({
    required List<ProjectModel> projects,
    required List<ApplicantModel> projectScoped,
    required String? effectiveProjectId,
    required int totalCount,
    required ProjectModel? openingsProject,
  }) {
    final acceptedForProject = openingsProject != null
        ? _applicantService.getAcceptedCount(openingsProject.id)
        : 0;
    final seatsFilled =
        openingsProject != null &&
        acceptedForProject >= openingsProject.openings;

    return Container(
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
              if (projects.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.work_outline_rounded,
                          size: 17,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: effectiveProjectId,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.deepNavy,
                              ),
                              hint: Text(
                                'All Published Projects',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    'All Projects ($totalCount applicants)',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ),
                                ...projects.map(
                                  (proj) => DropdownMenuItem<String?>(
                                    value: proj.id,
                                    child: Text(
                                      proj.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _currentProjectId = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (openingsProject != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: seatsFilled
                          ? AppColors.warningBg
                          : AppColors.lightAqua.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (seatsFilled
                                    ? AppColors.statusPending
                                    : AppColors.primaryBlue)
                                .withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          seatsFilled
                              ? Icons.group_rounded
                              : Icons.assignment_ind_outlined,
                          size: 17,
                          color: seatsFilled
                              ? AppColors.statusPending
                              : AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Assigned Seats: $acceptedForProject / ${openingsProject.openings} Openings',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            seatsFilled ? 'Filled' : 'Open',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: seatsFilled
                                  ? AppColors.statusPending
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                        'Search by student name, university, degree, or skill...',
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
                            onPressed: () => _searchController.clear(),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _statusFilters[index];
                      final isSelected = _selectedStatus == filter;
                      final count = filter == 'All'
                          ? projectScoped.length
                          : projectScoped
                                .where(
                                  (a) =>
                                      a.status.toLowerCase() ==
                                      filter.toLowerCase(),
                                )
                                .length;

                      return _buildFilterPill(
                        label: filter,
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
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
  }) {
    final dotColor = StatusBadge.colorForStatus(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isSelected) {
            setState(() => _selectedStatus = label);
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
              if (label != 'All') ...[
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
                label,
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

  Widget _buildRecruitmentBanner({
    required int totalCount,
    required int reviewingCount,
    required int shortlistedCount,
    required int acceptedCount,
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
                  _buildBannerMetric(
                    value: '$reviewingCount',
                    label: 'In Review',
                  ),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$shortlistedCount',
                    label: 'Shortlisted',
                  ),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$acceptedCount',
                    label: 'Accepted',
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

  Widget _buildEmptyState({required bool noApplicantsAtAll}) {
    if (noApplicantsAtAll) {
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
                    Icons.people_outline_rounded,
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
                'TALENT PIPELINE READY',
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
              'No Applications Submitted Yet',
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
                'When students apply to your published project challenges, their profiles and proposals will appear here.',
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
                onTap: _isRefreshing ? null : _refreshData,
                child: Ink(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Refresh Pipeline',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
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
      title: 'No Matching Applicants',
      subtitle: 'Try clearing your search term or switching status filters.',
      actionLabel: 'Reset Filters',
      actionIcon: Icons.restart_alt_rounded,
      onAction: _resetFilters,
    );
  }

  Widget _buildApplicantCard(ApplicantModel applicant) {
    final bool canDecide =
        applicant.status != 'Accepted' && applicant.status != 'Rejected';
    final statusTone = StatusBadge.colorForStatus(applicant.status);
    final previewSkills = applicant.skills.take(4).toList();
    final remainingSkills = applicant.skills.length - previewSkills.length;
    final academicMeta = [
      if (applicant.degree.isNotEmpty) applicant.degree,
      if (applicant.university.isNotEmpty) applicant.university,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.9)),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openStudentProfileModal(applicant),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.5,
                  width: double.infinity,
                  color: statusTone,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                applicant.avatarInitial,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
                                        applicant.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.deepNavy,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (applicant.isEducationVerified)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 5),
                                        child: Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                if (academicMeta.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.school_outlined,
                                        size: 13.5,
                                        color: AppColors.grayText,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          academicMeta,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: AppColors.grayText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(label: applicant.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.work_outline_rounded,
                              size: 15,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                applicant.projectTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ),
                            if (applicant.cgpa > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightAqua,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'CGPA ${applicant.cgpa.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.35,
                              ),
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          applicant.proposalSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.darkText,
                          ),
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
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.surfaceAlt),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13.5,
                                  color: AppColors.grayText,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Applied ${applicant.appliedDate}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => _openStudentProfileModal(applicant),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Review Profile',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 17,
                                    color: AppColors.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (canDecide) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (applicant.status != 'Shortlisted') ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.deepNavy,
                                    side: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                    backgroundColor: AppColors.background,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _updateStatus(applicant, 'Shortlisted'),
                                  icon: const Icon(
                                    Icons.bookmark_add_outlined,
                                    size: 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                  label: Text(
                                    'Shortlist',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusOpen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    _updateStatus(applicant, 'Accepted'),
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'Accept',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
