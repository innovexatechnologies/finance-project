import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final allApps = AppDataService.instance.getApplications();

          final filteredApps = allApps.where((app) {
            if (_selectedFilter == 'All') return true;
            return app['status']?.toString().toLowerCase() ==
                _selectedFilter.toLowerCase();
          }).toList();

          return Column(
            children: [
              // Filter Chips Horizontal Row
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
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
                      ),
                    );
                  },
                ),
              ),

              // Applications List
              Expanded(
                child: filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_late_outlined,
                                size: 52, color: AppColors.grayText),
                            const SizedBox(height: 12),
                            Text(
                              'No applications found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFilter == 'All'
                                  ? 'Apply for available opportunities from Explore'
                                  : 'No applications under $_selectedFilter status',
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
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          final status = app['status'] ?? 'Pending';
                          final timelineStep =
                              (app['timelineStep'] as int?) ?? 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side:
                                  const BorderSide(color: AppColors.lightGray),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row: Company, Title, Status
                                  Row(
                                    children: [
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
                                            (app['company'] ?? 'C')[0]
                                                .toUpperCase(),
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
                                              app['title'] ?? 'Title',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.deepNavy,
                                              ),
                                            ),
                                            Text(
                                              app['company'] ?? 'Company',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.grayText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Submission Date & Info
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Applied on: ${app['appliedDate'] ?? 'Nov 2026'}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.grayText,
                                        ),
                                      ),
                                      Text(
                                        'Stage $timelineStep of 3',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Timeline Progress Indicator
                                  _buildTimelineBar(timelineStep, status),
                                ],
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

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.lightAqua;
    Color fg = AppColors.primaryBlue;

    if (status == 'Accepted' || status == 'Completed') {
      bg = AppColors.statusOpen.withValues(alpha: 0.12);
      fg = AppColors.statusOpen;
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (status == 'Shortlisted' || status == 'In Progress') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildTimelineBar(int step, String status) {
    final isRejected = status == 'Rejected';

    return Row(
      children: [
        _buildTimelineStep('Submitted', step >= 1, isRejected && step == 1),
        Expanded(
          child: Container(
            height: 3,
            color: step >= 2 ? AppColors.primaryBlue : AppColors.lightGray,
          ),
        ),
        _buildTimelineStep(
            'Review', step >= 2, isRejected && step == 2),
        Expanded(
          child: Container(
            height: 3,
            color: step >= 3 ? AppColors.primaryBlue : AppColors.lightGray,
          ),
        ),
        _buildTimelineStep(
            isRejected ? 'Rejected' : 'Accepted',
            step >= 3,
            isRejected),
      ],
    );
  }

  Widget _buildTimelineStep(String label, bool isDone, bool isAlert) {
    Color dotColor = AppColors.lightGray;
    if (isAlert) {
      dotColor = Colors.redAccent;
    } else if (isDone) {
      dotColor = AppColors.primaryBlue;
    }

    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppColors.deepNavy : AppColors.grayText,
          ),
        ),
      ],
    );
  }
}
