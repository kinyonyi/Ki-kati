
import 'package:flutter/material.dart';
import 'package:ki_kati/screens/help_screen.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/secureStorageServices.dart';
import 'package:ki_kati/screens/contact_list_screen.dart';
import 'package:ki_kati/screens/notifications_screen.dart';
import 'package:ki_kati/screens/onboarding_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ki_kati/screens/privacy_policy_screen.dart';
import 'package:ki_kati/screens/user_profile_screen.dart';
import 'package:ki_kati/services/socket_service.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HttpService httpService = HttpService('https://ki-kati.com/api');
  final secureStorage = const FlutterSecureStorage();
  SecureStorageService storageService = SecureStorageService();
  SocketService? _socketService;

  Map<String, dynamic> user = {}; // Initialize user data
  bool _isLoading = false; // Loading state

  // Method to retrieve user data from secure storage
  Future<void> getUserData() async {
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');

    if (retrievedUserData != null) {
      setState(() {
        user = retrievedUserData["user"];
      });
    }
  }

  // Logout method
  void logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await httpService.post('/auth/logout', {});
      if (response['statusCode'] == 200) {
        await secureStorage.delete(key: 'authToken');
        await secureStorage.delete(key: 'username');
        _socketService?.disconnect();

        // Clean up the stored user data
        storageService.deleteData("user_data");

        // Navigate back to the onboarding screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  // Profile Image or Placeholder
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(user.isNotEmpty &&
                            user["profileImage"] != null
                        ? user["profileImage"]
                        : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgF2suM5kFwk9AdFjesEr8EP1qcyUvah8G7w&s'), // Replace with actual image URL
                  ),
                  const SizedBox(width: 16.0),
                  // User's Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isNotEmpty
                            ? '${user["firstName"]} ${user["lastName"]} '
                            : 'Loading...', // Fallback to loading message
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        user.isNotEmpty
                            ? '${user["email"]}'
                            : 'Loading...', // Fallback to loading message
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Settings Options
            SettingItem(
              icon: Icons.color_lens,
              title: "Account",
              subtitle: "user profile, update / edit",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserProfileScreen()),
                );
              },
            ),
            SettingItem(
              icon: Icons.lock,
              title: "Chat",
              subtitle: "Chat history, theme, wallpapers",
              onTap: () {},
            ),
            SettingItem(
              icon: Icons.info,
              title: "Notifications",
              subtitle: "Messages, group and other",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            SettingItem(
              icon: Icons.contacts,
              title: "Contacts",
              subtitle: "View My Contacts",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactListScreen()),
                );
              },
            ),
            SettingItem(
              icon: Icons.help,
              title: "Help",
              subtitle: "Help center, contact us, privacy policy",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
            SettingItem(
              icon: Icons.storage,
              title: "Storage and data",
              subtitle: "Network usage, storage usage",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
            SettingItem(
              icon: Icons.group,
              title: "Invite a friend",
              subtitle: "Help center, contact us, privacy policy",
              onTap: () async {
                const String appLink = 'https://ki-kati.com';
                await Share.share('Download our app Today: $appLink',
                    subject: 'Start Chatting & Stay Connected');
              },
            ),
            const Divider(height: 40),
            // Logout Section
            Text(
              "End Session",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text("Sign Out"),
              onTap: _isLoading ? null : logout, // Disable if loading
              trailing: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ) // Show spinning indicator if loading
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
