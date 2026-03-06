// lib/widgets/trip_history_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripHistoryCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TripHistoryCard({
    Key? key,
    required this.trip,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final destination = trip['destination'] as Map<String, dynamic>? ?? {};
    final startDate = trip['startDate'] != null
        ? DateTime.parse(trip['startDate'])
        : DateTime.now();
    final endDate = trip['endDate'] != null
        ? DateTime.parse(trip['endDate'])
        : DateTime.now().add(const Duration(days: 1));
    final duration =
        trip['duration'] ?? endDate.difference(startDate).inDays + 1;
    final totalPlaces = trip['totalPlaces'] ?? 0;
    final createdAt = trip['createdAt'] as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E3A8A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF00DFD8).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination['name'] ?? 'Unknown Destination',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.timer,
                    '$duration days',
                    'Duration',
                  ),
                  _buildStatItem(
                    Icons.place,
                    totalPlaces.toString(),
                    'Places',
                  ),
                  _buildStatItem(
                    Icons.wb_sunny,
                    _getWeatherSummary(),
                    'Weather',
                  ),
                ],
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Divider(
                  color: Colors.white.withOpacity(0.2),
                  height: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Planned on ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF00DFD8),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getWeatherSummary() {
    final predictions = trip['weatherPredictions'] as List<dynamic>? ?? [];
    if (predictions.isEmpty) return 'N/A';

    int goodDays = predictions.where((p) {
      final isGood = p['isGoodForTravel'];
      return isGood is bool ? isGood : (isGood?.toString() == 'true');
    }).length;

    return '${(goodDays / predictions.length * 100).round()}% good';
  }
}
