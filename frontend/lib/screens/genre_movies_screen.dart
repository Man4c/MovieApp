import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../widgets/video_grid.dart';

class GenreMoviesScreen extends StatelessWidget {
  final String genreName;
  final bool isType; // Whether we're filtering by type or category
  final List<VideoModel>? initialMovies; // New field

  const GenreMoviesScreen({
    super.key,
    required this.genreName,
    this.isType = false, // Default to category view
    this.initialMovies, // New parameter
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, _) {
        List<VideoModel> movies;
        bool providerLogicNeeded = false;

        if (widget.initialMovies != null && widget.initialMovies!.isNotEmpty) {
          movies = widget.initialMovies!;
        } else {
          providerLogicNeeded = true;
          // Existing logic to fetch from VideoProvider
          movies = widget.isType
              ? videoProvider.getVideosByType(widget.genreName)
              : videoProvider.getVideosByCategory(widget.genreName);
        }

        // Load all videos from provider if initialMovies are not provided and provider hasn't loaded yet
        if (providerLogicNeeded && !videoProvider.isLoading && videoProvider.allVideos.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // This will trigger a fetch that VideoProvider handles,
            // and Consumer will rebuild when data changes.
            videoProvider.loadVideos(refresh: true, loadAll: true);
          });
          // If provider is loading and initialMovies are not present,
          // movies list might be empty initially.
          // The UI below handles this by showing 'No videos found' or VideoGrid.
        }

        final ScrollController scrollController = ScrollController();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          genreName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          movies.isEmpty
              ? const Center(
                child: Text(
                  'No videos found in this category',
                  style: TextStyle(color: Colors.white60),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      '${movies.length} ${movies.length == 1 ? 'Video' : 'Videos'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: VideoGrid(
                      videos: movies,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              ),
    );
      },
    );
  }
}
