import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/comment_model.dart';
import 'package:flutter_video_app/providers/auth_provider.dart'; // Import AuthProvider
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart'; // Import Provider

class CommentCard extends StatelessWidget {
  final ReviewModel comment;
  final int replyCount;
  final bool isExpanded;
  final VoidCallback onToggleReplies; // Changed from Function(String)
  final VoidCallback onStartReply;    // Changed from Function(String)

  const CommentCard({
    Key? key,
    required this.comment,
    required this.replyCount,
    required this.isExpanded,
    required this.onToggleReplies,
    required this.onStartReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0), // Adjusted margin
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  // Placeholder for user avatar - replace with actual image if available
                  child: Text(comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U'),
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy - hh:mm a').format(comment.timestamp),
                      style: const TextStyle(fontSize: 11.0, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(comment.comment, style: const TextStyle(fontSize: 14)),
            if (comment.rating > 0) ...[
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Text(
                    'Rating: ${comment.rating.toStringAsFixed(1)}/5',
                    style: const TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ],
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Consumer<AuthProvider>( // Use Consumer to access AuthProvider
                  builder: (context, authProvider, child) {
                    if (authProvider.user?.role == 'admin') {
                      return TextButton.icon(
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Reply'),
                        onPressed: onStartReply,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Hide reply button if not admin
                  },
                ),
                if (replyCount > 0)
                  TextButton.icon(
                    icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
                    label: Text(isExpanded ? 'Hide replies' : 'View $replyCount replies'),
                    onPressed: onToggleReplies, // Use the new callback
                     style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
            // The recursive rendering of replies is removed from here.
            // It will be handled by the VideoDetailScreen.
          ],
        ),
      ),
    );
  }
}
