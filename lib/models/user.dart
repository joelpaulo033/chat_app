import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final bool isOnline;
  final Timestamp? lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    this.isOnline = false,
    this.lastSeen,
  });

  // factory user fromMap
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'],
    );
  }

  // user toMap
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }
}
