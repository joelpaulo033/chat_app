import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/user_tile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  final List<Color> volcanoColors = [
    const Color(0xFFFF4500),
    const Color(0xFFFF6347),
    const Color(0xFFFF8C00),
    const Color(0xFFFFD700),
  ];

  int _selectedIndex = 0; // bottom nav
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      drawer: const MyDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: volcanoColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: isLargeScreen
              ? Row(
            children: [
              // Chats on left
              Container(
                width: 400,
                color: Colors.black.withOpacity(0.05),
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(child: _buildChatsList()),
                  ],
                ),
              ),
              // Users on right
              Expanded(
                child: Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildUserList()),
                  ],
                ),
              ),
            ],
          )
              : Column(
            children: [
              _buildAppBar(),
              if (_selectedIndex == 0) _buildSearchBar(),
              Expanded(
                child: _selectedIndex == 0
                    ? _buildUserList()
                    : _buildChatsList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !isLargeScreen
          ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.black.withOpacity(0.1),
        selectedItemColor: volcanoColors[0],
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
        ],
      )
          : null,
    );
  }

  // ---------------- APP BAR ----------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Home",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search users...',
          fillColor: Colors.white.withOpacity(0.2),
          filled: true,
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // ---------------- USER LIST ----------------
  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _authService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text("Error", style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final users = snapshot.data!
            .where((userData) =>
        userData['email'] != _authService.getCurrentUser()!.email)
            .where((userData) =>
            userData['displayName']!.toLowerCase().contains(_searchQuery))
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text(
              "No other users found",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  // ---------------- CHATS LIST ----------------
  // ---------------- CHATS LIST ----------------
  Widget _buildChatsList() {
    final currentUserId = _authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text("Error", style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final chatDocs = snapshot.data!.docs;

        if (chatDocs.isEmpty) {
          return const Center(
            child: Text(
              "No chats yet",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // Only include users you have actually chatted with
        final Map<String, Map<String, dynamic>> chatUsers = {};

        for (var doc in chatDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants']);
          if (participants.length != 2) continue; // skip group chats

          final messages = data['messages'] as List<dynamic>?;
          if (messages == null || messages.isEmpty) continue; // skip empty chats

          final otherId = participants.firstWhere((id) => id != currentUserId);

          // Keep latest chat if multiple exist
          if (!chatUsers.containsKey(otherId) ||
              (messages.last['timestamp'] ?? 0) >
                  (chatUsers[otherId]!['messages'].last['timestamp'] ?? 0)) {
            chatUsers[otherId] = data;
          }
        }

        if (chatUsers.isEmpty) {
          return const Center(
            child: Text(
              "No chats yet",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // Convert map to list and sort by last message timestamp descending
        final sortedChats = chatUsers.entries.toList()
          ..sort((a, b) {
            final aMessages = a.value['messages'] as List<dynamic>;
            final bMessages = b.value['messages'] as List<dynamic>;
            final aTimestamp =
            aMessages.isNotEmpty ? aMessages.last['timestamp'] ?? 0 : 0;
            final bTimestamp =
            bMessages.isNotEmpty ? bMessages.last['timestamp'] ?? 0 : 0;
            return bTimestamp.compareTo(aTimestamp); // descending
          });

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: sortedChats.map((entry) {
            final otherUserId = entry.key;
            final chatData = entry.value;

            final messages = chatData['messages'] as List<dynamic>;
            final lastMessage =
            messages.isNotEmpty ? messages.last['text'] : '';
            final lastTimestamp =
            messages.isNotEmpty ? messages.last['timestamp'] : null;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>;
                return _buildChatListItem(
                    userData, lastMessage, lastTimestamp, context);
              },
            );
          }).toList(),
        );
      },
    );
  }


// ---------------- CHAT TILE ----------------
  Widget _buildChatListItem(
      Map<String, dynamic> userData,
      String lastMessage,
      int? lastTimestamp,
      BuildContext context,
      ) {
    final dateString = lastTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(lastTimestamp)
        .toLocal()
        .toString()
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: volcanoColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverEmail: userData['email'],
                  receiverID: userData['uid'],
                  receiverDisplayName:
                  userData['displayName'] ?? userData['email'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                UserTile(
                  text: userData['displayName'] ?? userData['email'],
                  profilePhotoUrl: userData['profilePhotoUrl'],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (dateString.isNotEmpty)
                        Text(
                          dateString.split('.')[0], // remove microseconds
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ---------------- USER TILE ----------------
  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: volcanoColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverEmail: userData['email'],
                  receiverID: userData['uid'],
                  receiverDisplayName:
                  userData['displayName'] ?? userData['email'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: UserTile(
              text: userData['displayName'] ?? userData['email'],
              profilePhotoUrl: userData['profilePhotoUrl'],
            ),
          ),
        ),
      ),
    );
  }
}
