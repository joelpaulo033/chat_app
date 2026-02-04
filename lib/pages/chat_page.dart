import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _chatService = ChatService();
  final _authService = AuthService();

  bool _selectionMode = false;
  Set<String> _selectedMessageIds = {};

  String get displayName =>
      (widget.receiverDisplayName?.trim().isEmpty ?? true)
          ? widget.receiverEmail
          : widget.receiverDisplayName!;

  // Volcano Fire colors - darker shades for readability
  final List<Color> volcanoColors = [
    const Color(0xFFB22222), // FireBrick
    const Color(0xFFFF4500), // OrangeRed
    const Color(0xFFFF8C00), // DarkOrange
    const Color(0xFFFFD700), // Gold
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: volcanoColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text('No messages yet', style: TextStyle(color: Colors.white70)),
          );
        }

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
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _authService.getCurrentUser()!.uid;
    final time = data['timestamp'] != null
        ? DateFormat('h:mm a').format((data['timestamp'] as Timestamp).toDate())
        : '';

    final isSelected = _selectedMessageIds.contains(doc.id);

    // Colors for messages
    final myMessageColor = const Color(0xFFFF6347); // Tomato
    final receivedMessageColor = Colors.white; // high contrast on gradient
    final selectedColor = const Color(0xFFFFA500).withOpacity(0.7); // DarkOrange semi-transparent

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
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor
                    : (isMe ? myMessageColor : receivedMessageColor),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isMe)
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  if (!isMe)
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                ],
              ),
              child: Text(
                data['message'],
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------- INPUT ----------------
  Widget _buildInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white.withOpacity(0.1),
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

    await _chatService.sendMessage(
      widget.receiverID,
      _messageController.text.trim(),
    );

    _messageController.clear();
  }

  // ---------------- DELETE OPTIONS ----------------
  void _openDeleteOptions() {
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
              await _chatService.clearChat(widget.receiverID);
            },
          ),
          if (_selectedMessageIds.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.orange),
              title: const Text('Delete selected messages'),
              onTap: () async {
                Navigator.pop(context);
                await _chatService.deleteSelectedMessages(
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
