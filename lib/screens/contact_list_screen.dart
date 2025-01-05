import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  bool isLoading = false;

  List<Map<String, dynamic>> users = [];

  List<Contact> _contacts = [];

  Future<void> getUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/users/all-users');
      setState(() {
        users = List.from(response);
      });
    } catch (e) {
      setState(() {
        users = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load friends')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getContacts();
    getUsers();
  }

  // Function to request permissions and fetch contacts
  Future<void> _getContacts() async {
    // Request contacts permission
    PermissionStatus permissionStatus = await Permission.contacts.request();

    if (permissionStatus.isGranted) {
      // Get all contacts (fully fetched with properties and photo)
      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true, // Fetch phone numbers, emails, etc.
        withPhoto: true, // Fetch contact photos as well
      );

      setState(() {
        _contacts = contacts;
      });
    } else {
      // Show an error if permission is denied
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permission to access contacts was denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text(
          'Contacts',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: CircularProgressIndicator()) // Loading indicator
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                var contact = _contacts[index];
                String displayName = contact.displayName ?? 'Unknown';
                // Extract phone numbers and emails
                String phoneNumber = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : 'No phone number';
                String email = contact.emails.isNotEmpty
                    ? contact.emails.first.address
                    : 'No email';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0]
                            : 'N', // First letter of name
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phoneNumber), // Display phone number
                        Text(email), // Display email address
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
