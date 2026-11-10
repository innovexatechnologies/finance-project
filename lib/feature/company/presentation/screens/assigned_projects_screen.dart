import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/company/models/assignment_model.dart';
import 'package:link_vibe/feature/company/models/project_model.dart';
import 'package:link_vibe/feature/company/services/company_assignment_service.dart';
import 'package:link_vibe/feature/company/services/company_profile_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';
import 'package:link_vibe/feature/student/chat/presentation/screens/chat_list_screen.dart';
import 'applicant_detail_screen.dart';
import 'company_project_detail_screen.dart';
import 'submission_review_screen.dart';

class AssignedProjectsScreen extends StatefulWidget {
  final String? filterProjectId;

  const AssignedProjectsScreen({
    super.key,
    this.filterProjectId,
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

  Future<void> _messageStudent(AssignmentModel assignment) async {
    await AppDataService.instance.openOrCreateConversation(
      companyName: assignment.studentName,
      peerUserId: assignment.studentId,
      supervisorName: assignment.studentUniversity,
      projectTitle: assignment.projectTitle,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
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
        ? company.companyName
        : 'Active Assignments';

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
              'Assigned Projects',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              companyLabel,
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
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Assignments',
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
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

          final List<AssignmentModel> statusFiltered;
          switch (_selectedFilter) {
            case 'In Progress':
              statusFiltered = projectFiltered
                  .where((a) => a.projectStatus == 'In Progress')
                  .toList();
              break;
            case 'Pending Review':
              statusFiltered = projectFiltered
                  .where((a) => a.submissionStatus == 'Pending Review')
                  .toList();
              break;
            case 'Revision Requested':
              statusFiltered = projectFiltered
                  .where((a) => a.submissionStatus == 'Revision Requested')
                  .toList();
              break;
            case 'Approved':
              statusFiltered = projectFiltered
                  .where((a) => a.submissionStatus == 'Approved')
                  .toList();
              break;
            case 'Pending Submission':
              statusFiltered = projectFiltered
                  .where((a) => a.submissionStatus == 'Pending Submission')
                  .toList();
              break;
            default:
              statusFiltered = projectFiltered;
          }

          final filteredList = _searchQuery.isEmpty
              ? statusFiltered
              : statusFiltered.where((a) {
                  return a.projectTitle.toLowerCase().contains(_searchQuery) ||
                      a.studentName.toLowerCase().contains(_searchQuery) ||
                      a.studentUniversity.toLowerCase().contains(_searchQuery);
                }).toList();

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryBlue,
            child: Column(
              children: [
                _buildFiltersBar(
                  totalCount: projectFiltered.length,
                  filteredCount: filteredList.length,
                ),
                Expanded(
                  child: filteredList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 24),
                            AppEmptyState(
                              icon: Icons.assignment_turned_in_outlined,
                              title: companyAssignments.isEmpty
                                  ? 'No Assigned Projects Yet'
                                  : 'No Matching Assignments',
                              subtitle: companyAssignments.isEmpty
                                  ? 'Accept a student applicant to start tracking progress milestones and deliverables here.'
                                  : 'Adjust your status filter or search query to inspect other assigned engagements.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildAssignmentCard(filteredList[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar({
    required int totalCount,
    required int filteredCount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedProjectId != null) ...[
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.filter_alt_rounded,
                      size: 16, color: AppColors.primaryBlue),
                  label: Text(
                    'Filtered to selected project',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => setState(() => _selectedProjectId = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search by project title, student name, or university...',
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
                final isSelected = _selectedFilter == filter;
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
                  onSelected: (_) => setState(() => _selectedFilter = filter),
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
            'Showing $filteredCount of $totalCount assignments',
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

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final pct = (assignment.progress * 100).round();
    final canReviewSubmission = assignment.hasSubmission &&
        assignment.latestSubmission != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToProjectDetails(assignment),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.projectTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${assignment.projectCategory} • Due ${assignment.deadline}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: assignment.submissionStatus),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToStudentProfile(assignment),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      assignment.studentAvatarInitial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
                          assignment.studentName,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        if (assignment.studentUniversity.isNotEmpty)
                          Text(
                            assignment.studentUniversity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.grayText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 19, color: AppColors.primaryBlue),
                    tooltip: 'Message Student',
                    onPressed: () => _messageStudent(assignment),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Milestone Completion',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: assignment.progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                assignment.submissionStatus == 'Approved'
                    ? AppColors.statusOpen
                    : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _navigateToProjectDetails(assignment),
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: const Text('Project'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: assignment.submissionStatus == 'Pending Review'
                        ? AppColors.primaryBlue
                        : (assignment.submissionStatus == 'Approved'
                            ? AppColors.statusOpen
                            : AppColors.deepNavy),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: canReviewSubmission
                      ? () => _navigateToSubmissionReview(assignment)
                      : null,
                  icon: Icon(
                    canReviewSubmission
                        ? Icons.rate_review_outlined
                        : Icons.hourglass_empty_rounded,
                    size: 17,
                  ),
                  label: Text(
                    canReviewSubmission
                        ? (assignment.submissionStatus == 'Pending Review'
                            ? 'Review Deliverable'
                            : 'View Submission')
                        : 'Awaiting Student Submission',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
