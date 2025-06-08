import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_app/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/models/comment_model.dart'; // Updated import
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:flutter_video_app/screens/player_screen.dart';
import 'package:flutter_video_app/widgets/comment_card.dart'; // Updated import
import 'package:flutter_video_app/services/api_service.dart'; // Added import
import 'package:flutter_video_app/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController(); // Renamed
  double _userRating = 0.0; // Kept for now, can be removed if not used for comments
  bool _isSubmittingComment = false; // Renamed
  bool _isExpanded = false;
  late AnimationController _animationController;
  late AnimationController _ratingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _ratingScaleAnimation;

  // New state variables for comments
  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  String? _replyingToCommentId; // To store parentId for a reply
  String? _activelyReplyingToCommentId; // To control which comment's reply field is open


  @override
  void initState() {
    super.initState();
    _fetchComments(); // Fetch comments on init
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _ratingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _ratingScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _ratingAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    try {
      final comments = await ApiService.getVideoComments(widget.video.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching comments: ${e.toString()}')),
        );
      }
    }
  }

  void _handleReplyTapped(String parentId) {
    setState(() {
      if (_activelyReplyingToCommentId == parentId) {
        _activelyReplyingToCommentId = null; // Close if already open
      } else {
        _activelyReplyingToCommentId = parentId;
      }
    });
  }

  // Modified to handle direct reply submission from CommentCard
  Future<void> _submitReplyFromCard(String parentId, String commentText, double rating) async {
     if (commentText.isEmpty) return;
    setState(() => _isSubmittingComment = true);

    try {
      await ApiService.addComment(
        widget.video.id,
        commentText,
        rating, // Using the rating from card, default 0.0 for replies
        parentId: parentId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Reply submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchComments(); // Refresh comments
        setState(() {
          _activelyReplyingToCommentId = null; // Close reply input
        });
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting reply: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }


  @override
  void dispose() {
    _commentController.dispose(); // Renamed
    _animationController.dispose();
    _ratingAnimationController.dispose();
    super.dispose();
  }

  bool _shouldShowExpandButton(BuildContext context) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: widget.video.description,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 15),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 40);
    return textPainter.didExceedMaxLines;
  }

  // Updated to submit comment/reply
  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await ApiService.addComment(
        widget.video.id,
        _commentController.text,
        _userRating, // Using existing _userRating, can be changed if rating is not part of comment
        parentId: _replyingToCommentId, // Pass parentId if it's a reply
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(_replyingToCommentId == null ? 'Comment submitted successfully' : 'Reply submitted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _commentController.clear();
        setState(() {
          _userRating = 0.0; // Reset rating
          _replyingToCommentId = null; // Reset replying state
        });
        _fetchComments(); // Refresh comments list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error submitting comment: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<FavoritesProvider, AuthProvider>(
      builder: (context, favoritesProvider, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          // Non-authenticated user view (same as before)
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Please log in to view video details and comments',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Authenticated user view
        final bool isFavorite = favoritesProvider.isFavorite(widget.video.id);
        // The FutureBuilder for reviews is removed as comments are handled by _fetchComments and _comments state

        // Calculate average rating based on current video's rating, can be updated if comments also have ratings
        final double averageRating = widget.video.rating;


        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.video.backdropPath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.error, size: 48),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.video.title,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 3,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isFavorite ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      key: ValueKey(isFavorite),
                                      color: isFavorite ? Colors.red : Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                                  onPressed: () async {
                                    try {
                                      await favoritesProvider.toggleFavorite(widget.video);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error updating favorites: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildEnhancedInfoChip(
                                widget.video.type.take(1).join(', ').toUpperCase(),
                                _getTypeColor(widget.video.type.join(', ')),
                                Icons.movie_outlined,
                              ),
                              _buildEnhancedInfoChip(
                                widget.video.categories.take(2).join(', '),
                                Colors.blueGrey,
                                Icons.category_outlined,
                              ),
                              _buildEnhancedInfoChip(
                                widget.video.releaseDate,
                                Colors.purple,
                                Icons.calendar_today_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                           _buildEnhancedRatingSection(
                            averageRating, // Use the calculated or video's direct rating
                            _comments.length, // Use comments length for review count if applicable
                          ),
                          const SizedBox(height: 24),
                          _buildExpandableDescription(),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(video: widget.video),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_circle_fill, size: 24),
                              label: const Text(
                                Constants.watchNowButton,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Display Comments Section
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedInfoChip(String label, Color color, IconData icon) { // Keep this helper
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRatingSection(double averageRating, int commentCount) { // Updated to commentCount
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _ratingScaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Using video's direct rating for display, can be dynamic if comments have ratings
                  '${widget.video.rating.toStringAsFixed(1)} / 5.0',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      final rating = widget.video.rating; // Video's rating
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '($commentCount comments)', // Updated to commentCount
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDescription() { // Keep this helper
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.video.description,
            maxLines: _isExpanded ? null : 3,
            overflow:
                _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 15),
          ),
        ),
        if (_shouldShowExpandButton(context))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // New section for comments
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.comment_outlined, // Changed icon
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Comments', // Changed title
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_comments.length}', // Use _comments length
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Add Comment Input Field (Top-level)
        _buildAddCommentInputSection(),
        const SizedBox(height: 24),

        // Comments list
        if (_isLoadingComments)
          _buildLoadingState("Loading comments...") // Updated message
        else if (_comments.isEmpty)
          _buildEmptyState("No comments yet. Be the first to comment!") // Updated message
        else
          ListView.builder(
            shrinkWrap: true, // Important for ListView inside Column/CustomScrollView
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner ListView
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CommentCard(
                  comment: comment,
                  onReplyTapped: _handleReplyTapped,
                  onReplySubmitted: _submitReplyFromCard,
                  replyingToId: _activelyReplyingToCommentId,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddCommentInputSection() {
    // This can be a simplified version or the existing _buildEnhancedAddReviewSection adapted
    // For now, let's make a simpler one for comments.
    // If _replyingToCommentId is not null, this input field is for a reply.
    String hintText = _replyingToCommentId != null ? 'Write your reply...' : 'Add a public comment...';
    String buttonText = _replyingToCommentId != null ? 'Post Reply' : 'Post Comment';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToCommentId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text("Replying to: ${_comments.firstWhere((c) => c.id == _replyingToCommentId, orElse: () => _findCommentRecursive(_comments, _replyingToCommentId!)!).userName}", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.cancel, size: 18),
                    onPressed: () {
                      setState(() {
                        _replyingToCommentId = null;
                        _commentController.clear(); // Clear text when cancelling reply
                      });
                    },
                  )
                ],
              ),
            ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            enabled: !_isSubmittingComment,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          // Star rating (optional for comments, can be removed or adapted)
          // For simplicity, I'm reusing the _userRating state and UI from reviews
          // This part can be removed if comments don't have ratings.
           if (_replyingToCommentId == null) // Only show rating for top-level comments
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    color: index < _userRating ? Colors.amber : Colors.grey,
                  ),
                  onPressed: _isSubmittingComment ? null : () {
                    setState(() {
                      _userRating = index + 1.0;
                    });
                  },
                );
              }),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isSubmittingComment || _commentController.text.isEmpty
                ? null
                : _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmittingComment
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(buttonText),
          ),
        ],
      ),
    );
  }

  CommentModel? _findCommentRecursive(List<CommentModel> comments, String id) {
    for (var comment in comments) {
      if (comment.id == id) return comment;
      var foundInReply = _findCommentRecursive(comment.replies, id);
      if (foundInReply != null) return foundInReply;
    }
    return null;
  }


  Widget _buildLoadingState(String message) { // Added message parameter
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(message), // Use message parameter
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, {bool isCommentError = false}) { // Added isCommentError
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            isCommentError ? 'Error loading comments: $error' : 'Error loading reviews: $error', // Differentiate message
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => isCommentError ? _fetchComments() : setState(() {}), // Call _fetchComments for comment errors
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) { // Added message parameter
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]), // Changed icon
          const SizedBox(height: 16),
          Text(
            message, // Use message parameter
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
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
