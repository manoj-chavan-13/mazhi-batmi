import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../posts/full_view.dart';
import 'Edit_Profile.dart';
import 'profile_screen_Skeleton.dart';
// Correct your PostDetailScreen import path

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Future<void> _refresh() async {
    setState(() {
      // Clear the current state
      userPosts = [];
      SavedPosts = [];
      isLoading = true; // Show loading indicator
    });

    // Wait for a while to simulate refreshing, then fetch new data
    await Future.delayed(Duration(seconds: 2));

    // Reload user data and posts
    await _getUserData();
    await _getUserPosts();
  }

  String userName = 'UserName';
  String userBio = 'What I feel..!';
  int followersCount = 0;
  int followingCount = 0;
  final SupabaseClient _supabase = Supabase.instance.client;
  String profilePicUrl = '';
  List<Post> userPosts = [];
  List<Post> SavedPosts = [];
  bool isLoading = true;
  bool userP = false;

  Future<void> deletePost(String postId) async {
    final client = Supabase.instance.client;

    // Step 1: Fetch the post data from the Post table
    final postResponse = await client
            .from('posts')
            .select() // Get the media_url field
            .eq('id', postId) // Filter by postId
            .single() // We expect a single result
        ;

    if (postResponse == null) {
      print('Error fetching post: ');
      return;
    }

    // Check if the post exists
    final post = postResponse;
    if (post == null) {
      print('Post not found');
      return;
    }

    // Step 2: Get the media URL
    final mediaUrl = post['media_url'];

    // If there is a media URL, delete it from Supabase Storage
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      try {
        // Extract the file path from the URL (assuming the URL contains the file path)
        final filePath =
            mediaUrl.split('/').last; // Get the file name or path from the URL

        // Delete the media file from Supabase Storage
        final storageResponse =
            await client.storage.from('posts').remove([filePath]);

        if (storageResponse == null) {
          print('Error deleting media:');
        } else {
          print('Media deleted successfully: $filePath');
        }
      } catch (e) {
        print('Error extracting file path or deleting media: $e');
      }
    } else {
      print('No media to delete');
    }

    final DeleteSaved = await client
        .from('SavedPost')
        .delete()
        .eq('PostId', postId)
        .eq('UserId', post['user_id']);

    final DeleteComments =
        await client.from("Comments").delete().eq('post_id', postId);

    // Step 3: Delete the post from the Post table
    final deleteResponse = await client
            .from('posts')
            .delete()
            .eq('id', postId) // Delete post where the postId matches
        ;

    if (deleteResponse != null) {
      print('Error deleting post: ');
    } else {
      print('Post deleted successfully');
      await _refresh();
    }
  }

  Future<void> RemoveSaved(String s) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      print('User is not logged in');
      return;
    }

    // Check if the post is already saved (use your existing method)

    // If already saved, remove it (delete)
    final deleteResponse = await Supabase.instance.client
        .from('SavedPost')
        .delete()
        .eq('UserId', userId)
        .eq('PostId', s);

    await _refresh();
  }

  Future<void> _getUserPosts() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        print("No user is logged in");
        return;
      }

      // Fetch posts data from the 'posts' table where 'user_id' matches the current user's id
      final response = await _supabase
          .from('posts')
          .select(
              'id, content, created_at, media_url,sender_name,user_id') // Add the fields you need
          .eq('user_id',
              user.id) // Match the user ID with 'user_id' in posts table
          .order('created_at', ascending: false);

      final savedPostIds = await _supabase
          .from('SavedPost')
          .select('PostId')
          .eq('UserId', user.id);

      List<String> postIds =
          savedPostIds.map<String>((post) => post['PostId'] as String).toList();

      // Fetch the post data for each PostId one by one (as an alternative)

      for (var postId in postIds) {
        final postDataResponse = await Supabase.instance.client
                .from('posts')
                .select() // Get all fields from the Post table
                .eq('id', postId) // Use 'eq' for individual PostId query
            ;

        if (postDataResponse == null) {
          print('Error fetching post data for PostId $postId:');
          continue; // Skip to next PostId if error occurs
        }

        List Sposts = postDataResponse;

        if (Sposts.isNotEmpty) {
          setState(() {
            SavedPosts.add(Post(
              Postid: Sposts[0]['id'] ?? '',
              senderName: Sposts[0]['user_id'] ?? '',
              title: Sposts[0]['content'] ?? '',
              content: Sposts[0]['content'] ?? '',
              imageUrl: Sposts[0]['media_url'] ?? '',
              comments: [], // You can populate this with comments if needed
            ));
          });
        }
      }
      setState(() {
        if (userPosts.isEmpty) {
          userPosts = response.map<Post>((post) {
            return Post(
              Postid: post['id'],
              senderName:
                  post['user_id'] ?? '', // Default to empty string if null
              title: post['content'] ?? '', // Default to empty string if null
              content: post['content'] ?? '', // Default to empty string if null
              imageUrl:
                  post['media_url'] ?? '', // Default to empty string if nu
              comments: [],
              // You can populate this with comments if needed
            );
          }).toList();
          userP = false;
        }
      });
    } catch (e) {
      print("An error occurred: $e");
    }
  }

  Future<void> _getUserData() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        print("No user is logged in");
        return;
      }

      // Fetch user data from the 'users' table where 'uid' matches the current user's id
      final response = await _supabase
          .from('users')
          .select('name, email, mobile, bio, profile_pic')
          .eq('uid', user.id) // Match the user ID
          .single(); // Assuming we expect a single result

      final Community = await Supabase.instance.client
          .from('follows')
          .select('follower_id, following_id')
          .or('follower_id.eq.${user.id},following_id.eq.${user.id}');

      if (Community == null) {
        setState(() {
          followersCount = 0;
          followingCount = 0;
        });
      }
      int f = 0;
      int fw = 0;

      for (var row in Community) {
        if (row['follower_id'] == user.id) {
          f++;
        } else if (row['following_id'] == user.id) {
          fw++;
        }
      }
      setState(() {
        followingCount = f;
        followersCount = fw;
      });
      setState(() {
        userName = response['name'];
        final String userEmail = response['email'];
        userBio = response['bio'];
        final int userMobile = response['mobile'];
        profilePicUrl = response['profile_pic'];
        isLoading = false;
      });
    } catch (e) {
      print("An error occurred: $e");
    }
  }

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getUserData();
    _getUserPosts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        surfaceTintColor: const Color.fromARGB(255, 245, 245, 245),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color.fromARGB(255, 20, 20, 20),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Container(
            color: const Color.fromARGB(255, 245, 245, 245),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show a loading skeleton or indicator while loading data
                isLoading
                    ? ProfileCard()
                    : Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        elevation: 10,
                        margin: EdgeInsets.all(20),
                        color: Colors.white,
                        shadowColor: const Color.fromARGB(44, 171, 171, 171),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50, // Set the desired radius
                                backgroundColor: Colors.white,
                                child: profilePicUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          profilePicUrl,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child; // If the image is loaded, display it
                                            } else {
                                              // While loading, show the asset image
                                              return CircleAvatar(
                                                radius: 50,
                                                backgroundColor: Colors.white,
                                                backgroundImage: AssetImage(
                                                    'assets/user.png'),
                                              );
                                            }
                                          },
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.white,
                                        backgroundImage:
                                            AssetImage('assets/user.png'),
                                      ), // Show the asset image if URL is not provided
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    userBio,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Followers',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          Text(
                                            '$followersCount',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 16),
                                      Column(
                                        children: [
                                          Text(
                                            'Following',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          Text(
                                            '$followingCount',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditProfileScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Text('Edit Profile'),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    indicatorColor: Colors.black,
                    dividerColor: const Color.fromARGB(255, 242, 242, 242),
                    tabs: [
                      Tab(text: 'Own Posts'),
                      Tab(text: 'Saved Posts'),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: isLoading
                      ? PostsGridSkeleton()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Own Posts Tab
                            userPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/Empty.svg',
                                          height: 100, // Adjust size if needed
                                          width: 100, // Adjust size if needed
                                        ),
                                        SizedBox(
                                            height:
                                                20), // Add space between image and text
                                        Text(
                                          'You haven’t posted anything yet.\nLet’s add some content to get started!',
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
                                    physics: ScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: userPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = userPosts[index];

                                      return GestureDetector(
                                        onTap: () =>
                                            _goToPostDetail(context, post),
                                        onLongPress: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors
                                                      .white, // Set a background color
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0), // Rounded corners for the dialog
                                                  ),
                                                  title: Text(
                                                    "Delete Post",
                                                    style: TextStyle(
                                                      fontSize: 18.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .red, // Highlight the title with a red color
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SvgPicture.asset(
                                                        'assets/Delete_Post.svg',
                                                        height: 120,
                                                      ),
                                                      SizedBox(
                                                        height: 20,
                                                      ),
                                                      Text(
                                                        "Are you sure you want to Delete this post?",
                                                        style: TextStyle(
                                                          fontSize: 16.0,
                                                          color: Colors
                                                              .black87, // Make the content text dark for readability
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        // Call deletePost when user confirms
                                                        deletePost(
                                                            post.Postid!);
                                                        Navigator.pop(
                                                            context); // Close the dialog
                                                      },
                                                      child: Text(
                                                        "Yes",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .white, // Make the button text white
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .red, // Red background for the "Yes" button
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8.0), // Rounded corners
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context); // Close the dialog
                                                      },
                                                      child: Text(
                                                        "No",
                                                        style: TextStyle(
                                                          color: const Color
                                                              .fromARGB(
                                                              255,
                                                              117,
                                                              117,
                                                              117), // Make the "No" button text blue
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .transparent, // Transparent background for "No"
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8.0), // Rounded corners
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              post.imageUrl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            // Saved Posts Tab

                            SavedPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/Empty-folder.svg',
                                          height: 100, // Adjust size if needed
                                          width: 100, // Adjust size if needed
                                        ),
                                        SizedBox(
                                            height:
                                                20), // Add space between image and text
                                        Text(
                                          'You haven’t Saved anything yet.\nLet’s Save Some content to get started!',
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
                                    physics: ScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: SavedPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = SavedPosts[index];
                                      return GestureDetector(
                                        onTap: () =>
                                            _goToPostDetail(context, post),
                                        onLongPress: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors
                                                      .white, // Set a background color
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0), // Rounded corners for the dialog
                                                  ),
                                                  title: Text(
                                                    "Remove Post From Saved",
                                                    style: TextStyle(
                                                      fontSize: 18.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color
                                                          .fromARGB(255, 0, 9,
                                                          90), // Highlight the title with a red color
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SvgPicture.asset(
                                                        'assets/UnSave.svg',
                                                        height: 120,
                                                      ),
                                                      SizedBox(
                                                        height: 20,
                                                      ),
                                                      Text(
                                                        "Are you sure you want to Unsave this post?",
                                                        style: TextStyle(
                                                          fontSize: 16.0,
                                                          color: Colors
                                                              .black87, // Make the content text dark for readability
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        // Call deletePost when user confirms
                                                        RemoveSaved(
                                                            post.Postid!);
                                                        Navigator.pop(
                                                            context); // Close the dialog
                                                      },
                                                      child: Text(
                                                        "Yes",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .white, // Make the button text white
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: const Color
                                                            .fromARGB(
                                                            255,
                                                            19,
                                                            32,
                                                            175), // Red background for the "Yes" button
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8.0), // Rounded corners
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context); // Close the dialog
                                                      },
                                                      child: Text(
                                                        "No",
                                                        style: TextStyle(
                                                          color: const Color
                                                              .fromARGB(
                                                              255,
                                                              111,
                                                              111,
                                                              111), // Make the "No" button text blue
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .transparent, // Transparent background for "No"
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8.0), // Rounded corners
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              post.imageUrl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
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

class Post {
  final String title;
  final String content;
  final String imageUrl;
  final List<Comment> comments;
  final String? videoUrl;
  final String senderName;
  final String? Postid;

  Post({
    required this.senderName,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.Postid,
    this.videoUrl,
    List<Comment>? comments, // Allow comments to be optional
  }) : comments = comments ?? [];

// If comments are null, assign an empty list
}

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
