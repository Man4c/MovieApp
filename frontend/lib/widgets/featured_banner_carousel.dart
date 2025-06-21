import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/screens/video_detail_screen.dart';

class FeaturedBannerCarousel extends StatefulWidget {
  final List<VideoModel> featuredVideos;

  const FeaturedBannerCarousel({super.key, required this.featuredVideos});

  @override
  State<FeaturedBannerCarousel> createState() => _FeaturedBannerCarouselState();
}

class _FeaturedBannerCarouselState extends State<FeaturedBannerCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
    initialPage: 0,
  );
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.featuredVideos.isEmpty) {
      print("FeaturedBannerCarousel: No videos provided");
      return const SizedBox.shrink();
    }

    print(
      "FeaturedBannerCarousel: Showing ${widget.featuredVideos.length} videos",
    );
    print(
      "First video data: {title: ${widget.featuredVideos[0].title}, backdropPath: ${widget.featuredVideos[0].backdropPath}}",
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * (9 / 16); // Rasio 16:9

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.featuredVideos.length,
            itemBuilder: (context, index) {
              final video = widget.featuredVideos[index];
              double horizontalPadding =
                  _pageController.viewportFraction < 1.0 ? 8.0 : 0.0;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value =
                        (_pageController.page ?? _currentPage.toDouble()) -
                        index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  } else {
                    value = index == _currentPage ? 1.0 : 0.85;
                  }
                  return Center(
                    child: SizedBox(
                      width: screenWidth * _pageController.viewportFraction,
                      child: Transform.scale(scale: value, child: child),
                    ),
                  );
                },
                child: _buildBannerItem(context, video, horizontalPadding),
              );
            },
          ),
        ),
        if (widget.featuredVideos.length > 1) _buildPageIndicator(),
      ],
    );
  }

  Widget _buildBannerItem(
    BuildContext context,
    VideoModel video,
    double horizontalPadding,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailScreen(video: video),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl:
                      (video.backdropPath.isNotEmpty)
                          ? video.backdropPath
                          : video.posterPath,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[900],
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

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0, //
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black54,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VideoDetailScreen(video: video),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepOrange.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Play'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.featuredVideos.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: _currentPage == index ? 12.0 : 8.0,
            height: _currentPage == index ? 12.0 : 8.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _currentPage == index ? 6 : 4,
              ),
              color:
                  _currentPage == index ? Colors.deepOrange : Colors.grey[700],
            ),
          );
        }),
      ),
    );
  }
}
