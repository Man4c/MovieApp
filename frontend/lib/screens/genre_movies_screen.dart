import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../widgets/video_grid.dart';

class GenreMoviesScreen extends StatelessWidget {
  final String genreName;

  const GenreMoviesScreen({Key? key, required this.genreName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final List<VideoModel> movies = videoProvider.getVideosByCategory(genreName);

    return Scaffold(
      appBar: AppBar(
        title: Text(genreName),
      ),
      body: VideoGrid(videos: movies),
    );
  }
}