import 'package:intl/intl.dart'; // For date formatting
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ki_kati/components/secureStorageServices.dart';
import 'package:ki_kati/screens/message_screen.dart';
import 'package:ki_kati/services/socket_service.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:provider/provider.dart'; // Import provider

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api/users");
  bool isLoading = false; // Track loading state

  SocketService? _socketService;
  SecureStorageService storageService = SecureStorageService();

  String? username;

  List<Map<String, dynamic>> friends = []; // Friend list from API response
  List<Map<String, dynamic>> activeUsers =
      []; // Active users from SocketService

  Future<void> getFriends() async {
    print("we are getting friewnds ");
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Call the API to get friends
      final response = await httpService.get('/friends');
      setState(() {
        friends = List.from(response);
      });
      print("These are my friends");
      print(friends);
    } catch (e) {
      setState(() {
        friends = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load friends')),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _socketService = Provider.of<SocketService>(context,
        listen: false); // Access the socket service here
    _socketService?.connect(); // Connect only once during the lifecycle
    _initialize();
    getFriends();
  }

  Future<void> _initialize() async {
    // Fetch the username asynchronously
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    username = retrievedUserData?['user']['username'];
    print("Fetched username: $username");

    // Trigger a rebuild after username is fetched
    setState(() {});
  }

  // Get random color for avatars
  Color getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256), // Red value (0-255)
      random.nextInt(256), // Green value (0-255)
      random.nextInt(256), // Blue value (0-255)
      1, // Full opacity
    );
  }

  // Function to get the color based on username hash
  Color getAvatarColor(String name) {
    final int hash = name.hashCode; // Hash the name or ID
    return Color((hash & 0xFFFFFF) + 0xFF000000); // Convert hash to a color
  }

  String formatTimestamp(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime); // Format for time
  }

  // Method to check if the user is active based on the active users list
  String isUserActive(final friend) {
    // Check if the 'isActive' flag is true
    if (friend['isActive']) {
      return 'Active Now'; // Return a string indicating they are currently active
    }

    // Parse the last active timestamp
    final lastActive = DateTime.parse(friend['lastActive']);

    // Determine if the user was active within the last 5 minutes
    final currentTime = DateTime.now();
    final difference = currentTime.difference(lastActive);

    // If the user was active within the last 5 minutes, consider them active
    if (difference.inMinutes <= 5) {
      return 'Active Recently'; // Return a string indicating recent activity
    }

    // Return the last active time formatted as a string
    return 'Last Active: ${formatTimestamp(lastActive)}';
  }
  /*
  bool isUserActive(final username) {
    final activeUser = activeUsers.firstWhere(
        (user) => user['username'] == username,
        orElse: () => {} // Return an empty map if not found
        );
    if (activeUser.isNotEmpty) {
      return true;
    }
    return false;
  }
  */

  // Function to handle refresh
  Future<void> _onRefresh() async {
    // Refresh friends list
    await getFriends();
  }

  @override
  Widget build(BuildContext context) {
    if (username == null) {
      // Display a loading indicator while waiting for the username
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Chats list
          Expanded(
            child: Consumer<SocketService>(
              builder: (context, socketService, child) {
                activeUsers = socketService.activeUsers;

                return RefreshIndicator(
                  onRefresh: _onRefresh, // Trigger the refresh
                  child: isLoading // Check if data is loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final friendUsername =
                                friend['username'] ?? 'Unknown';
                            final friendId = friend['_id'] ?? 'unknown';
                            final isActive = isUserActive(friend);

                            return ChatItem(
                              name: friendUsername,
                              message:
                                  "messages ...", // Placeholder for last message
                              time: isActive,
                              unreadCount:
                                  0, // Placeholder for unread messages count
                              avatarColor: getAvatarColor(friendUsername),
                              onTap: () {
                                // Navigate to the message screen with the friend details
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessageScreen(
                                      currentUserName: username ??
                                          "unknown", // Replace with actual current user ID
                                      connectionDetails:
                                          friend['connection_details'] ??
                                              'unknown',
                                      targetUserId: friendId,
                                      targetUsername: friendUsername,
                                      targetProfileImage:
                                          friend['profileImage'] ??
                                              'images/user.png',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StatusItem extends StatelessWidget {
  final String name;
  final IconData? icon;

  const StatusItem({super.key, required this.name, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: icon != null ? Colors.green : Colors.blue,
          child: icon != null
              ? Icon(icon, color: Colors.white)
              : Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final Color avatarColor;
  final VoidCallback onTap;

  const ChatItem({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          message,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time, style: const TextStyle(color: Colors.grey)),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
