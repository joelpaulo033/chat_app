import 'package:chat_app/components/chat_bubble.dart'; 
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String? receiverDisplayName;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    this.receiverDisplayName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _selectionMode = false;
  final Set<String> _selectedMessageIds = {};

  String get displayName => (widget.receiverDisplayName?.trim().isEmpty ?? true)
      ? widget.receiverEmail
      : widget.receiverDisplayName!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.darkVolcanoGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildMessageList()),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- APP BAR ----------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        displayName,
        style:
            const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: _openDeleteOptions,
        ),
      ],
    );
  }

  // ---------------- MESSAGE LIST ----------------
  Widget _buildMessageList() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getMessages(currentUserId, widget.receiverID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text('No messages yet',
                style: TextStyle(color: Colors.white70)),
          );
        }

        // Scroll to bottom after frame
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
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildMessageItem(docs[i]),
        );
      },
    );
  }

  // ---------------- MESSAGE ITEM ----------------
  Widget _buildMessageItem(DocumentSnapshot doc) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderID'] == authService.getCurrentUser()!.uid;
    final time = data['timestamp'] != null
        ? DateFormat('h:mm a').format((data['timestamp'] as Timestamp).toDate())
        : '';

    final isSelected = _selectedMessageIds.contains(doc.id);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _selectionMode = true;
          _selectedMessageIds.add(doc.id);
        });
      },
      onTap: () {
        if (_selectionMode) {
          setState(() {
            if (_selectedMessageIds.contains(doc.id)) {
              _selectedMessageIds.remove(doc.id);
              if (_selectedMessageIds.isEmpty) _selectionMode = false;
            } else {
              _selectedMessageIds.add(doc.id);
            }
          });
        }
      },
      child: Container(
        color: isSelected ? AppTheme.gold.withValues(alpha: 0.3) : Colors.transparent,
        child: ChatBubble(
          message: data['message'],
          isCurrentUser: isMe,
          time: time,
        ),
      ),
    );
  }

  // ---------------- INPUT ----------------
  Widget _buildInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black.withValues(alpha: 0.1),
        child: Row(
          children: [
            Expanded(
              child: MyTextField(
                controller: _messageController,
                hintText: 'Message',
                obscureText: false,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SEND ----------------
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.sendMessage(
      widget.receiverID,
      _messageController.text.trim(),
    );

    _messageController.clear();
  }

  // ---------------- DELETE OPTIONS ----------------
  void _openDeleteOptions() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete all messages'),
            onTap: () async {
              Navigator.pop(context);
              await chatService.clearChat(widget.receiverID);
            },
          ),
          if (_selectedMessageIds.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.orange),
              title: const Text('Delete selected messages'),
              onTap: () async {
                Navigator.pop(context);
                await chatService.deleteSelectedMessages(
                    _selectedMessageIds.toList(), widget.receiverID);
                setState(() {
                  _selectedMessageIds.clear();
                  _selectionMode = false;
                });
              },
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
