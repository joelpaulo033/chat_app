import 'dart:io';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  String displayName = 'Loading...';
  String email = 'Loading...';
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
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

  Future<void> _showMessage(String message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickImage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && user != null) {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference reference =
            FirebaseStorage.instance.ref().child('profile_images/$fileName');

        await reference.putFile(File(image.path));
        String newPhotoUrl = await reference.getDownloadURL();

        await authService.updateProfilePhoto(user.uid, newPhotoUrl);
        await user.updatePhotoURL(newPhotoUrl);

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
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
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
              if (user != null) {
                newDisplayName = newDisplayName.trim();
                if (newDisplayName.isEmpty) newDisplayName = email;

                try {
                  await authService.updateDisplayName(user.uid, newDisplayName);

                  setState(() {
                    displayName = newDisplayName;
                  });

                  if (!context.mounted) return;
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    if (user == null) return;

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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                final cred = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword,
                );
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newPassword);
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
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      _showMessage("Logged out successfully!");
      if (!context.mounted) return;
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
        decoration: AppTheme.darkVolcanoGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
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
                          backgroundColor: AppTheme.orangeRed,
                          child: (profilePhotoUrl == null ||
                                  profilePhotoUrl!.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 65, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.orangeRed,
                          radius: 20,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_a_photo,
                                color: Colors.white, size: 20),
                            onPressed: _pickImage,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: AppTheme.volcanoColors,
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
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
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: AppTheme.orangeRed,
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline,
                              color: Colors.white),
                          title: const Text(
                            'Change Password',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 16),
                          onTap: _changePassword,
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.logout, color: Colors.white),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 16),
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
