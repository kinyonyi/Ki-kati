//import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ki_kati/screens/post_details_screen.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final Function(String) onLike;
  final Function(String) onComment;

  const PostWidget({
    required this.post,
    required this.onLike,
    required this.onComment,
    super.key,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.post.userThumbnailUrl),
                ),
                const SizedBox(width: 8),
                Text(widget.post.username,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  _formatTimestamp(widget.post.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Post Text
            Text(widget.post.text),
            /*
            // Iterate through all media (images)
            if (widget.post.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: widget.post.imageUrls.map((imageUrl) {
                    return Image.network(imageUrl);
                  }).toList(),
                ),
              ),
              */

            // Display media (image/video)
            if (widget.post.media.isNotEmpty)
              ...widget.post.media.map((mediaItem) {
                if (mediaItem['type'] == 'image') {
                  return Image.network(
                      "https://ki-kati.com${mediaItem['url']}");
                }
                // Add handling for other types like video, if necessary
                return Container(); // Return empty container if media type is not recognized
              }).toList(),
            // Likes and Comments
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: Colors.red[600],
                    size: 14,
                  ),
                  onPressed: () {
                    widget.onLike(widget.post.id);
                  },
                ),
                Text(widget.post.likes.length.toString()),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PostDetailsScreen(post: widget.post),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Make the row take up only as much space as needed
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.amber[700],
                        size: 14, // Adjust icon size as needed
                      ),
                      const SizedBox(
                          width: 8), // Space between the icon and text
                      const Text(
                        "comments",
                        style: TextStyle(
                            fontSize: 14), // Adjust text style if needed
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.comment,
                    color: Colors.amber[700],
                    size: 14,
                  ),
                  onPressed: () {
                    _showCommentDialog(context);
                  },
                ),
                Text(widget.post.comments.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showCommentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing when tapping outside
      builder: (context) {
        return AlertDialog(
          //insetPadding: const EdgeInsets.all(10),
          title: const Text(
            'Add a comment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 150, // Limiting the height of the TextField
              ),
              child: TextField(
                style: const TextStyle(fontSize: 14),
                controller: _commentController,
                maxLines: 5, // Limit the text field to 5 lines
                decoration:
                    const InputDecoration(hintText: 'Type your comment'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  widget.onComment(_commentController.text);
                  _commentController.clear();
                }
                Navigator.of(context).pop(); // Close the dialog after posting
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}

class Post {
  final String id;
  final String userId;
  final String username;
  final String userThumbnailUrl;
  final String text;
  final List<Map<String, dynamic>> media;
  final DateTime timestamp;
  //int likes;
  List<String> likes; // List of user IDs who liked the post
  List<Map<String, dynamic>> comments; // List of maps for comments

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userThumbnailUrl,
    required this.text,
    required this.media,
    required this.timestamp,
    //this.likes = 0,
    List<String>? likes, // List of user IDs for likes
    List<Map<String, dynamic>>? comments, // List of maps for comments
  })  : comments = comments ?? [],
        likes = likes ?? []; // Default to an empty list if none is provided

  @override
  String toString() {
    return '''
    Post {
      id: $id,
      userId: $userId,
      username: $username,
      text: $text,
      likes: ${likes.length} (${likes.join(', ')}),
      comments: [
        ${comments.map((comment) {
      return '''
          {
            _id: ${comment['_id']},
            content: ${comment['content']},
            user: ${comment['user']},
            createdAt: ${comment['createdAt']}
          }''';
    }).join(',\n')}
      ]
    }''';
  }

  // Get image URL from the media list
  List<String> get imageUrls {
    // Extract URLs from the media list, assuming each media object has a 'url' field
    return media
        .where((mediaItem) => mediaItem['url'] != null)
        .map((mediaItem) => mediaItem['url'].toString())
        .toList();
  }

  void addComment(Map<String, dynamic> comment) {
    comments.add(comment);
  }

  // Add a like from a user (by user ID)
  void addLike(String userId) {
    if (!likes.contains(userId)) {
      likes.add(
          userId); // Add the user ID to the likes list if not already present
    }
  }

  // Remove a like from a user (by user ID)
  void removeLike(String userId) {
    likes.remove(userId); // Remove the user ID from the likes list
  }

  // Toggle the like status (like if not liked, unlike if already liked)
  void toggleLike(String userId) {
    if (likes.contains(userId)) {
      removeLike(userId); // If already liked, unlike
    } else {
      addLike(userId); // If not liked, add the like
    }
  }
}
