import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/feature/company/presentation/widgets/company_executive_app_bar.dart';

class CompanyMessagesScreen extends StatefulWidget {
  const CompanyMessagesScreen({super.key});

  @override
  State<CompanyMessagesScreen> createState() => _CompanyMessagesScreenState();
}

class _CompanyMessagesScreenState extends State<CompanyMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _unreadOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterSegment({
    required String label,
    required bool selected,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: badge > 0 ? 10 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected ? AppColors.softShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.deepNavy : AppColors.grayText,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showNewMessageDialog() async {
    final contacts =
        await AppDataService.instance.fetchAvailableChatContacts();
    if (!mounted) return;

    final contactSearchCtrl = TextEditingController();
    String contactQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 680),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            final filteredContacts = contacts.where((c) {
              if (contactQuery.trim().isEmpty) return true;
              final q = contactQuery.trim().toLowerCase();
              final name = (c['companyName']?.toString() ?? '').toLowerCase();
              final sub = (c['supervisorName']?.toString() ?? '').toLowerCase();
              final ind = (c['industry']?.toString() ?? '').toLowerCase();
              return name.contains(q) || sub.contains(q) || ind.contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.62,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) => Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Message a Student',
                                style: GoogleFonts.poppins(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              Text(
                                'Connect directly with registered students & project candidates.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.grayText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactSearchCtrl,
                      onChanged: (v) => setModalState(() => contactQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Filter by student name, university, degree...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  contacts.isEmpty
                                      ? 'No registered student contacts available yet. Pull down on Messages to sync your workspace.'
                                      : 'No student matches "$contactQuery".',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              itemCount: filteredContacts.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final c = filteredContacts[index];
                                final studentName =
                                    c['companyName']?.toString() ?? 'Student';
                                final degreeUni =
                                    c['supervisorName']?.toString() ?? '';
                                final dept = c['industry']?.toString() ?? '';
                                final subtitle = degreeUni.isNotEmpty
                                    ? degreeUni
                                    : dept;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.lightAqua,
                                    child: Text(
                                      SupabaseHelper.initialsFor(
                                        studentName,
                                        fallback: 'ST',
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          studentName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.deepNavy,
                                          ),
                                        ),
                                      ),
                                      if (c['isVerified'] == true) ...[
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 14,
                                          color: AppColors.teal,
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: subtitle.isNotEmpty
                                      ? Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.grayText,
                                          ),
                                        )
                                      : null,
                                  trailing: const Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onTap: () async {
                                    Navigator.pop(sheetCtx);
                                    final convId = await AppDataService.instance
                                        .openOrCreateConversation(
                                          companyName: studentName,
                                          peerUserId: c['userId']?.toString(),
                                          supervisorName: subtitle.isNotEmpty
                                              ? subtitle
                                              : studentName,
                                        );
                                    if (!mounted) return;
                                    final conv = AppDataService.instance
                                        .getConversation(convId);
                                    if (conv != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              _CompanyChatDetailScreen(
                                                conversationId: convId,
                                                initialChat: conv,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    contactSearchCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final allChats = AppDataService.instance.getConversations();
        final unreadTotal = allChats.fold<int>(
          0,
          (sum, c) => sum + ((c['unread'] as int?) ?? 0),
        );

        final filteredChats = allChats.where((chat) {
          if (_unreadOnly && ((chat['unread'] as int?) ?? 0) == 0) {
            return false;
          }
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.trim().toLowerCase();
          final name = (chat['company']?.toString() ?? '').toLowerCase();
          final sup = (chat['supervisor']?.toString() ?? '').toLowerCase();
          final proj = (chat['projectTitle']?.toString() ?? '').toLowerCase();
          final lastMsg = (chat['lastMessage']?.toString() ?? '').toLowerCase();
          return name.contains(q) ||
              sup.contains(q) ||
              proj.contains(q) ||
              lastMsg.contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CompanyExecutiveAppBar(
            title: 'Messages',
            subtitle: unreadTotal > 0
                ? '$unreadTotal unread message${unreadTotal == 1 ? '' : 's'}'
                : '${allChats.length} conversation${allChats.length == 1 ? '' : 's'}',
            actions: [
              CompanyHeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh Messages',
                onPressed: () => AppDataService.instance
                    .syncFromSupabase(forceRefresh: true),
              ),
              const SizedBox(width: 8),
              CompanyHeaderPillButton(
                label: 'New',
                icon: Icons.add_comment_rounded,
                filled: true,
                onPressed: _showNewMessageDialog,
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: AppColors.deepNavy,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search student, project, or message...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 19,
                                    color: AppColors.grayText,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryBlue,
                                      width: 1.4,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFilterSegment(
                                    label: 'All',
                                    selected: !_unreadOnly,
                                    onTap: () =>
                                        setState(() => _unreadOnly = false),
                                  ),
                                  _buildFilterSegment(
                                    label: 'Unread',
                                    selected: _unreadOnly,
                                    badge: unreadTotal,
                                    onTap: () =>
                                        setState(() => _unreadOnly = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryBlue,
                      backgroundColor: Colors.white,
                      onRefresh: () => AppDataService.instance
                          .syncFromSupabase(forceRefresh: true),
                      child: filteredChats.isEmpty
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
                                          Icons.chat_bubble_outline_rounded,
                                          size: 30,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        allChats.isEmpty
                                            ? 'No Active Conversations'
                                            : 'No Matching Conversations',
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
                                          allChats.isEmpty
                                              ? 'Start a direct thread with student applicants or assigned contributors to coordinate milestones.'
                                              : 'Adjust your search query or filter to view other conversations.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: AppColors.grayText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () {
                                          if (allChats.isEmpty) {
                                            _showNewMessageDialog();
                                          } else {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _unreadOnly = false;
                                            });
                                          }
                                        },
                                        icon: Icon(
                                          allChats.isEmpty
                                              ? Icons.add_comment_rounded
                                              : Icons.filter_alt_off_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          allChats.isEmpty
                                              ? 'Start Conversation'
                                              : 'Reset Filters',
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
                              itemCount: filteredChats.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                final unread = (chat['unread'] as int? ?? 0);
                                final studentName =
                                    (chat['company']
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true)
                                        ? chat['company'].toString().trim()
                                        : 'Student';
                                final contextInfo =
                                    chat['supervisor']?.toString().trim() ?? '';
                                final projectTitle =
                                    chat['projectTitle']?.toString().trim() ??
                                        '';
                                final subtitleLine = projectTitle.isNotEmpty
                                    ? projectTitle
                                    : (contextInfo != studentName
                                          ? contextInfo
                                          : 'Project Discussion');
                                final lastMsg =
                                    chat['lastMessage']?.toString().trim() ??
                                        '';
                                final time =
                                    chat['time']?.toString().trim() ?? '';

                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      final convId =
                                          chat['id']?.toString() ?? '';
                                      AppDataService.instance
                                          .markConversationRead(convId);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              _CompanyChatDetailScreen(
                                                conversationId: convId,
                                                initialChat: chat,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: unread > 0
                                              ? AppColors.primaryBlue
                                                  .withValues(alpha: 0.4)
                                              : AppColors.lightGray,
                                        ),
                                        boxShadow: AppColors.softShadow,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: unread > 0
                                                  ? AppColors.primaryBlue
                                                      .withValues(alpha: 0.12)
                                                  : AppColors.lightAqua,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Center(
                                              child: Text(
                                                SupabaseHelper.initialsFor(
                                                  studentName,
                                                  fallback: 'ST',
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primaryBlue,
                                                  fontSize: 14.5,
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
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        studentName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .deepNavy,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      time,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: unread > 0
                                                            ? AppColors
                                                                .primaryBlue
                                                            : AppColors
                                                                .textMuted,
                                                        fontWeight: unread > 0
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (subtitleLine.isNotEmpty) ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    subtitleLine,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      color:
                                                          AppColors.primaryBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 3),
                                                Text(
                                                  lastMsg.isNotEmpty
                                                      ? lastMsg
                                                      : 'Tap to send a message',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.5,
                                                    color: unread > 0
                                                        ? AppColors.darkText
                                                        : AppColors.grayText,
                                                    fontWeight: unread > 0
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (unread > 0) ...[
                                            const SizedBox(width: 10),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryBlue,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                unread > 99
                                                    ? '99+'
                                                    : '$unread',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
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

class _CompanyChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> initialChat;

  const _CompanyChatDetailScreen({
    required this.conversationId,
    required this.initialChat,
  });

  @override
  State<_CompanyChatDetailScreen> createState() =>
      _CompanyChatDetailScreenState();
}

class _CompanyChatDetailScreenState extends State<_CompanyChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    AppDataService.instance.markConversationRead(widget.conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    if (quickText == null) {
      _messageController.clear();
    }

    setState(() => _isSending = true);
    await AppDataService.instance.sendChatMessage(
      conversationId: widget.conversationId,
      text: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService.instance,
      builder: (context, _) {
        final conv =
            AppDataService.instance.getConversation(widget.conversationId) ??
                widget.initialChat;
        final studentName =
            (conv['company']?.toString().trim().isNotEmpty == true)
                ? conv['company'].toString().trim()
                : 'Student';
        final projectTitle = conv['projectTitle']?.toString().trim() ?? '';
        final contextMeta = conv['supervisor']?.toString().trim() ?? '';
        final subtitle = projectTitle.isNotEmpty
            ? projectTitle
            : (contextMeta != studentName ? contextMeta : 'Corporate Messaging');

        final rawMessages = conv['messages'] as List? ?? [];
        final messages = rawMessages
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CompanyExecutiveAppBar(
            title: studentName,
            subtitle: subtitle,
            leadingBadge: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  SupabaseHelper.initialsFor(studentName, fallback: 'ST'),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No messages yet. Introduce your team or share project expectations!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: AppColors.grayText,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg['isMe'] == true;
                              final senderName =
                                  msg['sender']?.toString() ??
                                  (isMe ? 'You' : studentName);

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 11,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.76,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primaryBlue
                                        : AppColors.cardWhite,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMe ? 16 : 2,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 2 : 16,
                                      ),
                                    ),
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color: AppColors.lightGray,
                                          ),
                                    boxShadow: isMe ? null : AppColors.softShadow,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 3,
                                          ),
                                          child: Text(
                                            senderName,
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.teal,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        msg['text']?.toString() ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          color: isMe
                                              ? Colors.white
                                              : AppColors.darkText,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg['time']?.toString() ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : AppColors.grayText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildQuickAction('Thanks for applying!'),
                        const SizedBox(width: 8),
                        _buildQuickAction(
                          'Please share your milestone update',
                        ),
                        const SizedBox(width: 8),
                        _buildQuickAction('Great work on this submission'),
                        const SizedBox(width: 8),
                        _buildQuickAction('Can we schedule a brief review?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      border: const Border(
                        top: BorderSide(color: AppColors.lightGray),
                      ),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Write a message to candidate...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSending ? null : () => _sendMessage(),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: _isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 19,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildQuickAction(String label) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _sendMessage(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.deepNavy,
            ),
          ),
        ),
      ),
    );
  }
}

