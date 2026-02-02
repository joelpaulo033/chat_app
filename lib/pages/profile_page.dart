import 'dart:io';

import 'package:chat_app/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = AuthService().getCurrentUser();
  final ImagePicker _picker = ImagePicker();

  // Local user data
  String displayName = 'Loading...';
  String email = 'Loading...';
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  // Load user details from Firestore
  Future<void> _loadUserDetails() async {
    if (currentUser == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final data = snapshot.data();
    if (data != null) {
      setState(() {
        displayName = data['displayName']?.trim().isEmpty == true
            ? data['email'] ?? 'No Name'
            : data['displayName'];
        email = data['email'] ?? 'No Email';
        profilePhotoUrl = data['profilePhotoUrl'];
      });
    }
  }

  // Pick and upload profile image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && currentUser != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
      FirebaseStorage.instance.ref().child('profile_images/$fileName');

      await reference.putFile(File(image.path));
      String newPhotoUrl = await reference.getDownloadURL();

      // Update Firestore
      await AuthService().updateProfilePhoto(currentUser!.uid, newPhotoUrl);

      // Optional: update FirebaseAuth photoURL
      await currentUser!.updatePhotoURL(newPhotoUrl);

      // Update UI immediately
      setState(() {
        profilePhotoUrl = newPhotoUrl;
      });
    }
  }

  // Edit display name with validation
  Future<void> _editDisplayName() async {
    String newDisplayName = displayName;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          onChanged: (value) {
            newDisplayName = value;
          },
          decoration:
          const InputDecoration(hintText: "Enter new display name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (currentUser != null) {
                // Trim whitespace and fallback to email if empty
                newDisplayName = newDisplayName.trim();
                if (newDisplayName.isEmpty) {
                  newDisplayName = email;
                }

                // Update Firestore
                await AuthService()
                    .updateDisplayName(currentUser!.uid, newDisplayName);

                // Update local state
                setState(() {
                  displayName = newDisplayName;
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundImage: (profilePhotoUrl != null &&
                      profilePhotoUrl!.isNotEmpty)
                      ? NetworkImage(profilePhotoUrl!)
                      : null,
                  child: (profilePhotoUrl == null || profilePhotoUrl!.isEmpty)
                      ? const Icon(
                    Icons.person,
                    size: 64,
                  )
                      : null,
                ),
                Positioned(
                  bottom: -10,
                  left: 80,
                  child: IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Display Name
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Email
            Text(
              email,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Edit Display Name Button
            ElevatedButton(
              onPressed: _editDisplayName,
              child: const Text('Edit Display Name'),
            ),
          ],
        ),
      ),
    );
  }
}
