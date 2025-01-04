import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:math';
import 'package:ki_kati/services/socket_service.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:file_picker/file_picker.dart';

// Enum for Message Type (you can expand this as needed)
enum MessageType { text, image, video }

extension MessageTypeExtension on String {
  MessageType intoChatMessage() {
    switch (this) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }
}

// MessageModel for representing each message
class MessageModel {
  final String uid;
  final String recvId;
  final String message;
  final String senderUsername;
  final String senderProfileImage;
  final MessageType type;
  final DateTime timeSent;
  final String? files;

  const MessageModel({
    required this.uid,
    required this.recvId,
    required this.message,
    required this.senderUsername,
    required this.senderProfileImage,
    required this.type,
    required this.timeSent,
    this.files, // Initialize fileUrl as null
  });
}

class GroupMessageScreen extends StatefulWidget {
  final String targetUserId;
  final String currentUserName;
  final String targetUsername;
  const GroupMessageScreen({
    super.key,
    required this.currentUserName,
    required this.targetUserId,
    required this.targetUsername,
  });

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  List<MessageModel> messages = [];
  final TextEditingController messageController = TextEditingController();
  final SocketService _socketService = SocketService(); // Singleton instance

  // Track if the user is typing or not
  bool isTyping = false;

  final ScrollController _scrollController =
      ScrollController(); // Scroll controller to manage scrolling

  bool isLoading = false;

  final HttpService httpService = HttpService("https://ki-kati.com/api");
  late Future<List<dynamic>> chatHistory;

  // Timer to debounce the typing status
  Timer? _typingTimer;

  // Listener method to handle changes in the text field (real-time input)
  void _onMessageInputChange() async {
    // If the user starts typing, set isTyping to
    if (messageController.text.isNotEmpty && !isTyping) {
      _socketService.sendTyping(widget.currentUserName, widget.targetUserId);
    }

    // Cancel the previous timer if the user continues typing
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }

    // Start a new timer to detect when the user stops typing
    _typingTimer = Timer(const Duration(seconds: 2), () {
      // After 2 seconds of inactivity, set isTyping to
      _socketService.sendStopTyping(
          widget.currentUserName, widget.targetUserId);
    });
  }

  @override
  void initState() {
    super.initState();

    // Listen for changes in the message input field
    messageController.addListener(_onMessageInputChange);

    // Listen for new direct messages
    _socketService.socket.on("directMessage", (data) {
      if (mounted) {
        setState(() {
          messages.add(MessageModel(
            uid: Random().nextInt(100000).toString(),
            recvId: widget.currentUserName,
            message: data['content'],
            senderUsername: data['sender'],
            senderProfileImage: "",
            type: MessageType.text,
            timeSent: DateTime.now(),
          ));
        });
        _scrollToLastMessage();
      }
    });

    _socketService.socket.on('typing', (data) {
      print('${data['username']} is typing...');

      if (mounted) {
        setState(() {
          isTyping = true;
        });
      }

      // Cancel the previous timer if the user continues typing
      if (_typingTimer != null) {
        _typingTimer!.cancel();
      }

      // Start a new timer to detect when the user stops typing
      _typingTimer = Timer(const Duration(seconds: 2), () {
        // After 2 seconds of inactivity, set isTyping to
        setState(() {
          isTyping = false;
        });
      });
    });

    _socketService.socket.on('stop_typing', (data) {
      print('${data['username']} stopped typing...');

      setState(() {
        isTyping = false;
      });
    });
  }

  @override
  void dispose() {
    // Clean up listener when the screen is disposed

    messageController.removeListener(_onMessageInputChange);
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }

    // Remove socket listeners
    _socketService.socket.off("directMessage");
    _socketService.socket.off('typing');
    _socketService.socket.off('stop_typing');

    super.dispose();
  }

  // Scroll to the last message in the ListView
  void _scrollToLastMessage() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String capitalizeAndFormatName(String name) {
    // Capitalize the first letter of the name
    String capitalized =
        name[0].toUpperCase() + name.substring(1).toLowerCase();

    // Check if the name ends with 's' to handle the possessive form
    if (capitalized.endsWith('s')) {
      return "$capitalized' Chat";
    } else {
      return "$capitalized's Chat";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.teal, // Solid blue background color
            foregroundColor: Colors.white,
            title: Row(children: [
              const CircleAvatar(
                backgroundImage: AssetImage(
                    "images/logo.png"), // Add the target profile image URL
              ),
              const SizedBox(
                  width:
                      10), // Add some space between the avatar and the username
              Text(
                capitalizeAndFormatName(widget.targetUsername),
                style: const TextStyle(fontSize: 14),
              ),
            ]),
            actions: [
              if (isTyping) // Only show the typing indicator when `isTyping` is true
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${widget.targetUsername} is typing...',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ]),
        body: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator()) // Show loading indicator if loading
            : Column(children: [
                // Message input field
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  5), // Optional: Same rounded corners
                              borderSide: const BorderSide(
                                color: Colors
                                    .blueAccent, // Border color when focused
                                width: 1, // Border width
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  5), // Optional: Rounded corners
                              borderSide: const BorderSide(
                                color: Color(
                                    0xFFBDBDBD), // Border color when enabled but not focused
                                width: 1, // Border width
                              ),
                            ),
                          ),
                          maxLines: 3, // Limit to a maximum of 3 lines
                          minLines: 1, // Start with 1 line
                          keyboardType:
                              TextInputType.multiline, // Allow multiline input
                          //textInputAction: TextInputAction.send,
                          textInputAction: TextInputAction
                              .newline, // Allows moving to the next line
                        ),
                      ),
                      IconButton(
                        onPressed: () {}, // Open file picker on button press
                        icon: const Icon(Icons.attach_file),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.send),
                      )
                    ],
                  ),
                ),
              ]));
  }
}
