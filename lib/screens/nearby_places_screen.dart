// lib/screens/nearby_places_screen.dart

import 'dart:math'; // ADD THIS IMPORT FOR MATH FUNCTIONS

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/location_service.dart';
import '../services/weather_prediction_service.dart';
import '../widgets/popup_message.dart';
import 'destination_detail_sheet.dart';

class NearbyPlacesScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const NearbyPlacesScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _NearbyPlacesScreenState createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocationService _locationService = LocationService();
  final WeatherPredictionService _weatherService = WeatherPredictionService();

  Map<String, List<Map<String, dynamic>>> _nearbyPlaces = {};
  Map<String, dynamic>? _currentWeather;
  bool _isLoading = true;
  String _currentLocation = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get location name
      final location = await _locationService.getAddressFromCoordinates(
        widget.latitude,
        widget.longitude,
      );

      // Get weather
      await _weatherService.initialize();
      final weather = await _weatherService.predictWeather(
        latitude: widget.latitude,
        longitude: widget.longitude,
        date: DateTime.now(),
      );

      // Get nearby places
      final places = await _locationService.getAllNearbyPlaces(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      setState(() {
        _currentLocation = location;
        _currentWeather = weather;
        _nearbyPlaces = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        PopupMessage.showError(
          context,
          'Failed to load nearby places: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F3F), Color(0xFF0074D9), Color(0xFF166D8F)],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nearby Places',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_currentLocation.isNotEmpty)
                            Text(
                              _currentLocation,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh, color: Color(0xFF00DFD8)),
                    ),
                  ],
                ),
              ),

              // Weather Card
              if (_currentWeather != null) _buildWeatherCard(),

              const SizedBox(height: 16),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF00DFD8),
                  unselectedLabelColor: Colors.white70,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  tabs: const [
                    Tab(text: 'Restaurants'),
                    Tab(text: 'Hotels'),
                    Tab(text: 'Attractions'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00DFD8),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPlaceList(_nearbyPlaces['restaurant'] ?? []),
                          _buildPlaceList(_nearbyPlaces['lodging'] ?? []),
                          _buildPlaceList(
                              _nearbyPlaces['tourist_attraction'] ?? []),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _currentWeather!;
    final isGood = weather['isGoodForTravel'] as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGood
              ? [const Color(0xFF1E3A8A), const Color(0xFF0D9488)]
              : [const Color(0xFF1E3A8A), const Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGood ? const Color(0xFF00DFD8) : const Color(0xFFEF4444),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              weather['icon'] as IconData? ?? Icons.wb_sunny,
              color: weather['color'] as Color? ?? Colors.yellow,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Weather',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${weather['condition']} • ${weather['temperature']}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weather['recommendation'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceList(List<Map<String, dynamic>> places) {
    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No places found nearby',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return _buildPlaceCard(place);
      },
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
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
        onTap: () => _showPlaceDetails(place),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Place image or icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: place['photoUrl'] != null
                      ? CachedNetworkImage(
                          imageUrl: place['photoUrl'],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF0A1F44),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00DFD8),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF0A1F44),
                            child: Icon(
                              _getPlaceIcon(place['types']),
                              color: Colors.white.withOpacity(0.5),
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF0A1F44),
                          child: Icon(
                            _getPlaceIcon(place['types']),
                            color: Colors.white.withOpacity(0.5),
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Place details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place['address'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${place['rating']?.toStringAsFixed(1) ?? '4.0'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${place['userRatingsTotal'] ?? 0} reviews)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (place['isOpen'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          place['isOpen'] ? '● Open now' : '○ Closed',
                          style: TextStyle(
                            color: place['isOpen'] ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Distance indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00DFD8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      color: Color(0xFF00DFD8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _calculateDistance(place),
                      style: const TextStyle(
                        color: Color(0xFF00DFD8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

  IconData _getPlaceIcon(List<dynamic>? types) {
    if (types == null) return Icons.place;

    if (types.contains('restaurant') || types.contains('cafe')) {
      return Icons.restaurant;
    } else if (types.contains('lodging') || types.contains('hotel')) {
      return Icons.hotel;
    } else if (types.contains('tourist_attraction')) {
      return Icons.tour;
    } else if (types.contains('museum')) {
      return Icons.museum;
    } else if (types.contains('park')) {
      return Icons.park;
    } else if (types.contains('shopping_mall')) {
      return Icons.shopping_bag;
    } else if (types.contains('place_of_worship')) {
      return Icons.church;
    }

    return Icons.place;
  }

  String _calculateDistance(Map<String, dynamic> place) {
    if (place['latitude'] == null || place['longitude'] == null) {
      return '? km';
    }

    const double earthRadius = 6371; // km

    // Convert to radians
    double lat1 = widget.latitude * pi / 180;
    double lon1 = widget.longitude * pi / 180;
    double lat2 = (place['latitude'] as double) * pi / 180;
    double lon2 = (place['longitude'] as double) * pi / 180;

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    // Haversine formula
    double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);

    // FIXED: Use atan2 instead of acos for better numerical stability
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c;

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationDetailSheet(destination: place),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
