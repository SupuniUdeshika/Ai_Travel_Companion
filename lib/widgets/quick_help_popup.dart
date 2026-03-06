// lib/widgets/quick_help_popup.dart

import 'package:flutter/material.dart';

class QuickHelpPopup {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    List<QuickHelpItem>? items,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF00DFD8),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: Color(0xFF00DFD8),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              if (items != null && items.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: item.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showContextualHelp(
    BuildContext context, {
    required String screenName,
  }) {
    Map<String, dynamic> helpContent = {
      'home': QuickHelpPopupData(
        title: '🏠 Home Screen Help',
        message: 'Your central hub for all features',
        items: [
          QuickHelpItem(
            icon: Icons.wb_sunny,
            label: 'Weather Card',
            description: 'Shows real-time weather at your location',
            color: Colors.amber,
          ),
          QuickHelpItem(
            icon: Icons.near_me,
            label: 'Nearby Places',
            description: 'Discover restaurants, hotels & attractions near you',
            color: const Color(0xFF8B5CF6),
          ),
          QuickHelpItem(
            icon: Icons.auto_awesome,
            label: 'Quick Actions',
            description: 'AI Planner, Explore, Chat, My Trips',
            color: const Color(0xFF00DFD8),
          ),
          QuickHelpItem(
            icon: Icons.map,
            label: 'Recent Trips',
            description: 'View your planned trips',
            color: Colors.green,
          ),
        ],
      ),
      'ai_planner': QuickHelpPopupData(
        title: '🤖 AI Trip Planner Help',
        message: 'Create intelligent, weather-based itineraries',
        items: [
          QuickHelpItem(
            icon: Icons.location_on,
            label: 'Step 1: Select Destination',
            description: 'Search for any city in Sri Lanka',
            color: Colors.blue,
          ),
          QuickHelpItem(
            icon: Icons.calendar_today,
            label: 'Step 2: Pick Dates',
            description: 'Choose start and end dates',
            color: Colors.orange,
          ),
          QuickHelpItem(
            icon: Icons.wb_sunny,
            label: 'Step 3: Weather Analysis',
            description: 'AI analyzes weather for each day',
            color: Colors.amber,
          ),
          QuickHelpItem(
            icon: Icons.place,
            label: 'Step 4: Choose Places',
            description: 'Select places based on weather',
            color: Colors.green,
          ),
        ],
      ),
      'explore': QuickHelpPopupData(
        title: '🗺️ Explore Screen Help',
        message: 'Discover amazing places across Sri Lanka',
        items: [
          QuickHelpItem(
            icon: Icons.search,
            label: 'Search',
            description: 'Search by city or place name',
            color: Colors.blue,
          ),
          QuickHelpItem(
            icon: Icons.filter_list,
            label: 'Categories',
            description: 'Filter by Beach, Historical, Cultural, etc.',
            color: Colors.purple,
          ),
          QuickHelpItem(
            icon: Icons.location_city,
            label: 'City Selector',
            description: 'Choose from 35+ Sri Lankan cities',
            color: Colors.orange,
          ),
          QuickHelpItem(
            icon: Icons.star,
            label: 'Ratings',
            description: 'View top-rated places first',
            color: Colors.amber,
          ),
        ],
      ),
    };

    final data = helpContent[screenName] ??
        QuickHelpPopupData(
          title: 'Quick Help',
          message: 'Tap the (?) icon on any screen for contextual help',
          items: [],
        );

    show(
      context: context,
      title: data.title,
      message: data.message,
      items: data.items,
    );
  }
}

class QuickHelpPopupData {
  final String title;
  final String message;
  final List<QuickHelpItem> items;

  QuickHelpPopupData({
    required this.title,
    required this.message,
    this.items = const [],
  });
}

class QuickHelpItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  QuickHelpItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}
