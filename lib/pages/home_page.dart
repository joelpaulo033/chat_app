import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedIndex = 0; // bottom nav

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      drawer: const MyDrawer(),
      body: Container(
        decoration: AppTheme.volcanoGradient,
        child: SafeArea(
          child: isLargeScreen
              ? Row(
                  children: [
                    // Chats on left
                    Container(
                      width: 400,
                      color: Colors.black.withValues(alpha: 0.05),
                      child: Column(
                        children: [
                          _buildAppBar(),
                          _buildSearchBox(), // Search for chats in large screen
                          Expanded(child: _buildChatsList()),
                        ],
                      ),
                    ),
                    // Users on right
                    Expanded(
                      child: Column(
                        children: [
                          _buildSearchBar(), // Search for users in large screen
                          Expanded(child: _buildUserList()),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildAppBar(),
                    if (_selectedIndex == 0)
                      _buildSearchBar(), // Search for users in small screen
                    if (_selectedIndex == 1)
                      _buildSearchBox(), // Search for chats in small screen
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
              backgroundColor: Colors.black.withValues(alpha: 0.1),
              selectedItemColor: AppTheme.orangeRed,
              unselectedItemColor: Colors.white70,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  // Clear search query when switching tabs
                  _searchController.clear();
                  _searchQuery = "";
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

  // APP BAR
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

  // ---------------- USER SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search users...',
          fillColor: Colors.white.withValues(alpha: 0.2),
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

  // ---------------- CHAT SEARCH BOX ----------------
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search chats...",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ---------------- USER LIST ----------------
  Widget _buildUserList() {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: authService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text("Error", style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final users = snapshot.data!;

        final filteredUsers = users
            .where((userData) =>
                userData['email'] != authService.getCurrentUser()?.email)
            .where((userData) => (userData['displayName'] ?? userData['email'])
                .toString()
                .toLowerCase()
                .contains(_searchQuery))
            .toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text(
              "No users found",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData = filteredUsers[index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  // ---------------- CHATS LIST ----------------
  Widget _buildChatsList() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.getCurrentUser()?.uid;

    if (currentUserId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error loading chats: ${snapshot.error}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Click the link in your terminal to create the Firestore Index for your chats list.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ),
          );
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(chatData['participants']);
            final otherUserId =
                participants.firstWhere((id) => id != currentUserId);

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

                // Filter chats based on search query
                final displayName =
                    (userData['displayName'] ?? userData['email'])
                        .toString()
                        .toLowerCase();
                if (_searchQuery.isNotEmpty &&
                    !displayName.contains(_searchQuery)) {
                  return const SizedBox.shrink(); // Hide if not matching search
                }

                return _buildChatListItem(
                  userData,
                  chatData['lastMessage'] ?? '',
                  chatData['lastTimestamp'] as Timestamp?,
                  context,
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------- CHAT TILE ----------------
  Widget _buildChatListItem(
    Map<String, dynamic> userData,
    String lastMessage,
    Timestamp? lastTimestamp,
    BuildContext context,
  ) {
    final timeString = lastTimestamp != null
        ? DateFormat('h:mm a').format(lastTimestamp.toDate())
        : '';

    return UserTile(
      text: userData['displayName'] ?? userData['email'],
      subtitle: lastMessage,
      profilePhotoUrl: userData['profilePhotoUrl'],
      trailing: timeString.isNotEmpty
          ? Text(
              timeString,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: userData['email'],
              receiverID: userData['uid'],
              receiverDisplayName: userData['displayName'] ?? userData['email'],
            ),
          ),
        );
      },
    );
  }

  // ---------------- USER TILE ----------------
  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    return UserTile(
      text: userData['displayName'] ?? userData['email'],
      profilePhotoUrl: userData['profilePhotoUrl'],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: userData['email'],
              receiverID: userData['uid'],
              receiverDisplayName: userData['displayName'] ?? userData['email'],
            ),
          ),
        );
      },
    );
  }
}
