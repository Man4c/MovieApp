class VideoModel {
  final String tmdbId; // Renamed from id
  final String title;
  final String description;
  final String posterPath; // Renamed from thumbnailUrl
  final String backdropPath;
  final String videoUrl;
  final List<String> genre; // Renamed from categories
  final List<String> type;
  final double rating;
  final List<String>? tags; // Made tags optional as backend might not handle it
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
    // Assumes the backend returns 'id' as tmdbId in GET requests, but 'tmdbId' when creating/returning specific movie.
    // The 'mapMovieData' in backend returns 'id' as tmdbId.
    // For consistency, let's assume the response from addMovie also maps tmdbId to 'id'.
    // If addMovie returns 'tmdbId', then this should be json['tmdbId']
    String idValue = json['id'] as String? ?? json['tmdbId'] as String? ?? '';

    return VideoModel(
      tmdbId: idValue,
      title: json['title'] as String,
      description: json['description'] as String,
      // Backend's mapMovieData uses 'thumbnailUrl' for posterPath and 'backdropPath'
      posterPath: json['thumbnailUrl'] as String? ?? json['posterPath'] as String? ?? '',
      backdropPath: json['backdropPath'] as String? ?? json['posterPath'] as String? ?? '', // Fallback
      videoUrl: json['videoUrl'] as String,
      genre: List<String>.from(json['categories'] as List? ?? json['genre'] as List? ?? []), // Accommodate 'categories' or 'genre'
      type: List<String>.from(json['type'] as List? ?? []),
      rating: (json['rating'] as num).toDouble(),
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      releaseDate: json['releaseDate'] as String,
    );
  }

  // toJson for sending data to the backend's addMovie endpoint
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
      if (tags != null) 'tags': tags, // Include tags only if not null
      'releaseDate': releaseDate,
    };
  }
}
