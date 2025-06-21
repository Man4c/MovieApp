import 'package:flutter/foundation.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/models/comment_model.dart';
import 'package:flutter_video_app/services/api_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<VideoModel> _favorites = [];
  final Map<String, List<ReviewModel>> _reviews = {};
  bool _isLoading = false;

  List<VideoModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Loading favorites...'); // Debug log
      _favorites = await ApiService.getFavorites();
      print('Loaded ${_favorites.length} favorites'); // Debug log

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e'); // Debug log
      _isLoading = false;
      _favorites = []; // Set empty list on error
      notifyListeners();
      // Don't rethrow, just log the error and continue with empty list
    }
  }

  bool isFavorite(String videoId) {
    return _favorites.any((video) => video.tmdbId == videoId);
  }

  Future<void> toggleFavorite(VideoModel video) async {
    try {
      await ApiService.toggleFavorite(video.tmdbId);

      if (isFavorite(video.tmdbId)) {
        _favorites.removeWhere((item) => item.tmdbId == video.tmdbId);
      } else {
        _favorites.add(video);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReviewModel>> getReviewsForVideo(String videoId) async {
    if (!_reviews.containsKey(videoId)) {
      try {
        final reviews = await ApiService.getVideoComments(videoId);
        _reviews[videoId] = reviews;
      } catch (e) {
        _reviews[videoId] = [];
        rethrow;
      }
    }
    return _reviews[videoId] ?? [];
  }

  Future<void> addReview(String videoId, String comment, double rating) async {
    try {
      final newReview = await ApiService.addComment(videoId, comment, rating);

      if (!_reviews.containsKey(videoId)) {
        _reviews[videoId] = [];
      }
      _reviews[videoId]!.add(newReview);

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  double getAverageRating(String videoId) {
    final reviews = _reviews[videoId] ?? [];
    if (reviews.isEmpty) {
      return 0.0;
    }

    double totalRating = reviews.fold(0.0, (sum, item) => sum + item.rating);
    return totalRating / reviews.length;
  }
}
