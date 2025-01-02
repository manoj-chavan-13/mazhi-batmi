import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../posts/full_view.dart';
import '../posts/post_Skeleton.dart';
import '../user/profile_screen.dart';
import '../user/view_profile.dart';

class NewsCard extends StatefulWidget {
  final Map<String, dynamic> news;

  const NewsCard({super.key, required this.news});

  @override
  _NewsCardState createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  @override
  void initState() {
    super.initState();
    // Call the method automatically when the widget is initialized
    _CheckSaved();
  }

  bool isSaved = false; // Track the save state
  Future<void> _CheckSaved() async {
    final user = Supabase.instance.client.auth.currentUser;

    final response = await Supabase.instance.client
        .from('SavedPost')
        .select()
        .eq('PostId',
            widget.news['id']) // Replace 'yourPostId' with the actual post ID
        .eq('UserId', user!.id)
        .single(); // Checking if the user has saved the post
    ;

    setState(() {
      isSaved = response != null;
    });
  }

  Future<void> _incrementViewCount() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('views')
        .eq('id', widget.news['id'])
        .single();

    var currentViews = response['views'];

    if (currentViews is String) {
      currentViews = int.tryParse(currentViews) ?? 0;
    }

    int updatedViews = currentViews + 1;

    final updateResponse = await Supabase.instance.client
        .from('posts')
        .update({'views': updatedViews.toString()}).eq('id', widget.news['id']);

    if (updateResponse != null) {
      print('Error updating views: ');
    } else {
      print('Views updated successfully');
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('name, profile_pic')
        .eq('uid', widget.news['user_id'])
        .single();

    return {
      'name': response['name'] ?? 'Unknown',
      'profile_pic':
          response['profile_pic'] ?? 'https://example.com/default-avatar.jpg'
    };
  }

  Future<void> savePost() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      print('User is not logged in');
      return;
    }

    // Check if the post is already saved (use your existing method)

    if (isSaved) {
      // If already saved, remove it (delete)
      final deleteResponse = await Supabase.instance.client
          .from('SavedPost')
          .delete()
          .eq('UserId', userId)
          .eq('PostId', widget.news['id']);
      print("deltete res");

      if (deleteResponse != null) {
        print('Error removing saved post:');
      } else {
        setState(() {
          isSaved = false;
        });
        print('Post removed from saved list');
      }
    } else {
      // If not saved, insert it (save)
      final insertResponse =
          await Supabase.instance.client.from('SavedPost').insert({
        'UserId': userId, // Assuming 'user_id' is the correct column name
        'PostId':
            widget.news['id'], // Assuming 'post_id' is the correct column name
      });

      if (insertResponse != null) {
        print('Error saving post:');
      } else {
        setState(() {
          isSaved = true;
        });
        print('Post saved successfully');
      }
    }
  }

  Widget loading(
      BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) {
      // Image loaded, return the child (actual image)
      return child;
    } else {
      // Image loading, show color grading
      return _buildSkeletonLoader(); // Loading spinner
    }
  }

  Widget _buildSkeletonLoader() {
    return Container(
      width: double.infinity,
      height: 200.0, // Set the height according to your image size
      color: Colors.grey[300], // Light grey background for the skeleton loader
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _incrementViewCount();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: Post(
                Postid: widget.news['id'],
                senderName: widget.news['user_id'] ?? 'unknown',
                title: widget.news['title'] ?? 'Untitled',
                content: widget.news['content'] ?? 'No description available',
                imageUrl: widget.news['media_url'] ?? '',
                comments: [],
                videoUrl: null,
              ),
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          shadowColor: const Color.fromARGB(33, 0, 0, 0),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: FutureBuilder<Map<String, String>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: NewsCardSkeleton());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No user data available.'));
                } else {
                  final userData = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      userId: widget.news['user_id'],
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    Color.fromARGB(255, 215, 255, 230),
                                backgroundImage: NetworkImage(userData[
                                        'profile_pic'] ??
                                    'https://example.com/default-avatar.jpg'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'Anonymous',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.news['location'] ?? 'Unknown location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            PopupMenuButton<String>(
                              icon:
                                  Icon(Icons.more_vert, color: Colors.black54),
                              color: Colors.white,
                              onSelected: (String value) {
                                if (value == 'report') {
                                  print('Report clicked');
                                } else if (value == 'unfollow') {
                                  print('Unfollow clicked');
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'report',
                                  child: Text('Report'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'unfollow',
                                  child: Text('Unfollow'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // News Image Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: SizedBox(
                              height: 200.0,
                              width: double.infinity,
                              child: Center(
                                child: Image.network(
                                  widget.news['media_url'] ??
                                      'https://example.com/default-image.jpg',
                                  loadingBuilder: loading,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Description Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.news['title'] ?? 'No description available',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Footer Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 18, color: Colors.grey[600]),
                                SizedBox(width: 6),
                                Text(
                                  (() {
                                    try {
                                      // Parse the date string
                                      DateTime parsedDate = DateTime.parse(
                                          widget.news['created_at']);
                                      // Format the date as yyyy-MM-dd
                                      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
                                    } catch (e) {
                                      // Fallback if date is null or invalid
                                      return 'Unknown date';
                                    }
                                  })(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.visibility,
                                            size: 18, color: Colors.grey[600]),
                                        SizedBox(width: 6),
                                        Text(
                                          widget.news['views'] ?? '0',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 12),
                                    IconButton(
                                      icon: Icon(
                                        isSaved
                                            ? Icons.bookmark
                                            : Icons.bookmark_outline,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: savePost,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
