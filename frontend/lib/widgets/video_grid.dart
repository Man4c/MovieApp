import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/widgets/video_card.dart';

class VideoGrid extends StatelessWidget {
  final List<VideoModel> videos;

  const VideoGrid({super.key, required this.videos, required ScrollController scrollController});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(video: videos[index]);
      },
    );
  }
}
