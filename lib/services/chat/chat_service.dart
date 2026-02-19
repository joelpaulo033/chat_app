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
  Future<void> sendMessage(String receiverID, String message,
      {bool isGroup = false}) async {
    final senderID = _auth.currentUser!.uid;
    final chatId = isGroup ? receiverID : getChatId(senderID, receiverID);

    final timestamp = FieldValue.serverTimestamp();

    // Add message to sub-collection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderID,
      'message': message,
      'timestamp': timestamp,
      'isForwarded': false,
    });

    // Prepare update data
    Map<String, dynamic> updateData = {
      'lastMessage': message,
      'lastMessageTimestamp': timestamp,
      'lastSenderId': senderID,
      'isGroup': isGroup,
    };

    // ONLY update participants for 1-on-1 chats
    if (!isGroup) {
      updateData['participants'] =
          FieldValue.arrayUnion([senderID, receiverID]);
    }

    // Update parent chat document with metadata for sorting and previews
    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(updateData, SetOptions(merge: true));
  }

  // Forward a message
  Future<void> forwardMessage(
      String targetChatId, String message, bool isGroup) async {
    final senderID = _auth.currentUser!.uid;
    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('chats')
        .doc(targetChatId)
        .collection('messages')
        .add({
      'senderId': senderID,
      'message': message,
      'timestamp': timestamp,
      'isForwarded': true,
    });

    await _firestore.collection('chats').doc(targetChatId).set({
      'lastMessage': message,
      'lastMessageTimestamp': timestamp,
      'lastSenderId': senderID,
      'isGroup': isGroup,
    }, SetOptions(merge: true));
  }

  // Toggle Favorite
  Future<void> toggleFavorite(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final userRef = _firestore.collection('users').doc(currentUserId);

    final doc = await userRef.get();
    List favorites = doc.data()?['favorites'] ?? [];

    if (favorites.contains(otherUserId)) {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([otherUserId])
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([otherUserId])
      });
    }
  }

  // Create Group
  Future<void> createGroup(String groupName, List<String> memberIds) async {
    final senderID = _auth.currentUser!.uid;
    final members = List<String>.from(memberIds);
    if (!members.contains(senderID)) members.add(senderID);

    final groupRef = await _firestore.collection('chats').add({
      'groupName': groupName,
      'isGroup': true,
      'participants': members,
      'createdBy': senderID,
      'lastMessage': 'Group created',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    // Add a system message
    await groupRef.collection('messages').add({
      'senderId': 'system',
      'message': 'Welcome to $groupName!',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Add Member to Group
  Future<void> addMemberToGroup(String chatId, String memberId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([memberId])
    });
  }

  // Remove Member from Group
  Future<void> removeMemberFromGroup(String chatId, String memberId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([memberId])
    });
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String chatID, bool isGroup) {
    final senderID = _auth.currentUser!.uid;
    final id = isGroup ? chatID : getChatId(senderID, chatID);

    return _firestore
        .collection('chats')
        .doc(id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Clear all messages
  Future<void> clearChat(String chatID, bool isGroup) async {
    final senderID = _auth.currentUser!.uid;
    final id = isGroup ? chatID : getChatId(senderID, chatID);

    final query = await _firestore
        .collection('chats')
        .doc(id)
        .collection('messages')
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Delete selected messages
  Future<void> deleteSelectedMessages(
      List<String> messageIds, String chatID, bool isGroup) async {
    final senderID = _auth.currentUser!.uid;
    final id = isGroup ? chatID : getChatId(senderID, chatID);

    for (var messageId in messageIds) {
      final docRef = _firestore
          .collection('chats')
          .doc(id)
          .collection('messages')
          .doc(messageId);
      final doc = await docRef.get();
      if (doc.exists && doc.data()!['senderId'] == senderID) {
        await docRef.delete();
      }
    }
  }
}
