import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/secureStorageServices.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ki_kati/screens/post_details_screen.dart';

class PostsFeedScreen extends StatefulWidget {
  @override
  _PostsFeedScreenState createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> {
  SecureStorageService storageService = SecureStorageService();
  final HttpService httpService = HttpService("https://ki-kati.com/api/posts");
  Map<String, dynamic>? retrievedUserData;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<File> filesSelected = [];

  List<dynamic> posts = [];
  bool isLoading = true;

  void _resetFields() {
    setState(() {
      _titleController.text = "";
      _contentController.text = "";
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    retrievedUserData = await storageService.retrieveData('user_data');
    setState(() {});
  }

  Future<void> fetchPosts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await httpService.get('/');
      setState(() {
        posts = List.from(response); // Update posts
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching posts: $error');
    }
  }

  Future<void> _likePost(String postId) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Find the post to like/unlike
      final post = posts.firstWhere((post) => post['_id'] == postId);
      final isLiked = post['likes'].contains(retrievedUserData?['user']['_id']);
      final endpoint = isLiked ? '/$postId/unlike' : '/$postId/like';

      final response = await httpService.post(endpoint, {});
      if (response['statusCode'] == 200) {
        setState(() {
          if (isLiked) {
            post['likes'].remove(retrievedUserData?['user']['_id']);
          } else {
            post['likes'].add(retrievedUserData?['user']['_id']);
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
        isLoading = false;
      });
    }
  }

  String formatTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      // List to store selected files
      List<File> selectedFiles = [];

      for (var file in result.files) {
        // Create a File object for each picked file
        selectedFiles.add(File(file.path!));
      }

      setState(() {
        filesSelected = selectedFiles;
      });

      // Showing a snack bar with file names
      String fileNames = result.files.map((e) => e.name).join(', ');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Picked files: $fileNames"),
      ));
    } else {
      // User canceled the picker
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No file was picked"),
      ));
    }
  }

  void _addPost() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.postdio('/create', {
        'content': _contentController.text,
        'title': _titleController.text,
        'media': filesSelected
      });
      print(response);

      if (response['statusCode'] == 201) {
        // success
        /*var postData = response['body']['post'];
        // Add the newly created post to the posts list
        setState(() {
          //posts.insert(0, postData); // Insert at the top of the list
        });
        */

        // Fetch updated posts
        await fetchPosts();

        setState(() {
          isLoading = false; // Set loading to false
          // Reset the input fields
        });
      }
    } catch (e) {
      print('Error: $e'); // Handle errors here\
    } finally {
      _resetFields();
      setState(() {
        isLoading = false; // Set loading to false
      });
      // Close the Bottom Sheet
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  void _showAddPostBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to expand fully
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Post',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Title input
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Post Title',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Content input
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Post Content',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // File picker button
                    TextButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.image, color: Colors.blue),
                      label: const Text('Select Files to Upload'),
                    ),
                    const SizedBox(height: 10),

                    // Display selected files
                    if (filesSelected.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: filesSelected.map((file) {
                          return Stack(
                            children: [
                              Image.file(
                                file,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      filesSelected.remove(file);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // Submit and cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _addPost,
                          child: const Text('Create Post'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
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

  Future<void> _deletePost(String postId) async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await httpService.delete('/$postId');
      print(response);
      if (response['statusCode'] == 200) {
        setState(() {
          posts.removeWhere((post) => post['_id'] == postId);
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['body']['message']),
            backgroundColor: Colors.green[400],
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete post'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      print('Error: $e'); // Handle errors here
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error deleting post'),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addComment(String postId, String comment) async {
    try {
      setState(() {
        isLoading = true;
      });
      final response =
          await httpService.post('/$postId/comment', {'content': comment});
      print(response);
      if (response['statusCode'] == 201) {
        //add overall comment eventually
        setState(() {
          final post = posts.firstWhere((post) => post['_id'] == postId);
          print("This is the post found");
          print(post);
          post['comments'].add({
            'content': comment,
            'author': response['body']['comment']['user']['username'],
            'timestamp': response['body']
                ['createdAt'] //DateTime.now().toIso8601String(),
          });
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
        isLoading = false; // Set loading to false
      });
    }
  }

  void _showAddCommentDialog(String postId) {
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(15),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a comment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your comment',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final comment = _commentController.text.trim();
                          if (comment.isNotEmpty) {
                            _addComment(postId, comment);
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comment cannot be empty'),
                              ),
                            );
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text(
          'Posts Feed',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPostBottomSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Content
          ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final authorName =
                  '${post['author']['firstName']} ${post['author']['lastName']}';
              final content = post['content'] ?? 'No content';
              final media = post['media'];
              final imageUrl = (media != null && media.isNotEmpty)
                  ? 'https://ki-kati.com${media[0]['url']}'
                  : null;
              final likesCount = post['likes'].length;
              final commentsCount = post['comments'].length;
              final createdAt = formatTimestamp(post['createdAt']);
              final isLiked =
                  post['likes'].contains(retrievedUserData?['user']['_id']);
              final isAuthor =
                  post['author']['_id'] == retrievedUserData?['user']['_id'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: User and timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Space between name and delete button
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                child: Text(authorName[0]),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (isAuthor) // Show delete button only for the author
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deletePost(
                                    post['_id']); // Call the delete post method
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Post content
                      Text(
                        content,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      // Media (Image)
                      // Media (Image)
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Footer: Likes, views, and comments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _likePost(post['_id']),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Text('$likesCount'),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailsScreen(postId: post['_id']),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'details',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.teal),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.read_more,
                                    color: Colors.teal, size: 22),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showAddCommentDialog(
                                post['_id']), // Open comment dialog
                            child: Row(
                              children: [
                                const Icon(Icons.comment,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 5),
                                Text('$commentsCount'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Loading Indicator
          if (isLoading)
            Positioned.fill(
              child: Container(
                color:
                    Colors.black.withOpacity(0.5), // Semi-transparent overlay
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
