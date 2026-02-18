import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- SEND MESSAGE ----------------
  Future<void> sendMessage(String receiverID, String message) async {
    final senderID = _auth.currentUser!.uid;
    await _firestore.collection('chats').add({
      'senderId': senderID,
      'receiverId': receiverID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- GET MESSAGES ----------------
  Stream<QuerySnapshot> getMessages(String receiverID, String senderID) {
    return _firestore
        .collection('chats')
        .where('senderId', whereIn: [senderID, receiverID])
        .where('receiverId', whereIn: [senderID, receiverID])
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ---------------- CLEAR CHAT ----------------
  Future<void> clearChat(String receiverID) async {
    final senderID = _auth.currentUser!.uid;

    // Get all messages between current user and receiver
    final query = await _firestore
        .collection('chats')
        .where('senderId', whereIn: [senderID, receiverID])
        .where('receiverId', whereIn: [senderID, receiverID])
        .get();

    // Use batch delete for efficiency
    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
