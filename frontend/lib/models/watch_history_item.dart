import 'package:flutter_video_app/models/video_model.dart';

class WatchHistoryItem {
  final String thumbnailUrl;
  final String episodeInfo;
  final String title;
  final String id;

  WatchHistoryItem({
    required this.thumbnailUrl,
    required this.episodeInfo,
    required this.title,
    required this.id,
  });

  factory WatchHistoryItem.fromVideo(VideoModel video) {
    return WatchHistoryItem(
      id: video.id,
      thumbnailUrl: video.thumbnailUrl,
      episodeInfo: video.type.isNotEmpty ? video.type.first : 'Movie',
      title: video.title,
    );
  }
}
