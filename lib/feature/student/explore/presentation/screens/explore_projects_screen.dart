import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
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

  final List<Map<String, dynamic>> _dummyProjects = [
    {
      'id': '1',
      'title': 'Market Research on AI Tools',
      'company': 'Google',
      'category': 'Research',
      'duration': '3-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Conduct comprehensive market research on the latest enterprise AI tools and compile an analytical summary.',
      'skills': ['Research', 'Analysis', 'Report Writing'],
    },
    {
      'id': '2',
      'title': 'Social Media Content Creation',
      'company': 'Meta',
      'category': 'Marketing',
      'duration': '2-4 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Design viral engaging banners and write creative copy for international developer community campaigns.',
      'skills': ['Copywriting', 'Canva', 'Social Media'],
    },
    {
      'id': '3',
      'title': 'UI/UX Design for Web App',
      'company': 'Microsoft',
      'category': 'Design',
      'duration': '5-7 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Create high-fidelity wireframes and prototype components using Figma for cloud service management portal.',
      'skills': ['Figma', 'UI/UX', 'Wireframing'],
    },
    {
      'id': '4',
      'title': 'Flutter App Mobile UI Development',
      'company': 'TechVista',
      'category': 'Development',
      'duration': '4-6 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Implement pixel-perfect responsive Flutter screens and integrate REST API endpoints.',
      'skills': ['Flutter', 'Dart', 'REST APIs'],
    },
    {
      'id': '5',
      'title': 'Product Analysis Report',
      'company': 'Amazon',
      'category': 'Research',
      'duration': '3-6 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Analyze logistics bottlenecks and produce strategic operational efficiency recommendations.',
      'skills': ['Data Analysis', 'Excel', 'Problem Solving'],
    },
    {
      'id': '6',
      'title': 'Python Data Pipeline Optimization',
      'company': 'CodeCraft',
      'category': 'Data Analysis',
      'duration': '3-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Clean, transform and process CSV datasets using Pandas and NumPy for automated reporting.',
      'skills': ['Python', 'Pandas', 'Data Cleaning'],
    },
  ];

  List<Map<String, dynamic>> _liveProjects = [];
  bool _isLoading = false;
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchLiveProjects();
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
          'description': item['description'] ?? 'No description provided.',
          'skills': ['Flutter', 'Dart', 'Teamwork'],
        });
      }

      if (mounted) {
        setState(() {
          _liveProjects = loaded;
        });
      }
    } catch (_) {
      // Fallback to dummy
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProjects {
    final allProjects = [..._liveProjects, ..._dummyProjects];
    final query = _searchController.text.trim().toLowerCase();

    return allProjects.where((p) {
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
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                            size: 20, color: AppColors.grayText),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Chips Horizontal Scroll
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: AppColors.cardWhite,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
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
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Projects List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Text(
                          'No projects found in this category',
                          style: GoogleFonts.inter(color: AppColors.grayText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          final id = project['id'] ?? index.toString();
                          final isBookmarked = _bookmarkedIds.contains(id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                  color: AppColors.lightGray, width: 0.8),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Company, Status & Bookmark Row
                                    Row(
                                      children: [
                                        // Company Logo/Initial
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.lightAqua,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (project['company'] ??
                                                  'C')[0].toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
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
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.deepNavy,
                                                ),
                                              ),
                                              Text(
                                                project['company'] ?? 'Company',
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
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
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isBookmarked) {
                                                _bookmarkedIds.remove(id);
                                              } else {
                                                _bookmarkedIds.add(id);
                                              }
                                            });
                                          },
                                          child: Icon(
                                            isBookmarked
                                                ? Icons.bookmark_rounded
                                                : Icons
                                                    .bookmark_outline_rounded,
                                            color: isBookmarked
                                                ? AppColors.teal
                                                : AppColors.grayText,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Meta Info
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded,
                                            size: 13,
                                            color: AppColors.grayText),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${project['duration']} • ${project['workMode']}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.grayText,
                                          ),
                                        ),
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
      ),
    );
  }
}
