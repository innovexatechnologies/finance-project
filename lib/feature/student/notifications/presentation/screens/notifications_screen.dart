import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

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

  void _selectAll(List<Map<String, dynamic>> allNotifs) {
    setState(() {
      if (_selectedIds.length == allNotifs.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (final n in allNotifs) {
          final id = n['id']?.toString();
          if (id != null && id.isNotEmpty) _selectedIds.add(id);
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
        content: Text('$count notification${count > 1 ? "s" : ""} deleted'),
        backgroundColor: AppColors.statusClosed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSingle(String id, String title) async {
    await AppDataService.instance.deleteNotification(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification "$title" deleted'),
        backgroundColor: AppColors.statusClosed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final notifications = AppDataService.instance.getNotifications();
        final canPop = Navigator.canPop(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              _isSelectionMode
                  ? '${_selectedIds.length} Selected'
                  : 'Notifications',
            ),
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
                : (canPop
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null),
            actions: [
              if (!_isSelectionMode) ...[
                if (notifications.isNotEmpty) ...[
                  IconButton(
                    tooltip: 'Select & Delete',
                    icon: const Icon(Icons.checklist_rounded, size: 21),
                    onPressed: () => setState(() => _isSelectionMode = true),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      AppDataService.instance.markNotificationsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                        ),
                      );
                    },
                    child: Text(
                      'Mark Read',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                IconButton(
                  tooltip: _selectedIds.length == notifications.length
                      ? 'Deselect All'
                      : 'Select All',
                  icon: Icon(
                    _selectedIds.length == notifications.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 22,
                  ),
                  onPressed: () => _selectAll(notifications),
                ),
                IconButton(
                  tooltip: 'Delete Selected',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.statusClosed, size: 22),
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
              ],
              const SizedBox(width: 6),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () => AppDataService.instance
                    .syncFromSupabase(forceRefresh: true),
                child: notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 48),
                          AppEmptyState(
                            icon: Icons.notifications_off_outlined,
                            title: 'No Notifications Yet',
                            subtitle:
                                'Application decisions, partner messages, and certificate updates will appear here in real time.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          final id = item['id']?.toString() ?? 'notif_$index';
                          final title =
                              item['title']?.toString() ?? 'Notification';
                          final isUnread = !(item['isRead'] as bool? ?? false);
                          final isSelected = _selectedIds.contains(id);
                          final type = item['type']?.toString() ?? 'default';

                          Color color = AppColors.primaryBlue;
                          IconData icon = Icons.notifications_rounded;

                          if (type == 'shortlisted') {
                            color = const Color(0xFFD97706);
                            icon = Icons.thumb_up_alt_rounded;
                          } else if (type == 'assigned') {
                            color = const Color(0xFF7C3AED);
                            icon = Icons.assignment_ind_rounded;
                          } else if (type == 'approved' ||
                              type == 'submitted') {
                            color = AppColors.statusOpen;
                            icon = Icons.check_circle_rounded;
                          } else if (type == 'certificate') {
                            color = AppColors.teal;
                            icon = Icons.military_tech_rounded;
                          } else if (type == 'chat') {
                            color = AppColors.primaryBlue;
                            icon = Icons.chat_bubble_outline_rounded;
                          }

                          return Card(
                            elevation: isSelected ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : (isUnread
                                        ? AppColors.primaryBlue
                                            .withValues(alpha: 0.35)
                                        : AppColors.lightGray),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            color: isSelected
                                ? AppColors.lightAqua.withValues(alpha: 0.4)
                                : AppColors.cardWhite,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
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
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isSelectionMode)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10, top: 4),
                                        child: Checkbox(
                                          value: isSelected,
                                          activeColor: AppColors.primaryBlue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          onChanged: (_) =>
                                              _toggleSelection(id),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child:
                                            Icon(icon, color: color, size: 20),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.5,
                                              fontWeight: isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: AppColors.deepNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['subtitle']?.toString() ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.grayText,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item['time']?.toString() ??
                                                'Recently',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              color: AppColors.grayText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_isSelectionMode) ...[
                                      if (isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(
                                              top: 8, right: 4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: AppColors.grayText,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () =>
                                            _deleteSingle(id, title),
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
          ),
        );
      },
    );
  }
}
