import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Pending',
    'Shortlisted',
    'Accepted',
    'Rejected',
  ];

  final List<Map<String, dynamic>> _dummyApplications = [
    {
      'title': 'Flutter E-Commerce App Redesign',
      'company': 'Innovexa Technologies',
      'status': 'Pending',
      'appliedDate': 'Nov 08, 2026',
      'timelineStep': 1,
    },
    {
      'title': 'Market Research on AI Tools',
      'company': 'Google',
      'status': 'Shortlisted',
      'appliedDate': 'Nov 06, 2026',
      'timelineStep': 2,
    },
    {
      'title': 'Barcode Scanning Mobile Utility',
      'company': 'CodeCraft Solutions',
      'status': 'Accepted',
      'appliedDate': 'Nov 02, 2026',
      'timelineStep': 3,
    },
    {
      'title': 'UI/UX Design for Web App',
      'company': 'Microsoft',
      'status': 'Rejected',
      'appliedDate': 'Oct 28, 2026',
      'timelineStep': 1,
    },
  ];

  List<Map<String, dynamic>> _liveApplications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('applications')
            .select('*, projects(*)')
            .eq('applicant_id', user.id)
            .order('created_at', ascending: false);

        final List<Map<String, dynamic>> loaded = [];
        for (var item in response) {
          final project = item['projects'] as Map<String, dynamic>?;
          loaded.add({
            'title': project?['title'] ?? 'Applied Project',
            'company': project?['company_name'] ?? 'Company',
            'status': item['status'] ?? 'Pending',
            'appliedDate': 'Today',
            'timelineStep': item['status'] == 'Accepted' ? 3 : 1,
          });
        }

        if (mounted) {
          setState(() {
            _liveApplications = loaded;
          });
        }
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    final list = [..._liveApplications, ..._dummyApplications];
    if (_selectedFilter == 'All') return list;
    return list
        .where((app) =>
            app['status']?.toString().toLowerCase() ==
            _selectedFilter.toLowerCase())
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.statusOpen;
      case 'shortlisted':
        return AppColors.teal;
      case 'rejected':
        return AppColors.statusClosed;
      default:
        return AppColors.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchApplications,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
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
                      borderRadius: BorderRadius.circular(16),
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

          // Applications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApplications.isEmpty
                    ? Center(
                        child: Text(
                          'No applications found',
                          style: GoogleFonts.inter(color: AppColors.grayText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApplications[index];
                          final status = app['status'] ?? 'Pending';
                          final statusColor = _getStatusColor(status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: AppColors.lightGray, width: 0.8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          app['title'] ?? 'Project',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.deepNavy,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Company: ${app['company']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Applied on: ${app['appliedDate']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                  const Divider(height: 24),

                                  // Timeline Progress Step Indicator
                                  Row(
                                    children: [
                                      _buildTimelineStep(
                                          'Submitted', true, true),
                                      _buildTimelineDivider(
                                          app['timelineStep'] >= 2),
                                      _buildTimelineStep(
                                        'Review',
                                        app['timelineStep'] >= 2,
                                        app['timelineStep'] >= 2,
                                      ),
                                      _buildTimelineDivider(
                                          app['timelineStep'] >= 3),
                                      _buildTimelineStep(
                                        'Decision',
                                        app['timelineStep'] >= 3,
                                        app['timelineStep'] >= 3,
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildTimelineStep(String label, bool isDone, bool isActive) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primaryBlue : AppColors.cardWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.primaryBlue : AppColors.lightGray,
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.deepNavy : AppColors.grayText,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isDone ? AppColors.primaryBlue : AppColors.lightGray,
      ),
    );
  }
}
