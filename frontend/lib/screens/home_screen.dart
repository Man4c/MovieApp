import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/screens/favorites_screen.dart';
import 'package:flutter_video_app/screens/discovery_screen.dart';
import 'package:flutter_video_app/widgets/video_row.dart';
import 'package:flutter_video_app/widgets/featured_banner_carousel.dart';
import 'package:flutter_video_app/utils/constants.dart';
import 'package:flutter_video_app/screens/user_profile_screen.dart'; // Import UserProfileScreen

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
  List<VideoModel> _videos = [];
  bool _isLoadingVideos = true;
  int _currentPage = 1;
  bool _hasMoreVideos = true;
  String? _currentSearchTerm;
  @override
  void initState() {
    super.initState();
    _fetchVideos(loadAll: true); // Load all videos initially
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideos({
    bool loadMore = false,
    bool loadAll = false,
  }) async {
    if (!loadMore || loadAll) {
      setState(() {
        _isLoadingVideos = true;
        _videos = [];
        _currentPage = 1;
        _hasMoreVideos = !loadAll;
      });
    } else if (_isLoadingVideos || !_hasMoreVideos) {
      return;
    }

    setState(() {
      _isLoadingVideos = true;
    });

    try {
      final newVideos = await ApiService.getVideos(
        page: loadAll ? null : _currentPage,
        search: _currentSearchTerm,
        loadAll: loadAll,
      );
      print("Fetched videos count: ${newVideos.length}");
      if (newVideos.isNotEmpty) {
        print("First video data: ${newVideos[0].toJson()}");
      }
      setState(() {
        if (loadMore) {
          _videos.addAll(newVideos);
        } else {
          _videos = newVideos;
        }
        _currentPage++;
        _hasMoreVideos = newVideos.isNotEmpty;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
      });
      debugPrint("Error fetching videos: $e");
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingVideos && _hasMoreVideos) {
        _fetchVideos(loadMore: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty && _currentSearchTerm == null) return;
    if (query.isEmpty) {
      _clearSearch();
      return;
    }
    setState(() {
      _currentSearchTerm = query;
    });
    _fetchVideos(loadAll: true);
  }

  void _clearSearch() {
    setState(() {
      _currentSearchTerm = null;
      _searchController.clear();
      _isSearching = false;
    });
    _fetchVideos(loadAll: true);
  }

  Map<String, List<VideoModel>> _groupVideosByType() {
    final Map<String, List<VideoModel>> groupedVideos = {};

    for (var video in _videos) {
      for (var type in video.type) {
        if (!groupedVideos.containsKey(type)) {
          groupedVideos[type] = [];
        }
        groupedVideos[type]!.add(video);
      }
    }

    return groupedVideos;
  }

  @override
  Widget build(BuildContext context) {
    // Using Consumer only for AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          // This logic can be moved to a wrapper widget or handled by routing
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder( // Added Builder to get context for Scaffold.of(context)
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white), // Standard menu icon
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: _isSearching
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: Constants.searchHint,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                          onPressed: _clearSearch,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: _onSearchChanged, // Debounced search
                    ),
                  )
                : Text(
                        _getAppBarTitle(), // Use a helper method for title
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
                        _clearSearch(); // Clear search when closing
                      } else {
                        // Optionally focus search field if needed
                      }
                    });
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.logout();
                    // Navigation to login screen should be handled by AuthProvider listener or here
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
              ),
            ],
          ),
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _isSearching = false; // Reset search state on tab change
                _currentSearchTerm = null;
                _searchController.clear();
                if (index == 0) {
                  _fetchVideos(); // Refresh videos for home tab
                }
              });
            },
            backgroundColor: Colors.black,
            selectedItemColor: Colors.deepOrange,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discovery'), // New Item
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

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return Constants.homeScreenTitle;
      case 1:
        return Constants.discoveryScreenTitle;
      case 2:
        return Constants.favoritesScreenTitle;
      default:
        return Constants.appName;
    }
  }

  Widget _buildBody() {
    // Handle tab changes for body content
    if (_currentIndex == 1) { // Discovery Screen
      return const DiscoveryScreen();
    } else if (_currentIndex == 2) { // Favorites Screen
      return const FavoritesScreen();
    }
    // Default is Home Screen (index 0)

    // Search results view takes precedence if searching on Home tab
    if (_isSearching && _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty) {
      // Search Results View
      if (_isLoadingVideos && _videos.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
      }
      if (_videos.isEmpty) {
        return Center(
          child: Text(
            'No movies found for "$_currentSearchTerm".',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Adjust for responsiveness later if needed
          childAspectRatio: 0.7, // Adjust as needed for VideoCard aspect ratio (0.7 is approx 130/(230*0.8) if card height is mostly image)
                                 // VideoCard default width 130, height 230. Image is AspectRatio(2/3) of width.
                                 // So image height is 130 * 3/2 = 195. Card height is 230.
                                 // Aspect ratio of card: 130/230 = ~0.56. Let's try that.
                                 // Or, if VideoCard height is dynamic, 130 / (130 * 3/2 + some_padding_for_title_if_any)
                                 // For VideoCard width 130, height 230, its own aspect ratio is 130/230 = 0.565
                                 // Let's use a common value or calculate based on VideoCard's actual rendering.
                                 // Given VideoCard has AspectRatio(2/3) for image, and width 130, image height = 195.
                                 // If VideoCard mostly consists of image, childAspectRatio should be close to 2/3 = 0.66
                                 // Or if it's width/height of the card itself: 130/230 = 0.56
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          return VideoCard(video: video); // VideoCard default width 130, height 230
        },
      );
    }
    // else, it's the Default Home View for index 0
    return _isLoadingVideos && _videos.isEmpty
        ? const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange),
          )
        : RefreshIndicator(
            onRefresh: () => _fetchVideos(loadAll: true), // For default view
            child: SingleChildScrollView(
              controller: _scrollController, // Attach scroll controller here
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_videos.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final featuredVideos = _videos.take(5).toList();
                        return FeaturedBannerCarousel(
                          featuredVideos: featuredVideos,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...(_videos.isEmpty && _currentSearchTerm == null // Show 'No videos available' only if not a failed search
                      ? [
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No videos available at the moment.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ]
                      : _groupVideosByType().entries.map((entry) {
                          return VideoRow(title: entry.key, videos: entry.value);
                        })),
                  if (_isLoadingVideos && _videos.isNotEmpty) // Loading indicator for pagination
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
  }
}
