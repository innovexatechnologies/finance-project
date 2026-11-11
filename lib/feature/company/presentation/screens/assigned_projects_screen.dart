import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicant_detail_screen.dart';
import 'company_project_detail_screen.dart';
import 'submission_review_screen.dart';

class AssignedProjectsScreen extends StatefulWidget {
  final String? filterProjectId;
  final Function(int)? onTabChange;

  const AssignedProjectsScreen({
    super.key,
    this.filterProjectId,
    this.onTabChange,
  });

  @override
  State<AssignedProjectsScreen> createState() => _AssignedProjectsScreenState();
}

class _AssignedProjectsScreenState extends State<AssignedProjectsScreen> {
  final _assignmentService = CompanyAssignmentService();
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  late String? _selectedProjectId;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final List<String> _statusFilters = [
    'All',
    'In Progress',
    'Pending Review',
    'Revision Requested',
    'Approved',
    'Pending Submission',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.filterProjectId;
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
    setState(() => _isLoading = true);
    await CompanyProfileService.loadAllCompanyPanelData();
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateToStudentProfile(AssignmentModel assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantDetailScreen(
          applicantId: assignment.applicantId,
          projectId: assignment.projectId,
        ),
      ),
    );
  }

  void _navigateToProjectDetails(AssignmentModel assignment) {
    ProjectModel? targetProject;
    for (final p in _projectService.allProjects) {
      if (p.id == assignment.projectId) {
        targetProject = p;
        break;
      }
    }

    if (targetProject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyProjectDetailScreen(
            projectId: targetProject!.id,
            initialProject: targetProject,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Project details for "${assignment.projectTitle}" are currently unavailable.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToSubmissionReview(AssignmentModel assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionReviewScreen(
          assignmentId: assignment.id,
          initialAssignment: assignment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = _profileService.currentProfile;
    final companyLabel = company.companyName.isNotEmpty
        ? '${company.companyName} • Deliverables'
        : 'Deliverables & Milestones';
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
                Icons.assignment_turned_in_outlined,
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
                    'Assigned Projects',
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
                    companyLabel,
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
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Tooltip(
                message: 'Sync Assignments',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isLoading ? null : _refreshData,
                    child: Ink(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Center(
                        child: _isLoading
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.lightGray.withValues(alpha: 0.75),
          ),
        ),
      ),
      body: ValueListenableBuilder<List<AssignmentModel>>(
        valueListenable: _assignmentService.assignmentsNotifier,
        builder: (context, allAssignments, _) {
          final companyAssignments = allAssignments.where((a) {
            return company.id.isEmpty ||
                a.companyId.isEmpty ||
                a.companyId == company.id;
          }).toList();

          final projectFiltered = _selectedProjectId != null
              ? companyAssignments
                    .where((a) => a.projectId == _selectedProjectId)
                    .toList()
              : companyAssignments;

          final statusFiltered = _filterByStatus(
            projectFiltered,
            _selectedFilter,
          );

          final filteredList = _searchQuery.isEmpty
              ? statusFiltered
              : statusFiltered.where((a) {
                  return a.projectTitle.toLowerCase().contains(_searchQuery) ||
                      a.studentName.toLowerCase().contains(_searchQuery) ||
                      a.studentUniversity.toLowerCase().contains(_searchQuery);
                }).toList();

          final toReviewCount = projectFiltered
              .where((a) => a.submissionStatus == 'Pending Review')
              .length;
          final revisionCount = projectFiltered
              .where((a) => a.submissionStatus == 'Revision Requested')
              .length;
          final approvedCount = projectFiltered
              .where((a) => a.submissionStatus == 'Approved')
              .length;
          final hasActiveFilters =
              _selectedFilter != 'All' ||
              _searchQuery.isNotEmpty ||
              _selectedProjectId != null;

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryBlue,
            child: Column(
              children: [
                _buildFiltersBar(projectFiltered: projectFiltered),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: filteredList.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                36,
                              ),
                              children: [
                                _buildDeliveryBanner(
                                  assignedCount: projectFiltered.length,
                                  toReviewCount: toReviewCount,
                                  revisionCount: revisionCount,
                                  approvedCount: approvedCount,
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 520,
                                    ),
                                    child: _buildEmptyState(
                                      noAssignmentsAtAll:
                                          companyAssignments.isEmpty,
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
                              itemCount: filteredList.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildDeliveryBanner(
                                        assignedCount: projectFiltered.length,
                                        toReviewCount: toReviewCount,
                                        revisionCount: revisionCount,
                                        approvedCount: approvedCount,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Showing ${filteredList.length} of ${projectFiltered.length} ${projectFiltered.length == 1 ? 'assignment' : 'assignments'}',
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
                                return _buildAssignmentCard(
                                  filteredList[index - 1],
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
      ),
    );
  }

  List<AssignmentModel> _filterByStatus(
    List<AssignmentModel> items,
    String filter,
  ) {
    switch (filter) {
      case 'In Progress':
        return items.where((a) => a.projectStatus == 'In Progress').toList();
      case 'Pending Review':
        return items
            .where((a) => a.submissionStatus == 'Pending Review')
            .toList();
      case 'Revision Requested':
        return items
            .where((a) => a.submissionStatus == 'Revision Requested')
            .toList();
      case 'Approved':
        return items.where((a) => a.submissionStatus == 'Approved').toList();
      case 'Pending Submission':
        return items
            .where((a) => a.submissionStatus == 'Pending Submission')
            .toList();
      default:
        return items;
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = 'All';
      _selectedProjectId = null;
      _searchController.clear();
    });
  }

  Widget _buildFiltersBar({required List<AssignmentModel> projectFiltered}) {
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
              if (_selectedProjectId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightAqua.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_rounded,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtered to selected project',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () =>
                              setState(() => _selectedProjectId = null),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: AppColors.deepNavy,
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
                        'Search by project title, student name, or university...',
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
                      final isSelected = _selectedFilter == filter;
                      final count = _filterByStatus(
                        projectFiltered,
                        filter,
                      ).length;

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
            setState(() => _selectedFilter = label);
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

  Widget _buildDeliveryBanner({
    required int assignedCount,
    required int toReviewCount,
    required int revisionCount,
    required int approvedCount,
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
                  _buildBannerMetric(
                    value: '$assignedCount',
                    label: 'Assigned',
                  ),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$toReviewCount',
                    label: 'To Review',
                  ),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$revisionCount',
                    label: 'Revisions',
                  ),
                  _buildBannerDivider(),
                  _buildBannerMetric(
                    value: '$approvedCount',
                    label: 'Approved',
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

  Widget _buildEmptyState({required bool noAssignmentsAtAll}) {
    if (noAssignmentsAtAll) {
      final hasApplicantsTab = widget.onTabChange != null;
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
                    Icons.assignment_turned_in_outlined,
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
                'DELIVERY TRACKER READY',
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
              'No Assigned Projects Yet',
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
                'Accept a student applicant to start tracking progress milestones and deliverables here.',
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
                onTap: hasApplicantsTab
                    ? () => widget.onTabChange!(3)
                    : (_isLoading ? null : _refreshData),
                child: Ink(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    gradient: hasApplicantsTab ? AppColors.brandGradient : null,
                    color: hasApplicantsTab ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: hasApplicantsTab
                        ? null
                        : Border.all(color: AppColors.borderLight),
                    boxShadow: hasApplicantsTab
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasApplicantsTab
                            ? Icons.people_alt_outlined
                            : Icons.refresh_rounded,
                        size: 18,
                        color: hasApplicantsTab
                            ? Colors.white
                            : AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasApplicantsTab
                            ? 'Review Applicants'
                            : 'Refresh Assignments',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: hasApplicantsTab
                              ? Colors.white
                              : AppColors.deepNavy,
                        ),
                      ),
                      if (hasApplicantsTab) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
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
      title: 'No Matching Assignments',
      subtitle:
          'Adjust your status filter or search query to inspect other assigned engagements.',
      actionLabel: 'Reset Filters',
      actionIcon: Icons.restart_alt_rounded,
      onAction: _resetFilters,
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final pct = (assignment.progress * 100).round();
    final canReviewSubmission =
        assignment.hasSubmission && assignment.latestSubmission != null;
    final statusTone = StatusBadge.colorForStatus(assignment.submissionStatus);
    final isApproved = assignment.submissionStatus == 'Approved';
    final isPendingReview = assignment.submissionStatus == 'Pending Review';

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
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _navigateToProjectDetails(assignment),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightAqua.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.work_outline_rounded,
                                          size: 12.5,
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            assignment.projectCategory,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12.5,
                                        color: AppColors.grayText,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Due ${assignment.deadline}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
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
                            StatusBadge(label: assignment.submissionStatus),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          assignment.projectTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => _navigateToStudentProfile(assignment),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  assignment.studentAvatarInitial,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ASSIGNED STUDENT',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    assignment.studentName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  if (assignment.studentUniversity.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.school_outlined,
                                            size: 12.5,
                                            color: AppColors.grayText,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              assignment.studentUniversity,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.grayText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderLight.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.checklist_rtl_rounded,
                              size: 15,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Milestone Completion',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? AppColors.statusOpen.withValues(
                                        alpha: 0.12,
                                      )
                                    : AppColors.lightAqua,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$pct%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isApproved
                                      ? AppColors.statusOpen
                                      : AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: assignment.progress.clamp(0.0, 1.0),
                            minHeight: 7.5,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isApproved
                                  ? AppColors.statusOpen
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.deepNavy,
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _navigateToProjectDetails(assignment),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.deepNavy,
                        ),
                        label: Text(
                          'Project',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: canReviewSubmission
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      _navigateToSubmissionReview(assignment),
                                  child: Ink(
                                    height: 43,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isPendingReview
                                          ? AppColors.brandGradient
                                          : null,
                                      color: isPendingReview
                                          ? null
                                          : (isApproved
                                                ? AppColors.statusOpen
                                                : AppColors.deepNavy),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isPendingReview
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primaryBlue
                                                    .withValues(alpha: 0.24),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.rate_review_outlined,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            isPendingReview
                                                ? 'Review Deliverable'
                                                : 'View Submission',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 43,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 15,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Awaiting Submission',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}
