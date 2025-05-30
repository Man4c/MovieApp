import 'package:flutter/foundation.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';

class VideoProvider with ChangeNotifier {
  List<VideoModel> _allVideos = [];
  List<VideoModel> _searchResults = [];
  String _selectedCategory = "All";
  bool _isLoading = true;
  String? _searchQuery;
  int _currentPage = 1;
  bool _hasMorePages = true;

  List<VideoModel> get allVideos => List<VideoModel>.from(_allVideos);
  List<VideoModel> get searchResults => List<VideoModel>.from(_searchResults);
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get hasMorePages => _hasMorePages;

  VideoProvider() {
    loadVideos();
  }
  Future<void> loadVideos({bool refresh = false, bool loadAll = false}) async {
    try {
      if (refresh || loadAll) {
        _currentPage = 1;
        _hasMorePages = !loadAll;
      }

      if (!_hasMorePages && !loadAll) return;

      _isLoading = true;
      notifyListeners();

      final videos = await ApiService.getVideos(
        category: _selectedCategory == "All" ? null : _selectedCategory,
        search: _searchQuery,
        page: loadAll ? null : _currentPage,
        loadAll: loadAll,
      );

      if (refresh) {
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          _searchResults = videos;
        } else {
          _allVideos = videos;
        }
      } else {
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          _searchResults.addAll(videos);
        } else {
          _allVideos.addAll(videos);
        }
      }

      _hasMorePages = videos.isNotEmpty;
      _currentPage++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasMorePages = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    await loadVideos(refresh: true);
  }

  List<VideoModel> getVideosByCategory(String categoryName) {
    if (categoryName.toLowerCase() == 'all') {
      return _allVideos;
    }
    return _allVideos
        .where(
          (video) => video.categories.any(
            (cat) => cat.toLowerCase() == categoryName.toLowerCase(),
          ),
        )
        .toList();
  }

  List<String> getCategories() {
    Set<String> uniqueCategories = {};
    for (var video in _allVideos) {
      for (var category in video.categories) {
        uniqueCategories.add(category);
      }
    }
    return uniqueCategories.toList()..sort();
  }

  VideoModel? getVideoById(String id) {
    try {
      return _allVideos.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> searchVideos(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    await loadVideos(refresh: true);
  }

  void clearSearch() {
    _searchQuery = null;
    _searchResults.clear();
    _currentPage = 1;
    _hasMorePages = true;
    notifyListeners();
  }

  List<VideoModel> getVideosByType(String typeName) {
    if (typeName.toLowerCase() == 'all') {
      return _allVideos;
    }
    return _allVideos
        .where(
          (video) =>
              video.type.any((t) => t.toLowerCase() == typeName.toLowerCase()),
        )
        .toList();
  }

  List<String> getTypes() {
    Set<String> uniqueTypes = {};
    for (var video in _allVideos) {
      uniqueTypes.addAll(video.type);
    }
    return uniqueTypes.toList()..sort();
  }
}
