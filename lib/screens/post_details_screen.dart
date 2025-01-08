import 'package:flutter/material.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/post_component.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post; // Accept Post object as parameter
  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api/posts");
  final ScrollController _scrollController =
      ScrollController(); //For Auto ScrollController

  String? _replyToCommentId;
  TextEditingController _replyController = TextEditingController();

  // This keeps track of which comments have expanded replies
  Set<String> _expandedComments = Set<String>();

  bool _isLoading = false;

  Map<String, dynamic> data = {};

  Future<void> getDetails() async {
    print("This is the post ID");
    print(widget.post.id);
    try {
      // Call the delete API
      final response = await httpService.get("/${widget.post.id}");
      print("Post details here!");
      setState(() {
        data = response; // Update the state to reflect the new data
      });
      print(response);

      // Scroll to the last comment after loading the post details
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load friends')),
      );
    } finally {
      print("done");
    }
  }

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  void _addComment(String postId, String comment) async {
    setState(() {
      _isLoading = true; // Set loading to false
    });

    try {
      final response =
          await httpService.post('/$postId/comment', {'content': comment});
      print("This is the added comment my brother david!");
      print(response);

      if (response['statusCode'] == 201) {
        setState(() {
          // Add the new comment to the comments list
          final newComment = {
            '_id': response['body']['comment']['_id'],
            'content': response['body']['comment']['content'],
            'user': response['body']['comment']['user']['username'],
            'createdAt': DateTime.now().toIso8601String(),
            'replies': [],
          };
          print("This is the added comment now!");
          print(newComment);

          // Add the new comment to the existing list
          widget.post.addComment(newComment);
          print(widget.post);
        });

        // Ensure scrolling happens after the comment is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(); // Scroll to the new comment
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['body']['message'])));
      } else {
        final String errorMessage =
            response['body']['message'] ?? 'Something went wrong';
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[400],
        ));
      }
    } catch (e) {
      print('Error: $e'); // Handle errors here\
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  // Add delete comment method
  Future<void> _deleteComment(String postId, String commentId) async {
    setState(() {
      widget.post.comments
          .removeWhere((comment) => comment['_id'] == commentId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment deleted successfully')),
    );
    /*
    try {
      // Call the delete API to delete the comment
      final response = await httpService.delete('/$postId/comment/$commentId');
      print("Comment deleted: $response");

      if (response['statusCode'] == 200) {
        // On successful deletion, remove the comment from the list
        setState(() {
          widget.post.comments.removeWhere((comment) => comment['id'] == commentId);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted successfully')),
        );
      } else {
        final String errorMessage =
            response['body']['message'] ?? 'Something went wrong';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red[400]),
        );
      }
    } catch (e) {
      print('Error: $e'); // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete comment')),
      );
    }
    */
  }

  void _addReply(String commentId, String reply) async {
    if (reply.isEmpty) return;
    try {
      final response = await httpService.post(
          '/${widget.post.id}/comment/$commentId/reply', {'content': reply});

      if (response['statusCode'] == 201) {
        setState(() {
          final replyData = response['body']['reply'];
          final comment = widget.post.comments
              .firstWhere((comment) => comment['_id'] == commentId);
          // Initialize replies if null before adding
          comment['replies'] ??= [];
          comment['replies'].add(replyData);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reply added')));
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to add reply')));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error occurred')));
    }
  }

  void _toggleRepliesVisibility(String commentId) {
    setState(() {
      if (_expandedComments.contains(commentId)) {
        _expandedComments.remove(commentId);
      } else {
        _expandedComments.add(commentId);
      }
      _replyToCommentId = commentId;
    });
  }

  // Scroll to the last comment
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Animate to the bottom of the ListView
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post; // Access the passed post object

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: const Text(
          'Posts Details',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.userThumbnailUrl),
                ),
                const SizedBox(width: 8),
                Text(post.username,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(_formatTimestamp(post.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            // Post Text
            Text(post.text),
            // Post Image (if available)
            /*
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(post.imageUrl!),
              ),
              */
            // Display media (image/video)
            if (post.media.isNotEmpty)
              ...post.media.map((mediaItem) {
                if (mediaItem['type'] == 'image') {
                  return Image.network(
                      "https://ki-kati.com${mediaItem['url']}");
                }
                // Add handling for other types like video, if necessary
                return Container(); // Return empty container if media type is not recognized
              }).toList(),
            const SizedBox(height: 16),
            // Likes and Comments
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up, color: Colors.red[600], size: 20),
                  onPressed: () {
                    // Handle like action (example: toggle like for user)
                    setState(() {
                      post.toggleLike('userId'); // Use actual userId here
                    });
                  },
                ),
                Text(post.likes.length.toString(),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.comment, color: Colors.amber[700], size: 20),
                  onPressed: () {
                    // Show bottom sheet to add a comment
                    _showCommentPopup(context);
                  },
                ),
                Text(post.comments.length.toString(),
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(),
            // Comments Section
            const Text('Comments',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Comments and Replies
            for (var comment in post.comments)
              Dismissible(
                key: Key(comment[
                    '_id']), // Unique key for each comment to handle dismissal
                direction: DismissDirection
                    .endToStart, // Swipe direction (left to right)
                onDismissed: (direction) {
                  // Handle the dismissal action (e.g., delete comment)
                  _deleteComment(post.id, comment['_id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment deleted')),
                  );
                },
                background: Container(
                  color: Colors.red, // Color when swiping to delete
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment
                    ListTile(
                      title: Text(comment['user']['username'] ?? 'Anonymous'),
                      subtitle: Text(comment['content'] ?? 'No content'),
                      trailing: Text(_formatTimestamp(
                          DateTime.parse(comment['createdAt']))),
                      onTap: () {
                        // Toggle replies visibility for this comment
                        _toggleRepliesVisibility(comment['_id']);
                      },
                    ),
                    // Replies (only visible if this comment's ID is in the expanded set)
                    if (_expandedComments.contains(comment['_id']))
                      for (var reply in comment['replies'] ?? [])
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: ListTile(
                            title:
                                Text(reply['user']['username'] ?? 'Anonymous'),
                            subtitle: Text(reply['content'] ?? 'No content'),
                            trailing: Text(_formatTimestamp(
                                DateTime.parse(reply['createdAt']))),
                          ),
                        ),
                    if (_replyToCommentId == comment['_id'])
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Text field for adding a reply
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Add a reply...',
                                  border:
                                      InputBorder.none, // Removes the border
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Button to submit the reply
                            ElevatedButton(
                              onPressed: () {
                                String reply = _replyController.text.trim();
                                if (reply.isNotEmpty) {
                                  _addReply(comment['_id'],
                                      reply); // Add the reply to the comment
                                  _replyController.clear();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Reply cannot be empty')),
                                  );
                                }
                              },
                              child: const Text('Submit Reply'),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                  ],
                ),
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

  // Function to show bottom sheet for adding a comment
  void _showCommentPopup(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          // Use the Dialog widget instead of AlertDialog
          insetPadding:
              const EdgeInsets.all(10), // Remove any padding from the dialog
          child: Container(
            width: double.infinity, // Make the container take the full width
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a comment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  decoration:
                      const InputDecoration(hintText: 'Type your comment'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        String comment = _commentController.text.trim();
                        if (comment.isNotEmpty) {
                          _addComment(
                              widget.post.id, comment); // Pass comment here
                          //Navigator.of(context).pop(); // Close the popup after posting
                        } else {
                          // Show an error message if the comment is empty
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Comment cannot be empty')),
                          );
                        }
                      },
                      child: const Text('Post Comment'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the popup
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


/*
 void _showCommentBottomSheet(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // To make the height configurable
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a comment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration:
                    const InputDecoration(hintText: 'Type your comment'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      String comment = _commentController.text.trim();
                      if (comment.isNotEmpty) {
                        _addComment(
                            widget.post.id, comment); // Pass comment here
                      } else {
                        // Show an error message if comment is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Comment cannot be empty')),
                        );
                      }
                    },
                    child: const Text('Post Comment'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
*/
