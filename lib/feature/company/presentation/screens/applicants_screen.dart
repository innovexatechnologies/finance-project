import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/company/models/applicant_model.dart';
import 'package:link_vibe/feature/company/services/company_applicant_service.dart';
import 'package:link_vibe/feature/company/services/company_project_service.dart';

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

  late String? _currentProjectId;
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  // Open Screen 29 (View Student Profile Detail)
  void _openStudentProfileModal(ApplicantModel applicant) {
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
                      'Student Candidate Profile (Screen 29)',
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
                    // Avatar & Academic Identity
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            applicant.avatarInitial,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                applicant.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                applicant.university,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                applicant.degree,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightIceBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'CGPA: ${applicant.cgpa.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14, color: Color(0xFFEAB308)),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${applicant.rating}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // Applied Project Context
                    _buildProfileSectionHeader(
                        'Project Applied', Icons.work_outline),
                    Text(
                      applicant.projectTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Proposal Summary Pitch
                    _buildProfileSectionHeader(
                        'Student Proposal & Pitch', Icons.notes_outlined),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        applicant.proposalSummary,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Technical Skills
                    _buildProfileSectionHeader(
                        'Verified Skills', Icons.code_rounded),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: applicant.skills
                          .map((s) => Chip(
                                label: Text(s),
                                backgroundColor: AppColors.lightIceBlue,
                                labelStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Portfolio link
                    if (applicant.portfolioUrl.isNotEmpty) ...[
                      _buildProfileSectionHeader(
                          'Portfolio / GitHub', Icons.link_rounded),
                      Text(
                        applicant.portfolioUrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  // Action: Shortlist Applicant
  Future<void> _handleShortlist(ApplicantModel applicant) async {
    final success = await _applicantService.updateApplicantStatus(
      applicantId: applicant.id,
      newStatus: 'Shortlisted',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${applicant.name} has been added to Shortlist!'),
          backgroundColor: const Color(0xFF7C3AED),
        ),
      );
    }
  }

  // Action: Accept / Hire Candidate with Openings Limit Check
  Future<void> _handleAccept(ApplicantModel applicant) async {
    final project = _projectService.allProjects.firstWhere(
      (p) => p.id == applicant.projectId,
      orElse: () => _projectService.allProjects.first,
    );

    final acceptedCount = _applicantService.getAcceptedCount(applicant.projectId);

    // Functional Constraint: Prevent accepting more students than available openings
    if (acceptedCount >= project.openings) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Openings Full',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'All ${project.openings} opening(s) for "${project.title}" are already filled with accepted students.\n\nTo accept additional candidates, increase student openings in project settings.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation dialog before acceptance
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Confirm Candidate Acceptance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to officially accept and hire "${applicant.name}" for "${project.title}"?\n\nThis will assign the candidate to the project, update project status to In Progress, and reflect in Screen 30.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _applicantService.updateApplicantStatus(
        applicantId: applicant.id,
        newStatus: 'Accepted',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${applicant.name} accepted! Assigned to "${project.title}" (Reflected in Screen 30).',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // Action: Reject Candidate with Confirmation
  Future<void> _handleReject(ApplicantModel applicant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text('Confirm Rejection',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to mark the application from "${applicant.name}" as Rejected?',
          style: const TextStyle(fontSize: 13.5),
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
            child: const Text('Reject Application'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _applicantService.updateApplicantStatus(
        applicantId: applicant.id,
        newStatus: 'Rejected',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application from ${applicant.name} marked as Rejected.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Project Applicants (Screen 28)'),
      ),
      body: ValueListenableBuilder<List<ApplicantModel>>(
        valueListenable: _applicantService.applicantsNotifier,
        builder: (context, allApplicants, _) {
          // 1. Filter applicants for the selected project (or all if not specified)
          final projectScoped = _currentProjectId != null
              ? allApplicants.where((a) => a.projectId == _currentProjectId).toList()
              : allApplicants;

          // 2. Filter by status
          final statusFiltered = _selectedStatus == 'All'
              ? projectScoped
              : projectScoped
                  .where((a) =>
                      a.status.toLowerCase() == _selectedStatus.toLowerCase())
                  .toList();

          // 3. Filter by search query
          final displayedApplicants = _searchQuery.isEmpty
              ? statusFiltered
              : statusFiltered.where((a) {
                  return a.name.toLowerCase().contains(_searchQuery) ||
                      a.university.toLowerCase().contains(_searchQuery) ||
                      a.skills.any((s) => s.toLowerCase().contains(_searchQuery));
                }).toList();

          return Column(
            children: [
              // Search & Filter Header Container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Optional Project Context Selector (If opened with multiple projects)
                    if (_currentProjectId == null)
                      _buildProjectFilterDropdown()
                    else
                      _buildActiveProjectInfoBanner(),
                    const SizedBox(height: 10),

                    // Search Field
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by student name, university, skill...',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
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
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Filter Chips
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

                          final count = status == 'All'
                              ? projectScoped.length
                              : projectScoped
                                  .where((a) =>
                                      a.status.toLowerCase() ==
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

              // Applicants List / Empty State
              Expanded(
                child: displayedApplicants.isEmpty
                    ? _buildEmptyState(projectScoped.isEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: displayedApplicants.length,
                        itemBuilder: (context, index) {
                          final applicant = displayedApplicants[index];
                          return _buildApplicantCard(applicant);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Active Project Banner when scoped
  Widget _buildActiveProjectInfoBanner() {
    final project = _projectService.allProjects.firstWhere(
      (p) => p.id == _currentProjectId,
      orElse: () => _projectService.allProjects.first,
    );
    final acceptedCount = _applicantService.getAcceptedCount(project.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightIceBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Project: ${project.title}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Hired: $acceptedCount/${project.openings}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Project selector if opened globally
  Widget _buildProjectFilterDropdown() {
    final projects = _projectService.allProjects;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _currentProjectId,
          hint: const Text('Filter applicants by project...',
              style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Company Projects',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            ...projects.map((p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(p.title,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (val) {
            setState(() {
              _currentProjectId = val;
            });
          },
        ),
      ),
    );
  }

  // Applicant Card (Requirements 1-8 + Actions)
  Widget _buildApplicantCard(ApplicantModel applicant) {
    final isPending = applicant.status == 'Pending';
    final isUnderReview = applicant.status == 'Under Review';
    final isAccepted = applicant.status == 'Accepted';
    final isRejected = applicant.status == 'Rejected';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Profile picture, Student Name, Degree, Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Profile Picture / Avatar initial
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    applicant.avatarInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 1, 3, 4. Student Name, University, Degree
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              applicant.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                          // 8. Application Status Badge
                          _buildStatusBadge(applicant.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        applicant.university,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${applicant.degree} • CGPA: ${applicant.cgpa.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Application Date & Applied Project Context
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Applied: ${applicant.appliedDate}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  applicant.projectTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 7. Proposal Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${applicant.proposalSummary}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 5. Skills Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: applicant.skills.take(4).map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightIceBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // AVAILABLE ACTIONS: View Profile, Shortlist, Accept, Reject
            Row(
              children: [
                // View Profile (Screen 29)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _openStudentProfileModal(applicant),
                  child: const Text('View Profile',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),

                // Shortlist Button (if pending or under review)
                if (isPending || isUnderReview)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => _handleShortlist(applicant),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('Shortlist',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),

                // Reject Button (if not already rejected or accepted)
                if (!isRejected && !isAccepted)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => _handleReject(applicant),
                    child: const Text('Reject',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),

                // Accept Button (if not accepted)
                if (!isAccepted)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _handleAccept(applicant),
                    child: const Text('Accept',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Status Badge Widget
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;

    switch (status) {
      case 'Pending':
        bg = AppColors.warningBg;
        textColor = AppColors.warning;
        break;
      case 'Under Review':
        bg = AppColors.infoBg;
        textColor = AppColors.info;
        break;
      case 'Shortlisted':
        bg = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF7C3AED);
        break;
      case 'Accepted':
        bg = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'Rejected':
        bg = AppColors.errorBg;
        textColor = AppColors.error;
        break;
      default:
        bg = AppColors.background;
        textColor = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
  Widget _buildEmptyState(bool noApplicantsAtAll) {
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
                Icons.person_search_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              noApplicantsAtAll
                  ? 'No Student Applications Yet'
                  : 'No Applicants Match Your Filters',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noApplicantsAtAll
                  ? 'University students have not submitted proposals for this project yet. Published projects receive applications as students browse campus challenges.'
                  : 'Try searching by other keywords or switching your applicant status filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
