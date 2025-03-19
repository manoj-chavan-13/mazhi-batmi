import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cross_file/cross_file.dart';
import '../models/post.dart';
import '../user/profile_screen.dart' as profile;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  String? UserP;
  String? UserN;
  String? UserI;
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getComment();
  }

  List<Comment> CommentList = [];
  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    // Fetch user data from the 'users' table where 'uid' matches the current user's id
    final response = await Supabase.instance.client
        .from('users')
        .select('name, email, mobile, bio, profile_pic')
        .eq('uid', user!.id) // Match the user ID
        .single(); // Assuming we expect a single result
    setState(() {
      UserP = response['profile_pic'];
      UserN = response['name'];
      UserI = user.id;
    });
  }

  Future<void> _getComment() async {
    final comments_res = await Supabase.instance.client
        .from('Comments')
        .select()
        .eq('post_id', widget.post.Postid!);

    setState(() {
      CommentList = comments_res.map<Comment>((comment) {
        return Comment(
            commentText: comment['comment_c'],
            username: comment['user_name'],
            userProfileUrl: comment['user_profile']);
      }).toList();
    });
  }

  // Function to fetch user data (name, profile pic) from Supabase
  Future<Map<String, String>> _getUserData(String userId) async {
    final response = await Supabase.instance.client
        .from('users')
        .select('name, profile_pic')
        .eq('uid', userId)
        .single();

    return {
      'name': response['name'] ?? 'Unknown',
      'profile_pic':
          response['profile_pic'] ?? 'https://example.com/default-avatar.jpg'
    };
  }

  // Function to add a new comment to the database
  Future<void> _addComment(
      String postId, String userId, String commentText) async {
    final response = await Supabase.instance.client.from('Comments').insert({
      'post_id': postId,
      'user_id': userId,
      'comment_c': commentText,
      'user_profile': UserP,
      'user_name': UserN
    });

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment:')),
      );
    }
  }

  // Method to download media file (image or video)
  Future<File?> _downloadMediaFile(String url, String type) async {
    try {
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final extension = type == 'video' ? '.mp4' : '.jpg';
      final uniqueFileName =
          'post_media_${DateTime.now().millisecondsSinceEpoch}$extension';
      final file = File('${tempDir.path}/$uniqueFileName');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      print('Error downloading media: $e');
      return null;
    }
  }

  // Method to share post
  Future<void> _sharePost() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(width: 16),
              Text('Preparing to share...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );

      // Get user data for the post
      final userData = await _getUserData(widget.post.senderName);

      // Create share text
      final String shareText = '''${widget.post.title}

Posted by: ${userData['name']}

${widget.post.content}

Shared via Mazhi Batmi App''';

      try {
        await FlutterShare.share(
            title: widget.post.title,
            text: shareText,
            linkUrl: widget.post.imageUrl,
            chooserTitle: 'Share via');
      } catch (e) {
        print('Error sharing: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing content'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing share content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.post.Postid!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 4,
        title: Text(
          widget.post.title,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: const Color.fromARGB(255, 0, 0, 0)),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post image with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.post.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 16),
                // Post title
                Text(
                  widget.post.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // Post content
                Text(
                  widget.post.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 20),
                // Fetch and display user data using FutureBuilder
                FutureBuilder<Map<String, String>>(
                  future: _getUserData(widget.post.senderName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: LoadingProfileWidget());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData) {
                      return Center(child: Text('No user data available.'));
                    } else {
                      final userData = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    NetworkImage(userData['profile_pic']!),
                              ),
                              SizedBox(width: 12),
                              Text(
                                userData['name']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                      );
                    }
                  },
                ),
                // Comments section header
                Text(
                  'Comments:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // Display comments or show message if there are no comments
                CommentList.isEmpty
                    ? Text(
                        'No comments yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: CommentList.length,
                        itemBuilder: (context, index) {
                          final comment = CommentList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage:
                                    NetworkImage(comment.userProfileUrl),
                              ),
                              title: Text(
                                comment.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                comment.commentText,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
                SizedBox(height: 16),
                // TextField for adding a comment
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          final commentText = _commentController.text.trim();
                          if (commentText.isNotEmpty) {
                            setState(() {
                              // Add the new comment to the list
                              CommentList.add(Comment(
                                username: UserN!,
                                // Replace with actual username
                                commentText: commentText,
                                userProfileUrl:
                                    UserP!, // Replace with actual profile URL
                              ));
                              // Clear the text field
                              _commentController.clear();
                            });
                            // Add comment to Supabase
                            _addComment(
                                widget.post.Postid!, UserI!, commentText);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Loading Profile Widget
class LoadingProfileWidget extends StatelessWidget {
  const LoadingProfileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 18,
                color: Colors.grey[300],
              ),
              SizedBox(height: 8),
              Container(
                width: 150,
                height: 14,
                color: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dummy Comment class for demonstration
class Comment {
  final String username;
  final String commentText;
  final String userProfileUrl;

  Comment({
    required this.username,
    required this.commentText,
    required this.userProfileUrl,
  });
}
