import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/widgets/video_card.dart';
import 'package:flutter_video_app/widgets/video_grid.dart';
import 'package:flutter_video_app/utils/constants.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<String> _genres = [];
  Map<String, List<VideoModel>> _moviesByGenre = {};
  bool _isLoadingGenres = true;
  bool _isLoadingMovies = false;
  String? _selectedGenre;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchGenres() async {
    setState(() {
      _isLoadingGenres = true;
    });
    try {
      final genres = await ApiService.getMovieTypes();
      setState(() {
        _genres = genres.where((genre) => genre.isNotEmpty).toList();
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGenres = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load genres: ${e.toString()}')),
        );
      }
      debugPrint("Error fetching genres: $e");
    }
  }

  Future<void> _fetchMoviesByGenre(String genre) async {
    setState(() {
      _selectedGenre = genre;
      _isLoadingMovies = true;
    });
    try {
      final movies = await ApiService.getVideos(category: genre, loadAll: true);
      setState(() {
        _moviesByGenre[genre] = movies;
        _isLoadingMovies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMovies = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load movies for $genre: ${e.toString()}'),
          ),
        );
      }
      debugPrint("Error fetching movies for $genre: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child:
            _isLoadingGenres
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
      itemCount: _genres.length,
      itemBuilder: (context, index) {
        final genre = _genres[index];
        return _buildGenreCard(genre, index);
      },
    );
  }

  Widget _buildGenreCard(String genre, int index) {
    // Sample movie poster - you might want to get actual poster from your movies data
    final movieForGenre =
        _moviesByGenre[genre]?.isNotEmpty == true
            ? _moviesByGenre[genre]!.first
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => _fetchMoviesByGenre(genre),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Movie Poster
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey[800],
                  ),
                  child:
                      movieForGenre?.thumbnailUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              movieForGenre!.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderPoster();
                              },
                            ),
                          )
                          : _buildPlaceholderPoster(),
                ),

                const SizedBox(width: 16.0),

                // Genre Text
                Expanded(
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[700]!, Colors.grey[900]!],
        ),
      ),
      child: const Center(
        child: Icon(Icons.movie, color: Colors.white54, size: 30.0),
      ),
    );
  }
}
