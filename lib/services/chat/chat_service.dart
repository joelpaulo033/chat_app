import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a consistent chatId for 1-on-1 chats
  String getChatId(String senderID, String receiverID) {
    return senderID.compareTo(receiverID) > 0
        ? '$receiverID-$senderID'
        : '$senderID-$receiverID';
  }

  // Send a message
  Future<void> sendMessage(String receiverID, String message) async {
    final senderID = _auth.currentUser!.uid;
    final chatId = getChatId(senderID, receiverID);

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String receiverID) {
    final senderID = _auth.currentUser!.uid;
    final chatId = getChatId(senderID, receiverID);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Clear all messages
  Future<void> clearChat(String receiverID) async {
    final senderID = _auth.currentUser!.uid;
    final chatId = getChatId(senderID, receiverID);

    final query = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Delete selected messages
  Future<void> deleteSelectedMessages(List<String> messageIds, String receiverID) async {
    final senderID = _auth.currentUser!.uid;
    final chatId = getChatId(senderID, receiverID);

    for (var id in messageIds) {
      final docRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(id);
      final doc = await docRef.get();
      if (doc.exists && doc.data()!['senderId'] == senderID) {
        await docRef.delete();
      }
    }
  }
}
