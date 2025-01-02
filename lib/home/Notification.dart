import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationList extends StatefulWidget {
  final ScrollController scrollController;

  const NotificationList({
    super.key,
    required this.scrollController,
  });

  @override
  _NotificationListState createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  List<Map<String, String>> notifications = [];

  @override
  void initState() {
    super.initState();
    listenToPosts();
  }

  void listenToPosts() {
    final supabase = Supabase.instance.client;

    final subscription = supabase
        .from('posts')
        .stream(primaryKey: ['id']) // You can specify a primary key if needed
        .order('created_at', ascending: false) // Optionally order the results
        .listen((List<Map<String, dynamic>> data) async {
          if (data.isNotEmpty) {
            final payload = data.first; // Handle new record

            // Fetch user details using user_id
            final userId =
                payload['user_id']; // Get user_id from the post payload

            final userResponse = await supabase
                .from('users')
                .select('name')
                .eq('uid', userId)
                .single();

            if (userResponse == null) {
              // Handle the error (if any)
              print('Error fetching user:');
            } else {
              final username = userResponse['name'] ?? 'Unknown user';

              // Generate a new notification
              String newNotification = 'Check out the post by $username';

              // Add the new notification to the list
              addNotification({
                'title': newNotification,
                'content': payload['title'] ?? 'No content available',
                'username': username,
                'mediaUrl':
                    payload['media_url'] ?? '', // Assuming there's a media URL
              });
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0), // Adjust the value as per your design
        topRight: Radius.circular(16.0), // Adjust the value as per your design
      ),
      child: Container(
        color: const Color.fromARGB(255, 241, 241, 241),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              return Card(
                elevation: 4.0,
                shadowColor: const Color.fromARGB(39, 0, 0, 0),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12.0),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(notification['mediaUrl'] ??
                        'https://via.placeholder.com/150'), // Replace with your media URL
                    radius: 25.0,
                  ),
                  title: Text(
                    notification['title'] ?? 'New Notification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(notification['content'] ?? 'No content available'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void addNotification(Map<String, String> notification) {
    // Prevent adding duplicate notifications
    if (!notifications.contains(notification)) {
      setState(() {
        notifications.insert(0, notification); // Adds at the top
      });
    }
  }
}
