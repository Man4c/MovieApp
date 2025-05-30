class ReviewModel  {
  final String id;

  final String videoId;
  
  final String comment;
  
  final double rating;
  
  final DateTime timestamp;
  
  ReviewModel({
    required this.id,
    required this.videoId,
    required this.comment,
    required this.rating,
    required this.timestamp,
  });
}