// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/weather_prediction_service.dart';
import '../services/location_service.dart';
import '../services/trip_service.dart';
import '../services/google_places_service.dart';
import '../widgets/feature_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/destination_card.dart';
import '../widgets/trip_history_card.dart';
import '../widgets/quick_help_popup.dart';
import 'login_screen.dart';
import 'explore_screen.dart';
import 'ai_planner_screen.dart';
import 'chatbot_screen.dart';
import 'my_trips_screen.dart';
import 'nearby_places_screen.dart';
import 'user_guide_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final TripService _tripService = TripService();
  Map<String, double>? _currentLocation;
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _recentTrips = [];
  bool _isLoadingTrips = true;

  // New variables for popular destinations
  List<Map<String, dynamic>> _popularDestinations = [];
  bool _isLoadingPopular = true;

  // Sri Lankan cities for popular destinations
  final List<String> _popularCities = [
    'Sigiriya',
    'Kandy',
    'Galle',
    'Ella',
    'Mirissa',
    'Nuwara Eliya',
    'Anuradhapura',
    'Trincomalee',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadRecentTrips();
    _loadPopularDestinations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadRecentTrips() async {
    try {
      final trips = await _tripService.getRecentTrips(limit: 3);
      setState(() {
        _recentTrips = trips;
        _isLoadingTrips = false;
      });
    } catch (e) {
      print('Error loading trips: $e');
      setState(() => _isLoadingTrips = false);
    }
  }

  // New method to load popular destinations from Google Places API
  Future<void> _loadPopularDestinations() async {
    setState(() {
      _isLoadingPopular = true;
    });

    try {
      List<Map<String, dynamic>> allPopularPlaces = [];

      // Fetch popular places from different cities
      for (String city in _popularCities) {
        final places = await GooglePlacesService.searchPlaces(
          city: city,
          category: 'Tourist Attractions',
          radius: 20000, // 20km radius
        );

        if (places.isNotEmpty) {
          // Take top 2 from each city
          allPopularPlaces.addAll(places.take(2));
        }

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // If API returns empty, use sample data
      if (allPopularPlaces.isEmpty) {
        allPopularPlaces = _getSamplePopularDestinations();
      }

      // Sort by rating and take top 6
      allPopularPlaces.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      setState(() {
        _popularDestinations = allPopularPlaces.take(6).toList();
        _isLoadingPopular = false;
      });
    } catch (e) {
      print('Error loading popular destinations: $e');
      setState(() {
        _popularDestinations = _getSamplePopularDestinations();
        _isLoadingPopular = false;
      });
    }
  }

  // Sample popular destinations as fallback
  List<Map<String, dynamic>> _getSamplePopularDestinations() {
    return [
      {
        'name': 'Sigiriya Rock Fortress',
        'address': 'Sigiriya, Central Province',
        'rating': 4.8,
        'reviewCount': 1250,
        'city': 'Sigiriya',
        'province': 'Central',
        'photoUrl': null,
        'description': 'Ancient rock fortress and palace ruins with frescoes.',
      },
      {
        'name': 'Temple of the Tooth',
        'address': 'Kandy, Central Province',
        'rating': 4.9,
        'reviewCount': 2100,
        'city': 'Kandy',
        'province': 'Central',
        'photoUrl': null,
        'description': 'Sacred Buddhist temple housing a relic of Buddha.',
      },
      {
        'name': 'Galle Fort',
        'address': 'Galle, Southern Province',
        'rating': 4.6,
        'reviewCount': 850,
        'city': 'Galle',
        'province': 'Southern',
        'photoUrl': null,
        'description':
            'Historic Portuguese-built fort with colonial architecture.',
      },
      {
        'name': 'Nine Arch Bridge',
        'address': 'Ella, Uva Province',
        'rating': 4.8,
        'reviewCount': 1200,
        'city': 'Ella',
        'province': 'Uva',
        'photoUrl': null,
        'description': 'Iconic bridge with nine arches, beautiful train rides.',
      },
      {
        'name': 'Mirissa Beach',
        'address': 'Mirissa, Southern Province',
        'rating': 4.7,
        'reviewCount': 980,
        'city': 'Mirissa',
        'province': 'Southern',
        'photoUrl': null,
        'description': 'Beautiful beach famous for whale watching and surfing.',
      },
      {
        'name': 'Nuwara Eliya',
        'address': 'Nuwara Eliya, Central Province',
        'rating': 4.5,
        'reviewCount': 1500,
        'city': 'Nuwara Eliya',
        'province': 'Central',
        'photoUrl': null,
        'description':
            'Hill station known for tea plantations and cool climate.',
      },
    ];
  }

  // Method to show help options bottom sheet
  void _showHelpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'How can we help you?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Quick Guide Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00DFD8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book, color: Color(0xFF00DFD8)),
              ),
              title: const Text(
                '📖 Full User Guide',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Step-by-step tutorial with tips',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserGuideScreen(),
                  ),
                );
              },
            ),

            // Contextual Help Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help, color: Colors.amber),
              ),
              title: const Text(
                '❓ Quick Help',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Get help for current screen',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              onTap: () {
                Navigator.pop(context);
                QuickHelpPopup.showContextualHelp(context, screenName: 'home');
              },
            ),

            // Tips & Tricks Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates, color: Colors.green),
              ),
              title: const Text(
                '💡 Pro Tips',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Expert advice for better experience',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showProTips(context);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Method to show pro tips
  void _showProTips(BuildContext context) {
    QuickHelpPopup.show(
      context: context,
      title: '💡 Pro Tips',
      message: 'Make the most of your AI Travel Companion',
      items: [
        QuickHelpItem(
          icon: Icons.wb_sunny,
          label: 'Weather Planning',
          description: 'Plan outdoor activities on sunny days (Dec-Mar)',
          color: Colors.amber,
        ),
        QuickHelpItem(
          icon: Icons.notifications,
          label: 'Enable Notifications',
          description: 'Get reminders before your trips',
          color: Colors.blue,
        ),
        QuickHelpItem(
          icon: Icons.location_on,
          label: 'Allow Location',
          description: 'Better nearby place suggestions',
          color: Colors.green,
        ),
        QuickHelpItem(
          icon: Icons.save,
          label: 'Save Trips',
          description: 'Login to save itineraries permanently',
          color: Colors.purple,
        ),
      ],
    );
  }

  // Updated method to show destination detail
  void _showDestinationDetail(Map<String, dynamic> destination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DestinationDetailSheet(destination: destination);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.menu, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Text(
                      'AI Travel Companion',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _showLogoutConfirmation(context);
                        } else if (value == 'profile') {
                          _showProfileDialog(context, authService);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'profile', child: Text('Profile')),
                        PopupMenuItem(value: 'logout', child: Text('Logout')),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Animation
                Container(
                  height: 120,
                  child: Lottie.asset(
                    'assets/animations/travel_animation.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.transparent,
                      child: const Center(
                        child: Icon(
                          Icons.travel_explore,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Welcome text
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Ready to explore beautiful Sri Lanka?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 30),

                // Weather Card
                _isLoadingLocation
                    ? Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00DFD8),
                          ),
                        ),
                      )
                    : WeatherCard(),

                const SizedBox(height: 30),

                // Nearby Places Button
                if (_currentLocation != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Material(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NearbyPlacesScreen(
                                latitude: _currentLocation!['lat']!,
                                longitude: _currentLocation!['lng']!,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.near_me,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Discover Nearby Places',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Hotels, restaurants & attractions near you',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Quick actions title
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Quick actions grid
                _buildQuickActions(context),

                const SizedBox(height: 30),

                // My Trips Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Recent Trips',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyTripsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF00DFD8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Recent Trips List
                _isLoadingTrips
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00DFD8),
                        ),
                      )
                    : _recentTrips.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No trips planned yet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AIPlannerScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00DFD8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Plan a Trip Now'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentTrips.length,
                            itemBuilder: (context, index) {
                              return TripHistoryCard(
                                trip: _recentTrips[index],
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/trip-details',
                                    arguments: _recentTrips[index],
                                  );
                                },
                              );
                            },
                          ),

                const SizedBox(height: 30),

                // Featured destinations header with navigation to ExploreScreen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popular Destinations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to ExploreScreen when "Explore All" is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExploreScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Explore All',
                        style: TextStyle(
                          color: Color(0xFF00DFD8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Popular destinations list from Google Places API - FIXED VERSION
                _isLoadingPopular
                    ? _buildPopularDestinationsShimmer()
                    : _buildPopularDestinationsList(),

                const SizedBox(height: 30),

                // Plan My Trip button
                Container(
                  width: double.infinity,
                  height: 65,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Material(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AIPlannerScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007CF0).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'PLAN MY TRIP WITH AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Shimmer loading for popular destinations
  Widget _buildPopularDestinationsShimmer() {
    return SizedBox(
      height: 260, // Increased height to prevent overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 140, // Increased height
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                // Content placeholder
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 12,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build popular destinations list - FIXED VERSION
  Widget _buildPopularDestinationsList() {
    return SizedBox(
      height: 280, // Increased height to accommodate all content
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _popularDestinations.length,
        itemBuilder: (context, index) {
          final destination = _popularDestinations[index];
          return _buildPopularDestinationCard(destination);
        },
      ),
    );
  }

  // Build individual popular destination card - FIXED VERSION
  Widget _buildPopularDestinationCard(Map<String, dynamic> destination) {
    final name = destination['name'] as String? ?? 'Destination';
    final city = destination['city'] as String? ?? '';
    final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
    final photoUrl = destination['photoUrl'] as String?;
    final address = destination['address'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showDestinationDetail(destination),
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(16),
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
          children: [
            // Image section - Fixed height
            Container(
              height: 130, // Fixed height for image
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 130,
                        placeholder: (context, url) => Container(
                          color: Color(0xFF007CF0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Color(0xFF007CF0),
                          child: Center(
                            child: Icon(
                              Icons.place,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Color(0xFF007CF0),
                        child: Center(
                          child: Icon(
                            Icons.place,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),

            // Details section - Fixed layout
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Location
                    Text(
                      city.isNotEmpty ? city : address,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Spacer to push rating to bottom
                    const Spacer(),

                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick actions grid
  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        FeatureCard(
          title: 'AI Planner',
          subtitle: 'Weather-based',
          icon: Icons.auto_awesome,
          color: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AIPlannerScreen()),
            );
          },
        ),
        FeatureCard(
          title: 'Explore',
          subtitle: 'Destinations',
          icon: Icons.explore,
          color: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExploreScreen()),
            );
          },
        ),
        FeatureCard(
          title: 'Chat Assistant',
          subtitle: 'AI Travel Guide',
          icon: Icons.chat,
          color: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatbotScreen()),
            );
          },
        ),
        FeatureCard(
          title: 'My Trips',
          subtitle: 'View Saved Trips',
          icon: Icons.map,
          color: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyTripsScreen()),
            );
          },
        ),
        FeatureCard(
          title: 'Nearby',
          subtitle: 'Places Near You',
          icon: Icons.near_me,
          color: Colors.white,
          onTap: () {
            if (_currentLocation != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NearbyPlacesScreen(
                    latitude: _currentLocation!['lat']!,
                    longitude: _currentLocation!['lng']!,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to get your location'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
        ),
        FeatureCard(
          title: 'User Guide',
          subtitle: 'Learn How to Use',
          icon: Icons.help_outline,
          color: const Color(0xFFF59E0B),
          onTap: () {
            _showHelpOptions(context);
          },
        ),
      ],
    );
  }

  void _showProfileDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person,
                color: const Color(0xFF00DFD8),
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF00DFD8),
                  child: Text(
                    _getUserInitials(authService.userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  authService.userName ?? 'Traveler',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  authService.userEmail ?? 'No email',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Travel Stats',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00DFD8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Trips', _recentTrips.length.toString()),
                        _buildStatItem('Places', '0'),
                        _buildStatItem('Badges', '0'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00DFD8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getUserInitials(String? userName) {
    if (userName == null || userName.isEmpty) return 'T';
    final names = userName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00DFD8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );

                  await authService.signOut();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Logged out successfully'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    _showErrorDialog(
                      context,
                      'Logout Failed',
                      error.toString(),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00DFD8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OK',
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

// Destination Detail Sheet Widget
class _DestinationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> destination;

  const _DestinationDetailSheet({Key? key, required this.destination})
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
    final province = destination['province'] as String? ?? '';

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
                // Drag Handle
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

                // Hero Image
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

                // Content
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating
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

                      // Location
                      if (city.isNotEmpty || province.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_city,
                              color: Color(0xFF00DFD8),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              city.isNotEmpty && province.isNotEmpty
                                  ? '$city, $province Province'
                                  : city.isNotEmpty
                                      ? city
                                      : province,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                      // Reviews
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

                      // Address
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

                      // Description
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

                      // Action Buttons
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
