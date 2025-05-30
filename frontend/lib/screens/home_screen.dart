import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/providers/video_provider.dart';
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:flutter_video_app/screens/favorites_screen.dart';
import 'package:flutter_video_app/widgets/video_grid.dart';
import 'package:flutter_video_app/widgets/featured_banner_carousel.dart';
import 'package:flutter_video_app/widgets/video_row.dart';
import 'package:flutter_video_app/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      if (!videoProvider.isLoading && videoProvider.hasMorePages) {
        videoProvider.loadVideos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VideoProvider, AuthProvider>(
      builder: (context, videoProvider, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const Center(child: Text('Please log in to access content'));
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title:
                _isSearching
                    ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: Constants.searchHint,
                        hintStyle: const TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        videoProvider.searchVideos(value);
                      },
                    )
                    : Text(
                      _currentIndex == 0
                          ? Constants.homeScreenTitle
                          : Constants.favoritesScreenTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        videoProvider.clearSearch();
                      }
                    });
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.logout();
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: const Text('Logout'),
                      ),
                    ],
              ),
            ],
          ),
          body: _buildBody(videoProvider),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _isSearching = false;
                _searchController.clear();
                if (index == 0) {
                  videoProvider.clearSearch();
                }
              });
            },
            backgroundColor: Colors.black,
            selectedItemColor: Colors.deepOrange,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(VideoProvider videoProvider) {
    if (videoProvider.isLoading && videoProvider.allVideos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (_currentIndex == 1) {
      return const FavoritesScreen();
    }

    if (_isSearching) {
      return _buildSearchResults(videoProvider);
    }

    return _buildHomeContent(videoProvider);
  }

  Widget _buildSearchResults(VideoProvider videoProvider) {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search for videos...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    final searchResults = videoProvider.searchResults;
    if (searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No videos found',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return VideoGrid(videos: searchResults);
  }

  Widget _buildHomeContent(VideoProvider videoProvider) {
    final List<VideoModel> carouselVideos;
    List<VideoModel> potentialFeaturedVideos = videoProvider
        .getVideosByCategory('Featured');

    if (potentialFeaturedVideos.isNotEmpty) {
      carouselVideos = potentialFeaturedVideos.take(5).toList();
    } else if (videoProvider.allVideos.isNotEmpty) {
      carouselVideos = videoProvider.allVideos.take(5).toList();
    } else {
      carouselVideos = [];
    }

    final List<String> categoriesForRows = videoProvider.getCategories();

    return RefreshIndicator(
      onRefresh: () => videoProvider.loadVideos(refresh: true),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (carouselVideos.isNotEmpty)
              FeaturedBannerCarousel(featuredVideos: carouselVideos),

            const SizedBox(height: 10),

            ...categoriesForRows.map((categoryName) {
              if (categoryName.toLowerCase() == 'featured' &&
                  potentialFeaturedVideos.isNotEmpty &&
                  carouselVideos.any(
                    (v) => v.categories.contains('Featured'),
                  )) {
                return const SizedBox.shrink();
              }

              final List<VideoModel> videosForThisCategory = videoProvider
                  .getVideosByCategory(categoryName);
              if (videosForThisCategory.isEmpty) {
                return const SizedBox.shrink();
              }

              return VideoRow(
                title: categoryName,
                videos: videosForThisCategory,
              );
            }).toList(),

            if (videoProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
