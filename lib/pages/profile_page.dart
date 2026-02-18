import 'dart:io';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
        final rawName = data['displayName']?.toString() ?? '';
        displayName = rawName.trim().isEmpty
            ? data['email']?.toString() ?? 'No Name'
            : rawName;
        email = data['email']?.toString() ?? 'No Email';
        profilePhotoUrl = data['profilePhotoUrl']?.toString();
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

                  if (!mounted) return;
                  setState(() {
                    displayName = newDisplayName;
                  });

                  Navigator.pop(context);
                  _showMessage("Names updated successfully!");
                } catch (e) {
                  _showMessage("Failed to update name: $e");
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
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
                if (!mounted) return;
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
      if (!mounted) return;
      _showMessage("Logged out successfully!");
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showMessage("Logout failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      backgroundImage: (profilePhotoUrl != null &&
                              profilePhotoUrl!.isNotEmpty)
                          ? NetworkImage(profilePhotoUrl!)
                          : null,
                      child:
                          (profilePhotoUrl == null || profilePhotoUrl!.isEmpty)
                              ? Icon(Icons.person,
                                  size: 70,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 20,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),

              // Display Name
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                email,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // Account Controls
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    // Theme Toggle
                    _buildThemeTile(),
                    _buildDivider(),
                    _buildProfileOption(
                      icon: Icons.person_outline,
                      title: "Edit Name",
                      onTap: _editDisplayName,
                    ),
                    _buildDivider(),
                    _buildProfileOption(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: _changePassword,
                    ),
                    _buildDivider(),
                    _buildProfileOption(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: _logout,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListTile(
      leading: Icon(
        themeProvider.isDarkMode
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text(
        "App Theme",
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        themeProvider.themeMode == ThemeMode.system
            ? "Following System"
            : (themeProvider.isDarkMode ? "Dark Mode" : "Light Mode"),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: DropdownButton<ThemeMode>(
        value: themeProvider.themeMode,
        underline: const SizedBox(),
        onChanged: (ThemeMode? newMode) {
          if (newMode != null) {
            themeProvider.setThemeMode(newMode);
          }
        },
        items: const [
          DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
          DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
          DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? Colors.red
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
    );
  }
}
