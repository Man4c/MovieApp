class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String backdropPath;
  final String videoUrl;
  final List<String> categories;
  final String type;
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
      categories: List<String>.from(json['categories'] as List),
      type: json['type'] as String,

      rating: (json['rating'] as num).toDouble(),

      tags: List<String>.from(json['tags'] as List),
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
      'type': type,
      'rating': rating,
      'tags': tags,
      'releaseDate': releaseDate,
    };
  }
}
