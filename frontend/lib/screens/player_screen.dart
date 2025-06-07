import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/watch_history_provider.dart';

class PlayerScreen extends StatefulWidget {
  final VideoModel video;

  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Gagal memuat video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        additionalOptions: (context) {
          return <OptionItem>[
            OptionItem(
              onTap: (_) => _toggleFavorite(),
              iconData: Icons.favorite,
              title: 'Tambahkan ke Favorit',
            ),
          ];
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('Error initializing video player: $e');
    }
  }

  void _toggleFavorite() async {
    try {
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      await favoritesProvider.toggleFavorite(widget.video);

      if (mounted) {
        final isFavorite = favoritesProvider.isFavorite(widget.video.id);
        final message =
            isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorites: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final position = await _videoPlayerController.position;
        print('Video stopped at position: ${position?.inSeconds} seconds');

        // Add to watch history when user has watched at least 30 seconds
        if ((position?.inSeconds ?? 0) >= 30) {
          try {
            await Provider.of<WatchHistoryProvider>(
              context,
              listen: false,
            ).addToWatchHistory(widget.video);
          } catch (e) {
            print('Error updating watch history: $e');
          }
        }
        return true;
      },
      child: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final bool isFavorite = favoritesProvider.isFavorite(widget.video.id);

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.video.title),
              actions: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildVideoPlayer()),
                  _buildVideoInfo(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = '';
                });
                _initializePlayer();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      return Chewie(controller: _chewieController!);
    }
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.video.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 14.0),
          ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}
