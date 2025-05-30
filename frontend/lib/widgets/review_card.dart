import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/review_model.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  
  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating dan Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rating
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < review.rating.floor()
                            ? Icons.star
                            : (index < review.rating 
                                ? Icons.star_half
                                : Icons.star_border),
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(review.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 16),
            
            
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}