import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  // Instance of FirebaseAuth to handle authentication.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Instance of FirebaseFirestore to interact with the database.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the currently signed-in user.
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Signs in a user with the given email and password.
  ///
  /// If the user does not exist in the 'users' collection, a new document
  /// will be created for them.
  Future<UserCredential> signInWithEmailandPassword(
      String email, String password) async {
    try {
      // Sign in with email and password.
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // Ensure a document for the user exists in the 'users' collection.
      _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors.
      throw Exception(e.code);
    }
  }

  /// Creates a new user with the given email and password.
  ///
  /// After creating the user, a new document is added to the 'users' collection
  /// with a default display name and an empty profile picture URL.
  Future<UserCredential> signUpWithEmailandPassword(
      String email, String password) async {
    try {
      // Create a new user.
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create a new document for the user in the 'users' collection.
      _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': email.split('@')[0], // Default display name
        'profilePhotoUrl': '' // Initially empty profile photo
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors.
      throw Exception(e.code);
    } catch (e) {
      // Handle other errors.
      throw Exception(e.toString());
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }

  /// Returns a stream of all users from the 'users' collection.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Updates the display name for a given user.
  Future<void> updateDisplayName(String uid, String newDisplayName) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': newDisplayName,
    });
  }

  /// Updates the profile photo URL for a given user.
  Future<void> updateProfilePhoto(String uid, String newPhotoUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'profilePhotoUrl': newPhotoUrl,
    });
  }
}
