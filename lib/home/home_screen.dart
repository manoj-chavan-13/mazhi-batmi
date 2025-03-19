import 'dart:convert';
import 'dart:async'; // Add this for TimeoutException

import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';
import 'package:mazhi_batmi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../posts/post_Skeleton.dart';

import 'Notification.dart';
import 'category.dart';
import 'postcard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, String>> notifications = [];
  bool isLoading = true;
  String searchQuery = '';
  int notificationCount = 0;
  String Temp = '';
  String userName = 'Manoj';
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadTemp();
      await loadNotificationsFromDatabase();
      listenForNotifications();
      await _getName();
      await fetchPosts();
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getName() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      print("No user is logged in");
      return;
    }

    final response = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('uid', user.id) // Match the user ID
        .single();
    setState(() {
      userName = response['name'];
    });
  }

  // Function to load the last notification ID from SharedPreferences
// Function to load the last notification ID and notification count from SharedPreferences
  Future<void> _loadTemp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      Temp = prefs.getString('last_notification_id') ?? '';
      notificationCount =
          prefs.getInt('notification_count') ?? 0; // Load notification count
    });
  }

// Function to save the notification ID and notification count to SharedPreferences
  Future<void> _saveTemp(String id, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_id', id);
    await prefs.setInt('notification_count', count); // Save notification count
  }

  Future<void> fetchPosts() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Add timeout to the request
      final response = await supabase
          .from('posts')
          .select()
          .eq('category', selectedCategory)
          .or('content.ilike.%$searchQuery%')
          .order('created_at', ascending: false)
          .timeout(
        Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      setState(() {
        posts = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to load posts. Please check your connection and try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                fetchPosts();
              },
            ),
          ),
        );
      }
    }
  }

  // Add pagination support
  static const int pageSize = 10;
  int currentPage = 1;
  bool hasMorePosts = true;
  bool isLoadingMore = false;

  Future<void> loadMorePosts() async {
    if (isLoadingMore || !hasMorePosts) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final response = await supabase
          .from('posts')
          .select()
          .eq('category', selectedCategory)
          .or('content.ilike.%$searchQuery%')
          .order('created_at', ascending: false)
          .range(currentPage * pageSize, (currentPage + 1) * pageSize - 1)
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response == null || response.isEmpty) {
        setState(() {
          hasMorePosts = false;
          isLoadingMore = false;
        });
        return;
      }

      setState(() {
        posts.addAll(List<Map<String, dynamic>>.from(response));
        currentPage++;
        isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more posts: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  // Add scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  void listenForNotifications() {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        print('No user logged in for notifications');
        return;
      }

      // Listen to changes in the 'posts' table
      supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (List<Map<String, dynamic>> data) async {
              if (data.isEmpty) return;

              try {
                final latestId = data.first['id'];

                // Only process if this is a new post (different from last seen)
                if (latestId != Temp) {
                  final payload = data.first;
                  final postUserId = payload['user_id'];

                  // Don't notify if the post is from the current user
                  if (postUserId == user.id) {
                    await _saveTemp(latestId, notificationCount);
                    setState(() {
                      Temp = latestId;
                    });
                    return;
                  }

                  // Get the post creator's name
                  final userResponse = await supabase
                      .from('users')
                      .select('name')
                      .eq('uid', postUserId)
                      .single();

                  if (userResponse == null) {
                    throw Exception('User not found');
                  }

                  final username = userResponse['name'] ?? 'Unknown user';

                  // Create notification for new post
                  final newNotification = {
                    'title': 'New Post from $username',
                    'content': payload['title'] ?? 'No content available',
                    'username': username,
                    'mediaUrl': payload['media_url'] ?? '',
                    'userId': user.id, // This is the recipient's ID
                    'postId': latestId.toString(),
                    'postUserId': postUserId, // This is the post creator's ID
                  };

                  // Add notification to database
                  await addNotificationToDatabase(newNotification);

                  // Update notification count and last seen post
                  setState(() {
                    notificationCount++;
                  });

                  await _saveTemp(latestId, notificationCount);
                  setState(() {
                    Temp = latestId;
                  });
                }
              } catch (e) {
                print('Error processing notification: $e');
              }
            },
            onError: (error) {
              print('Error in notification stream: $error');
              // Attempt to reconnect
              listenForNotifications();
            },
          );
    } catch (e) {
      print('Error setting up notification listener: $e');
    }
  }

  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showNotifications(BuildContext context) async {
    try {
      setState(() {
        notificationCount = 0;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', 0);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (BuildContext context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 1.0,
            builder: (BuildContext context, scrollController) {
              return NotificationList(
                scrollController: scrollController,
                notifications: notifications,
              );
            },
          );
        },
        isScrollControlled: true,
      );
    } catch (e) {
      print('Error showing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to show notifications. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadNotificationsFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;

      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      // Load notifications for current user
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      if (response == null) {
        print('Error loading notifications: No response from database');
        return;
      }

      setState(() {
        notifications = List<Map<String, String>>.from(response);
        notificationCount = notifications.length;
      });

      // Save the updated count
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', notificationCount);
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                loadNotificationsFromDatabase();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> addNotificationToDatabase(
      Map<String, dynamic> notification) async {
    try {
      final supabase = Supabase.instance.client;

      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Validate required fields
      if (notification['title'] == null || notification['content'] == null) {
        throw Exception('Missing required notification fields');
      }

      // Add user_id and timestamp
      notification['user_id'] = user.id;
      notification['created_at'] = DateTime.now().toIso8601String();

      final response =
          await supabase.from('notifications').insert(notification);

      if (response == null) {
        throw Exception('Failed to insert notification');
      }

      // Refresh notifications list
      await loadNotificationsFromDatabase();
    } catch (e) {
      print('Error adding notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add notification. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                addNotificationToDatabase(notification);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Column for Username and Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    getGreeting(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Notification Bell Icon with Count
            GestureDetector(
              onTap: () {
                _showNotifications(context);
              },
              child: Stack(
                children: [
                  Icon(Icons.notifications),
                  if (notificationCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          notificationCount.toString(),
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Column(
            children: [
              // Search and Categories Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      isLoading = true;
                    });
                    fetchPosts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                ),
              ),
              // Categories ScrollView
              Container(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        CategoryButton(
                          title: 'All',
                          isSelected: selectedCategory == 'All',
                          onTap: () {
                            setState(() => selectedCategory = 'All');
                            fetchPosts();
                          },
                        ),
                        SizedBox(width: 10),
                        CategoryButton(
                          title: 'Sports',
                          isSelected: selectedCategory == 'Sports',
                          onTap: () {
                            setState(() => selectedCategory = 'Sports');
                            fetchPosts();
                          },
                        ),
                        SizedBox(width: 10),
                        CategoryButton(
                          title: 'Tech',
                          isSelected: selectedCategory == 'Tech',
                          onTap: () {
                            setState(() => selectedCategory = 'Tech');
                            fetchPosts();
                          },
                        ),
                        SizedBox(width: 10),
                        CategoryButton(
                          title: 'Health',
                          isSelected: selectedCategory == 'Health',
                          onTap: () {
                            setState(() => selectedCategory = 'Health');
                            fetchPosts();
                          },
                        ),
                        SizedBox(width: 10),
                        CategoryButton(
                          title: 'Business',
                          isSelected: selectedCategory == 'Business',
                          onTap: () {
                            setState(() => selectedCategory = 'Business');
                            fetchPosts();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Posts Section
              Expanded(
                child: posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/NotFound.svg',
                              height: 200,
                              width: 200,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'get started! By Posting News',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 181, 181, 181),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: const Color.fromARGB(255, 244, 244, 244),
                        child: isLoading
                            ? ListView.builder(
                                itemCount: 5,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return NewsCardSkeleton();
                                },
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await fetchPosts();
                                },
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(bottom: 16),
                                  itemCount:
                                      posts.length + (isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == posts.length) {
                                      return Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    return NewsCard(news: posts[index]);
                                  },
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
