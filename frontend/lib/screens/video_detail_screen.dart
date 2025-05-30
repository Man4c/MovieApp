import 'package:flutter/material.dart';
import 'package:flutter_video_app/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/models/review_model.dart';
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:flutter_video_app/screens/player_screen.dart';
import 'package:flutter_video_app/widgets/review_card.dart';
import 'package:flutter_video_app/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(FavoritesProvider provider) async {
    if (_userRating == 0 || _reviewController.text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await provider.addReview(
        widget.video.id,
        _reviewController.text,
        _userRating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
        _reviewController.clear();
        setState(() => _userRating = 0.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FavoritesProvider, AuthProvider>(
      builder: (context, favoritesProvider, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view video details')),
          );
        }

        final bool isFavorite = favoritesProvider.isFavorite(widget.video.id);

        return Scaffold(
          body: FutureBuilder<List<ReviewModel>>(
            future: favoritesProvider.getReviewsForVideo(widget.video.id),
            builder: (context, snapshot) {
              final List<ReviewModel> reviews = snapshot.data ?? [];
              final double averageRating = favoritesProvider.getAverageRating(
                widget.video.id,
              );

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: CachedNetworkImage(
                        imageUrl: widget.video.backdropPath,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.error),
                            ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and favorite button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.video.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () async {
                                  try {
                                    await favoritesProvider.toggleFavorite(
                                      widget.video,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error updating favorites: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              _buildInfoChip(
                                widget.video.type.toUpperCase(),
                                _getTypeColor(widget.video.type),
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                widget.video.categories.take(2).join(', '),
                                Colors.blueGrey,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                widget.video.releaseDate,
                                Colors.purple,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${averageRating > 0 ? averageRating.toStringAsFixed(1) : widget.video.rating.toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '(${reviews.length} reviews)',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.video.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 24),

                          // Watch button
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PlayerScreen(video: widget.video),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text(Constants.watchNowButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Reviews section
                          Text(
                            'Reviews',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),

                          // Add review section
                          _buildAddReviewSection(context, favoritesProvider),

                          const SizedBox(height: 16),

                          // Reviews list
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (snapshot.hasError)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading reviews: ${snapshot.error}',
                                      style: TextStyle(color: Colors.red[300]),
                                      textAlign: TextAlign.center,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(
                                          () {},
                                        ); // This will trigger a rebuild and retry
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (reviews.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  Constants.noReviewsMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            )
                          else
                            ...reviews.map(
                              (review) => ReviewCard(review: review),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddReviewSection(
    BuildContext context,
    FavoritesProvider provider,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed:
                      _isSubmitting
                          ? null
                          : () {
                            setState(() {
                              _userRating = index + 1;
                            });
                          },
                );
              }),
            ),

            const SizedBox(height: 8),

            // Review text field
            TextField(
              controller: _reviewController,
              maxLines: 3,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: Constants.addReviewHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed:
                  _isSubmitting ||
                          _userRating == 0 ||
                          _reviewController.text.isEmpty
                      ? null
                      : () => _submitReview(provider),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(Constants.submitReviewButton),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return Colors.blue;
      case 'series':
        return Colors.green;
      case 'trailer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
