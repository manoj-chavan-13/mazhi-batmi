import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CardSkelton extends StatelessWidget {
  const CardSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: AnimatedScale(
        scale: 1.0,
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Skeleton
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Profile picture skeleton
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name skeleton
                      Container(
                        width: 150,
                        height: 15,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 4),
                      // Location skeleton
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                  Spacer(),
                  // More options button skeleton
                  Container(
                    width: 30,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
            // News Image Section - Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    height: 200.0,
                    width: double.infinity,
                    child: Container(
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
            // Title Section - Skeleton
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                height: 15,
                color: Colors.grey[300],
              ),
            ),
            // Footer Section - Skeleton
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date and time skeleton
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 18, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Container(
                        width: 60,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                  // Views, comments, share, and bookmark skeletons
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.visibility,
                              size: 18, color: Colors.grey[600]),
                          SizedBox(width: 6),
                          Container(
                            width: 30,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.comment,
                              size: 18, color: Colors.grey[600]),
                          SizedBox(width: 6),
                          Container(
                            width: 30,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.share, size: 18, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Icon(Icons.bookmark, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
