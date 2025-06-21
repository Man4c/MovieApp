import 'package:flutter/foundation.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';

class WatchHistoryProvider with ChangeNotifier {
  List<VideoModel> _watchHistory = [];
  bool _isLoading = false;

  List<VideoModel> get watchHistory => _watchHistory;
  bool get isLoading => _isLoading;

  WatchHistoryProvider() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    try {
      _isLoading = true;
      notifyListeners();
      _watchHistory = await ApiService.getWatchHistory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addToWatchHistory(VideoModel video) async {
    try {
      await ApiService.addToWatchHistory(video.tmdbId);
      if (!_watchHistory.any((v) => v.tmdbId == video.tmdbId)) {
        _watchHistory.insert(0, video); // Add to beginning of list
      } else {
        // Move to beginning if already exists
        _watchHistory.removeWhere((v) => v.tmdbId == video.tmdbId);
        _watchHistory.insert(0, video);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearWatchHistory() async {
    try {
      await ApiService.clearWatchHistory();
      _watchHistory.clear();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
