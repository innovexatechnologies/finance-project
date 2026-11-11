import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

import 'applicants_screen.dart';
import 'company_project_detail_screen.dart';
import 'post_project_screen.dart';

class CompanyProjectsListScreen extends StatefulWidget {
  final String initialFilter;
  final Function(int)? onTabChange;

  const CompanyProjectsListScreen({
    super.key,
    this.initialFilter = 'All',
    this.onTabChange,
  });

  @override
  State<CompanyProjectsListScreen> createState() =>
      _CompanyProjectsListScreenState();
}

class _CompanyProjectsListScreenState extends State<CompanyProjectsListScreen> {
  final _projectService = CompanyProjectService();
  final _profileService = CompanyProfileService();

  late String _selectedStatus;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Company Projects'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryBlue,
            ),
            tooltip: 'Post New Project',
            onPressed: _navigateToPostProject,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Post Challenge',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        onPressed: _navigateToPostProject,
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

          final statusFiltered = _selectedStatus == 'All'
              ? companyProjects
              : companyProjects
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

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by title, category, or skill...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        fillColor: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusFilters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = _statusFilters[index];
                          final isSelected = _selectedStatus == status;
                          final count = status == 'All'
                              ? companyProjects.length
                              : companyProjects
                                    .where(
                                      (p) =>
                                          p.status.toLowerCase() ==
                                          status.toLowerCase(),
                                    )
                                    .length;

                          return ChoiceChip(
                            label: Text('$status ($count)'),
                            selected: isSelected,
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: AppColors.surfaceAlt,
                            showCheckmark: false,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkText,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.lightGray,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshProjects,
                  color: AppColors.primaryBlue,
                  child: displayedProjects.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 40),
                            _buildEmptyState(companyProjects.isEmpty),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                          itemCount: displayedProjects.length,
                          itemBuilder: (context, index) {
                            return _buildProjectCard(displayedProjects[index]);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final canCloseOrCancel =
        project.status == 'Open' || project.status == 'In Progress';
    final isDraft = project.status == 'Draft';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openProjectDetails(project),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightAqua,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project.category,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: project.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  project.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
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
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: AppColors.grayText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: ${project.deadline}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          size: 14,
                          color: AppColors.grayText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.projectType} • ${project.openings} seat(s)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _navigateToApplicants(project.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: project.applicantsCount > 0
                              ? AppColors.lightAqua
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 14,
                              color: project.applicantsCount > 0
                                  ? AppColors.primaryBlue
                                  : AppColors.grayText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${project.applicantsCount} Applicant(s)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: project.applicantsCount > 0
                                    ? AppColors.primaryBlue
                                    : AppColors.grayText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (canCloseOrCancel || isDraft)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              size: 20,
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
                                  child: Text('Publish Listing'),
                                ),
                                const PopupMenuItem(
                                  value: 'DeleteDraft',
                                  child: Text(
                                    'Delete Draft',
                                    style: TextStyle(
                                      color: AppColors.statusClosed,
                                    ),
                                  ),
                                ),
                              ],
                              if (canCloseOrCancel) ...[
                                const PopupMenuItem(
                                  value: 'Close',
                                  child: Text('Mark as Closed'),
                                ),
                                const PopupMenuItem(
                                  value: 'Cancel',
                                  child: Text(
                                    'Cancel Project',
                                    style: TextStyle(
                                      color: AppColors.statusClosed,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                          ),
                          onPressed: () => _openProjectDetails(project),
                          child: const Text(
                            'Manage',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noProjectsAtAll) {
    if (noProjectsAtAll) {
      return AppEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'No Projects Posted Yet',
        subtitle: 'Your organization has not created any student challenge listings yet. Post a project to start receiving applications.',
        actionLabel: 'Post First Project',
        actionIcon: Icons.add_rounded,
        onAction: _navigateToPostProject,
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
