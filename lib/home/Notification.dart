import 'package:flutter/material.dart';

class NotificationList extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> notifications;

  const NotificationList({
    super.key,
    required this.scrollController,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      child: Container(
        color: const Color.fromARGB(255, 241, 241, 241),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            controller: scrollController,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              try {
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
                      backgroundImage: NetworkImage(
                        notification['mediaUrl'] ??
                            'https://via.placeholder.com/150',
                      ),
                      radius: 25.0,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle image loading error
                        print('Error loading notification image: $exception');
                      },
                    ),
                    title: Text(
                      notification['title'] ?? 'New Notification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(
                          notification['content'] ?? 'No content available',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notification['timestamp'] != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              _formatTimestamp(notification['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                print('Error building notification item: $e');
                return SizedBox.shrink(); // Skip problematic items
              }
            },
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return '';
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return '';
    }
  }
}
