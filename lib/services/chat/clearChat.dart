import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a message
  Future<void> sendMessage(String receiverID, String message) async {
    final senderID = _auth.currentUser!.uid;
    await _firestore.collection('chats').add({
      'senderId': senderID,
      'receiverId': receiverID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get messages between current user and receiver
  Stream<QuerySnapshot> getMessages(String receiverID, String senderID) {
    return _firestore
        .collection('chats')
        .where('senderId', whereIn: [senderID, receiverID])
        .where('receiverId', whereIn: [senderID, receiverID])
        .orderBy('timestamp', descending: false) // new messages at bottom
        .snapshots();
  }

  // Clear all chat messages between current user and receiver
  Future<void> clearChat(String receiverID) async {
    final senderID = _auth.currentUser!.uid;

    final query = await _firestore
        .collection('chats')
        .where('senderId', whereIn: [senderID, receiverID])
        .where('receiverId', whereIn: [senderID, receiverID])
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }
}
