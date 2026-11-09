import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

class ExploreProjectsScreen extends StatefulWidget {
  const ExploreProjectsScreen({super.key});

  @override
  State<ExploreProjectsScreen> createState() => _ExploreProjectsScreenState();
}

class _ExploreProjectsScreenState extends State<ExploreProjectsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Design',
    'Development',
    'Research',
    'Marketing',
    'Writing',
    'Data Analysis',
  ];

  List<Map<String, dynamic>> _supabaseProjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveProjects() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loaded = [];
      for (var item in response) {
        loaded.add({
          'id': item['id']?.toString() ?? '',
          'title': item['title'] ?? 'Untitled Project',
          'company': item['company_name'] ?? 'Company',
          'category': 'Development',
          'duration': '3-5 days',
          'workMode': 'Remote',
          'status': item['status'] ?? 'Open',
          'stipend': item['budget'] ?? '20-30K',
          'description': item['description'] ?? 'No description provided.',
          'skills': ['Flutter', 'Dart', 'Teamwork'],
          'isVerified': true,
        });
      }

      if (mounted) {
        setState(() {
          _supabaseProjects = loaded;
        });
      }
    } catch (_) {
      // Fallback to local
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    final localProjects = AppDataService.instance.getAllProjects();

    // Merge Supabase projects and local projects without duplicates
    final existingIds = <String>{};
    final combined = <Map<String, dynamic>>[];

    for (var p in _supabaseProjects) {
      final id = p['id']?.toString() ?? '';
      if (id.isNotEmpty && !existingIds.contains(id)) {
        existingIds.add(id);
        combined.add(p);
      }
    }

    for (var p in localProjects) {
      final id = p['id']?.toString() ?? '';
      if (!existingIds.contains(id)) {
        existingIds.add(id);
        combined.add(p);
      }
    }

    final query = _searchController.text.trim().toLowerCase();

    return combined.where((p) {
      final matchesCategory = _selectedCategory == 'All' ||
          (p['category']?.toString().toLowerCase() ==
              _selectedCategory.toLowerCase());
      final matchesSearch = query.isEmpty ||
          (p['title']?.toString().toLowerCase().contains(query) ?? false) ||
          (p['company']?.toString().toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore Projects'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLiveProjects,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final filteredProjects = _getFilteredProjects();

          return Column(
            children: [
              // Search & Filter Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search projects, companies...',
                            prefixIcon: Icon(Icons.search_rounded,
                                color: AppColors.grayText),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          // Quick filter reset
                          setState(() {
                            _selectedCategory = 'All';
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Categories Horizontal List
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.cardWhite,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.darkText,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.lightGray,
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Projects Listing
              Expanded(
                child: _isLoading && filteredProjects.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 48, color: AppColors.grayText),
                                const SizedBox(height: 12),
                                Text(
                                  'No projects found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try searching for something else or change category',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              final id = project['id']?.toString() ?? '';
                              final isBookmarked =
                                  AppDataService.instance.isProjectSaved(id);
                              final skills = (project['skills'] as List?) ??
                                  ['Research', 'Analysis'];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                      color: AppColors.lightGray),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StudentProjectDetailsScreen(
                                                project: project),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Company Logo, Title, Bookmark
                                        Row(
                                          children: [
                                            // Company Icon Box
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppColors.lightAqua,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (project['company'] ??
                                                      'C')[0].toUpperCase(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryBlue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    project['title'] ?? 'Title',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.deepNavy,
                                                    ),
                                                  ),
                                                  Text(
                                                    project['company'] ??
                                                        'Company',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: AppColors.grayText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Status Chip
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.statusOpen
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                project['status'] ?? 'Open',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.statusOpen,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Bookmark Button
                                            IconButton(
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                              icon: Icon(
                                                isBookmarked
                                                    ? Icons.bookmark_rounded
                                                    : Icons
                                                        .bookmark_border_rounded,
                                                color: isBookmarked
                                                    ? AppColors.teal
                                                    : AppColors.grayText,
                                                size: 24,
                                              ),
                                              onPressed: () {
                                                AppDataService.instance
                                                    .toggleSaveProject(project);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      isBookmarked
                                                          ? 'Removed from saved projects'
                                                          : 'Project saved to bookmarks!',
                                                    ),
                                                    duration: const Duration(
                                                        seconds: 1),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Short Description
                                        Text(
                                          project['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.darkText,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Skills Tags
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: skills.map((s) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: AppColors.lightGray),
                                              ),
                                              child: Text(
                                                s.toString(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: AppColors.grayText,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 12),

                                        // Details Row: Duration, Remote, Stipend
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule_rounded,
                                                size: 14,
                                                color: AppColors.grayText),
                                            const SizedBox(width: 4),
                                            Text(
                                              project['duration'] ?? '3-5 days',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.grayText,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            const Icon(Icons.public_rounded,
                                                size: 14,
                                                color: AppColors.grayText),
                                            const SizedBox(width: 4),
                                            Text(
                                              project['workMode'] ?? 'Remote',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.grayText,
                                              ),
                                            ),
                                            if (project['stipend'] != null) ...[
                                              const SizedBox(width: 14),
                                              const Icon(
                                                  Icons.monetization_on_outlined,
                                                  size: 14,
                                                  color: AppColors.grayText),
                                              const SizedBox(width: 4),
                                              Text(
                                                project['stipend'].toString(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.deepNavy,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
