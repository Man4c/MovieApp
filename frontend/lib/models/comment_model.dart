class CommentModel  {
  final String id;

  final String videoId;
  
  final String comment;
  
  final double rating; // Keep rating for now
  
  final DateTime timestamp;

  final String userId;
  final String userName;
  final String? parentId;
  final List<CommentModel> replies;
  
  CommentModel({
    required this.id,
    required this.videoId,
    required this.comment,
    required this.rating,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.parentId, // Nullable
    required this.replies, // List of CommentModel
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      comment: json['comment'] as String,
      rating: (json['rating'] as num).toDouble(),
      // Assuming backend sends user: { id: '...', name: '...' }
      userId: json['user'] != null ? json['user']['id'] as String : '',
      userName: json['user'] != null ? json['user']['name'] as String : '',
      // Assuming backend sends timestamp as string
      timestamp: DateTime.parse(json['timestamp'] as String),
      parentId: json['parentId'] as String?,
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'comment': comment,
      'rating': rating,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      'parentId': parentId,
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}