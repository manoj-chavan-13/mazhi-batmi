import 'package:flutter/material.dart';
import 'package:mazhi_batmi/models/post.dart';
import 'package:mazhi_batmi/posts/full_view.dart' as full_view;
import 'package:mazhi_batmi/services/notification_service.dart';
import 'package:mazhi_batmi/user/profile_screen.dart' as profile;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final unreadNotifications =
          await _notificationService.getUnreadNotifications(userId);
      setState(() {
        notifications = unreadNotifications;
        isLoading = false;
      });
    }
  }

  void _subscribeToNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _notificationService
          .subscribeToNotifications(userId)
          .listen((newNotifications) {
        setState(() {
          notifications = newNotifications;
        });
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _notificationService.markAllAsRead(userId);
      setState(() {
        notifications = [];
      });
    }
  }

  Future<void> _goToPost(String postId) async {
    try {
      // Fetch post details
      final postResponse = await _supabase.from('posts').select('''
            *,
            user:users!posts_user_id_fkey(name, profile_pic)
          ''').eq('id', postId).single();

      // Create Post object with fetched data
      final post = Post(
        Postid: postResponse['id'],
        senderName: postResponse['user']['name'] ?? '',
        title: postResponse['content'] ?? '',
        content: postResponse['content'] ?? '',
        imageUrl: postResponse['media_url'] ?? '',
        videoUrl: postResponse['video_url'],
        comments: (postResponse['comments'] as List<dynamic>?)?.map((comment) {
          return Comment(
            username: comment['username'] ?? '',
            commentText: comment['comment_text'] ?? '',
            userProfileUrl: comment['user_profile_url'] ?? '',
          );
        }).toList(),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => full_view.PostDetailScreen(post: post),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text('No new notifications'),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final sender =
                        notification['sender'] as Map<String, dynamic>;
                    final post = notification['post'] as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(sender['profile_pic'] ?? ''),
                          onBackgroundImageError: (_, __) =>
                              const AssetImage('assets/user.png'),
                          radius: 25,
                        ),
                        title: Text(
                          notification['message'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sender['name'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            if (post['title'] != null &&
                                post['title'].isNotEmpty)
                              Text(
                                'Post: ${post['title']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Text(
                          _formatTimestamp(notification['created_at']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () => _goToPost(post['id']),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
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
  }
}
