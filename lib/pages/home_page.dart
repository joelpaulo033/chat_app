import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  final List<Color> volcanoColors = [
    const Color(0xFFFF4500),
    const Color(0xFFFF6347),
    const Color(0xFFFF8C00),
    const Color(0xFFFFD700),
  ];

  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      drawer: const MyDrawer(), // just keep it simple; logout is handled inside drawer
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
              Container(
                width: 400,
                color: Colors.black.withOpacity(0.05),
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildSearchBar(),
                    Expanded(child: _buildChatsList()),
                  ],
                ),
              ),
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
              _buildSearchBar(),
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
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final users = snapshot.data!
            .where((u) =>
        u['email'] != _authService.getCurrentUser()!.email &&
            u['displayName']
                .toLowerCase()
                .contains(_searchQuery))
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildUserListItem(users[index], context);
          },
        );
      },
    );
  }

  // ---------------- USER TILE ----------------
  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final displayName = userData['displayName'] ?? userData['email'];
    final email = userData['email'];

    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.orangeAccent,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          displayName,
          style:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          email,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chat, color: Colors.white),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                receiverEmail: email,
                receiverID: userData['uid'],
                receiverDisplayName: displayName,
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- CHATS LIST ----------------
  Widget _buildChatsList() {
    final currentUserId = _authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final chatDocs = snapshot.data!.docs;
        if (chatDocs.isEmpty) {
          return const Center(
              child:
              Text("No chats yet", style: TextStyle(color: Colors.white70)));
        }

        final Map<String, Map<String, dynamic>> chatUsers = {};

        for (var doc in chatDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants']);
          if (participants.length != 2) continue;

          final otherId = participants.firstWhere((id) => id != currentUserId);
          chatUsers[otherId] = data;
        }

        return ListView(
          children: chatUsers.entries.map((entry) {
            final otherUserId = entry.key;
            final messages = entry.value['messages'] as List<dynamic>?;
            final lastMessage =
            messages != null && messages.isNotEmpty ? messages.last['message'] ?? '' : '';
            final lastTimestamp =
            messages != null && messages.isNotEmpty ? messages.last['timestamp'] : null;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();
                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>;

                return StreamBuilder<int>(
                  stream: _chatService.getUnreadCount(otherUserId),
                  builder: (context, unreadSnapshot) {
                    final unread = unreadSnapshot.data ?? 0;
                    return _buildChatListItem(
                        userData, lastMessage, lastTimestamp, context, unread);
                  },
                );
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
      dynamic lastTimestamp,
      BuildContext context,
      int unreadCount) {
    String time = '';
    if (lastTimestamp is Timestamp) {
      time = DateTime.fromMillisecondsSinceEpoch(
          lastTimestamp.millisecondsSinceEpoch)
          .toLocal()
          .toString()
          .substring(11, 16); // HH:mm
    }

    return ListTile(
      title: Text(
        userData['displayName'] ?? userData['email'],
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        lastMessage,
        style: const TextStyle(color: Colors.white70),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unreadCount > 0
          ? Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              receiverEmail: userData['email'],
              receiverID: userData['uid'],
              receiverDisplayName:
              userData['displayName'] ?? userData['email'],
            ),
          ),
        );
      },
    );
  }
}
