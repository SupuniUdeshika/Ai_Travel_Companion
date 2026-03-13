import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/weather_prediction_service.dart';
import '../services/google_places_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/popup_message.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_textfield.dart';
import 'destination_search_screen.dart';
import 'trip_details_screen.dart';
import 'day_place_selection_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AIPlannerScreen extends StatefulWidget {
  @override
  _AIPlannerScreenState createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  Map<String, dynamic>? _selectedDestination;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _weatherPredictions = [];
  List<Map<String, dynamic>> _recommendedPlaces = [];
  List<Map<String, dynamic>> _nearbyHotels = [];
  List<Map<String, dynamic>> _nearbyRestaurants = [];

  // NEW: Store selected places for each day
  Map<int, List<Map<String, dynamic>>> _dailySelectedPlaces = {};

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
  }

  Future<void> _openDestinationSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationSearchScreen(
          onDestinationSelected: (destination) {
            setState(() {
              _selectedDestination = destination;
              // Clear previous selections when destination changes
              _dailySelectedPlaces.clear();
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(
      TextEditingController controller, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00DFD8),
              onPrimary: Colors.white,
              surface: Color(0xFF1E3A8A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });

      if (_startDate != null &&
          _endDate != null &&
          _selectedDestination != null) {
        _analyzeWeatherAndGetRecommendations();
      }
    }
  }

  Future<void> _analyzeWeatherAndGetRecommendations() async {
    if (_selectedDestination == null || _startDate == null || _endDate == null)
      return;

    setState(() => _isAnalyzing = true);

    try {
      final weatherService = WeatherPredictionService();
      await weatherService.initialize();

      final days = _endDate!.difference(_startDate!).inDays + 1;
      final lat = _getLatitude(_selectedDestination!);
      final lng = _getLongitude(_selectedDestination!);
      final city = _selectedDestination!['name'] ?? 'Unknown';

      // Get weather predictions for all days
      _weatherPredictions = await weatherService.predictTripWeather(
        latitude: lat,
        longitude: lng,
        startDate: _startDate!,
        days: days,
      );

      // Initialize daily selected places map
      for (int i = 0; i < days; i++) {
        _dailySelectedPlaces[i] = [];
      }

      // Get nearby places categorized by weather suitability
      _recommendedPlaces = await _getWeatherBasedRecommendations(
        city: city,
        weatherPredictions: _weatherPredictions,
      );

      // Get hotels and restaurant
      _nearbyHotels = await GooglePlacesService.searchPlaces(
        city: city,
        category: 'Hotels',
      );

      _nearbyRestaurants = await GooglePlacesService.searchPlaces(
        city: city,
        category: 'Restaurants',
      );

      setState(() => _isAnalyzing = false);

      // Show weather suggestion popup
      if (mounted) {
        _showWeatherSuggestionPopup();
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      PopupMessage.show(
        context: context,
        title: 'Analysis Failed',
        message: 'Could not analyze weather. Please try again.',
        isSuccess: false,
      );
      print('Error in analysis: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getWeatherBasedRecommendations({
    required String city,
    required List<Map<String, dynamic>> weatherPredictions,
  }) async {
    // Use text search for better results across the entire city
    final allPlaces = await GooglePlacesService.searchPlaces(
      city: city,
      category: 'Tourist Attractions',
    );

    // If no places found, try with broader search terms
    if (allPlaces.isEmpty) {
      print('⚠️ No places found for $city, trying broader search...');
      // Try searching without category restriction
      final broadPlaces = await GooglePlacesService.textSearch(
        'places to visit',
        city,
      );

      if (broadPlaces.isNotEmpty) {
        return _categorizePlaces(broadPlaces, weatherPredictions);
      }
    }

    return _categorizePlaces(allPlaces, weatherPredictions);
  }

  // Helper method to categorize places
  List<Map<String, dynamic>> _categorizePlaces(
    List<Map<String, dynamic>> places,
    List<Map<String, dynamic>> weatherPredictions,
  ) {
    // Categorize places by weather suitability
    for (var place in places) {
      final types = place['types'] as List<dynamic>? ?? [];
      final name = place['name']?.toString().toLowerCase() ?? '';

      // Determine if place is indoor or outdoor based on types
      bool isIndoor = types.any((type) => [
            'museum',
            'art_gallery',
            'aquarium',
            'shopping_mall',
            'movie_theater',
            'spa',
          ].contains(type));

      // Also check name for indoor indicators
      if (!isIndoor) {
        isIndoor = name.contains('museum') ||
            name.contains('temple') ||
            name.contains('church') ||
            name.contains('shopping') ||
            name.contains('hotel');
      }

      place['isIndoor'] = isIndoor;

      // Calculate suitability score for each weather type
      double sunnyScore = isIndoor ? 0.3 : 1.0;
      double rainyScore = isIndoor ? 0.9 : 0.2;
      double cloudyScore = isIndoor ? 0.6 : 0.8;

      place['weatherSuitability'] = {
        'Clear': sunnyScore,
        'Partly Cloudy': cloudyScore,
        'Rain': rainyScore,
        'Drizzle': rainyScore * 0.8,
        'Thunderstorm': isIndoor ? 0.7 : 0.0,
        'Snow': 0.5,
      };
    }

    return places;
  }

  void _showWeatherSuggestionPopup() {
    final goodDays = _weatherPredictions.where((p) {
      final isGood = p['isGoodForTravel'];
      return isGood is bool ? isGood : (isGood?.toString() == 'true');
    }).length;
    final totalDays = _weatherPredictions.length;
    final percentage = totalDays > 0 ? (goodDays / totalDays * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: percentage > 60 ? const Color(0xFF00DFD8) : Colors.orange,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              percentage > 60 ? Icons.wb_sunny : Icons.warning,
              color: percentage > 60 ? const Color(0xFF00DFD8) : Colors.orange,
            ),
            const SizedBox(width: 10),
            Text(
              percentage > 60 ? 'Great Weather!' : 'Weather Alert',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather forecast for your ${totalDays}-day trip:',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '$goodDays out of $totalDays days have good weather',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: totalDays > 0 ? goodDays / totalDays : 0,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 60 ? const Color(0xFF00DFD8) : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              percentage > 60
                  ? 'Most days are perfect for outdoor activities!'
                  : 'Consider planning indoor activities on rainy days.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue Planning',
              style: TextStyle(color: Color(0xFF00DFD8)),
            ),
          ),
        ],
      ),
    );
  }

  double _getLatitude(Map<String, dynamic> destination) {
    if (destination.containsKey('coordinates')) {
      final coords = destination['coordinates'];
      if (coords is Map && coords.containsKey('lat')) {
        return (coords['lat'] as num).toDouble();
      }
    }
    return (destination['latitude'] as num?)?.toDouble() ?? 6.9271;
  }

  double _getLongitude(Map<String, dynamic> destination) {
    if (destination.containsKey('coordinates')) {
      final coords = destination['coordinates'];
      if (coords is Map && coords.containsKey('lng')) {
        return (coords['lng'] as num).toDouble();
      }
    }
    return (destination['longitude'] as num?)?.toDouble() ?? 79.8612;
  }

  // NEW: Navigate to full screen place selection
  void _openDayPlaceSelection(int dayIndex) async {
    final weather = _weatherPredictions[dayIndex];

    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => DayPlaceSelectionScreen(
          dayIndex: dayIndex,
          date: _startDate!.add(Duration(days: dayIndex)),
          weather: weather,
          city: _selectedDestination!['name'] ?? 'Unknown',
          alreadySelectedPlaces: _dailySelectedPlaces[dayIndex] ?? [],
          allPlaces: _recommendedPlaces,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _dailySelectedPlaces[dayIndex] = result;
      });
    }
  }

  // UPDATED: Build day selector with tap to open full screen
  Widget _buildDaySelector() {
    final days = _endDate!.difference(_startDate!).inDays + 1;

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days,
        itemBuilder: (context, index) {
          final date = _startDate!.add(Duration(days: index));
          final weather = _weatherPredictions.length > index
              ? _weatherPredictions[index]
              : null;
          final placeCount = _dailySelectedPlaces[index]?.length ?? 0;
          final isSelected = placeCount > 0;

          return GestureDetector(
            onTap: () => _openDayPlaceSelection(index),
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF0A1F44)],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00DFD8) : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00DFD8).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Day ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  if (weather != null) ...[
                    const SizedBox(height: 4),
                    Icon(
                      weather['icon'] as IconData? ?? Icons.wb_sunny,
                      color: weather['color'] as Color? ?? Colors.yellow,
                      size: 18,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: placeCount > 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      placeCount > 0 ? '$placeCount places' : 'Tap to add',
                      style: TextStyle(
                        color: placeCount > 0
                            ? const Color(0xFF007CF0)
                            : Colors.white70,
                        fontSize: placeCount > 0 ? 10 : 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // SIMPLIFIED: Show selected places summary only
  Widget _buildPlaceSelectionForDay(int dayIndex) {
    final places = _dailySelectedPlaces[dayIndex] ?? [];

    if (places.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00DFD8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${dayIndex + 1} Selected Places',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openDayPlaceSelection(dayIndex),
                icon:
                    const Icon(Icons.edit, color: Color(0xFF00DFD8), size: 16),
                label: const Text(
                  'Edit',
                  style: TextStyle(color: Color(0xFF00DFD8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...places
              .map((place) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: place['photoUrl'] != null
                                ? CachedNetworkImage(
                                    imageUrl: place['photoUrl'] as String,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: const Color(0xFF0A1F44),
                                      child: const Icon(Icons.image,
                                          color: Colors.white24),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFF0A1F44),
                                      child: const Icon(Icons.location_on,
                                          color: Colors.white24),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF0A1F44),
                                    child: const Icon(Icons.location_on,
                                        color: Colors.white24),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(place['rating'] as num?)?.toStringAsFixed(1) ?? '4.0'}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _dailySelectedPlaces[dayIndex]!
                                  .removeWhere((p) => p['id'] == place['id']);
                            });
                          },
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Future<void> _planTrip() async {
    if (_formKey.currentState!.validate()) {
      final authService = AuthService();
      final user = authService.currentUser;

      // Check if user is logged in
      if (user == null) {
        PopupMessage.show(
          context: context,
          title: 'Login Required',
          message: 'Please login to save your trip plans.',
          isSuccess: false,
        );
        return;
      }

      // Check if at least one place is selected
      bool hasSelectedPlaces =
          _dailySelectedPlaces.values.any((list) => list.isNotEmpty);
      if (!hasSelectedPlaces) {
        PopupMessage.show(
          context: context,
          title: 'No Places Selected',
          message:
              'Please select at least one place to visit before planning your trip.',
          isSuccess: false,
        );
        return;
      }

      // Show loading indicator
      PopupMessage.showLoading(context, 'Saving your trip...');

      try {
        // Save trip to Firestore
        final tripId = await _saveTripToFirestore(user.uid);

        // FIXED: Request notification permission first
        final notificationService = NotificationService();

        // Try to schedule notifications, but don't fail if permissions are missing
        try {
          final lat = _getLatitude(_selectedDestination!);
          final lng = _getLongitude(_selectedDestination!);

          await notificationService.scheduleWeatherNotification(
            tripId:
                '${_selectedDestination!['name']}_${DateTime.now().millisecondsSinceEpoch}',
            destination: _selectedDestination!['name'] ?? 'Unknown',
            tripDate: _startDate!,
            lat: lat,
            lng: lng,
          );

          // Schedule daily reminders for each day with activities
          for (int i = 0; i < _dailySelectedPlaces.length; i++) {
            if (_dailySelectedPlaces[i]!.isNotEmpty) {
              final date = _startDate!.add(Duration(days: i));
              await notificationService.scheduleDailyItineraryReminder(
                destination: _selectedDestination!['name'] ?? 'Unknown',
                date: date,
                activityCount: _dailySelectedPlaces[i]!.length,
              );
            }
          }
        } catch (notificationError) {
          // Log error but don't fail the trip save
          print('⚠️ Notification scheduling failed: $notificationError');
          print('Trip saved successfully but notifications may not work.');
        }

        // Dismiss loading
        PopupMessage.dismiss(context);

        // Show success message and navigate
        PopupMessage.showSuccess(
          context,
          'Your trip has been saved successfully with ${_getTotalSelectedPlaces()} places!',
          title: 'Trip Saved',
          onConfirm: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(
                  destination: _selectedDestination!,
                  startDate: _startDate!,
                  endDate: _endDate!,
                  weatherPredictions: _weatherPredictions,
                  recommendedPlaces: _recommendedPlaces,
                  nearbyHotels: _nearbyHotels,
                  nearbyRestaurants: _nearbyRestaurants,
                  dailySelectedPlaces: _dailySelectedPlaces,
                ),
              ),
            );
          },
        );
      } catch (e) {
        PopupMessage.dismiss(context);
        PopupMessage.show(
          context: context,
          title: 'Error',
          message: 'Failed to save trip: ${e.toString()}',
          isSuccess: false,
        );
        print('Error saving trip: $e');
      }
    }
  }

  // Helper method to count total selected places
  int _getTotalSelectedPlaces() {
    int total = 0;
    _dailySelectedPlaces.values.forEach((list) => total += list.length);
    return total;
  }

  Future<String> _saveTripToFirestore(String userId) async {
    try {
      // FIX: Use smaller unique ID (not millisecondsSinceEpoch which overflows 32-bit int)
      final tripId =
          'trip_${DateTime.now().millisecondsSinceEpoch % 1000000000}_${userId.substring(0, 8)}';

      // Prepare daily itinerary data
      final Map<String, dynamic> dailyItinerary = {};
      _dailySelectedPlaces.forEach((dayIndex, places) {
        final date = _startDate!.add(Duration(days: dayIndex));
        // FIX: Convert DateTime to string key to avoid integer issues
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        dailyItinerary[dateKey] = places
            .map((p) => {
                  'id': p['id']?.toString() ??
                      'place_${dayIndex}_${places.indexOf(p)}',
                  'name': p['name'] ?? 'Unknown Place',
                  'address': p['address'] ?? '',
                  'rating': (p['rating'] as num?)?.toDouble() ?? 0.0,
                  'isIndoor': p['isIndoor'] ?? false,
                  'photoUrl': p['photoUrl'] ?? '',
                })
            .toList();
      });

      // Prepare trip data with safe conversions
      final tripData = {
        'tripId': tripId,
        'destination': {
          'name': _selectedDestination!['name'] ?? 'Unknown',
          'address': _selectedDestination!['address'] ?? '',
          'coordinates': {
            'lat': _getLatitude(_selectedDestination!),
            'lng': _getLongitude(_selectedDestination!),
          },
        },
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'duration': _endDate!.difference(_startDate!).inDays + 1,
        'weatherPredictions': _weatherPredictions
            .asMap()
            .map((index, w) => MapEntry(
                  index,
                  {
                    'condition': w['condition']?.toString() ?? 'Unknown',
                    'temperature':
                        (w['temperature'] as num?)?.toDouble() ?? 0.0,
                    'isGoodForTravel': w['isGoodForTravel'] is bool
                        ? w['isGoodForTravel']
                        : (w['isGoodForTravel']?.toString() == 'true'),
                    'recommendation': w['recommendation']?.toString() ?? '',
                  },
                ))
            .values
            .toList(),
        'dailyItinerary': dailyItinerary,
        'totalPlaces': _getTotalSelectedPlaces(),
        'nearbyHotels': _nearbyHotels
            .map((h) => {
                  'id': h['id']?.toString() ?? '',
                  'name': h['name'] ?? '',
                  'address': h['address'] ?? '',
                  'rating': (h['rating'] as num?)?.toDouble() ?? 0.0,
                  'photoUrl': h['photoUrl'] ?? '',
                })
            .toList(),
        'nearbyRestaurants': _nearbyRestaurants
            .map((r) => {
                  'id': r['id']?.toString() ?? '',
                  'name': r['name'] ?? '',
                  'address': r['address'] ?? '',
                  'rating': (r['rating'] as num?)?.toDouble() ?? 0.0,
                  'photoUrl': r['photoUrl'] ?? '',
                })
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'planned',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .set(tripData);

      print('✅ Trip saved successfully for user: $userId with ID: $tripId');
      return tripId;
    } catch (e, stackTrace) {
      print('❌ Error saving trip to Firestore: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _startDate != null && _endDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;

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
                    const Text(
                      'AI Trip Planner',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destination Selection Card
                        GestureDetector(
                          onTap: _openDestinationSearch,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _selectedDestination != null
                                    ? [
                                        const Color(0xFF007CF0),
                                        const Color(0xFF00DFD8)
                                      ]
                                    : [
                                        const Color(0xFF1E3A8A),
                                        const Color(0xFF0A1F44)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedDestination != null
                                    ? const Color(0xFF00DFD8)
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedDestination != null
                                            ? _selectedDestination!['name'] ??
                                                'Select Destination'
                                            : 'Select Destination',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_selectedDestination != null)
                                        Text(
                                          _selectedDestination!['address'] ??
                                              'Tap to change',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date Selection
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _selectDate(_startDateController, true),
                                child: AbsorbPointer(
                                  child: CustomTextField(
                                    controller: _startDateController,
                                    label: 'Start Date',
                                    prefixIcon: Icons.calendar_today,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _selectDate(_endDateController, false),
                                child: AbsorbPointer(
                                  child: CustomTextField(
                                    controller: _endDateController,
                                    label: 'End Date',
                                    prefixIcon: Icons.calendar_today,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Weather Analysis
                        if (_isAnalyzing)
                          Center(
                            child: Column(
                              children: [
                                Lottie.asset(
                                  'assets/animations/travel_animation.json',
                                  height: 150,
                                  width: 150,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(
                                    height: 150,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF00DFD8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'AI is analyzing weather and finding places...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_weatherPredictions.isNotEmpty)
                          _buildWeatherAnalysis(),

                        // NEW: Place Selection Section
                        if (_weatherPredictions.isNotEmpty &&
                            !_isAnalyzing) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Select Places to Visit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose places for each day based on weather',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),

                          // Day selector
                          _buildDaySelector(),

                          const SizedBox(height: 16),

                          // Place selection for each day
                          ...List.generate(days,
                              (index) => _buildPlaceSelectionForDay(index)),
                        ],

                        const SizedBox(height: 24),

                        // Plan Trip Button
                        if (_selectedDestination != null &&
                            _startDate != null &&
                            _endDate != null &&
                            !_isAnalyzing)
                          GradientButton(
                            onPressed: _planTrip,
                            child: Text(
                              'PLAN MY TRIP ($days DAYS)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherAnalysis() {
    final goodDays = _weatherPredictions.where((p) {
      final isGood = p['isGoodForTravel'];
      return isGood is bool ? isGood : (isGood?.toString() == 'true');
    }).length;
    final totalDays = _weatherPredictions.length;
    final percentage = totalDays > 0 ? (goodDays / totalDays * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: percentage > 60 ? const Color(0xFF00DFD8) : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weather Forecast',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: percentage > 60
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage% Good',
                  style: TextStyle(
                    color: percentage > 60 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weatherPredictions.length,
              itemBuilder: (context, index) {
                final pred = _weatherPredictions[index];
                final isGood = pred['isGoodForTravel'];
                final isGoodBool =
                    isGood is bool ? isGood : (isGood?.toString() == 'true');
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isGoodBool
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isGoodBool ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Day ${index + 1}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        pred['icon'] as IconData? ?? Icons.wb_sunny,
                        color: pred['color'] as Color? ?? Colors.yellow,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(pred['temperature'] as num?)?.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
