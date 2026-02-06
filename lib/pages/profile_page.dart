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

  String displayName = 'Loading...';
  String email = 'Loading...';
  String? profilePhotoUrl;

  final List<Color> volcanoColors = [
    const Color(0xFFFF4500),
    const Color(0xFFFF6347),
    const Color(0xFFFF8C00),
    const Color(0xFFFFD700),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    if (currentUser == null) return;
    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
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

  Future<void> _showMessage(String message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && currentUser != null) {
      try {
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

        _showMessage("Profile photo updated successfully!");
      } catch (e) {
        _showMessage("Failed to update profile photo: $e");
      }
    }
  }

  Future<void> _editDisplayName() async {
    String newDisplayName = displayName;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          onChanged: (value) => newDisplayName = value,
          decoration: const InputDecoration(hintText: "Enter new display name"),
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

                try {
                  await AuthService()
                      .updateDisplayName(currentUser!.uid, newDisplayName);

                  setState(() {
                    displayName = newDisplayName;
                  });

                  Navigator.pop(context);
                  _showMessage("Display name updated successfully!");
                } catch (e) {
                  _showMessage("Failed to update display name: $e");
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    String currentPassword = '';
    String newPassword = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              onChanged: (value) => currentPassword = value,
              decoration: const InputDecoration(hintText: "Current Password"),
            ),
            const SizedBox(height: 10),
            TextField(
              obscureText: true,
              onChanged: (value) => newPassword = value,
              decoration: const InputDecoration(hintText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                // Re-authenticate user
                final cred = EmailAuthProvider.credential(
                  email: currentUser!.email!,
                  password: currentPassword,
                );
                await currentUser!.reauthenticateWithCredential(cred);

                await currentUser!.updatePassword(newPassword);
                Navigator.pop(context);
                _showMessage("Password updated successfully!");
              } catch (e) {
                _showMessage("Failed to update password: $e");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      _showMessage("Logged out successfully!");
      // Navigate to login page or landing page
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showMessage("Logout failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: volcanoColors.map((c) => c.withOpacity(0.9)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundImage: (profilePhotoUrl != null &&
                              profilePhotoUrl!.isNotEmpty)
                              ? NetworkImage(profilePhotoUrl!)
                              : null,
                          backgroundColor: Colors.orangeAccent,
                          child: (profilePhotoUrl == null ||
                              profilePhotoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 65, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: volcanoColors[0],
                          radius: 20,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                            onPressed: _pickImage,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Display Name
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: volcanoColors,
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Edit Name Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: volcanoColors[0],
                      shadowColor: Colors.black45,
                      elevation: 5,
                    ),
                    onPressed: _editDisplayName,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Name',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Change Password & Logout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline, color: Colors.white),
                          title: const Text(
                            'Change Password',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          onTap: _changePassword,
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.white),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
