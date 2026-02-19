import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupSettingsPage extends StatefulWidget {
  final String chatId;
  final String groupName;

  const GroupSettingsPage({
    super.key,
    required this.chatId,
    required this.groupName,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  void _showAddMemberDialog(List<String> currentParticipants) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _authService.getUsersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = _authService.getCurrentUser();
          final users = snapshot.data!
              .where((u) =>
                  u['uid'] != currentUser?.uid &&
                  !currentParticipants.contains(u['uid']))
              .toList();

          return AlertDialog(
            title: const Text("Add Member"),
            content: SizedBox(
              width: double.maxFinite,
              child: users.isEmpty
                  ? const Text("No more users to add.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (user['profilePhotoUrl'] != null &&
                                    user['profilePhotoUrl']
                                        .toString()
                                        .isNotEmpty)
                                ? NetworkImage(user['profilePhotoUrl'])
                                : null,
                            child: (user['profilePhotoUrl'] == null ||
                                    user['profilePhotoUrl'].toString().isEmpty)
                                ? Text(user['displayName']?[0].toUpperCase() ??
                                    '?')
                                : null,
                          ),
                          title: Text(user['displayName'] ?? user['email']),
                          onTap: () {
                            _chatService.addMemberToGroup(
                                widget.chatId, user['uid']);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    "Added ${user['displayName'] ?? user['email']}")));
                          },
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  void _confirmRemoveMember(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Are you sure you want to remove $name from the group?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                _chatService.removeMemberFromGroup(widget.chatId, userId);
                Navigator.pop(context);
              },
              child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);
          final createdBy = data['createdBy'] ?? '';
          final currentUser = _authService.getCurrentUser();
          final isAdmin = currentUser?.uid == createdBy;

          return Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                child: Icon(Icons.group_rounded,
                    size: 50, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(widget.groupName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${participants.length} members",
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                title: const Text("Members",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        onPressed: () => _showAddMemberDialog(participants),
                      )
                    : null,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final userId = participants[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        if (userData == null) return const SizedBox.shrink();

                        final name = userData['displayName'] ??
                            userData['email'] ??
                            'User';
                        final isGroupAdmin = userId == createdBy;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (userData['profilePhotoUrl'] != null &&
                                        userData['profilePhotoUrl']
                                            .toString()
                                            .isNotEmpty)
                                    ? NetworkImage(userData['profilePhotoUrl'])
                                    : null,
                            child: (userData['profilePhotoUrl'] == null ||
                                    userData['profilePhotoUrl']
                                        .toString()
                                        .isEmpty)
                                ? Text(name[0].toUpperCase())
                                : null,
                          ),
                          title: Text(name),
                          subtitle: isGroupAdmin
                              ? const Text("Admin",
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 12))
                              : null,
                          trailing: (isAdmin && userId != currentUser?.uid)
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmRemoveMember(userId, name),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
