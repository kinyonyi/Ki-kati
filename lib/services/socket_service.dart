import 'dart:async';
import 'package:ki_kati/components/secureStorageServices.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:ki_kati/components/http_servive.dart';

class SocketService with ChangeNotifier {
  static final SocketService _singleton = SocketService._internal();
  late IO.Socket socket;

  SecureStorageService storageService = SecureStorageService();

  // List to store active users
  List<Map<String, dynamic>> activeUsers = [];
  List<Map<String, dynamic>> receivedMessages = [];

  // Map to track who is typing
  Map<String, bool> typingStatus = {};

  // Private constructor for Singleton pattern
  SocketService._internal();

  factory SocketService() {
    return _singleton;
  }

  final HttpService httpService = HttpService("https://ki-kati.com/api");

  // Fetch active users from the API
  Future<void> fetchActiveUsers() async {
    try {
      final response = await httpService.get("/messages/active-users");
      if (response != null) {
        activeUsers = List<Map<String, dynamic>>.from(response);
        notifyListeners(); // Notify listeners (e.g., UI) about the change
      }
    } catch (error) {
      print("Error fetching active users: $error");
      activeUsers = []; // Reset active users list on error
      notifyListeners(); // Notify listeners (e.g., UI) about the change
    }
  }

  Future<void> connect() async {
    print("Attempting to connect to socket");

    // Retrieve user data from storage
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    String? username = retrievedUserData?['user']['username'];
    String? token = retrievedUserData?['token'];

    if (username == null || token == null) {
      print("User data is missing, unable to connect");
      return;
    }

    socket = IO.io('https://ki-kati.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': token,
      },
      'reconnectionAttempts': 5, // Limit reconnection attempts
      'reconnectionDelay': 1000, // Delay before retrying (1 second)
      'reconnectionDelayMax': 5000, // Maximum delay before retrying (5 seconds)
      'randomizationFactor': 0.5, // Factor to randomize reconnection delay
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to the server as $username');
      socket.emit('registerUser', username); // Register user after connection
    });

    socket.onDisconnect((_) {
      print("You have been disconnected from the server!");
    });

    // Handle connection errors
    socket.on('connect_error', (error) {
      print('Connection error: $error');
    });

    // Handle connection timeout
    socket.on('connect_timeout', (_) {
      print('Connection timed out');
    });

    // Optional: handle reconnection attempts
    socket.onReconnectAttempt((attempt) {
      print('Reconnection attempt #$attempt');
    });

    // Listen for active users (server should emit the active users data)
    socket.on('activeUsers', (data) async {
      if (data != null) {
        print('Active Users event received: $data');
        // Fetch active users when the event is received
        await fetchActiveUsers();
      }
    });

    // Listen for incoming messages (directMessage)
    socket.on("directMessage", (data) {
      if (data != null) {
        receivedMessages.add({
          'sender': data['sender'],
          'content': data['content'],
        });
        print("Received message: ${data['content']}");
        notifyListeners(); // Notify listeners to update the UI
      }
    });

    // Listen for incoming messages (directMessage)
    socket.on("messageReceived", (data) {
      print("This is the data from group socket");
      print(data);
      if (data != null) {
        receivedMessages.add({
          'sender': data['sender'],
          'content': data['content'],
        });
        print("Received message: ${data['content']}");
        notifyListeners(); // Notify listeners to update the UI
      }
    });

    socket.on('typing', (data) {
      if (data != null) {
        String typingUser = data['username'];
        typingStatus[typingUser] = true; // User is typing
        print('$typingUser is typing');
        notifyListeners(); // Notify UI
      }
    });

    socket.on('stop_typing', (data) {
      if (data != null) {
        String typingUser = data['username'];
        typingStatus[typingUser] = false; // User stopped typing
        print('$typingUser stopped typing');
        notifyListeners(); // Notify UI
      }
    });
  }

  void sendMessage(String recipient, String message, String from) {
    if (socket.connected) {
      socket.emit('sendMessage', {
        'recipientId': recipient,
        'content': message,
        'from': from,
      });
      print("Message sent to $recipient: $message");
    } else {
      print("Socket is not connected. Unable to send message.");
    }
  }

  void sendTyping(String from, String recipientId) {
    if (socket.connected) {
      socket.emit('typing', {'username': from, 'recipientId': recipientId});
      print('$from started typing...');
    } else {
      print("Socket is not connected. Unable to emit typing status.");
    }
  }

  void sendStopTyping(String from, String recipientId) {
    if (socket.connected) {
      socket
          .emit('stop_typing', {'username': from, 'recipientId': recipientId});
      print('$from stopped typing');
    } else {
      print("Socket is not connected. Unable to emit stop typing status.");
    }
  }

  void disconnect() {
    socket.disconnect();
    print('Socket disconnected');
    // Optionally clear data on disconnect
    activeUsers.clear();
    receivedMessages.clear();
    typingStatus.clear();
    notifyListeners();
  }

  IO.Socket getSocket() {
    return socket;
  }

  List<Map<String, dynamic>> getActiveUsers() {
    return activeUsers;
  }

  Map<String, bool> getTypingStatus() {
    return typingStatus;
  }
}


/*
   // Send a message via socketrecipientId: recipientId,
  void sendMessage(String recipient, String message, String from) {
    // Prepare the payload for the message
    Map<String, dynamic> payload = {
      'recipientId': recipient,
      'content': message,
      'from': from,
    };
    
    socket.emit('sendMessage', payload);
  }






  import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';

Future<void> sendMessage(String recipient, String message, String from, {File? file}) async {
  try {
    // Prepare the payload for the message
    var uri = Uri.parse('https://your-api-endpoint/sendMessage'); // Replace with your actual API endpoint
    
    var request = http.MultipartRequest('POST', uri);

    // Add message text to the request
    request.fields['recipientId'] = recipient;
    request.fields['content'] = message;
    request.fields['from'] = from;

    if (file != null) {
      // Add file to the request as a multipart file
      var fileStream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'file', // Name of the field in your API
        fileStream,
        length,
        filename: file.uri.pathSegments.last,
        contentType: MediaType('application', 'octet-stream'), // Adjust the content type as necessary
      );

      request.files.add(multipartFile);
    }

    // Send the request to the server
    var response = await request.send();

    if (response.statusCode == 200) {
      // If the request is successful, handle the response
      print('Message sent successfully');
      // Handle the server's response, e.g., update the UI or show a success message
    } else {
      print('Failed to send message: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending message: $e');
  }
}
 */