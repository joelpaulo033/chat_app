import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/storage/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final StorageService _storageService = StorageService();

  String displayName = 'Loading...';
  String email = 'Loading...';
  String? profilePhotoUrl;

  bool isUploading = false;
  double uploadProgress = 0.0;

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
    if (data != null && mounted) {
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

  // ✅ Refined cross-platform image upload using StorageService
  Future<void> _pickImage() async {
    if (currentUser == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      setState(() {
        isUploading = true;
        uploadProgress = 0.0;
      });

      // Use the centralized StorageService
      final String newPhotoUrl = await _storageService.uploadProfileImage(
        image: image,
        uid: currentUser!.uid,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              uploadProgress = progress;
            });
          }
        },
      );

      // Update Firestore and Local User Profile
      await AuthService().updateProfilePhoto(currentUser!.uid, newPhotoUrl);
      await currentUser!.updatePhotoURL(newPhotoUrl);

      if (!mounted) return;

      setState(() {
        profilePhotoUrl = newPhotoUrl;
        isUploading = false;
      });

      _showMessage("Profile photo updated successfully!");
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
      _showMessage("Failed to update profile photo: $e");
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
              if (currentUser == null) return;

              newDisplayName = newDisplayName.trim();
              if (newDisplayName.isEmpty) newDisplayName = email;

              try {
                await AuthService()
                    .updateDisplayName(currentUser!.uid, newDisplayName);

                if (!context.mounted) return;

                setState(() {
                  displayName = newDisplayName;
                });

                Navigator.pop(context);
                _showMessage("Name updated successfully!");
              } catch (e) {
                if (!context.mounted) return;
                _showMessage("Failed to update name: $e");
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
                final cred = EmailAuthProvider.credential(
                  email: currentUser!.email!,
                  password: currentPassword,
                );

                await currentUser!.reauthenticateWithCredential(cred);
                await currentUser!.updatePassword(newPassword);

                if (!context.mounted) return;

                Navigator.pop(context);
                _showMessage("Password updated successfully!");
              } catch (e) {
                if (!context.mounted) return;
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: profilePhotoUrl != null &&
                          profilePhotoUrl!.isNotEmpty
                          ? Image.network(
                        profilePhotoUrl!,
                        key: ValueKey(profilePhotoUrl), // Force refresh
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("❌ Profile Image Error: $error");
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person,
                                size: 70, color: Colors.grey),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person,
                            size: 70, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ Progress Indicator for upload
              if (isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: uploadProgress),
                      const SizedBox(height: 6),
                      Text("${(uploadProgress * 100).toStringAsFixed(0)}%"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              Text(displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(email),
              const SizedBox(height: 30),

              // Theme
              ListTile(
                leading: Icon(themeProvider.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode),
                title: const Text("Theme"),
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      themeProvider.setThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text("System")),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text("Light")),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text("Dark")),
                  ],
                ),
              ),

              // Profile actions
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Edit Name"),
                onTap: _editDisplayName,
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Change Password"),
                onTap: _changePassword,
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                const Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
