import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../widgets/video_grid.dart';

class GenreMoviesScreen extends StatelessWidget {
  final String genreName;
  final bool isType; // Whether we're filtering by type or category

  const GenreMoviesScreen({
    Key? key,
    required this.genreName,
    this.isType = false, // Default to category view
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, _) {
        // Load all videos when entering this screen
        if (!videoProvider.isLoading && videoProvider.allVideos.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            videoProvider.loadVideos(refresh: true, loadAll: true);
          });
        }

        final List<VideoModel> movies = isType
            ? videoProvider.getVideosByType(genreName)
            : videoProvider.getVideosByCategory(genreName);
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
  }
}
