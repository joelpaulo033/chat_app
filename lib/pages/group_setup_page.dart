import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class GroupSetupPage extends StatefulWidget {
  const GroupSetupPage({super.key});

  @override
  State<GroupSetupPage> createState() => _GroupSetupPageState();
}

class _GroupSetupPageState extends State<GroupSetupPage> {
  final _groupNameController = TextEditingController();
  final _authService = AuthService();
  final _chatService = ChatService();
  final Set<String> _selectedUserIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text("CREATE",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.group_rounded),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Participants",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _authService.getUsersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUser = _authService.getCurrentUser();
                final users = snapshot.data!
                    .where((u) => u['uid'] != currentUser?.uid)
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUserIds.contains(user['uid']);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedUserIds.add(user['uid']);
                          } else {
                            _selectedUserIds.remove(user['uid']);
                          }
                        });
                      },
                      title: Text(user['displayName'] ?? user['email']),
                      secondary: CircleAvatar(
                        backgroundImage: (user['profilePhotoUrl'] != null &&
                                user['profilePhotoUrl'].toString().isNotEmpty)
                            ? NetworkImage(user['profilePhotoUrl'])
                            : null,
                        child: (user['profilePhotoUrl'] == null ||
                                user['profilePhotoUrl'].toString().isEmpty)
                            ? Text(user['displayName']?[0].toUpperCase() ?? '?')
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a group name")));
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select at least one participant")));
      return;
    }

    await _chatService.createGroup(name, _selectedUserIds.toList());
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Group '$name' created!")));
  }
}
