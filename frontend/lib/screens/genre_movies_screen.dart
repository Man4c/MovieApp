import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../widgets/video_grid.dart';

class GenreMoviesScreen extends StatefulWidget {
  final String genreName;
  final bool isType;
  final List<VideoModel>? initialMovies;

  const GenreMoviesScreen({
    super.key,
    required this.genreName,
    this.isType = false,
    this.initialMovies,
  });

  @override
  State<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  bool _initialLoadTriggered = false;

  @override
  void initState() {
    super.initState();
    // Trigger load in initState instead of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialLoad();
    });
  }

  void _triggerInitialLoad() {
    if (!_initialLoadTriggered) {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      if (widget.initialMovies == null) {
        videoProvider.loadVideos(refresh: true, category: widget.genreName);
      }
      _initialLoadTriggered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, _) {
        List<VideoModel> movies;
        if (widget.initialMovies != null && widget.initialMovies!.isNotEmpty) {
          movies = widget.initialMovies!;
        } else {
          movies =
              widget.isType
                  ? videoProvider.getVideosByType(widget.genreName)
                  : videoProvider.getVideosByCategory(widget.genreName);
        }

        final ScrollController scrollController = ScrollController();

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.genreName,
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
              videoProvider.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                  : movies.isEmpty
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
