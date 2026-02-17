import 'package:chat_app/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a consistent chatId for 1-on-1 chats
  String getChatId(String senderID, String receiverID) {
    List<String> ids = [senderID, receiverID];
    ids.sort();
    return ids.join('-');
  }

  // Send a message
  Future<void> sendMessage(String receiverID, String messageText) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: messageText,
      timestamp: timestamp,
    );

    String chatId = getChatId(currentUserID, receiverID);

    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update parent document for the chats list on HomePage
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUserID, receiverID],
      'lastMessage': messageText,
      'lastTimestamp': timestamp,
    }, SetOptions(merge: true));
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    String chatId = getChatId(userID, otherUserID);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Clear all messages in a chat
  Future<void> clearChat(String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;
    String chatId = getChatId(currentUserID, receiverID);

    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    
    // Also clear the last message preview
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': '',
      'lastTimestamp': null,
    });

    await batch.commit();
  }

  // Delete selected messages
  Future<void> deleteSelectedMessages(List<String> messageIds, String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;
    String chatId = getChatId(currentUserID, receiverID);

    WriteBatch batch = _firestore.batch();
    for (var id in messageIds) {
      batch.delete(_firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(id));
    }
    await batch.commit();
  }
}
