// lib/widgets/destination_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DestinationCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final String? imageUrl;
  final VoidCallback onTap;

  const DestinationCard({
    Key? key,
    required this.name,
    required this.location,
    required this.rating,
    this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, // Reduced width
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFF1E3A8A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section - fixed height
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: Color(0xFF007CF0),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 90,
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF00DFD8),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.landscape,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.landscape,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
              ),
            ),

            // Content section - fixed padding
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),

                  // Location
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  // Rating row
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 12,
                      ),
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
