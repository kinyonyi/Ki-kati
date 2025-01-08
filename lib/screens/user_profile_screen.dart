import 'package:flutter/material.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/secureStorageServices.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  SecureStorageService storageService = SecureStorageService();
  Map<String, dynamic> user = {}; // Initialize user data

  final HttpService httpService = HttpService("https://ki-kati.com/api");
  bool _isLoading = false;

  // Controllers for the form fields
  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _dateOfBirthController;
  String? _gender;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    // Retrieve user data from secure storage
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');

    if (retrievedUserData != null) {
      setState(() {
        user = retrievedUserData["user"];
      });
      _initializeControllers(); // Initialize the controllers after the data is fetched
    }
  }

  void _initializeControllers() {
    // Initialize controllers with current user data
    _usernameController = TextEditingController(text: user["username"]);
    _firstNameController = TextEditingController(text: user["firstName"]);
    _lastNameController = TextEditingController(text: user["lastName"]);
    _emailController = TextEditingController(text: user["email"]);
    _phoneNumberController = TextEditingController(text: user["phoneNumber"]);

    // Ensure dateOfBirth is correctly parsed into DateTime
    DateTime parsedDateOfBirth = DateTime.parse(user['dateOfBirth']);
    _dateOfBirthController = TextEditingController(
        text:
            "${parsedDateOfBirth.day}/${parsedDateOfBirth.month}/${parsedDateOfBirth.year}");

    _gender = user["gender"];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text(message,
              style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the pop-up
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _saveProfile() async {
    final updatedUserData = {
      "username": _usernameController.text,
      "firstName": _firstNameController.text,
      "lastName": _lastNameController.text,
      "email": _emailController.text,
      "phoneNumber": _phoneNumberController.text,
      "dateOfBirth":
          _dateOfBirthController.text, // Here we save the formatted date
      "gender": _gender,
    };

    try {
      final response = await httpService.put('/auth/profile', updatedUserData);
      print(response);
      if (response['statusCode'] == 201) {
        // Simulate success
        print("data updated");
        String message =
            response['body']['message'] ?? 'Data Updated Successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        // Handle other status codes
        print(response);
        _showErrorDialog(response['body']['message']);
      }
    } catch (e) {
      print('Error: $e'); // Handle errors here
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }

    // For demonstration purposes, print the updated user data
    print(updatedUserData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );

    setState(() {
      isEditing = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime currentDate = DateTime.now();
    final DateTime initialDate = DateTime.parse(user["dateOfBirth"]);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: currentDate,
    );

    if (picked != null && picked != initialDate) {
      setState(() {
        _dateOfBirthController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user data is fetched before building the widget
    if (user.isEmpty) {
      return const Center(
          child: CircularProgressIndicator()); // Loading indicator
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (user.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60.0,
                      backgroundImage: NetworkImage(user["profilePicture"] ??
                          'https://via.placeholder.com/150'),
                      child: user["profilePicture"] == null
                          ? const Icon(
                              Icons.person,
                              size: 60.0,
                              color: Colors.white,
                            )
                          : null, // Default icon if no picture is available
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${user['firstName']} ${user['lastName']}",
                      style: const TextStyle(
                          fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "@${user['username']}",
                      style:
                          const TextStyle(fontSize: 16.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _buildProfileField("Username", _usernameController, isEditing),
            const SizedBox(height: 16),
            _buildProfileField("First Name", _firstNameController, isEditing),
            const SizedBox(height: 16),
            _buildProfileField("Last Name", _lastNameController, isEditing),
            const SizedBox(height: 16),
            _buildProfileField("Email", _emailController, isEditing),
            const SizedBox(height: 16),
            _buildProfileField(
                "Phone Number", _phoneNumberController, isEditing),
            const SizedBox(height: 16),
            _buildDateOfBirthField(isEditing),
            const SizedBox(height: 16),
            const Text(
              'Gender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isEditing)
              Row(
                children: [
                  Radio<String>(
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('Male'),
                  Radio<String>(
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('Female'),
                  Radio<String>(
                    value: 'Others',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('Others'),
                ],
              )
            else
              Text(_gender ?? "Not specified"),
            const SizedBox(height: 20),
            isEditing
                ? ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      iconColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save Profile',
                        style: TextStyle(fontSize: 16)),
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      iconColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Edit Profile',
                        style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
      String label, TextEditingController controller, bool isEditing) {
    if (isEditing) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            controller.text,
            style: const TextStyle(fontSize: 16.0, color: Colors.black),
          ),
          const SizedBox(
            height: 5,
          ),
          const Divider()
        ],
      );
    }
  }

  Widget _buildDateOfBirthField(bool isEditing) {
    if (isEditing) {
      return GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextField(
            controller: _dateOfBirthController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Date of Birth', style: TextStyle(fontSize: 16.0)),
          Text(
            _dateOfBirthController.text,
            style: const TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
        ],
      );
    }
  }
}
