import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/screens/genre_movies_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<String> _genres = [];
  // This map will now be populated with the first movie of each genre on initial load.
  final Map<String, VideoModel> _firstMovieByGenre = {};
  bool _isLoading = true;
  String? _tappedGenre; // To show a loading indicator on the specific tapped card

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // NEW: Combined fetch method for genres and their first movie poster
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch all genre names
      final genres = await ApiService.getMovieTypes();
      final validGenres = genres.where((genre) => genre.isNotEmpty).toList();
      setState(() {
        _genres = validGenres;
      });

      // 2. For each genre, fetch its first movie in parallel
      List<Future<void>> futures = validGenres.map((genre) async {
        try {
          // Fetch only the first page/batch of movies to find a poster, not all.
          final movies = await ApiService.getVideos(
            category: genre,
            loadAll: false, // More efficient than loading all movies
            filterType: 'genre',
          );
          if (movies.isNotEmpty) {
            _firstMovieByGenre[genre] = movies.first;
          }
        } catch (e) {
          // If fetching for one genre fails, don't stop the whole process
          debugPrint("Could not fetch preview for genre $genre: $e");
        }
      }).toList();

      // Wait for all fetches to complete
      await Future.wait(futures);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load discovery data: ${e.toString()}')),
        );
      }
      debugPrint("Error fetching initial discovery data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // MODIFIED: This now fetches the *full list* of movies for navigation
  Future<void> _fetchMoviesAndNavigate(String genre) async {
    setState(() {
      _tappedGenre = genre; // Show loading indicator on this specific card
    });

    try {
      // Fetch the complete list of movies for the selected genre
      final movies = await ApiService.getVideos(
        category: genre,
        loadAll: true, // Load all movies for the genre screen
        filterType: 'genre',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenreMoviesScreen(
              genreName: genre,
              initialMovies: movies,
              isType: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load movies for $genre: ${e.toString()}'),
          ),
        );
      }
      debugPrint("Error fetching movies for $genre: $e");
    } finally {
      if (mounted) {
        setState(() {
          _tappedGenre = null; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              )
            : _buildGenreList(),
      ),
    );
  }

  Widget _buildGenreList() {
    if (_genres.isEmpty) {
      return const Center(
        child: Text(
          'No genres available at the moment.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _genres.length,
      itemBuilder: (context, index) {
        final genre = _genres[index];
        final movie = _firstMovieByGenre[genre];
        return _buildGenreCard(genre, movie);
      },
    );
  }

  // REWRITTEN: The UI for the genre card is now completely different
  Widget _buildGenreCard(String genre, VideoModel? movie) {
    final bool isTapped = _tappedGenre == genre;
    final hasImage = movie?.thumbnailUrl != null && movie!.thumbnailUrl.isNotEmpty;

    return Container(
      height: 120, // Give the card a fixed height
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Material(
          color: Colors.grey[900], // Fallback color
          child: InkWell(
            onTap: () => _fetchMoviesAndNavigate(genre),
            child: Stack(
              fit: StackFit.expand, // Make stack children fill the container
              children: [
                // 1. Background Image
                if (hasImage)
                  Image.network(
                    movie!.thumbnailUrl,
                    fit: BoxFit.cover,
                    // Add a loading builder for a smoother experience
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white54,));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback in case of image load error
                      return _buildPlaceholderBackground();
                    },
                  ),

                if (!hasImage)
                  _buildPlaceholderBackground(),

                // 2. Gradient Overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),

                // 3. Content (Text and Icon)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ]
                          ),
                        ),
                      ),

                      // Show a loader if this specific card was tapped
                      isTapped
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 24.0,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for placeholder gradient background
  Widget _buildPlaceholderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepOrange[800]!, Colors.grey[900]!],
        ),
      ),
    );
  }
}