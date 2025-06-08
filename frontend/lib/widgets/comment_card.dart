import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/comment_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final Function(String parentId) onReplyTapped;
  final Function(String parentId, String commentText, double rating) onReplySubmitted; // Added for submitting reply directly from card
  final String? replyingToId; // To highlight which comment is being replied to

  const CommentCard({
    Key? key,
    required this.comment,
    required this.onReplyTapped,
    required this.onReplySubmitted,
    this.replyingToId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _replyController = TextEditingController();
    bool isReplyingCurrent = replyingToId == comment.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            Text(
              DateFormat('MMM d, yyyy - hh:mm a').format(comment.timestamp), // Format timestamp
              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
            const SizedBox(height: 8.0),
            Text(comment.comment),
            // Rating can be displayed if needed: Text('Rating: ${comment.rating}/5'),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onReplyTapped(comment.id),
                  child: Text(isReplyingCurrent ? 'Cancel Reply' : 'Reply'),
                ),
              ],
            ),
            if (isReplyingCurrent) // Show reply input field directly under the comment
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          hintText: 'Write your reply...',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_replyController.text.isNotEmpty) {
                          // For now, using a default rating of 0.0 for replies
                          onReplySubmitted(comment.id, _replyController.text, 0.0);
                          _replyController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: comment.replies
                      .map((reply) => CommentCard(
                            comment: reply,
                            onReplyTapped: onReplyTapped,
                            onReplySubmitted: onReplySubmitted, // Pass down the submission handler
                            replyingToId: replyingToId, // Pass down replyingToId
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
