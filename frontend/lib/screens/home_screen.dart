import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/screens/favorites_screen.dart';
import 'package:flutter_video_app/screens/discovery_screen.dart';
import 'package:flutter_video_app/screens/user_profile_screen.dart'; // Added import
import 'package:flutter_video_app/screens/login_screen.dart'; // Added import
import 'package:flutter_video_app/widgets/video_row.dart';
import 'package:flutter_video_app/widgets/featured_banner_carousel.dart';
import 'package:flutter_video_app/widgets/video_card.dart';
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

  // State for categorized home screen
  final List<String> _homeScreenCategories = [
    "upcoming",
    "now_playing",
    "trending",
    "top_rated",
  ];
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
      final videos = await ApiService.getVideos(
        category: category,
        loadAll: true,
        filterType: 'type', // Added filterType
      );
      if (!mounted) return;
      setState(() {
        _categorizedVideos[category] = videos;
        _isLoadingCategory[category] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategory[category] = false;
        _categorizedVideos[category] = [];
      });
      debugPrint("Error fetching videos for $category: $e");
    }
  }

  Future<void> _fetchSearchResults(String searchTerm) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSearch = true;
    });
    try {
      final videos = await ApiService.getVideos(
        search: searchTerm,
        loadAll: true,
      );
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
      _searchResults = [];
      _isLoadingSearch = false;
    });
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
          appBar: _currentIndex == 0
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    _getAppBarTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  // The actions for AppBar are removed here if CircleAvatar was for profile,
                  // as drawer will handle profile access. If it was for openDrawer,
                  // AppBar automatically adds a drawer icon if Scaffold.drawer is present.
                  // The existing IconButton was in actions, let's rely on automatic leading icon.
                ),
          drawer: _buildAppDrawer(context, authProvider), // Added drawer
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                if (_isSearching) {
                  _isSearching = false;
                  _clearSearch();
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
                icon: Icon(Icons.explore),
                label: 'Discovery',
              ), // New Item
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
    if (_currentIndex == 1) {
      // Discovery Screen
      return const DiscoveryScreen();
    } else if (_currentIndex == 2) {
      // Favorites Screen
      return const FavoritesScreen();
    } // Default is Home Screen (index 0)
    return SafeArea(
      child: Column(
        children: [
          if (_currentIndex == 0) _buildHomeHeader(),

          // Content Area
          Expanded(child: _buildHomeContent()),
        ],
      ),
    );
  }

  Widget _buildHomeHeader() {
    final user = Provider.of<AuthProvider>(context).user;
    String userName = user?.name ?? 'Guest';
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'What to Watch',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.6),
                ),
                suffixIcon:
                    _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          onPressed: _clearSearch,
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_currentSearchTerm != null && _currentSearchTerm!.isNotEmpty) {
      if (_isLoadingSearch && _searchResults.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        );
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

    // Default Home Content (existing logic)
    bool anyCategoryLoading = _isLoadingCategory.values.any(
      (isLoading) => isLoading,
    );
    bool allCategoriesLoadedAndEmpty =
        !anyCategoryLoading &&
        _categorizedVideos.values.every((list) => list.isEmpty);

    if (anyCategoryLoading &&
        _categorizedVideos.values.every((list) => list.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
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

    List<VideoModel> featuredVideos =
        _categorizedVideos['trending'] ??
        _categorizedVideos.values.firstWhere(
          (v) => v.isNotEmpty,
          orElse: () => [],
        );

    return RefreshIndicator(
      onRefresh: () async {
        _initializeHomeScreen();
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (featuredVideos.isNotEmpty)
              FeaturedBannerCarousel(
                featuredVideos: featuredVideos.take(5).toList(),
              ),

            ..._homeScreenCategories.map((category) {
              final videosForCategory = _categorizedVideos[category];
              final isLoading = _isLoadingCategory[category] ?? false;

              if (isLoading &&
                  (videosForCategory == null || videosForCategory.isEmpty)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }

              if (videosForCategory != null && videosForCategory.isNotEmpty) {
                return VideoRow(
                  title: category.replaceAll('_', ' ').toUpperCase(),
                  videos: videosForCategory,
                );
              }
              return const SizedBox.shrink();
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          if (authProvider.isAuthenticated && authProvider.user != null)
            UserAccountsDrawerHeader(
              accountName: Text(authProvider.user!.name),
              accountEmail: Text(authProvider.user!.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  authProvider.user!.name.isNotEmpty
                      ? authProvider.user!.name[0].toUpperCase()
                      : "U",
                  style: const TextStyle(fontSize: 40.0, color: Colors.white),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
              ),
            )
          else
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          if (authProvider.isAuthenticated) ...[
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
                // }
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
