import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'applicants_screen.dart';
import 'post_project_screen.dart';

class CompanyProjectsListScreen extends StatefulWidget {
  final String initialFilter;

  const CompanyProjectsListScreen({
    super.key,
    this.initialFilter = 'All',
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
    _selectedStatus = widget.initialFilter;
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

  // Navigate to Screen 25 (Post New Project)
  Future<void> _navigateToPostProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostProjectScreen(),
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Projects list updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Navigate to Screen 28 (Review Applicants)
  void _navigateToApplicants() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicantsScreen(),
      ),
    );
  }

  // Navigate to Screen 27 (View / Manage Project Details)
  void _openProjectDetailsModal(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Project Overview (Screen 27)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(project.status),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightIceBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            project.category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sponsoring Company: ${project.companyName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem('Description & Objectives', project.description),
                    if (project.requirements.isNotEmpty)
                      _buildDetailItem('Student Requirements', project.requirements),
                    if (project.deliverables.isNotEmpty)
                      _buildDetailItem('Expected Deliverables', project.deliverables),
                    _buildDetailItem(
                        'Project Mode & Openings',
                        '${project.projectType} • ${project.openings} Student Opening(s)'),
                    _buildDetailItem('Application Deadline', project.deadline),
                    const SizedBox(height: 12),
                    const Text(
                      'Required Skills:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: project.skillsRequired
                          .map((s) => Chip(
                                label: Text(s),
                                backgroundColor: AppColors.lightIceBlue,
                                labelStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    if (project.applicantsCount > 0)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _navigateToApplicants();
                        },
                        icon: const Icon(Icons.people),
                        label: Text(
                            'Review All Applicants (${project.applicantsCount})'),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation before closing or cancelling project
  Future<void> _confirmStatusChange(
      ProjectModel project, String newStatus) async {
    final isClose = newStatus == 'Closed';
    final actionName = isClose ? 'Close Project' : 'Cancel Project';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isClose ? Icons.lock_outline : Icons.cancel_outlined,
                color: isClose ? AppColors.darkNavy : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                '$actionName?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          content: Text(
            isClose
                ? 'Are you sure you want to mark "${project.title}" as Closed?\n\nStudents will no longer be able to apply.'
                : 'Are you sure you want to Cancel "${project.title}"?\n\nThis project will be terminated and marked as cancelled.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isClose ? AppColors.darkNavy : AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          content: Text('Project status updated to "$newStatus"!'),
          backgroundColor: isClose ? AppColors.darkNavy : AppColors.error,
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('My Posted Projects (Screen 26)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary),
            tooltip: 'Post New Project (Screen 25)',
            onPressed: _navigateToPostProject,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Post Project'),
        onPressed: _navigateToPostProject,
      ),
      body: ValueListenableBuilder<List<ProjectModel>>(
        valueListenable: _projectService.projectsNotifier,
        builder: (context, allProjects, _) {
          // 1. Strictly filter projects belonging to the logged-in company
          final companyProjects = allProjects
              .where((p) => p.companyId == company.id)
              .toList();

          // 2. Filter by status
          final statusFiltered = _selectedStatus == 'All'
              ? companyProjects
              : companyProjects
                  .where((p) => p.status.toLowerCase() == _selectedStatus.toLowerCase())
                  .toList();

          // 3. Filter by search query
          final displayedProjects = _searchQuery.isEmpty
              ? statusFiltered
              : statusFiltered.where((p) {
                  return p.title.toLowerCase().contains(_searchQuery) ||
                      p.category.toLowerCase().contains(_searchQuery);
                }).toList();

          return Column(
            children: [
              // Search Bar & Filter Tabs Area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search posted projects by title or category...',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Filters Horizontal Scroll
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusFilters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = _statusFilters[index];
                          final isSelected = _selectedStatus == status;

                          // Count for this filter
                          final count = status == 'All'
                              ? companyProjects.length
                              : companyProjects
                                  .where((p) =>
                                      p.status.toLowerCase() ==
                                      status.toLowerCase())
                                  .length;

                          return ChoiceChip(
                            label: Text('$status ($count)'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.background,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
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

              const Divider(height: 1, color: AppColors.border),

              // Project Cards List / Empty State
              Expanded(
                child: displayedProjects.isEmpty
                    ? _buildEmptyState(companyProjects.isEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: displayedProjects.length,
                        itemBuilder: (context, index) {
                          final project = displayedProjects[index];
                          return _buildProjectCard(project);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Project Card
  Widget _buildProjectCard(ProjectModel project) {
    final canCloseOrCancel =
        project.status == 'Open' || project.status == 'In Progress';
    final isDraft = project.status == 'Draft';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.9),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openProjectDetailsModal(project),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightIceBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(project.status),
                ],
              ),
              const SizedBox(height: 10),

              // Project Title
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 6),

              // Project Description Preview
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),

              // Meta Info Row: Deadline, Mode & Openings
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${project.deadline}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.apartment_outlined,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${project.projectType} (${project.openings})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // Bottom Action Row: Applicants & View/Manage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Applicants Count Button
                  GestureDetector(
                    onTap: project.applicantsCount > 0
                        ? _navigateToApplicants
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: project.applicantsCount > 0
                            ? AppColors.lightIceBlue
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 14,
                            color: project.applicantsCount > 0
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${project.applicantsCount} Applications',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: project.applicantsCount > 0
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions: Context Menu & View/Manage Button
                  Row(
                    children: [
                      if (canCloseOrCancel || isDraft)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          tooltip: 'Project Options',
                          onSelected: (val) {
                            if (val == 'Close') {
                              _confirmStatusChange(project, 'Closed');
                            } else if (val == 'Cancel') {
                              _confirmStatusChange(project, 'Cancelled');
                            } else if (val == 'PublishDraft') {
                              _projectService.updateProjectStatus(
                                  project.id, 'Open');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Draft project published!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (isDraft)
                              const PopupMenuItem(
                                value: 'PublishDraft',
                                child: Text('Publish Draft Listing'),
                              ),
                            if (canCloseOrCancel) ...[
                              const PopupMenuItem(
                                value: 'Close',
                                child: Text('Mark as Closed'),
                              ),
                              const PopupMenuItem(
                                value: 'Cancel',
                                child: Text(
                                  'Cancel Project',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _openProjectDetailsModal(project),
                        child: const Text(
                          'View / Manage',
                          style: TextStyle(fontSize: 12),
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
    );
  }

  // Status Badge Builder
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;

    switch (status) {
      case 'Open':
        bg = AppColors.infoBg;
        textColor = AppColors.info;
        break;
      case 'In Progress':
        bg = const Color(0xFFE0F7FA);
        textColor = AppColors.accentTeal;
        break;
      case 'Completed':
        bg = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'Draft':
        bg = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        break;
      case 'Closed':
        bg = const Color(0xFFE2E8F0);
        textColor = AppColors.darkNavy;
        break;
      case 'Cancelled':
        bg = AppColors.errorBg;
        textColor = AppColors.error;
        break;
      default:
        bg = AppColors.background;
        textColor = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(bool noProjectsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.lightIceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              noProjectsAtAll
                  ? 'No Projects Posted Yet'
                  : 'No Projects Match Your Filter',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noProjectsAtAll
                  ? 'Your organization has not published any student challenges yet. Tap below to create your first project.'
                  : 'Try adjusting your search keywords or switching status tabs to see other listings.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (noProjectsAtAll)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _navigateToPostProject,
                icon: const Icon(Icons.add),
                label: const Text('Post Your First Project'),
              )
            else
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = 'All';
                    _searchController.clear();
                  });
                },
                child: const Text('Reset Filters'),
              ),
          ],
        ),
      ),
    );
  }
}

