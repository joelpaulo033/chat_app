import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  // Firebase instances
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================= GET CURRENT USER =================
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// ================= SIGN IN =================
  Future<UserCredential> signInWithEmailandPassword(
      String email, String password) async {
    try {
      // Sign in with email and password.
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Ensure user document exists with token
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fcmToken': fcmToken, // Store token
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  /// ================= SIGN UP =================
  Future<UserCredential> signUpWithEmailandPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Create a new document for the user in the 'users' collection.
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': email.split('@')[0], // Default display name
        'profilePhotoUrl': '', // Initially empty profile photo
        'fcmToken': fcmToken, // Store token
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// ================= FORGOT PASSWORD =================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  /// ================= SIGN OUT =================
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// ================= USERS STREAM =================
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// ================= UPDATE DISPLAY NAME =================
  Future<void> updateDisplayName(String uid, String newDisplayName) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': newDisplayName,
    });
  }

  /// ================= UPDATE PROFILE PHOTO =================
  Future<void> updateProfilePhoto(String uid, String newPhotoUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'profilePhotoUrl': newPhotoUrl,
    });
  }

  /// ================= AUTH ERROR HANDLER =================
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Invalid email address.";
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'weak-password':
        return "Password should be at least 6 characters.";
      case 'network-request-failed':
        return "Check your internet connection.";
      default:
        return e.message ?? "Authentication error occurred.";
    }
  }
}
