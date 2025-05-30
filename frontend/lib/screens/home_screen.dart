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
  final ScrollController _scrollController = ScrollController(); // Still used for search GridView scrolling if results are many

  // State for categorized home screen
  final List<String> _homeScreenCategories = ["upcoming", "now_playing", "trending", "top_rated"];
  Map<String, List<VideoModel>> _categorizedVideos = {};
  Map<String, bool> _isLoadingCategory = {};

  // State for search results
  List<VideoModel> _searchResults = [];
  bool _isLoadingSearch = false;
  String? _currentSearchTerm;

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen();
  }

  void _initializeHomeScreen() {
    for (String category in _homeScreenCategories) {
      _isLoadingCategory[category] = false; // Initialize
      _fetchVideosForCategory(category);
    }
  }

  Future<void> _fetchVideosForCategory(String category) async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategory[category] = true;
    });
    try {
      final videos = await ApiService.getVideos(category: category, loadAll: true);
      if (!mounted) return;
      setState(() {
        _categorizedVideos[category] = videos;
        _isLoadingCategory[category] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategory[category] = false;
        _categorizedVideos[category] = []; // Set to empty on error to avoid null issues
      });
      debugPrint("Error fetching videos for $category: $e");
    }
  }

  // Fetch videos for search
  Future<void> _fetchSearchResults(String searchTerm) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSearch = true;
    });
    try {
      final videos = await ApiService.getVideos(search: searchTerm, loadAll: true);
      if (!mounted) return;
      setState(() {
        _searchResults = videos;
        _isLoadingSearch = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSearch = false;
        _searchResults = [];
      });
      debugPrint("Error fetching search results for $searchTerm: $e");
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
      if (query.isNotEmpty) {
        _fetchSearchResults(query);
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _currentSearchTerm = null;
      _searchController.clear();
      // _isSearching = false; // This will be set by the AppBar action
      _searchResults = [];
      _isLoadingSearch = false;
    });
    // No need to fetch categorized videos here, they are already loaded or being loaded.
    // Setting _isSearching to false will make _buildBody show the categorized view.
  }

  // _groupVideosByType is no longer needed for the main home screen display.
  // It might be useful if search results were to be grouped, but current plan is a simple grid.

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
            // leading: Builder( ... ) // REMOVED leading menu icon
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
                  _clearSearch();
                  // When closing search, ensure home categories are visible if not already loaded.
                  // However, _initializeHomeScreen should handle initial load.
                  // If returning to home and categories are empty, a refresh might be desired.
                  // For now, _clearSearch just clears search state.
                      } else {
                        // Optionally focus search field if needed
                      }
                    });
                  },
                ),
              // PopupMenuButton for logout is removed as logout is now in Drawer.
              Builder( // Use Builder to get correct context for Scaffold.of
                builder: (context) {
                  // final authProvider = Provider.of<AuthProvider>(context); // Already available from Consumer
                  final user = authProvider.user;
                  String userInitial = 'G'; // Guest/Generic
                  if (user != null && user.name.isNotEmpty) {
                    userInitial = user.name[0].toUpperCase();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0), // Add some padding
                    child: IconButton(
                      icon: CircleAvatar(
                        radius: 18, // Adjust size
                        backgroundColor: Colors.deepOrange.withOpacity(0.8),
                        child: Text(userInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        // backgroundImage: user?.profilePhotoUrl != null ? NetworkImage(user!.profilePhotoUrl!) : null, // If photo URL existed
                      ),
                      tooltip: 'Open navigation menu',
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
            if (_isSearching) { // If was searching, clear it when changing tabs
              _isSearching = false;
              _clearSearch();
                }
            // No specific fetch needed here for home categories as they load on initState.
            // Discovery and Favorites manage their own loading.
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
    if (_currentIndex == 0 && _isSearching && _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty) {
      // Search Results View
      if (_isLoadingSearch && _searchResults.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
      }
      if (_searchResults.isEmpty) {
        return Center(
          child: Text(
            'No movies found for "$_currentSearchTerm".',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        );
      }
      return GridView.builder(
        // controller: _scrollController, // Use if search results can be very long and need separate scroll state
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final video = _searchResults[index];
          return VideoCard(video: video);
        },
      );
    }

    // Default Home View (index 0, not searching)
    // Check if any category is still loading or if all are loaded and empty
    bool anyCategoryLoading = _isLoadingCategory.values.any((isLoading) => isLoading);
    bool allCategoriesLoadedAndEmpty = !anyCategoryLoading && _categorizedVideos.values.every((list) => list.isEmpty);

    if (anyCategoryLoading && _categorizedVideos.values.every((list) => list.isEmpty)) {
        return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }
    if (allCategoriesLoadedAndEmpty) {
        return Center(
          child: Text(
            'No movies available at the moment. Pull to refresh.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
    }

    List<VideoModel> featuredVideos = _categorizedVideos['trending'] ??
                                     _categorizedVideos.values.firstWhere((v) => v.isNotEmpty, orElse: () => []);


    return RefreshIndicator(
      onRefresh: () async {
        _initializeHomeScreen(); // Re-fetch all category data
      },
      child: SingleChildScrollView(
        // controller: _scrollController, // Main scroll controller for home screen rows if needed for other effects
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (featuredVideos.isNotEmpty)
              FeaturedBannerCarousel(featuredVideos: featuredVideos.take(5).toList()),

            ..._homeScreenCategories.map((category) {
              final videosForCategory = _categorizedVideos[category];
              final isLoading = _isLoadingCategory[category] ?? false;

              if (isLoading && (videosForCategory == null || videosForCategory.isEmpty)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }

              if (videosForCategory != null && videosForCategory.isNotEmpty) {
                // Use category.replaceAll to make titles more readable if they have underscores
                return VideoRow(title: category.replaceAll('_', ' ').toUpperCase(), videos: videosForCategory);
              }
              return const SizedBox.shrink();
            }).toList(),
            const SizedBox(height: 16), // Padding at the bottom
          ],
        ),
      ),
    );
  }
}
