import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/widgets/video_card.dart';
import 'package:flutter_video_app/widgets/video_grid.dart'; // Using VideoGrid
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
  ScrollController _scrollController = ScrollController(); // For VideoGrid

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
        _genres = genres.where((genre) => genre.isNotEmpty).toList(); // Filter out empty strings
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
    // If movies for this genre are already fetched, don't fetch again unless necessary
    // For simplicity here, we fetch every time, but could add caching.
    setState(() {
      _selectedGenre = genre;
      _isLoadingMovies = true;
      // Clear previous movies for this genre to show loading indicator correctly
      // _moviesByGenre[genre] = [];
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
          SnackBar(content: Text('Failed to load movies for $genre: ${e.toString()}')),
        );
      }
      debugPrint("Error fetching movies for $genre: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(title: Text(Constants.discoveryScreenTitle)), // AppBar is in HomeScreen
      body: SafeArea( // Added SafeArea
        child: _isLoadingGenres
            ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenreSelector(), // This should take its natural height

                  // This Expanded widget will contain either the loading indicator for movies,
                  // the movie grid, or a message.
                  Expanded(
                    child: _buildMoviesArea(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMoviesArea() {
    if (_isLoadingMovies) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }

    if (_selectedGenre == null) {
      if (_genres.isEmpty) { // No genres loaded at all
        return const Center(
          child: Text(
            'No genres available at the moment. Pull to refresh or check connection.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
      }
      return const Center( // Genres loaded, but none selected
        child: Text(
          'Select a genre to discover movies.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    final moviesForSelectedGenre = _moviesByGenre[_selectedGenre!];

    if (moviesForSelectedGenre == null || moviesForSelectedGenre.isEmpty) {
      return Center(
        child: Text(
          'No movies found for "$_selectedGenre".',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return VideoGrid(
      videos: moviesForSelectedGenre,
      scrollController: _scrollController,
    );
  }

  Widget _buildGenreSelector() {
    if (_genres.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No genres available.', style: TextStyle(color: Colors.white70))),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _genres.map((genre) {
          final isSelected = _selectedGenre == genre;
          return ChoiceChip(
            label: Text(genre),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                _fetchMoviesByGenre(genre);
              }
            },
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.deepOrange,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? Colors.deepOrange : Colors.grey[700]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
