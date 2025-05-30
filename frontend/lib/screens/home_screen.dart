import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart'; // Import ApiService
import 'package:flutter_video_app/providers/auth_provider.dart'; // Still needed for auth
import 'package:provider/provider.dart'; // Still needed for AuthProvider
import 'package:flutter_video_app/screens/favorites_screen.dart';
import 'package:flutter_video_app/widgets/video_grid.dart';
import 'package:flutter_video_app/widgets/category_selector.dart'; // Import CategorySelector
import 'package:flutter_video_app/utils/constants.dart';
// Removed VideoProvider import

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

  // New state variables
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  List<VideoModel> _videos = []; // For the main display area
  bool _isLoadingCategories = true;
  bool _isLoadingVideos = true;
  int _currentPage = 1;
  bool _hasMoreVideos = true;
  String? _currentSearchTerm;

  @override
  void initState() {
    super.initState();
    _fetchMovieTypes();
    _fetchVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMovieTypes() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final types = await ApiService.getMovieTypes();
      setState(() {
        _categories = ['All', ...types.where((type) => type.isNotEmpty)];
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        // Handle error, e.g., show a SnackBar
      });
      debugPrint("Error fetching movie types: $e");
    }
  }

  Future<void> _fetchVideos({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoadingVideos = true;
        _videos = [];
        _currentPage = 1;
        _hasMoreVideos = true;
      });
    } else if (_isLoadingVideos || !_hasMoreVideos) {
      return;
    }

    setState(() {
      _isLoadingVideos = true; // Set loading true for loadMore as well
    });

    try {
      final newVideos = await ApiService.getVideos(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        page: _currentPage,
        search: _currentSearchTerm,
      );
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
        // Handle error
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

  void _onCategorySelected(String newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      _currentSearchTerm = null; // Clear search when category changes
      _searchController.clear();
      _isSearching = false;
    });
    _fetchVideos(); // Reset to page 1
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
     _fetchVideos(); // Reset to page 1
  }

  void _clearSearch() {
    setState(() {
      _currentSearchTerm = null;
      _searchController.clear();
      _isSearching = false; // Optional: to close search UI immediately
    });
    _fetchVideos(); // Reset to page 1
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: Constants.searchHint,
                      hintStyle: const TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60),
                        onPressed: _clearSearch,
                      )
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: _onSearchChanged, // Use onSubmitted or onChanged
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
                itemBuilder: (BuildContext context) => [
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

  Widget _buildBody() {
    if (_currentIndex == 1) {
      return const FavoritesScreen(); // Favorites screen might need its own data fetching
    }

    // Home Tab
    return Column(
      children: [
        _isLoadingCategories
            ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Loading categories...", style: TextStyle(color: Colors.white))))
            : CategorySelector(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),
        Expanded(
          child: _isLoadingVideos && _videos.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
              : _videos.isEmpty
                  ? Center(child: Text(_currentSearchTerm != null ? 'No videos found for "$_currentSearchTerm".' : 'No videos available for $_selectedCategory.', style: const TextStyle(color: Colors.white70)))
                  : RefreshIndicator(
                      onRefresh: () => _fetchVideos(),
                      child: VideoGrid(videos: _videos, scrollController: _scrollController),
                    ),
        ),
         if (_isLoadingVideos && _videos.isNotEmpty) // Loading indicator at bottom for pagination
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
            ),
      ],
    );
  }
}
