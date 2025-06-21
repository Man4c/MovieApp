import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/screens/video_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/providers/favorites_provider.dart';

class VideoCard extends StatefulWidget {
  final VideoModel video;
  final double width;
  final double height;
  final bool showTitle;

  const VideoCard({
    super.key,
    required this.video,
    this.width = 130,
    this.height = 230,
    this.showTitle = true,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  final bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        bool isFavorite = favoritesProvider.isFavorite(widget.video.tmdbId);
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(video: widget.video),
                ),
              );
            },
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
                  width: 130,
                  margin: const EdgeInsets.only(right: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 2 / 3,
                        child: CachedNetworkImage(
                          imageUrl: widget.video.posterPath,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/placeholder.png',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Positioned(
                //   top: 4,
                //   right: 8, // Adjusted right padding to align with AnimatedContainer margin
                //   child: Container(
                //     decoration: BoxDecoration(
                //       color: Colors.black.withOpacity(0.3),
                //       shape: BoxShape.circle,
                //     ),
                //     child: IconButton(
                //       icon: Icon(
                //         isFavorite ? Icons.favorite : Icons.favorite_border,
                //         color: isFavorite ? Colors.red : Colors.white,
                //       ),
                //       iconSize: 20.0, // Smaller icon size
                //       padding: EdgeInsets.zero, // Remove default padding
                //       constraints: const BoxConstraints(), // Remove default constraints
                //       onPressed: () async { // Make async
                //         try {
                //           await favoritesProvider.toggleFavorite(widget.video); // Add await
                //         } catch (e) {
                //           // Use 'context' from the Consumer's builder
                //           if (mounted) { // Check if mounted (StatefulWidget)
                //             ScaffoldMessenger.of(context).showSnackBar(
                //               SnackBar(
                //                 content: Text('Error updating favorite: ${e.toString()}'),
                //                 backgroundColor: Colors.red,
                //               ),
                //             );
                //           }
                //         }
                //       },
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}