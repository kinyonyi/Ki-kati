import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Method to store data as an object (serialized to JSON)
  Future<void> storeData(String key, Map<String, dynamic> data) async {
    try {
      // Convert the object to JSON string
      String jsonData = jsonEncode(data);

      // Store the JSON string securely
      await _storage.write(key: key, value: jsonData);
      print("$key data stored securely.");
    } catch (e) {
      print("Error storing data: $e");
    }
  }

  // Method to retrieve data (deserialized from JSON)
  Future<Map<String, dynamic>?> retrieveData(String key) async {
    try {
      // Retrieve the stored JSON string
      String? jsonData = await _storage.read(key: key);

      if (jsonData != null) {
        // Convert JSON string back into an object (Map)
        return jsonDecode(jsonData);
      } else {
        print("No data found for key: $key");
        return null;
      }
    } catch (e) {
      print("Error retrieving data: $e");
      return null;
    }
  }

  Future<void> updateUserData(String key, Map<String, dynamic> updates) async {
    try {
      Map<String, dynamic>? existingData = await retrieveData(key);

      print("Thius is the existing data");
      print(existingData);

      if (existingData != null) {
        existingData['user'] = updates;
        //existingData.addAll(updates); // Merge updates into existing data

        // Step 3: Store the updated data back into storage
        await storeData(key, existingData);
        print("User data updated successfully.");
      } else {
        print("No existing data found for key: $key");
      }
    } catch (e) {
      print("Error updating user data: $e");
    }
  }

  // Method to delete data
  Future<void> deleteData(String key) async {
    try {
      await _storage.delete(key: key);
      print("$key data deleted.");
    } catch (e) {
      print("Error deleting data: $e");
    }
  }
}
