import 'package:flutter/material.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/secureStorageServices.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId; // Accept postId instead of a Post object
  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  SecureStorageService storageService = SecureStorageService();
  final HttpService httpService = HttpService("https://ki-kati.com/api/posts");
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  Map<String, dynamic>? postDetails;
  Set<String> _expandedComments = {};
  String? _replyToCommentId;
  bool _isLoading = false;

  Map<String, dynamic>? retrievedUserData;

  Future<void> _fetchUserData() async {
    retrievedUserData = await storageService.retrieveData('user_data');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
    _fetchUserData();
  }

  Future<void> _fetchPostDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await httpService.get('/${widget.postId}');
      print(response);
      setState(() {
        postDetails = response;
      });
    } catch (e) {
      print('Error fetching post details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load post details')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addComment(String comment) async {
    if (comment.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await httpService.post(
        '/${widget.postId}/comment',
        {'content': comment},
      );

      if (response['statusCode'] == 201) {
        setState(() {
          postDetails?['comments'].add(response['body']['comment']);
        });
        _commentController.clear();
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['body']['message'])),
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addReply(String commentId, String reply) async {
    if (reply.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await httpService.post(
        '/${widget.postId}/comment/$commentId/reply',
        {'content': reply},
      );

      if (response['statusCode'] == 201) {
        setState(() {
          final comment =
              postDetails?['comments'].firstWhere((c) => c['_id'] == commentId);
          comment['replies'].add(response['body']['reply']);
        });
        _replyController.clear();
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added')),
        );
      }
    } catch (e) {
      print('Error adding reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add reply')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleReplies(String commentId) {
    setState(() {
      if (_expandedComments.contains(commentId)) {
        _expandedComments.remove(commentId);
      } else {
        _expandedComments.add(commentId);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return '${difference.inDays} days ago';
    if (difference.inHours > 0) return '${difference.inHours} hours ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
    return 'Just now';
  }

  Future<void> _likePost(String postId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      //like/unlike
      final isLiked =
          postDetails?['likes'].contains(retrievedUserData?['user']['_id']);
      final endpoint = isLiked ? '/$postId/unlike' : '/$postId/like';

      final response = await httpService.post(endpoint, {});
      if (response['statusCode'] == 200) {
        setState(() {
          if (isLiked) {
            postDetails?['likes'].remove(retrievedUserData?['user']['_id']);
          } else {
            postDetails?['likes'].add(retrievedUserData?['user']['_id']);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['body']['message']),
            backgroundColor: isLiked ? Colors.red[400] : Colors.green[400],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['body']['message'] ?? 'Error liking post'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                          _addComment(comment.trim()); // Pass comment here
                          Navigator.of(context)
                              .pop(); // Close the popup after posting
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

  @override
  Widget build(BuildContext context) {
    if (postDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final post = postDetails!;
    final comments = post['comments'] ?? [];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text(
          'Post Details',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              controller: _scrollController,
              children: [
                // Post content
                Text(
                  post['content'] ?? 'No content',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Media display
                if (post['media'] != null && post['media'].isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://ki-kati.com${post['media'][0]['url']}',
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                    ),
                  ),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: post['likes']
                                .contains(retrievedUserData?['user']['_id'])
                            ? Colors.red
                            : Colors.grey, // Correct ternary operator
                        size: 20,
                      ),
                      onPressed: () => _likePost(post['_id']),
                    ),
                    Text(postDetails!['likes'].length.toString(),
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.comment,
                          color: Colors.amber[700], size: 20),
                      onPressed: () {
                        // Show bottom sheet to add a comment
                        _showCommentPopup(context);
                      },
                    ),
                    Text(postDetails!['comments'].length.toString(),
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),

                const Divider(),
                // Comments Section
                const Text('Comments', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                for (var comment in comments)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(comment['user']['username'] ?? 'Anonymous'),
                        subtitle: Text(comment['content']),
                        trailing: IconButton(
                          icon: Icon(
                            _expandedComments.contains(comment['_id'])
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.grey,
                          ),
                          onPressed: () => _toggleReplies(comment['_id']),
                        ),
                      ),
                      if (_expandedComments.contains(comment['_id']))
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            children: [
                              for (var reply in comment['replies'] ?? [])
                                ListTile(
                                  title: Text(reply['user']),
                                  /*reply['user']['username'] ?? 'Anonymous'*/
                                  subtitle: Text(reply['content']),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _replyController,
                                      decoration: const InputDecoration(
                                        hintText: 'Write a reply...',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () => _addReply(
                                      comment['_id'],
                                      _replyController.text.trim(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                    ],
                  ),
                // Add comment input
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Add a comment',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => _addComment(value.trim()),
                ),
              ],
            ),
          ),
          // Loading Indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color:
                    Colors.black.withOpacity(0.5), // Semi-transparent overlay
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
