import 'package:flutter/material.dart';
import 'package:ki_kati/components/custom_button.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/secureStorageServices.dart';
import 'package:ki_kati/screens/group_message_screen.dart';

class KikatiGroup extends StatefulWidget {
  const KikatiGroup({super.key});

  @override
  State<KikatiGroup> createState() => _KikatiGroupState();
}

class _KikatiGroupState extends State<KikatiGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  SecureStorageService storageService = SecureStorageService();
  Map<String, dynamic> user = {};

  bool _isLoading = false;
  bool isLoading = false;

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> myGroups = []; // Stores the user's groups
  List<Map<String, dynamic>> availableGroups =
      []; // Stores other available groups
  Set<String> selectedFriends = {}; // Set to track selected friends by userId
  Set<String> selectedUsernames = {}; // Set to track selected usernames

  bool isMyGroups = true; // Track if the "My Groups" button is selected

  Future<void> getUserData() async {
    // Retrieve user data from secure storage
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');

    if (retrievedUserData != null) {
      setState(() {
        user = retrievedUserData["user"];
      });
    }
  }

  // Fetch the user's friends
  Future<void> getFriends() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/users/friends');
      setState(() {
        friends = List.from(response);
      });
    } catch (e) {
      setState(() {
        friends = [];
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

  // Fetch the user's groups
  Future<void> getMyGroups() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/groups/my-groups');
      setState(() {
        myGroups = List<Map<String, dynamic>>.from(response['groups']);
      });
    } catch (e) {
      print(e);
      setState(() {
        myGroups = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load groups')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch the other available groups
  Future<void> getAvailableGroups() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/groups/all-groups');
      print(response);
      setState(() {
        availableGroups = List<Map<String, dynamic>>.from(response['groups']);
      });
    } catch (e) {
      setState(() {
        availableGroups = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load available groups')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle user selection for group creation
  void _toggleUserSelection(String userId, String username) {
    setState(() {
      if (selectedFriends.contains(userId)) {
        selectedFriends.remove(userId);
      } else {
        selectedFriends.add(userId);
      }

      // Remove and add usernames
      if (selectedUsernames.contains(username)) {
        selectedUsernames.remove(username);
      } else {
        selectedUsernames.add(username);
      }
    });
  }

  // Get initials from the user's name
  String _getInitials(String firstName, String lastName) {
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  // Handle the group creation action
  Future<void> _createGroup() async {
    String groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name cannot be empty')));
    } else if (selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one user')));
    } else {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await httpService.post('/groups/create', {
          'name': groupName,
          'members': selectedFriends.toList(),
        });

        if (response['statusCode'] == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Group "$groupName" created with members: ${selectedUsernames.join(", ")}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create group')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getFriends(); // Fetch friends on initialization
    getMyGroups(); // Fetch the user's groups
    getAvailableGroups(); // Fetch available groups
    getUserData(); //Get data for current user stored in secure storage
  }

  // Show bottom sheet for members of the group
  void _showMembersBottomSheet(List<dynamic> members) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300, // Set a height for the bottom sheet
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final firstName = member['firstName'];
              final lastName = member['lastName'];
              final username = member['username'];
              final initials = _getInitials(firstName, lastName);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(initials),
                ),
                title: Text('$firstName $lastName'),
                subtitle: Text(username),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _joinGroup(String groupId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await httpService.post('/groups/join', {'groupId': groupId});
      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined the group.')),
        );
        getAvailableGroups(); // Refresh available groups
        getMyGroups(); // Refresh my groups
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join the group.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await httpService.post('/groups/leave', {'groupId': groupId});
      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully left the group.')),
        );
        getMyGroups(); // Refresh my groups
        getAvailableGroups(); // Refresh available groups
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave the group.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Distribute space between children
              children: [
                const Text(
                  "Groups",
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Buttons aligned to the right
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isMyGroups = true;
                        });
                      },
                      icon: const Icon(
                        Icons.group, // You can change this to any relevant icon
                        color: Colors.blue, // Icon color
                        size: 30.0, // Icon size
                      ),
                      tooltip:
                          'My Groups', // Optional tooltip for accessibility
                    ),
                    const SizedBox(width: 10), // Space between the buttons
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isMyGroups = false; // Update the state when pressed
                        });
                      },
                      icon: const Icon(
                        Icons
                            .group_add, // You can use any relevant icon here (e.g., group add)
                        color: Colors.green, // Icon color
                        size: 30.0, // Icon size
                      ),
                      tooltip:
                          'Other Groups', // Optional tooltip for accessibility
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Group Description",
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              "Make Group For Team \nWork",
              style: TextStyle(
                  fontSize: 26.0,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(221, 19, 19, 19)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 135, 193, 241), // Background color
                      foregroundColor: Colors.white, // Text color (foreground)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Set border radius here
                      ),
                    ),
                    child: const Text("Group Work")),
                const SizedBox(width: 20),
                ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 135, 193, 241), // Background color
                      foregroundColor: Colors.white, // Text color (foreground)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Set border radius here
                      ),
                    ),
                    child: const Text("Team Relationship")),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Group Admin",
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                CircleAvatar(
                  radius: 35, // Increase the radius to make the image bigger
                  backgroundImage:
                      AssetImage('images/logo.png'), // Path to the image asset
                ),
                SizedBox(width: 16), // Space between the image and text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EngDave'),
                    Text(
                      'Group Admin',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Friends to be Added",
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final userId = friend['_id'];
                      final username = friend['username'];
                      final firstName = friend['firstName'];
                      final lastName = friend['lastName'];
                      final fullName = '$firstName $lastName';
                      final initials = _getInitials(firstName, lastName);

                      return GestureDetector(
                        onTap: () => _toggleUserSelection(userId, username),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30.0,
                              backgroundImage:
                                  const AssetImage('images/user.png'),
                              backgroundColor: selectedFriends.contains(userId)
                                  ? const Color.fromARGB(255, 131, 193, 244)
                                  : Colors.grey,
                              child: selectedFriends.contains(userId)
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            CustomButton(
              onTap: _createGroup,
              buttonText: _isLoading
                  ? "Creating the group, please wait ..."
                  : "Create Group",
              isLoading: _isLoading,
              color: _isLoading
                  ? const Color.fromARGB(255, 38, 34, 34)
                  : Colors.teal,
            ),
            const SizedBox(height: 20),
            isMyGroups
                ? const Text(
                    "My Groups",
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  )
                : const Text(
                    "All Groups",
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: isMyGroups
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: myGroups.length,
                      itemBuilder: (context, index) {
                        final group = myGroups[index];
                        return Column(
                          children: [
                            ListTile(
                              title: Text(group['name']),
                              subtitle:
                                  Text("Members: ${group['members'].length}"),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.people,
                                          color: Colors.blue),
                                      onPressed: () {
                                        _showMembersBottomSheet(
                                            group['members']);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat,
                                          color: Colors.green),
                                      onPressed: () {
                                        // Navigate to chat with group page or start chat
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GroupMessageScreen(
                                              currentUserName: user[
                                                  "username"], //get teh details of the current logged in user from local storage to use for typing purposes
                                              targetGroupId:
                                                  group['_id'] ?? "Unknown",
                                              targetGroupName:
                                                  group['name'] ?? 'Unknown',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.exit_to_app,
                                          color: Colors.red),
                                      onPressed: () {
                                        _leaveGroup(group['_id']);
                                      },
                                      tooltip: 'Leave Group',
                                    ),
                                  ]),
                            ),
                            const Divider()
                          ],
                        );
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableGroups.length,
                      itemBuilder: (context, index) {
                        final group = availableGroups[index];
                        return Column(
                          children: [
                            ListTile(
                              title: Text(group['name']),
                              subtitle:
                                  Text("Members: ${group['members'].length}"),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _joinGroup(group['_id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.teal, // Join button color
                                ),
                                child: const Text(
                                  "Join Group",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const Divider()
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
