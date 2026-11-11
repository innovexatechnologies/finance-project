import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';

class CompanyNotificationsScreen extends StatefulWidget {
  const CompanyNotificationsScreen({super.key});

  @override
  State<CompanyNotificationsScreen> createState() =>
      _CompanyNotificationsScreenState();
}

class _CompanyNotificationsScreenState
    extends State<CompanyNotificationsScreen> {
  String _activeFilter = 'All';
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

  static const List<String> _filters = [
    'All',
    'Unread',
    'Applications',
    'Deliverables',
    'Messages',
  ];

  bool _matchesFilter(Map<String, dynamic> item, String filter) {
    final type = (item['type']?.toString() ?? 'default').toLowerCase();
    final isUnread = item['isRead'] != true;

    switch (filter) {
      case 'Unread':
        return isUnread;
      case 'Applications':
        return type == 'shortlisted' ||
            type == 'assigned' ||
            type == 'submitted' ||
            type == 'application';
      case 'Deliverables':
        return type == 'approved' ||
            type == 'deliverable' ||
            type == 'milestone' ||
            type == 'certificate';
      case 'Messages':
        return type == 'chat';
      default:
        return true;
    }
  }

  ({IconData icon, Color color, String badge}) _resolveTypeMeta(String type) {
    switch (type.toLowerCase()) {
      case 'shortlisted':
        return (
          icon: Icons.how_to_reg_rounded,
          color: AppColors.statusPending,
          badge: 'Recruitment',
        );
      case 'assigned':
        return (
          icon: Icons.assignment_ind_rounded,
          color: AppColors.indigoAccent,
          badge: 'Assignment',
        );
      case 'approved':
      case 'submitted':
      case 'deliverable':
      case 'milestone':
        return (
          icon: Icons.task_alt_rounded,
          color: AppColors.statusOpen,
          badge: 'Deliverable',
        );
      case 'certificate':
        return (
          icon: Icons.workspace_premium_rounded,
          color: AppColors.teal,
          badge: 'Certificate',
        );
      case 'chat':
        return (
          icon: Icons.chat_bubble_outline_rounded,
          color: AppColors.primaryBlue,
          badge: 'Message',
        );
      default:
        return (
          icon: Icons.notifications_active_outlined,
          color: AppColors.primaryBlue,
          badge: 'Update',
        );
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Map<String, dynamic>> visible) {
    setState(() {
      if (_selectedIds.length == visible.length && visible.isNotEmpty) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var i = 0; i < visible.length; i++) {
          final id = visible[i]['id']?.toString() ?? 'notif_$i';
          if (id.isNotEmpty) _selectedIds.add(id);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    await AppDataService.instance.deleteNotifications(_selectedIds.toList());
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count notification${count > 1 ? "s" : ""} removed'),
        backgroundColor: AppColors.statusClosed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteSingle(String id, String title) async {
    await AppDataService.instance.deleteNotification(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "$title"'),
        backgroundColor: AppColors.statusClosed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final allNotifs = AppDataService.instance.getNotifications();
        final filtered = allNotifs
            .where((n) => _matchesFilter(n, _activeFilter))
            .toList();
        final unreadTotal = allNotifs.where((n) => n['isRead'] != true).length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.deepNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSelectionMode
                      ? '${_selectedIds.length} Selected'
                      : 'Corporate Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (!_isSelectionMode)
                  Text(
                    unreadTotal > 0
                        ? '$unreadTotal unread alert${unreadTotal == 1 ? '' : 's'}'
                        : 'All updates reviewed',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.lightAqua,
                    ),
                  ),
              ],
            ),
            actions: [
              if (!_isSelectionMode) ...[
                IconButton(
                  tooltip: 'Sync Alerts',
                  icon: const Icon(Icons.refresh_rounded, size: 21),
                  onPressed: () => AppDataService.instance
                      .syncFromSupabase(forceRefresh: true),
                ),
                if (allNotifs.isNotEmpty)
                  IconButton(
                    tooltip: 'Select & Remove',
                    icon: const Icon(Icons.checklist_rounded, size: 21),
                    onPressed: () => setState(() => _isSelectionMode = true),
                  ),
                if (unreadTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () async {
                        await AppDataService.instance.markNotificationsRead();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All alerts marked as read.'),
                            backgroundColor: AppColors.statusOpen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Mark Read',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightAqua,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                IconButton(
                  tooltip:
                      _selectedIds.length == filtered.length &&
                              filtered.isNotEmpty
                          ? 'Deselect All'
                          : 'Select All',
                  icon: Icon(
                    _selectedIds.length == filtered.length &&
                            filtered.isNotEmpty
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 22,
                  ),
                  onPressed: () => _selectAll(filtered),
                ),
                IconButton(
                  tooltip: 'Delete Selected',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFCA5A5),
                    size: 22,
                  ),
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final count = allNotifs
                              .where((n) => _matchesFilter(n, filter))
                              .length;
                          final isSelected = _activeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: isSelected,
                              showCheckmark: false,
                              label: Text(
                                '$filter ($count)',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.deepNavy,
                                ),
                              ),
                              selectedColor: AppColors.deepNavy,
                              backgroundColor: AppColors.surfaceAlt,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.deepNavy
                                    : AppColors.lightGray,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _activeFilter = filter;
                                  _selectedIds.clear();
                                  _isSelectionMode = false;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.lightGray),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryBlue,
                      onRefresh: () => AppDataService.instance
                          .syncFromSupabase(forceRefresh: true),
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 40),
                                AppEmptyState(
                                  icon: Icons.notifications_off_outlined,
                                  title: allNotifs.isEmpty
                                      ? 'No Notifications Yet'
                                      : 'No $_activeFilter Alerts',
                                  subtitle: allNotifs.isEmpty
                                      ? 'Student applications, milestone submissions, and direct message alerts will appear here in real time.'
                                      : 'Switch filters or pull down to refresh corporate workspace alerts.',
                                  actionLabel: allNotifs.isNotEmpty
                                      ? 'Show All Alerts'
                                      : 'Sync Workspace',
                                  actionIcon: allNotifs.isNotEmpty
                                      ? Icons.filter_alt_off_rounded
                                      : Icons.refresh_rounded,
                                  onAction: () {
                                    if (allNotifs.isNotEmpty) {
                                      setState(() => _activeFilter = 'All');
                                    } else {
                                      AppDataService.instance.syncFromSupabase(
                                        forceRefresh: true,
                                      );
                                    }
                                  },
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                28,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final id =
                                    item['id']?.toString() ?? 'notif_$index';
                                final title =
                                    item['title']?.toString() ?? 'Notification';
                                final subtitle =
                                    item['subtitle']?.toString() ?? '';
                                final time =
                                    item['time']?.toString() ?? 'Recently';
                                final isUnread = item['isRead'] != true;
                                final isSelected = _selectedIds.contains(id);
                                final meta = _resolveTypeMeta(
                                  item['type']?.toString() ?? 'default',
                                );

                                return Material(
                                  color: isSelected
                                      ? AppColors.lightAqua.withValues(
                                          alpha: 0.45,
                                        )
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onLongPress: () {
                                      if (!_isSelectionMode) {
                                        setState(() {
                                          _isSelectionMode = true;
                                          _selectedIds.add(id);
                                        });
                                      }
                                    },
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(id);
                                      } else if (isUnread) {
                                        AppDataService.instance
                                            .markNotificationRead(id);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryBlue
                                              : isUnread
                                                  ? AppColors.primaryBlue
                                                      .withValues(alpha: 0.35)
                                                  : AppColors.lightGray,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: AppColors.softShadow,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_isSelectionMode)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 10,
                                                top: 2,
                                              ),
                                              child: Checkbox(
                                                value: isSelected,
                                                activeColor:
                                                    AppColors.primaryBlue,
                                                onChanged: (_) =>
                                                    _toggleSelection(id),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: meta.color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                meta.icon,
                                                color: meta.color,
                                                size: 21,
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: meta.color
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        meta.badge,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: meta.color,
                                                            ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      time,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  title,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: isUnread
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: AppColors.deepNavy,
                                                  ),
                                                ),
                                                if (subtitle.isNotEmpty) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    subtitle,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      height: 1.4,
                                                      color: AppColors.grayText,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (!_isSelectionMode) ...[
                                            const SizedBox(width: 4),
                                            Column(
                                              children: [
                                                if (isUnread)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                          bottom: 6,
                                                        ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppColors
                                                              .primaryBlue,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 18,
                                                    color: AppColors.grayText,
                                                  ),
                                                  tooltip: 'Remove',
                                                  onPressed: () =>
                                                      _deleteSingle(id, title),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

