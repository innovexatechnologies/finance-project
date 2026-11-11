import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/share_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';
import 'package:link_vibe/core/widgets/status_badge.dart';
import 'package:link_vibe/feature/admin/services/admin_settings_service.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

class ExploreProjectsScreen extends StatefulWidget {
  const ExploreProjectsScreen({super.key});

  @override
  State<ExploreProjectsScreen> createState() => _ExploreProjectsScreenState();
}

class _ExploreProjectsScreenState extends State<ExploreProjectsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  static const List<String> _defaultCategories = [
    'All',
    'Design',
    'Development',
    'Research',
    'Marketing',
    'Writing',
    'Data Analysis',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshLiveCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshLiveCatalog({
    bool showFeedback = false,
    bool resetFilters = false,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      if (resetFilters) {
        _searchController.clear();
        _selectedCategory = 'All';
      }
    });

    try {
      await AppDataService.instance.syncFromSupabase(forceRefresh: true);
    } catch (_) {
      // Handled gracefully inside syncFromSupabase
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (showFeedback) {
          final count = _getFilteredProjects().length;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Catalog synced! $count open ${count == 1 ? 'opportunity' : 'opportunities'} found.',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.statusOpen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  List<String> _buildCategories(List<Map<String, dynamic>> projects) {
    final seenLower = <String>{};
    final result = <String>[];

    void addCat(String raw) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) return;
      final key = cleaned.toLowerCase();
      if (seenLower.add(key)) {
        result.add(cleaned);
      }
    }

    for (final c in _defaultCategories) {
      addCat(c);
    }
    for (final item in AdminSettingsService().categoriesNotifier.value) {
      if (item.isActive) addCat(item.name);
    }
    for (final p in projects) {
      final cat = p['category']?.toString() ?? '';
      if (cat.isNotEmpty) addCat(cat);
    }
    return result;
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    final allProjects = AppDataService.instance.getAllProjects();
    final query = _searchController.text.trim().toLowerCase();

    return allProjects.where((p) {
      final status = (p['status']?.toString() ?? 'Open').toLowerCase();
      if (status == 'removed' || status == 'flagged' || status == 'closed') {
        return false;
      }

      final matchesCategory = _selectedCategory == 'All' ||
          (p['category']?.toString().toLowerCase() ==
              _selectedCategory.toLowerCase());

      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      final title = p['title']?.toString().toLowerCase() ?? '';
      final company = p['company']?.toString().toLowerCase() ?? '';
      final desc = p['description']?.toString().toLowerCase() ?? '';
      final skills = SupabaseHelper.parseStringList(p['skills'])
          .join(' ')
          .toLowerCase();

      return title.contains(query) ||
          company.contains(query) ||
          desc.contains(query) ||
          skills.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ExecutiveAppBar(
        title: 'Explore Projects',
        subtitle: 'Live Corporate Opportunities',
        showLeading: Navigator.canPop(context),
        leadingBadge: Container(
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
            Icons.explore_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
        actions: [
          ExecutiveHeaderIconButton(
            tooltip: 'Open Shared Link',
            icon: Icons.link_rounded,
            iconColor: AppColors.primaryBlue,
            onPressed: () => ShareService.showOpenSharedLinkDialog(context),
          ),
          const SizedBox(width: 8),
          ExecutiveHeaderIconButton(
            tooltip: 'Refresh Live Catalog',
            icon: Icons.refresh_rounded,
            onPressed: _isLoading
                ? null
                : () => _refreshLiveCatalog(
                      showFeedback: true,
                      resetFilters: true,
                    ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final allProjects = AppDataService.instance.getAllProjects();
          final categories = _buildCategories(allProjects);
          final filteredProjects = _getFilteredProjects();
          final hasActiveFilters = _selectedCategory != 'All' ||
              _searchController.text.trim().isNotEmpty;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.lightAqua,
                    ),

                  // Crisp White Executive Search & Filter Control Dock
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (value) async {
                                  final opener =
                                      ShareService.deepLinkTextOpener;
                                  if (opener != null &&
                                      value.toLowerCase().contains(
                                        '${ShareService.appScheme}://',
                                      )) {
                                    final opened = await opener(
                                      value,
                                      context: context,
                                    );
                                    if (opened && mounted) {
                                      _searchController.clear();
                                      setState(() {});
                                    }
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText:
                                      'Search projects, companies, skills...',
                                  filled: true,
                                  fillColor: AppColors.background,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.grayText,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: hasActiveFilters
                                    ? AppColors.primaryBlue
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasActiveFilters
                                      ? AppColors.primaryBlue
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: IconButton(
                                tooltip: 'Reset Filters',
                                icon: Icon(
                                  Icons.filter_alt_off_rounded,
                                  color: hasActiveFilters
                                      ? Colors.white
                                      : AppColors.deepNavy,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCategory = cat);
                                    }
                                  },
                                  selectedColor: AppColors.primaryBlue,
                                  backgroundColor: AppColors.background,
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.darkText,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primaryBlue
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  showCheckmark: false,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Projects Listing
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryBlue,
                      onRefresh: () =>
                          _refreshLiveCatalog(showFeedback: false),
                      child: _isLoading && filteredProjects.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : filteredProjects.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    const SizedBox(height: 36),
                                    AppEmptyState(
                                      icon: hasActiveFilters
                                          ? Icons.search_off_rounded
                                          : Icons.work_outline_rounded,
                                      title: hasActiveFilters
                                          ? 'No Matching Projects Found'
                                          : 'No Open Projects Published Yet',
                                      subtitle: hasActiveFilters
                                          ? 'Try clearing your search or switching back to "All" categories.'
                                          : 'Once partner companies publish opportunities, they will appear live here.',
                                      actionLabel: hasActiveFilters
                                          ? 'Reset Filters'
                                          : 'Refresh Catalog',
                                      actionIcon: hasActiveFilters
                                          ? Icons.restart_alt_rounded
                                          : Icons.refresh_rounded,
                                      onAction: hasActiveFilters
                                          ? () {
                                              setState(() {
                                                _selectedCategory = 'All';
                                                _searchController.clear();
                                              });
                                            }
                                          : () => _refreshLiveCatalog(
                                                showFeedback: true,
                                              ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredProjects.length,
                                  itemBuilder: (context, index) {
                                    return _buildProjectCard(
                                      filteredProjects[index],
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final id = project['id']?.toString() ?? '';
    final isBookmarked = AppDataService.instance.isProjectSaved(id);
    final skills = SupabaseHelper.parseStringList(project['skills']);
    final companyStr =
        (project['company']?.toString().trim().isNotEmpty == true)
            ? project['company'].toString().trim()
            : 'Partner Company';
    final isVerified = project['isVerified'] == true;
    final duration = project['duration']?.toString().trim() ?? 'Flexible';
    final workMode = project['workMode']?.toString().trim() ?? 'Remote';
    final stipend = project['stipend']?.toString().trim() ?? '';
    final status = project['status']?.toString() ?? 'Open';
    final category = project['category']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentProjectDetailsScreen(project: project),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.lightAqua,
                            AppColors.primaryBlue.withValues(alpha: 0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          SupabaseHelper.initialsFor(
                            companyStr,
                            fallback: 'CO',
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['title']?.toString() ?? 'Untitled Project',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                companyStr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.grayText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.teal,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusBadge(label: status),
                ],
              ),
              const SizedBox(height: 12),

              if ((project['description']?.toString().trim() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    project['description'].toString().trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.darkText,
                      height: 1.45,
                    ),
                  ),
                ),

              if (skills.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.take(5).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (category.isNotEmpty)
                          _metaItem(
                            Icons.category_outlined,
                            category,
                            AppColors.primaryBlue,
                          ),
                        _metaItem(
                          Icons.schedule_rounded,
                          duration,
                          AppColors.grayText,
                        ),
                        _metaItem(
                          Icons.public_rounded,
                          workMode,
                          AppColors.grayText,
                        ),
                        if (stipend.isNotEmpty)
                          _metaItem(
                            Icons.workspace_premium_outlined,
                            stipend,
                            AppColors.statusOpen,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Share Project',
                    icon: const Icon(
                      Icons.share_outlined,
                      color: AppColors.grayText,
                      size: 20,
                    ),
                    onPressed: () {
                      ShareService.shareProject(
                        context: context,
                        project: project,
                      );
                    },
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    tooltip: isBookmarked ? 'Remove Bookmark' : 'Save Project',
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? AppColors.teal : AppColors.grayText,
                      size: 22,
                    ),
                    onPressed: () {
                      AppDataService.instance.toggleSaveProject(project);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBookmarked
                                ? 'Removed from saved projects'
                                : 'Project saved to bookmarks!',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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

  Widget _metaItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grayText,
          ),
        ),
      ],
    );
  }
}
