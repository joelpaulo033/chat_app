import 'package:chat_app/pages/group_settings_page.dart';
import 'package:chat_app/components/chat_bubble.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String? receiverDisplayName;
  final bool isGroup;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    this.receiverDisplayName,
    this.isGroup = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _authService = AuthService();

  String get displayName => (widget.receiverDisplayName?.trim().isEmpty ?? true)
      ? widget.receiverEmail
      : widget.receiverDisplayName!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInput(),
        ],
      ),
    );
  }

  // ---------------- APP BAR ----------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: widget.isGroup ? _buildGroupTitle() : _buildUserTitle(),
      actions: [
        if (!widget.isGroup)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_authService.getCurrentUser()!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              bool isFavorite = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                List favorites = data['favorites'] ?? [];
                isFavorite = favorites.contains(widget.receiverID);
              }
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite
                      ? Colors.orange
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                ),
                onPressed: () => _chatService.toggleFavorite(widget.receiverID),
              );
            },
          ),
        if (widget.isGroup)
          IconButton(
            icon: Icon(Icons.info_outline_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsPage(
                    chatId: widget.receiverID,
                    groupName: displayName,
                  ),
                ),
              );
            },
          ),
        IconButton(
          icon: Icon(Icons.more_vert,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6)),
          onPressed: _openDeleteOptions,
        ),
      ],
    );
  }

  Widget _buildUserTitle() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverID)
          .snapshots(),
      builder: (context, snapshot) {
        bool isOnline = false;
        String? profilePhotoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          isOnline = data['isOnline'] ?? false;
          profilePhotoUrl = data['profilePhotoUrl'];
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: (profilePhotoUrl == null ||
                      profilePhotoUrl.isEmpty)
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              backgroundImage:
                  (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                      ? NetworkImage(profilePhotoUrl)
                      : null,
              child: (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
                  ? Icon(Icons.person,
                      color: Theme.of(context).colorScheme.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? "Online" : "Offline",
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline
                            ? Colors.green
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupTitle() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.group_rounded,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              "Group Chat",
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- MESSAGE LIST ----------------
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverID, widget.isGroup),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong...'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No messages yet',
                    style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        // Auto-scroll to bottom on new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildMessageItem(docs[i]),
        );
      },
    );
  }

  // ---------------- MESSAGE ITEM ----------------
  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _authService.getCurrentUser()!.uid;
    final time = data['timestamp'] != null
        ? DateFormat('h:mm a').format((data['timestamp'] as Timestamp).toDate())
        : '';
    final isForwarded = data['isForwarded'] ?? false;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              ChatBubble(
                message: data['message'],
                isCurrentUser: isMe,
                isForwarded: isForwarded,
                onLongPress: () => _onMessageLongPress(doc.id, data['message']),
              ),
            ],
          ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 24, right: 24),
              child: Text(time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ),
        ],
      ),
    );
  }

  void _onMessageLongPress(String messageId, String messageContent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.forward_rounded, color: Colors.blue),
            title: const Text('Forward Message'),
            onTap: () {
              Navigator.pop(context);
              _showForwardDialog(messageContent);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Message'),
            onTap: () async {
              Navigator.pop(context);
              await _chatService.deleteSelectedMessages(
                  [messageId], widget.receiverID, widget.isGroup);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showForwardDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs
              .where((d) => d.id != _authService.getCurrentUser()!.uid)
              .toList();

          return AlertDialog(
            title: const Text("Forward to..."),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (userData['profilePhotoUrl'] != null &&
                              userData['profilePhotoUrl'].toString().isNotEmpty)
                          ? NetworkImage(userData['profilePhotoUrl'])
                          : null,
                      child: (userData['profilePhotoUrl'] == null ||
                              userData['profilePhotoUrl'].toString().isEmpty)
                          ? Text(
                              userData['displayName']?[0].toUpperCase() ?? '?')
                          : null,
                    ),
                    title: Text(userData['displayName'] ?? userData['email']),
                    onTap: () async {
                      final targetChatId = _chatService.getChatId(
                          _authService.getCurrentUser()!.uid, users[index].id);
                      await _chatService.forwardMessage(
                          targetChatId, message, false);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Message forwarded")));
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- INPUT ----------------
  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4500), Color(0xFFFF8C00)],
                  ),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SEND ----------------
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final msg = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(
      widget.receiverID,
      msg,
      isGroup: widget.isGroup,
    );
  }

  // ---------------- DELETE OPTIONS ----------------
  void _openDeleteOptions() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete chat history'),
            onTap: () async {
              Navigator.pop(context);
              await _chatService.clearChat(widget.receiverID, widget.isGroup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
