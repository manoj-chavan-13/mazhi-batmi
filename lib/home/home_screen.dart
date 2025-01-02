import 'package:firebase_messaging/firebase_messaging.dart';
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
  bool isLoading = true;
  String searchQuery = '';
  int notificationCount = 0;
  String Temp = '';
  @override
  void initState() {
    super.initState();
    fetchPosts();
    _loadTemp();
    listenForNotifications();
  }

  // Function to load the last notification ID from SharedPreferences
  Future<void> _loadTemp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      Temp = prefs.getString('last_notification_id') ?? '';
    });
  }

  // Function to save the notification ID to SharedPreferences
  Future<void> _saveTemp(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_id', id);
  }

  Future<void> fetchPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('category', selectedCategory)
          // Match search term anywhere in the title
          .or(
              'content.ilike.%$searchQuery%') // Match search term anywhere in the content  // Full-text search on content// You can match content as well
          .order('created_at',
              ascending:
                  false); // Order posts by creation date (most recent first)

      setState(() {
        posts = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  String userName = 'Manoj'; // Change this as needed

  void listenForNotifications() {
    final supabase = Supabase.instance.client;

    // Listen to changes in the 'posts' table
    final subscription = supabase
        .from('posts') // Listen to the posts table
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Order by created_at
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            if (data.first['id'] != Temp) {
              setState(() {
                notificationCount++;
                _saveTemp(data.first['id']);
              });
            }
          }
        });

    // Ensure to cancel the subscription when the widget is disposed
    @override
    void dispose() {
      subscription
          ?.cancel(); // Cancel the subscription when the widget is disposed
      super.dispose();
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

  // FocusNode for managing focus of the TextField
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    // Don't forget to dispose the FocusNode to avoid memory leaks
    _focusNode.dispose();

    super.dispose();
  }

  void _showNotifications(BuildContext context) {
    setState(() {
      notificationCount = 0;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Removes the extra background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft:
              Radius.circular(20), // Adjust the radius for the top-left corner
          topRight:
              Radius.circular(20), // Adjust the radius for the top-right corner
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
            );
          },
        );
      },
      isScrollControlled: true,
    );
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display username in large size
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22, // Larger font size for the username
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Display greeting in smaller size
                Text(
                  getGreeting(),
                  style: TextStyle(
                    fontSize: 14, // Smaller font size for the greeting
                    color: Colors
                        .grey, // You can also add a color for the greeting
                  ),
                ),
              ],
            ),
            // Notification Bell Icon with Count
            GestureDetector(
              onTap: () {
                _showNotifications(context);
              },
              child: Stack(
                children: [
                  Icon(Icons.notifications),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(notificationCount.toString(),
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside of the TextField
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value; // Update search query
                      isLoading = true; // Set loading state when user types
                    });
                    fetchPosts(); // Fetch posts based on the search query
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
              posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/NotFound.svg',
                            height: 400, // Adjust size if needed
                            width: 400, // Adjust size if needed
                          ),
                          SizedBox(
                              height: 20), // Add space between image and text
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
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                          color: const Color.fromARGB(255, 244, 244, 244),
                          child: isLoading
                              ? ListView.builder(
                                  itemCount:
                                      5, // Show 5 skeleton loaders while loading
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return NewsCardSkeleton();
                                  },
                                )
                              : Column(
                                  children: posts.map((post) {
                                    return NewsCard(news: post);
                                  }).toList(),
                                )),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
