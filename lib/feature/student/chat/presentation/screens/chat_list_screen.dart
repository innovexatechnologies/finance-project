import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/core/widgets/executive_ui.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Future<void> _showNewMessageDialog() async {
    final contacts =
        await AppDataService.instance.fetchAvailableChatContacts();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Start New Conversation',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect directly with registered partners and applicants.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.grayText),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: contacts.isEmpty
                    ? Center(
                        child: Text(
                          'No available contacts found yet. Apply to projects or sync your workspace first.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        itemCount: contacts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final c = contacts[index];
                          final name =
                              c['companyName']?.toString() ?? 'Partner';
                          final sup = c['supervisorName']?.toString() ?? '';
                          final subtitle = [
                            if (sup.isNotEmpty && sup != name) sup,
                            if ((c['industry']?.toString() ?? '').isNotEmpty)
                              c['industry'].toString(),
                          ].join(' • ');

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightAqua,
                              child: Text(
                                SupabaseHelper.initialsFor(name, fallback: 'CC'),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (c['isVerified'] == true) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded,
                                      size: 14, color: AppColors.teal),
                                ],
                              ],
                            ),
                            subtitle: subtitle.isNotEmpty
                                ? Text(subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 12))
                                : null,
                            trailing: const Icon(Icons.send_rounded,
                                size: 18, color: AppColors.primaryBlue),
                            onTap: () async {
                              Navigator.pop(sheetCtx);
                              final convId = await AppDataService.instance
                                  .openOrCreateConversation(
                                companyName: name,
                                peerUserId: c['userId']?.toString(),
                                supervisorName: sup,
                              );
                              if (!mounted) return;
                              final conv = AppDataService.instance
                                  .getConversation(convId);
                              if (conv != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _ChatDetailScreen(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ExecutiveAppBar(
        title: 'Messages',
        subtitle: 'Company & Project Threads',
        showLeading: Navigator.canPop(context),
        actions: [
          ExecutiveHeaderIconButton(
            tooltip: 'Sync Messages',
            icon: Icons.refresh_rounded,
            onPressed: () =>
                AppDataService.instance.syncFromSupabase(forceRefresh: true),
          ),
          const SizedBox(width: 8),
          ExecutiveHeaderPillButton(
            label: 'New',
            icon: Icons.add_comment_rounded,
            filled: true,
            onPressed: _showNewMessageDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataService.instance,
        builder: (context, _) {
          final chats = AppDataService.instance.getConversations();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () => AppDataService.instance
                    .syncFromSupabase(forceRefresh: true),
                child: chats.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 48),
                          AppEmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'No Conversations Yet',
                            subtitle:
                                'Start a direct conversation with a verified partner company or student contributor.',
                            actionLabel: 'Start Conversation',
                            actionIcon: Icons.add_comment_rounded,
                            onAction: _showNewMessageDialog,
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: chats.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final unread = (chat['unread'] as int? ?? 0);
                          final companyName =
                              (chat['company']?.toString().trim().isNotEmpty ==
                                      true)
                                  ? chat['company'].toString().trim()
                                  : 'Partner';
                          final supervisor =
                              chat['supervisor']?.toString().trim() ??
                                  'Contact';
                          final lastMsg =
                              chat['lastMessage']?.toString().trim() ?? '';
                          final time = chat['time']?.toString().trim() ?? '';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: unread > 0
                                    ? AppColors.primaryBlue
                                        .withValues(alpha: 0.35)
                                    : AppColors.lightGray,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.lightAqua,
                                child: Text(
                                  SupabaseHelper.initialsFor(
                                    companyName,
                                    fallback: 'CC',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      companyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: unread > 0
                                          ? AppColors.primaryBlue
                                          : AppColors.grayText,
                                      fontWeight: unread > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supervisor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastMsg.isNotEmpty
                                        ? lastMsg
                                        : 'Tap to send a message',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: unread > 0
                                          ? AppColors.darkText
                                          : AppColors.grayText,
                                      fontWeight: unread > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: unread > 0
                                  ? Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                final convId = chat['id']?.toString() ?? '';
                                AppDataService.instance
                                    .markConversationRead(convId);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _ChatDetailScreen(
                                      conversationId: convId,
                                      initialChat: chat,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> initialChat;

  const _ChatDetailScreen({
    required this.conversationId,
    required this.initialChat,
  });

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    AppDataService.instance.setActiveConversation(widget.conversationId);
    AppDataService.instance.markConversationRead(widget.conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    AppDataService.instance.setActiveConversation(null);
    AppDataService.instance.markConversationRead(widget.conversationId);
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
        final companyName = conv['company']?.toString() ?? 'Partner';
        final supervisor = conv['supervisor']?.toString() ?? 'Contact';
        final rawMessages = conv['messages'] as List? ?? [];
        final messages = rawMessages
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ExecutiveAppBar(
            title: companyName,
            subtitle: supervisor,
            leadingBadge: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  SupabaseHelper.initialsFor(companyName, fallback: 'CO'),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No messages yet. Say hello to start collaborating!',
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
                          final senderName = msg['sender']?.toString() ??
                              (isMe ? 'You' : supervisor);

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primaryBlue
                                    : AppColors.cardWhite,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(color: AppColors.lightGray),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        senderName,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    msg['text']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
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
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickAction('Work submitted for review 👍'),
                    const SizedBox(width: 8),
                    _buildQuickAction('Reviewing instructions now'),
                    const SizedBox(width: 8),
                    _buildQuickAction('Thank you for the update!'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  boxShadow: AppColors.softShadow,
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Write a message...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        onPressed: _isSending ? null : () => _sendMessage(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(String label) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.deepNavy),
      ),
      backgroundColor: AppColors.lightAqua.withValues(alpha: 0.5),
      side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: () => _sendMessage(label),
    );
  }
}
