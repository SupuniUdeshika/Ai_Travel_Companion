import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DestinationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailSheet({Key? key, required this.destination})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = destination['name'] as String? ?? 'Destination';
    final address = destination['address'] as String? ?? '';
    final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = destination['reviewCount'] as int? ?? 0;
    final photoUrl = destination['photoUrl'] as String?;
    final description = destination['description'] as String? ?? '';
    final city = destination['city'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF1E3A8A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (photoUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Color(0xFF007CF0),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Color(0xFF007CF0),
                        child: Center(
                          child: Icon(
                            Icons.place,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF00DFD8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (city.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_city,
                              color: Color(0xFF00DFD8),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              city,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Icon(Icons.reviews, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '${reviewCount} reviews',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Color(0xFF00DFD8),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (description.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Color(0xFF00DFD8),
                                    content: Text('Added to trip planner!'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00DFD8),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: Icon(
                                Icons.add_location_alt,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Add to Trip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Color(0xFF00DFD8),
                                    content: Text('Opening in Google Maps...'),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFF00DFD8)),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: Icon(
                                Icons.directions,
                                color: Color(0xFF00DFD8),
                              ),
                              label: Text(
                                'Directions',
                                style: TextStyle(
                                  color: Color(0xFF00DFD8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
      },
    );
  }
}
