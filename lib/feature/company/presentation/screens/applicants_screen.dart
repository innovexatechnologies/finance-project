import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicant_detail_screen.dart';

class ApplicantsScreen extends StatefulWidget {
  final String? projectId;

  const ApplicantsScreen({
    super.key,
    this.projectId,
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
        : 'Talent Recruitment';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Applicants',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              companyTitle,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.lightAqua,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Applicants',
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ProjectModel>>(
        valueListenable: _projectService.projectsNotifier,
        builder: (context, projects, _) {
          return ValueListenableBuilder<List<ApplicantModel>>(
            valueListenable: _applicantService.applicantsNotifier,
            builder: (context, allApplicants, _) {
              final hasValidProjectSelection = _currentProjectId != null &&
                  projects.any((p) => p.id == _currentProjectId);
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
                      .where((a) =>
                          a.status.toLowerCase() ==
                          _selectedStatus.toLowerCase())
                      .toList();

              final filtered = _searchQuery.isEmpty
                  ? statusScoped
                  : statusScoped.where((a) {
                      return a.name.toLowerCase().contains(_searchQuery) ||
                          a.university.toLowerCase().contains(_searchQuery) ||
                          a.degree.toLowerCase().contains(_searchQuery) ||
                          a.projectTitle.toLowerCase().contains(_searchQuery) ||
                          a.skills.any(
                              (s) => s.toLowerCase().contains(_searchQuery));
                    }).toList();

              final selectedProject =
                  _findProject(projects, effectiveProjectId);
              final openingsBannerProject = selectedProject;

              return RefreshIndicator(
                onRefresh: _refreshData,
                color: AppColors.primaryBlue,
                child: Column(
                  children: [
                    _buildTopFilters(
                      projects: projects,
                      effectiveProjectId: effectiveProjectId,
                      totalCount: projectScoped.length,
                      filteredCount: filtered.length,
                      openingsProject: openingsBannerProject,
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 24),
                                AppEmptyState(
                                  icon: Icons.people_outline_rounded,
                                  title: allApplicants.isEmpty
                                      ? 'No Applications Received Yet'
                                      : 'No Matching Applicants',
                                  subtitle: allApplicants.isEmpty
                                      ? 'When students apply to your published project challenges, their profiles and proposals will appear here.'
                                      : 'Try clearing your search term or switching status filters.',
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildApplicantCard(filtered[index]),
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

  Widget _buildTopFilters({
    required List<ProjectModel> projects,
    required String? effectiveProjectId,
    required int totalCount,
    required int filteredCount,
    required ProjectModel? openingsProject,
  }) {
    final acceptedForProject = openingsProject != null
        ? _applicantService.getAcceptedCount(openingsProject.id)
        : 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (projects.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: effectiveProjectId,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.deepNavy),
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
            const SizedBox(height: 10),
          ],
          if (openingsProject != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: acceptedForProject >= openingsProject.openings
                    ? AppColors.warningBg
                    : AppColors.lightAqua.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    acceptedForProject >= openingsProject.openings
                        ? Icons.group_rounded
                        : Icons.assignment_ind_outlined,
                    size: 16,
                    color: acceptedForProject >= openingsProject.openings
                        ? AppColors.statusPending
                        : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
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
                ],
              ),
            ),
          ],
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search by student name, university, degree, or skill...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedStatus = filter),
                  selectedColor: AppColors.deepNavy,
                  backgroundColor: AppColors.surfaceAlt,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.deepNavy
                        : AppColors.lightGray,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing $filteredCount of $totalCount applicants',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(ApplicantModel applicant) {
    final bool canDecide =
        applicant.status != 'Accepted' && applicant.status != 'Rejected';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openStudentProfileModal(applicant),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.deepNavy,
                    child: Text(
                      applicant.avatarInitial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
                            Expanded(
                              child: Text(
                                applicant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ),
                            if (applicant.isEducationVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (applicant.degree.isNotEmpty) applicant.degree,
                            if (applicant.university.isNotEmpty)
                              applicant.university,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: applicant.status),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline_rounded,
                        size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        applicant.projectTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                    if (applicant.cgpa > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        'CGPA ${applicant.cgpa.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                applicant.proposalSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.darkText,
                ),
              ),
              if (applicant.skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: applicant.skills.take(5).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightAqua.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.lightGray),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Applied ${applicant.appliedDate}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.grayText,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openStudentProfileModal(applicant),
                    child: const Text('Review Profile'),
                  ),
                  if (canDecide) ...[
                    if (applicant.status != 'Shortlisted') ...[
                      const SizedBox(width: 4),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () =>
                            _updateStatus(applicant, 'Shortlisted'),
                        child: const Text('Shortlist'),
                      ),
                    ],
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusOpen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _updateStatus(applicant, 'Accepted'),
                      child: const Text('Accept'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
