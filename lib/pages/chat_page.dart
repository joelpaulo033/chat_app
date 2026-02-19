import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String receiverDisplayName;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    required this.receiverDisplayName, required bool isGroup,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _typingTimer;
  bool _isTyping = false;

  String getChatId(String a, String b) {
    return a.compareTo(b) > 0 ? '$b-$a' : '$a-$b';
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final senderId = _auth.currentUser!.uid;
    final chatId = getChatId(senderId, widget.receiverID);

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'receiverId': widget.receiverID,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _stopTyping();
  }

  void _startTyping() {
    if (_isTyping) return;

    _isTyping = true;
    final chatId = getChatId(_auth.currentUser!.uid, widget.receiverID);

    _firestore.collection('chats').doc(chatId).set({
      'typing': {_auth.currentUser!.uid: true}
    }, SetOptions(merge: true));

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _isTyping = false;
    final chatId = getChatId(_auth.currentUser!.uid, widget.receiverID);

    _firestore.collection('chats').doc(chatId).set({
      'typing': {_auth.currentUser!.uid: false}
    }, SetOptions(merge: true));
  }

  Stream<bool> _listenTyping() {
    final chatId = getChatId(_auth.currentUser!.uid, widget.receiverID);

    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null || data['typing'] == null) return false;
      final typingMap = Map<String, dynamic>.from(data['typing']);
      return typingMap[widget.receiverID] == true;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingTimer?.cancel();
    _stopTyping();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;
    final chatId = getChatId(currentUserId, widget.receiverID);

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverDisplayName)),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Typing indicator
          StreamBuilder<bool>(
            stream: _listenTyping(),
            builder: (context, snapshot) {
              final isTyping = snapshot.data == true;
              return isTyping
                  ? const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  "Typing...",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              )
                  : const SizedBox.shrink();
            },
          ),

          // Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (_) => _startTyping(),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
