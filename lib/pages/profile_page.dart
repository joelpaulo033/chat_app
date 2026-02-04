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

  // Volcano Fire colors
  final List<Color> volcanoColors = [
    Color(0xFFFF4500), // OrangeRed
    Color(0xFFFF6347), // Tomato
    Color(0xFFFF8C00), // DarkOrange
    Color(0xFFFFD700), // Gold
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && currentUser != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
      FirebaseStorage.instance.ref().child('profile_images/$fileName');

      await reference.putFile(File(image.path));
      String newPhotoUrl = await reference.getDownloadURL();

      await AuthService().updateProfilePhoto(currentUser!.uid, newPhotoUrl);
      await currentUser!.updatePhotoURL(newPhotoUrl);

      setState(() {
        profilePhotoUrl = newPhotoUrl;
      });
    }
  }

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
                newDisplayName = newDisplayName.trim();
                if (newDisplayName.isEmpty) newDisplayName = email;

                await AuthService()
                    .updateDisplayName(currentUser!.uid, newDisplayName);

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: volcanoColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
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
                        backgroundColor: Colors.orangeAccent,
                        child: (profilePhotoUrl == null || profilePhotoUrl!.isEmpty)
                            ? const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: -10,
                        left: 80,
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Display Name
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: volcanoColors,
                        ).createShader(Rect.fromLTWH(0, 0, 200, 50)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),

                  // Edit Display Name Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: volcanoColors[0], // OrangeRed
                    ),
                    onPressed: _editDisplayName,
                    child: const Text(
                      'Edit Display Name',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
