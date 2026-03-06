// lib/screens/user_guide_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  _UserGuideScreenState createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<GuideSection> _guideSections = [
    GuideSection(
      title: 'Welcome to AI Travel Companion',
      icon: Icons.rocket_launch,
      color: Color(0xFF00DFD8),
      content: '''
Your personal AI-powered travel assistant for exploring beautiful Sri Lanka! This app helps you plan trips, discover places, get weather updates, and much more.

Let's take a tour of the amazing features waiting for you!''',
      animation: 'travel_animation.json',
    ),
    GuideSection(
      title: '🏠 Home Screen Overview',
      icon: Icons.home,
      color: Color(0xFF007CF0),
      content: '''
• Current Weather: See real-time weather at your location
• Nearby Places: Discover hotels, restaurants & attractions near you
• Quick Actions: Access all features with one tap
• Recent Trips: View your planned trips
• Popular Destinations: Explore Sri Lanka's top spots
• AI Trip Planner: Plan your perfect journey''',
      tips: [
        'Tap on Weather card for detailed forecast',
        'Swipe left/right on recent trips to see more',
        'Use the menu button for profile & settings',
      ],
    ),
    GuideSection(
      title: '🤖 AI Trip Planner',
      icon: Icons.auto_awesome,
      color: Color(0xFF8B5CF6),
      content: '''
Create intelligent, weather-based travel itineraries:

Step 1: Select Your Destination
• Search for any city in Sri Lanka
• Choose from popular destinations

Step 2: Pick Your Dates
• Select start and end dates
• Trip duration automatically calculated

Step 3: Weather Analysis
• AI analyzes weather for each day
• Get recommendations for indoor/outdoor activities

Step 4: Choose Places
• Pick places for each day based on weather
• Filter by category (Indoor, Outdoor, Beach, etc.)
• See ratings and suitability scores

Step 5: Save & View
• Save your trip to Firestore
• View detailed itinerary
• Get notifications before your trip''',
      tips: [
        'Green "Perfect" badge shows best weather matches',
        'Indoor places are recommended on rainy days',
        'You can edit selections anytime',
      ],
    ),
    GuideSection(
      title: '🗺️ Explore Destinations',
      icon: Icons.explore,
      color: Color(0xFF0D9488),
      content: '''
Discover amazing places across Sri Lanka:

Search & Filter
• Search by city or place name
• Filter by category (Beaches, Historical, Cultural, etc.)
• Choose from 35+ Sri Lankan cities

Place Details
• View photos, ratings, and reviews
• Read descriptions and best time to visit
• Get address and location info

Interactive Features
• Tap any place to see full details
• Add directly to trip planner
• Get directions (coming soon)''',
      tips: [
        'Use the city selector (📍 icon) to change location',
        'Top-rated places show first',
        'Search works with both English and Sinhala place names',
      ],
    ),
    GuideSection(
      title: '💬 Chat Assistant',
      icon: Icons.chat,
      color: Color(0xFFF59E0B),
      content: '''
Your AI travel guide that answers all your questions:

What You Can Ask:
• Weather information for any destination
• Best places to visit
• Food recommendations
• Hotel suggestions
• Transport options
• Budget planning tips
• Cultural insights

Smart Features:
• Real-time weather-based recommendations
• Context-aware responses
• Suggestion chips for quick questions
• Typing indicators for natural feel''',
      tips: [
        'Try asking "Weather in Sigiriya"',
        'Ask about specific places like "Galle Fort"',
        'Get budget tips with "Cost of travel"',
        'Use suggestion chips for quick info',
      ],
    ),
    GuideSection(
      title: '📍 Nearby Places',
      icon: Icons.near_me,
      color: Color(0xFFEC4899),
      content: '''
Discover what's around your current location:

Categories:
• 🍽️ Restaurants - Find places to eat
• 🏨 Hotels - Accommodation options
• 🎯 Attractions - Things to see and do

Features:
• Real-time distance calculation
• Open/closed status
• Ratings and reviews
• Weather overlay
• One-tap details view

Navigation:
• Tap any place to see full details
• Get walking/driving distance
• View on map (coming soon)''',
      tips: [
        'Green dots show open places',
        'Distance shows in meters or km automatically',
        'Weather card helps plan outdoor visits',
      ],
    ),
    GuideSection(
      title: '🗓️ My Trips & Itineraries',
      icon: Icons.map,
      color: Color(0xFF6366F1),
      content: '''
Manage all your planned trips in one place:

Trip Categories:
• All Trips - View everything
• Upcoming - Future adventures
• Past - Memories of completed trips

Trip Details:
• Day-by-day itinerary
• Weather forecast for each day
• Selected places with photos
• Hotels and restaurants nearby
• Activity reminders

Features:
• Delete unwanted trips
• View trip statistics
• Quick access to saved plans
• Reorder daily activities''',
      tips: [
        'Swipe to delete trips',
        'Tap any trip to view full details',
        'Check weather predictions before packing',
      ],
    ),
    GuideSection(
      title: '🎯 Pro Tips & Tricks',
      icon: Icons.tips_and_updates,
      color: Color(0xFFD97706),
      content: '''
Make the most of your AI Travel Companion:

Planning Tips:
• Plan trips during dry season (Dec-Mar for west coast)
• Check weather before outdoor activities
• Mix indoor/outdoor places for rainy days

Navigation Tips:
• Use Quick Actions for instant access
• Pull to refresh on all screens
• Long-press for additional options (coming soon)

Account Tips:
• Log in to save trips permanently
• Profile shows your travel stats
• Logout when sharing devices

Coming Soon:
• Real-time maps integration
• User reviews and photos
• Share itineraries with friends
• Offline mode''',
      tips: [
        'Enable notifications for trip reminders',
        'Allow location for better nearby suggestions',
        'Bookmark favorite destinations',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001F3F),
              Color(0xFF0074D9),
              Color(0xFF166D8F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'User Guide',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00DFD8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00DFD8)),
                      ),
                      child: Text(
                        '${_currentStep + 1}/${_guideSections.length}',
                        style: const TextStyle(
                          color: Color(0xFF00DFD8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _guideSections.length,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00DFD8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _guideSections.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildGuidePage(_guideSections[index]);
                  },
                ),
              ),

              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF001F3F).withOpacity(0.9),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    if (_currentStep > 0)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: const Color(0xFF00DFD8).withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                      )
                    else
                      const Spacer(),

                    const SizedBox(width: 16),

                    // Next/Finish Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep < _guideSections.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.pop(context);
                            _showWelcomePopup(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00DFD8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep < _guideSections.length - 1
                              ? 'Next'
                              : 'Finish Tour',
                        ),
                      ),
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

  Widget _buildGuidePage(GuideSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [section.color, section.color.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: section.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              section.icon,
              color: Colors.white,
              size: 50,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Animation (if available)
          if (section.animation != null)
            Container(
              height: 120,
              child: Lottie.asset(
                'assets/animations/${section.animation}',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    section.icon,
                    color: section.color,
                    size: 40,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Content Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: section.color.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content
                Text(
                  section.content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                // Tips section
                if (section.tips.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: section.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: section.color.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pro Tips',
                              style: TextStyle(
                                color: section.color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...section.tips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                      color: section.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick tip badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe left/right to navigate',
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
    );
  }

  void _showWelcomePopup(BuildContext context) {
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
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF00DFD8), size: 28),
            SizedBox(width: 10),
            Text(
              'Ready to Explore!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/travel_animation.json',
              height: 100,
              width: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.travel_explore,
                color: Color(0xFF00DFD8),
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'re all set to start your Sri Lankan adventure!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use Quick Actions to access any feature instantly.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Let\'s Go!',
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
}

class GuideSection {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final List<String> tips;
  final String? animation;

  GuideSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    this.tips = const [],
    this.animation,
  });
}
