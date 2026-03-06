// lib/screens/my_trips_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/trip_service.dart';
import '../services/auth_service.dart';
import '../widgets/trip_history_card.dart';
import '../widgets/popup_message.dart';
import 'trip_details_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  _MyTripsScreenState createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripService _tripService = TripService();
  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _upcomingTrips = [];
  List<Map<String, dynamic>> _pastTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    try {
      final all = await _tripService.getUserTrips();
      final upcoming = await _tripService.getUpcomingTrips();
      final past = await _tripService.getPastTrips();

      setState(() {
        _allTrips = all;
        _upcomingTrips = upcoming;
        _pastTrips = past;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        PopupMessage.showError(
          context,
          'Failed to load trips: $e',
        );
      }
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Trip',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this trip? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      PopupMessage.showLoading(context, 'Deleting trip...');
      final success = await _tripService.deleteTrip(tripId);
      PopupMessage.dismiss(context);

      if (success && mounted) {
        PopupMessage.showSuccess(context, 'Trip deleted successfully');
        _loadTrips();
      } else if (mounted) {
        PopupMessage.showError(context, 'Failed to delete trip');
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
                    const Expanded(
                      child: Text(
                        'My Trips',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadTrips,
                      icon: const Icon(Icons.refresh, color: Color(0xFF00DFD8)),
                    ),
                  ],
                ),
              ),

              // Stats Summary
              _buildStatsSummary(),

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
                    Tab(text: 'All Trips'),
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
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
                          _buildTripList(_allTrips),
                          _buildTripList(_upcomingTrips),
                          _buildTripList(_pastTrips),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    int totalTrips = _allTrips.length;

    // FIXED: Safely convert to int with proper type handling
    int totalDays = _allTrips.fold<int>(0, (sum, trip) {
      final duration = trip['duration'];
      if (duration is int) {
        return sum + duration;
      } else if (duration is num) {
        return sum + duration.toInt();
      } else if (duration is String) {
        return sum + (int.tryParse(duration) ?? 0);
      }
      return sum;
    });

    int totalPlaces = _allTrips.fold<int>(0, (sum, trip) {
      final places = trip['totalPlaces'];
      if (places is int) {
        return sum + places;
      } else if (places is num) {
        return sum + places.toInt();
      } else if (places is String) {
        return sum + (int.tryParse(places) ?? 0);
      }
      return sum;
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0A1F44)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00DFD8).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Trips', totalTrips.toString()),
          _buildStatColumn('Total Days', totalDays.toString()),
          _buildStatColumn('Places', totalPlaces.toString()),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00DFD8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTripList(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No trips found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your first trip with AI!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ai-planner');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00DFD8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Plan a Trip'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripHistoryCard(
          trip: trip,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(
                  destination: trip['destination'],
                  startDate: DateTime.parse(trip['startDate']),
                  endDate: DateTime.parse(trip['endDate']),
                  weatherPredictions: List<Map<String, dynamic>>.from(
                    trip['weatherPredictions'] ?? [],
                  ),
                  recommendedPlaces: List<Map<String, dynamic>>.from(
                    trip['dailyItinerary']?.values.expand((e) => e).toList() ??
                        [],
                  ),
                  nearbyHotels: List<Map<String, dynamic>>.from(
                    trip['nearbyHotels'] ?? [],
                  ),
                  nearbyRestaurants: List<Map<String, dynamic>>.from(
                    trip['nearbyRestaurants'] ?? [],
                  ),
                ),
              ),
            );
          },
          onDelete: () => _deleteTrip(trip['id']),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
