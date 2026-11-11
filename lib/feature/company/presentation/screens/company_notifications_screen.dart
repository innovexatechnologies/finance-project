import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/company/presentation/widgets/company_executive_app_bar.dart';

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
          appBar: CompanyExecutiveAppBar(
            title: _isSelectionMode
                ? '${_selectedIds.length} Selected'
                : 'Notifications',
            subtitle: _isSelectionMode
                ? 'Tap alerts to include or exclude'
                : (unreadTotal > 0
                    ? '$unreadTotal unread alert${unreadTotal == 1 ? '' : 's'}'
                    : 'All updates reviewed'),
            leadingIcon: _isSelectionMode
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            onLeadingPressed: _isSelectionMode
                ? () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    });
                  }
                : null,
            actions: [
              if (!_isSelectionMode) ...[
                CompanyHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh Notifications',
                  onPressed: () => AppDataService.instance
                      .syncFromSupabase(forceRefresh: true),
                ),
                if (allNotifs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  CompanyHeaderIconButton(
                    icon: Icons.checklist_rounded,
                    tooltip: 'Select Alerts',
                    onPressed: () => setState(() => _isSelectionMode = true),
                  ),
                ],
                if (unreadTotal > 0) ...[
                  const SizedBox(width: 8),
                  CompanyHeaderPillButton(
                    label: 'Mark Read',
                    icon: Icons.done_all_rounded,
                    filled: true,
                    onPressed: () async {
                      await AppDataService.instance.markNotificationsRead();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read.'),
                          backgroundColor: AppColors.statusOpen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ] else ...[
                CompanyHeaderIconButton(
                  icon: _selectedIds.length == filtered.length &&
                          filtered.isNotEmpty
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  tooltip: _selectedIds.length == filtered.length &&
                          filtered.isNotEmpty
                      ? 'Deselect All'
                      : 'Select All',
                  onPressed: () => _selectAll(filtered),
                ),
                const SizedBox(width: 8),
                CompanyHeaderIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete Selected',
                  iconColor: _selectedIds.isEmpty
                      ? AppColors.textMuted
                      : AppColors.statusClosed,
                  backgroundColor: _selectedIds.isEmpty
                      ? AppColors.background
                      : AppColors.errorBg,
                  borderColor: _selectedIds.isEmpty
                      ? AppColors.borderLight
                      : AppColors.statusClosed.withValues(alpha: 0.25),
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                setState(() {
                                  _activeFilter = filter;
                                  _selectedIds.clear();
                                  _isSelectionMode = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.deepNavy
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.deepNavy
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      filter,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.deepNavy,
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : AppColors.primaryBlue.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          count > 99 ? '99+' : '$count',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryBlue,
                      backgroundColor: Colors.white,
                      onRefresh: () => AppDataService.instance
                          .syncFromSupabase(forceRefresh: true),
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                28,
                                16,
                                28,
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 34,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                    ),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 74,
                                        height: 74,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.08),
                                          border: Border.all(
                                            color: AppColors.primaryBlue
                                                .withValues(alpha: 0.18),
                                            width: 6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_none_rounded,
                                          size: 32,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        allNotifs.isEmpty
                                            ? 'You Are All Caught Up'
                                            : 'No $_activeFilter Alerts',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.deepNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 360,
                                        ),
                                        child: Text(
                                          allNotifs.isEmpty
                                              ? 'Real-time updates for new student applications, deliverable submissions, and direct replies appear here.'
                                              : 'Switch filter tabs or refresh to check for new workspace activity.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: AppColors.grayText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.deepNavy,
                                          backgroundColor: AppColors.background,
                                          side: const BorderSide(
                                            color: AppColors.borderLight,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 11,
                                          ),
                                        ),
                                        onPressed: () {
                                          if (allNotifs.isNotEmpty) {
                                            setState(
                                              () => _activeFilter = 'All',
                                            );
                                          } else {
                                            AppDataService.instance
                                                .syncFromSupabase(
                                              forceRefresh: true,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          allNotifs.isNotEmpty
                                              ? Icons.filter_alt_off_rounded
                                              : Icons.refresh_rounded,
                                          size: 17,
                                          color: AppColors.primaryBlue,
                                        ),
                                        label: Text(
                                          allNotifs.isNotEmpty
                                              ? 'Show All Alerts'
                                              : 'Refresh Notifications',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

