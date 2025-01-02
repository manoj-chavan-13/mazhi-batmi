import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazhi_batmi/posts/full_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_screen.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({required this.userId, super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  List<Post> userPosts = [];
  bool isFollowing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      // Fetch user data
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('uid', widget.userId)
          .single();
      // Fetch user posts
      final postsResponse =
          await _supabase.from('posts').select().eq('user_id', widget.userId);

      // Check if the current user is following
      final currentUserId = _supabase.auth.currentUser?.id;
      final followResponse = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUserId!)
          .eq('following_id', widget.userId)
          .single();

      bool isFollowing = followResponse.isEmpty
          ? false
          : followResponse['follower_id'] == followResponse['following_id'];

      setState(() {
        userData = userResponse;
        userPosts = postsResponse.map<Post>((post) {
          return Post(
            senderName: post['user_id'] ?? '',
            title: post['content'] ?? '',
            content: post['content'] ?? '',
            imageUrl: post['media_url'] ?? '',
            comments: [],
          );
        }).toList();
        this.isFollowing = isFollowing;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (isFollowing) {
        // Unfollow
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId!)
            .eq('following_id', widget.userId);
      } else {
        // Follow
        await _supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': widget.userId,
        });
      }
      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      print('Error toggling follow status: $e');
    }
  }

  void _goToPostDetail(BuildContext context, Post post) {
    if (post.senderName.isEmpty) {
      print("Error: senderName is null or empty");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card Skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 15,
              color: Colors.white,
              shadowColor: const Color.fromARGB(34, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Circle Placeholder for Profile Picture
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Column for Name and Bio Placeholder
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 18,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 14,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        // Follow Button Placeholder
                        Container(
                          width: 100,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Posts Card Skeleton
          Card(
            color: Colors.white,
            elevation: 5,
            shadowColor: const Color.fromARGB(34, 0, 0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  // GridView Skeleton for Posts
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 6, // Placeholder for 6 posts
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        title: Text(userData != null ? userData!['name'] : 'Profile'),
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        surfaceTintColor: const Color.fromARGB(255, 245, 245, 245),
      ),
      body: isLoading
          ? _buildSkeleton() // Display skeleton while loading
          : userData == null
              ? const Center(child: Text('User not found'))
              : Container(
                  color: const Color.fromARGB(255, 245, 245, 245),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Card
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 15,
                          shadowColor: const Color.fromARGB(34, 0, 0, 0),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(
                                      userData!['profile_pic'] ?? ''),
                                  onBackgroundImageError: (_, __) =>
                                      const AssetImage('assets/user.png'),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData!['name'],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        userData!['bio'] ?? 'No bio available'),
                                    ElevatedButton(
                                      onPressed: _toggleFollow,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                          isFollowing ? 'Unfollow' : 'Follow'),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Posts Card
                      Expanded(
                        child: Card(
                          elevation: 5,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                userPosts.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/Empty.svg',
                                              height:
                                                  100, // Adjust size if needed
                                              width:
                                                  100, // Adjust size if needed
                                            ),
                                            SizedBox(
                                                height:
                                                    20), // Add space between image and text
                                            Text(
                                              'They had Not Post Anything!',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Color.fromARGB(
                                                    255, 181, 181, 181),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 1,
                                        ),
                                        itemCount: userPosts.length,
                                        itemBuilder: (context, index) {
                                          final post = userPosts[index];
                                          return GestureDetector(
                                            onTap: () =>
                                                _goToPostDetail(context, post),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                post.imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
