import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/screens/video_detail_screen.dart';

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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
        child: AnimatedContainer(
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
                  imageUrl: widget.video.thumbnailUrl,
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
      ),
    );
  }
}
