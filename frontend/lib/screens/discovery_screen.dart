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
  final Map<String, VideoModel> _firstMovieByGenre = {};
  bool _isLoading = true;
  String? _tappedGenre;
  String? _error;
  Map<String, bool> _genreLoading = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _genreLoading.clear();
    });

    try {
      print('Fetching genre names...'); // Debug log
      final genres = await ApiService.getMovieTypes();
      print('Received genres: $genres'); // Debug log

      if (!mounted) return;

      final validGenres = genres.where((genre) => genre.isNotEmpty).toList();
      setState(() {
        _genres = validGenres;
        // Initialize loading state for each genre
        for (var genre in validGenres) {
          _genreLoading[genre] = true;
        }
      });

      print('Fetching movies for each genre...'); // Debug log

      // Use Future.wait to fetch all genres in parallel
      final futures = validGenres.map((genre) async {
        try {
          final movies = await ApiService.getVideos(category: genre);
          print(
            'Received ${movies.length} movies for genre $genre',
          ); // Debug log

          if (!mounted) return;

          setState(() {
            if (movies.isNotEmpty) {
              _firstMovieByGenre[genre] = movies.first;
            }
            _genreLoading[genre] = false;
          });
        } catch (e) {
          print('Error fetching movies for genre $genre: $e'); // Debug log
          if (!mounted) return;
          setState(() {
            _genreLoading[genre] = false;
          });
        }
      });

      await Future.wait(futures);
    } catch (e) {
      print('Error in _fetchInitialData: $e'); // Debug log
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load discovery data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _fetchInitialData,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoviesAndNavigate(String genre) async {
    setState(() {
      _tappedGenre = genre;
    });

    try {
      final movies = await ApiService.getVideos(category: genre);

      if (!mounted) return;

      if (movies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No movies found for $genre'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GenreMoviesScreen(
                genreName: genre,
                initialMovies: movies,
                isType: false,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load movies for $genre: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _tappedGenre = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load content',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_genres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No genres available',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final movie = _firstMovieByGenre[genre];
          final isLoading = _genreLoading[genre] ?? false;
          return _buildGenreCard(genre, movie, isLoading);
        },
      ),
    );
  }

  Widget _buildGenreCard(String genre, VideoModel? movie, bool isLoading) {
    final bool isTapped = _tappedGenre == genre;
    final hasImage = movie?.posterPath != null && movie!.posterPath.isNotEmpty;

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Material(
          color: Colors.grey[900],
          child: InkWell(
            onTap: isTapped ? null : () => _fetchMoviesAndNavigate(genre),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage && movie != null)
                  Image.network(
                    movie.posterPath,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white54,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return const SizedBox.shrink();
                    },
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16.0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Row(
                      children: [
                        Text(
                          genre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white54,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isTapped)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
