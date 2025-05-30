import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/providers/favorites_provider.dart';
import 'package:flutter_video_app/widgets/video_grid.dart';
import 'package:flutter_video_app/utils/constants.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final List<VideoModel> favorites = favoritesProvider.favorites;
    final ScrollController scrollController = ScrollController();

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              Constants.noFavoritesMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    return VideoGrid(videos: favorites, scrollController: scrollController);
  }
}