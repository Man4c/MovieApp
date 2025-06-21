class VideoModel {
  final String tmdbId;
  final String title;
  final String description;
  final String posterPath;
  final String backdropPath;
  final String videoUrl;
  final List<String> genre;
  final List<String> type;
  final double rating;
  final List<String>? tags;
  final String releaseDate;

  VideoModel({
    required this.tmdbId,
    required this.title,
    required this.description,
    required this.posterPath,
    required this.backdropPath,
    required this.videoUrl,
    required this.genre,
    required this.type,
    required this.rating,
    this.tags,
    required this.releaseDate,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    print('Parsing video JSON: ${json.toString()}');
    String idValue = json['id'] as String? ?? json['tmdbId'] as String? ?? '';
    print('ID Value: $idValue');
    String title = json['title'] as String? ?? '';
    String description = json['description'] as String? ?? '';
    String posterPath =
        json['thumbnailUrl'] as String? ?? json['posterPath'] as String? ?? '';
    String backdropPath = json['backdropPath'] as String? ?? posterPath;
    String videoUrl = json['videoUrl'] as String? ?? '';
    // Handle genre/categories with proper casing
    List<String> genres = [];
    var rawGenres = json['categories'] ?? json['genre'] ?? [];
    if (rawGenres is List) {
      genres =
          rawGenres
              .map((g) => g.toString().trim())
              .where((g) => g.isNotEmpty)
              .toList();
    }
    // Handle type with proper casing
    List<String> types = [];
    var rawTypes = json['type'] ?? [];
    if (rawTypes is List) {
      types =
          rawTypes
              .map((t) => t.toString().trim())
              .where((t) => t.isNotEmpty)
              .toList();
    } else if (rawTypes is String) {
      types = [rawTypes];
    }
    // Handle rating safely
    double rating = 0.0;
    var rawRating = json['rating'];
    if (rawRating != null) {
      if (rawRating is num) {
        rating = rawRating.toDouble();
      } else if (rawRating is String) {
        rating = double.tryParse(rawRating) ?? 0.0;
      }
    }
    // Handle tags safely
    List<String>? tags;
    var rawTags = json['tags'];
    if (rawTags != null && rawTags is List) {
      tags =
          rawTags
              .map((t) => t.toString().trim())
              .where((t) => t.isNotEmpty)
              .toList();
    }
    String releaseDate = json['releaseDate'] as String? ?? '';

    final videoModel = VideoModel(
      tmdbId: idValue,
      title: title,
      description: description,
      posterPath: posterPath,
      backdropPath: backdropPath,
      videoUrl: videoUrl,
      genre: genres,
      type: types,
      rating: rating,
      tags: tags,
      releaseDate: releaseDate,
    );

    print('Successfully parsed VideoModel: ${videoModel.title}');
    return videoModel;
  }

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'title': title,
      'description': description,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'videoUrl': videoUrl,
      'genre': genre,
      'type': type,
      'rating': rating,
      if (tags != null) 'tags': tags,
      'releaseDate': releaseDate,
    };
  }
}
