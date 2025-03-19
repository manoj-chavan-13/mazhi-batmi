import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String postId,
    required String senderId,
    required String message,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'post_id': postId,
        'sender_id': senderId,
        'message': message,
        'is_read': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get unread notifications for a user
  Future<List<Map<String, dynamic>>> getUnreadNotifications(
      String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            sender:users!notifications_sender_id_fkey(name, profile_pic),
            post:posts!notifications_post_id_fkey(id, title, media_url)
          ''')
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Subscribe to new notifications
  Stream<List<Map<String, dynamic>>> subscribeToNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id']).map((data) {
      final notifications = List<Map<String, dynamic>>.from(data);
      return notifications.where((notification) {
        return notification['user_id'] == userId &&
            notification['is_read'] == false;
      }).toList()
        ..sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
    });
  }
}
