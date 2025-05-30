class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String backdropPath;
  final String videoUrl;
  final List<String> categories;
  final List<String> type; // Changed from String to List<String>
  final double rating;
  final List<String> tags;
  final String releaseDate;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.backdropPath,
    required this.videoUrl,
    required this.categories,
    required this.type,
    required this.rating,
    required this.tags,
    required this.releaseDate,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      backdropPath: json['backdropPath'] as String,
      videoUrl: json['videoUrl'] as String,
      categories: List<String>.from(json['categories'] as List? ?? []), // Ensure null check
      type: List<String>.from(json['type'] as List? ?? []), // Ensure null check and correct type
      // Removed duplicated lines for categories and type
      rating: (json['rating'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List? ?? []), // Ensure null check
      releaseDate: json['releaseDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'backdropPath': backdropPath,
      'videoUrl': videoUrl,
      'categories': categories,
      'type': type, // This remains the same, but 'type' is now List<String>
      'rating': rating,
      'tags': tags,
      'releaseDate': releaseDate,
    };
  }
}
