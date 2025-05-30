class ReviewModel  {
  final String id;

  final String videoId;
  
  final String comment;
  
  final double rating;
  
  final DateTime timestamp;

  final String userId; // Added userId
  final String userName; // Added userName
  
  ReviewModel({
    required this.id,
    required this.videoId,
    required this.comment,
    required this.rating,
    required this.timestamp,
    required this.userId, // Added to constructor
    required this.userName, // Added to constructor
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      comment: json['comment'] as String,
      rating: (json['rating'] as num).toDouble(),
      // Assuming backend sends user: { id: '...', name: '...' }
      userId: json['user'] != null ? json['user']['id'] as String : '',
      userName: json['user'] != null ? json['user']['name'] as String : '',
      // Assuming backend sends timestamp as string
      timestamp: DateTime.parse(json['timestamp'] as String),
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
    };
  }
}