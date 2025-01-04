import 'package:flutter/material.dart';
import 'package:ki_kati/screens/chat_screen.dart';
import 'package:ki_kati/screens/feed_screen.dart';
import 'package:ki_kati/screens/friend_requests_screen.dart';
import 'package:ki_kati/screens/friends_screen.dart';
import 'package:ki_kati/screens/group_screen.dart';
import 'package:ki_kati/screens/market_screen.dart';
import 'package:ki_kati/screens/search_screen.dart';
import 'package:ki_kati/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // To track the currently selected index
  final List<Widget> _screens = [
    const ChatScreen(),
    const KikatiGroup(),
    const FriendsScreen(),
    const SettingsScreen(),
  ];

  ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
    /*
    if (index == 3) {
      // Profile tab index
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    }
    */
  }

  @override
  void initState() {
    super.initState();
    // get current username from secure storage
  }

  void _onActionSelected(String action) {
    print("Action selected: $action");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.search), // Search icon
          onPressed: () {
            Navigator.push(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          }, // Open the search modal on press
          padding: const EdgeInsets.all(6.0), // Adjust padding for smaller size
          splashColor: Colors.transparent, // Remove splash color
          highlightColor: Colors.transparent, // Remove highlight color
        ),
        title: const Text(
          "Ki-Kati",
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          // Popup menu button to show a dropdown of actions
          PopupMenuButton<String>(
            color: Colors.teal,
            shadowColor: Colors.red,
            onSelected: (value) {
              // Perform action based on selected value
              if (value == 'Requests') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FriendRequestScreen(),
                  ),
                );
              } else if (value == 'News Feed') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedScreen(),
                  ),
                );
              }
              // Add more actions as needed
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Requests',
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('Requests',
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'News Feed',
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('News Feed',
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
                // Add more items as needed
              ];
            },
            offset: const Offset(
                0, 50), // Offset the menu 50 pixels below the button
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            // Detect scroll direction
            if (scrollNotification.scrollDelta! > 0 && _isFabVisible) {
              // Scrolling down
              setState(() {
                _isFabVisible = false;
              });
            } else if (scrollNotification.scrollDelta! < 0 && !_isFabVisible) {
              // Scrolling up
              setState(() {
                _isFabVisible = true;
              });
            }
          }
          return true;
        },
        child: _screens[_selectedIndex], // Display the selected screen
      ),
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketScreen()),
                );
              },
              child: const Icon(Icons.store),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'My Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex, // Set the current index
        selectedItemColor: Colors.green, // Color for the selected item
        onTap: _onItemTapped, // Handle item tap
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
