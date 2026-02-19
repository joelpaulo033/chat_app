import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/pages/profile_page.dart';
import 'package:chat_app/pages/group_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0; // 0: Chats, 1: People, 2: Profile
  String _searchQuery = '';
  String _activeFilter = 'All';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Google Messages style Header
            _buildDeepMixHeader(),

            // 2. WhatsApp style Filter Chips
            if (_selectedIndex == 0) _buildFilterChips(),

            // 3. Main Content (Real-time List)
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
      // 4. Floating Action Button (Volcano style)
      floatingActionButton: _selectedIndex != 2
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _selectedIndex = 1); // Switch to People
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_comment_rounded),
            )
          : null,
      // 5. Modern Bottom Nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'People',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildDeepMixHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!_isSearching)
            const Text(
              "Let's Chat", // Updated Brand Name
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            )
          else
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search...",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          if (!_isSearching) const Spacer(),
          IconButton(
            icon:
                Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 2),
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person,
                    color: Theme.of(context).colorScheme.primary, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Unread', 'Favorites', 'Groups'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(filter),
              selected: isActive,
              onSelected: (val) {
                if (val) setState(() => _activeFilter = filter);
              },
              selectedColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildChatsList();
      case 1:
        return _buildUserList();
      case 2:
        return const ProfilePage();
      default:
        return _buildChatsList();
    }
  }

  // --- DATA LISTS (REAL-TIME) ---

  Widget _buildUserList() {
    final currentUser = _authService.getCurrentUser();
    return Column(
      children: [
        // Create Group Entry
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.group_add_rounded, color: Colors.white),
          ),
          title: const Text("Create New Group",
              style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupSetupPage()),
            );
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _authService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error"));
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!
                  .where((u) => u['uid'] != currentUser?.uid)
                  .where((u) => (u['displayName'] ?? u['email'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index];
                  return UserTile(
                    text: userData['displayName'] ?? userData['email'] ?? '',
                    profilePhotoUrl: userData['profilePhotoUrl'],
                    isOnline: userData['isOnline'] ?? false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverEmail: userData['email'] ?? '',
                          receiverID: userData['uid'] ?? '',
                          receiverDisplayName: userData['displayName'] ??
                              userData['email'] ??
                              '',
                          isGroup: false,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatsList() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _authService.getUsersStream(),
        builder: (context, usersSnapshot) {
          // Create a map for quick name lookup: uid -> name
          final Map<String, String> userNameMap = {};
          if (usersSnapshot.hasData) {
            for (var u in usersSnapshot.data!) {
              userNameMap[u['uid'] ?? ''] =
                  u['displayName'] ?? u['email'] ?? 'User';
            }
          }

          return StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                List favorites = [];
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  favorites = (userSnapshot.data!.data()
                          as Map<String, dynamic>)['favorites'] ??
                      [];
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .where('participants', arrayContains: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading chats"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter based on Search Query and Categories
                    final chatDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isGroup = data['isGroup'] ?? false;
                      final query = _searchQuery.toLowerCase();

                      // 1. Get search targets
                      final lastMsg =
                          (data['lastMessage'] ?? '').toString().toLowerCase();
                      String targetName = '';

                      if (isGroup) {
                        targetName =
                            (data['groupName'] ?? '').toString().toLowerCase();
                      } else {
                        final participants =
                            List<String>.from(data['participants'] ?? []);
                        final otherUserId = participants.firstWhere(
                            (id) => id != currentUser.uid,
                            orElse: () => '');
                        targetName =
                            (userNameMap[otherUserId] ?? '').toLowerCase();
                      }

                      // 2. Search Query Filter
                      bool matchesSearch =
                          lastMsg.contains(query) || targetName.contains(query);

                      // 3. Category Filter
                      if (_activeFilter == 'Unread') {
                        return matchesSearch && (data['unreadCount'] ?? 0) > 0;
                      } else if (_activeFilter == 'Groups') {
                        return matchesSearch && isGroup;
                      } else if (_activeFilter == 'Favorites') {
                        if (isGroup) {
                          return false; // Groups usually not favorites in this logic
                        }
                        final participants =
                            List<String>.from(data['participants'] ?? []);
                        final otherUserId = participants.firstWhere(
                            (id) => id != currentUser.uid,
                            orElse: () => '');
                        return matchesSearch && favorites.contains(otherUserId);
                      }

                      return matchesSearch;
                    }).toList();

                    // Sort client-side
                    chatDocs.sort((a, b) {
                      final aTime = (a.data()
                          as Map<String, dynamic>)['lastMessageTimestamp'];
                      final bTime = (b.data()
                          as Map<String, dynamic>)['lastMessageTimestamp'];
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime);
                    });

                    if (chatDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                                _searchQuery.isEmpty
                                    ? "No conversations yet"
                                    : "No results for '$_searchQuery'",
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: chatDocs.length,
                      itemBuilder: (context, index) {
                        final chatData =
                            chatDocs[index].data() as Map<String, dynamic>;
                        return _buildChatTile(
                            chatData, currentUser.uid, chatDocs[index].id);
                      },
                    );
                  },
                );
              });
        });
  }

  Widget _buildChatTile(
      Map<String, dynamic> chatData, String currentUserId, String chatId) {
    final isGroup = chatData['isGroup'] ?? false;

    if (isGroup) {
      return ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: '',
              receiverID: chatId,
              receiverDisplayName: chatData['groupName'] ?? 'Unnamed Group',
              isGroup: true,
            ),
          ),
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.group_rounded,
              color: Theme.of(context).colorScheme.primary, size: 28),
        ),
        title: Text(
          chatData['groupName'] ?? 'Unnamed Group',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          chatData['lastMessage'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14),
        ),
        trailing: _buildTimestamp(chatData['lastMessageTimestamp']),
      );
    }

    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final lastMessage = chatData['lastMessage'] ?? '';
        final isOnline = userData['isOnline'] ?? false;
        final name = userData['displayName'] ?? userData['email'] ?? '?';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: userData['email'] ?? '',
                receiverID: userData['uid'] ?? '',
                receiverDisplayName:
                    userData['displayName'] ?? userData['email'] ?? '',
                isGroup: false,
              ),
            ),
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: (userData['profilePhotoUrl'] != null &&
                        userData['profilePhotoUrl'].toString().isNotEmpty)
                    ? NetworkImage(userData['profilePhotoUrl'])
                    : null,
                child: (userData['profilePhotoUrl'] == null ||
                        userData['profilePhotoUrl'].toString().isEmpty)
                    ? Text(
                        initial,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14),
          ),
          trailing: _buildTimestamp(chatData['lastMessageTimestamp']),
        );
      },
    );
  }

  Widget _buildTimestamp(dynamic timestamp) {
    String dateString = '';
    if (timestamp != null) {
      final dt = (timestamp is Timestamp)
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
      dateString = DateFormat('HH:mm').format(dt);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          dateString,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
