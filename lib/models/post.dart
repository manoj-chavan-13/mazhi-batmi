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
    List<Comment>? comments,
  }) : comments = comments ?? [];

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      Postid: json['id'],
      senderName: json['user_id'] ?? '',
      title: json['content'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['media_url'] ?? '',
      videoUrl: json['video_url'],
      comments: (json['comments'] as List<dynamic>?)?.map((comment) {
        return Comment(
          username: comment['username'] ?? '',
          commentText: comment['comment_text'] ?? '',
          userProfileUrl: comment['user_profile_url'] ?? '',
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': Postid,
      'user_id': senderName,
      'content': content,
      'media_url': imageUrl,
      'video_url': videoUrl,
      'comments': comments
          .map((comment) => {
                'username': comment.username,
                'comment_text': comment.commentText,
                'user_profile_url': comment.userProfileUrl,
              })
          .toList(),
    };
  }
}
