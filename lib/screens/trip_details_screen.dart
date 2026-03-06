import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/popup_message.dart';
import 'destination_detail_sheet.dart';

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> weatherPredictions;
  final List<Map<String, dynamic>> recommendedPlaces;
  final List<Map<String, dynamic>> nearbyHotels;
  final List<Map<String, dynamic>> nearbyRestaurants;
  // NEW: Add dailySelectedPlaces parameter
  final Map<int, List<Map<String, dynamic>>>? dailySelectedPlaces;

  const TripDetailsScreen({
    Key? key,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.weatherPredictions,
    required this.recommendedPlaces,
    required this.nearbyHotels,
    required this.nearbyRestaurants,
    this.dailySelectedPlaces, // Make it optional with default null
  }) : super(key: key);

  @override
  _TripDetailsScreenState createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Map<DateTime, List<Map<String, dynamic>>> _dailyItinerary = {};
  int _currentDayIndex = 0;
  late List<Map<String, dynamic>> _dailyRecommendations;

  @override
  void initState() {
    super.initState();
    _initializeItinerary();
    _prepareDailyRecommendations();
  }

  void _initializeItinerary() {
    final days = widget.endDate.difference(widget.startDate).inDays + 1;

    // If we have dailySelectedPlaces from AIPlannerScreen, use them
    if (widget.dailySelectedPlaces != null &&
        widget.dailySelectedPlaces!.isNotEmpty) {
      for (int i = 0; i < days; i++) {
        final date = widget.startDate.add(Duration(days: i));
        final selectedForDay = widget.dailySelectedPlaces![i] ?? [];
        _dailyItinerary[date] = List.from(selectedForDay);
      }
    } else {
      // Otherwise initialize empty
      for (int i = 0; i < days; i++) {
        _dailyItinerary[widget.startDate.add(Duration(days: i))] = [];
      }
    }
  }

  void _prepareDailyRecommendations() {
    _dailyRecommendations = [];

    for (int i = 0; i < widget.weatherPredictions.length; i++) {
      final weather = widget.weatherPredictions[i];
      final isGoodWeather = weather['isGoodForTravel'] as bool;
      final condition = weather['condition'] as String;

      // Filter places based on weather
      final suitablePlaces = widget.recommendedPlaces.where((place) {
        final suitability =
            place['weatherSuitability'] as Map<String, dynamic>?;
        if (suitability != null && suitability.containsKey(condition)) {
          return suitability[condition] > 0.5;
        }
        return isGoodWeather
            ? !(place['isIndoor'] as bool)
            : (place['isIndoor'] as bool);
      }).toList();

      // Sort by rating and take top recommendations
      suitablePlaces.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
        return ratingB.compareTo(ratingA);
      });

      _dailyRecommendations.add({
        'day': i + 1,
        'date': widget.startDate.add(Duration(days: i)),
        'weather': weather,
        'recommendations': suitablePlaces.take(5).toList(),
      });
    }
  }

  void _addToItinerary(Map<String, dynamic> item, DateTime date) {
    setState(() {
      if (!_dailyItinerary[date]!.any((i) => i['id'] == item['id'])) {
        _dailyItinerary[date]!.add(item);
      }
    });

    PopupMessage.showSuccess(
      context,
      '${item['name']} added to your itinerary for ${DateFormat('MMM dd').format(date)}',
      title: 'Added Successfully',
    );

    // Schedule reminder notification for this activity
    _scheduleActivityReminder(item, date);
  }

  void _removeFromItinerary(Map<String, dynamic> item, DateTime date) {
    setState(() {
      _dailyItinerary[date]!.removeWhere((i) => i['id'] == item['id']);
    });
  }

  Future<void> _scheduleActivityReminder(
      Map<String, dynamic> item, DateTime date) async {
    // Schedule notification 2 hours before activity (assuming morning activity)
    final reminderTime = DateTime(
      date.year,
      date.month,
      date.day,
      8, // 8 AM
    ).subtract(const Duration(hours: 2));

    if (reminderTime.isAfter(DateTime.now())) {
      await NotificationService().scheduleActivityReminder(
        activityName: item['name'] ?? 'Activity',
        activityDate: date,
        location: item['address'] ?? 'Your destination',
      );
    }
  }

  Future<void> _saveItinerary() async {
    PopupMessage.showLoading(context, 'Saving your itinerary...');

    try {
      final authService = AuthService();
      final userId = authService.userId;

      if (userId != null) {
        final itineraryData = {
          'destination': widget.destination['name'],
          'startDate': widget.startDate.toIso8601String(),
          'endDate': widget.endDate.toIso8601String(),
          'itinerary': _dailyItinerary.map((date, items) => MapEntry(
                date.toIso8601String(),
                items
                    .map((item) => {
                          'id': item['id'],
                          'name': item['name'],
                          'address': item['address'],
                          'rating': item['rating'],
                          'time': '10:00 AM', // Default time
                        })
                    .toList(),
              )),
          'savedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saved_itineraries')
            .add(itineraryData);

        PopupMessage.dismiss(context);
        PopupMessage.showSuccess(
          context,
          'Your itinerary has been saved successfully!',
          title: 'Itinerary Saved',
        );
      }
    } catch (e) {
      PopupMessage.dismiss(context);
      PopupMessage.show(
        context: context,
        title: 'Error',
        message: 'Failed to save itinerary. Please try again.',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.endDate.difference(widget.startDate).inDays + 1;
    final currentDate = widget.startDate.add(Duration(days: _currentDayIndex));
    final currentWeather = widget.weatherPredictions.length > _currentDayIndex
        ? widget.weatherPredictions[_currentDayIndex]
        : null;
    final currentRecommendations =
        _dailyRecommendations.length > _currentDayIndex
            ? _dailyRecommendations[_currentDayIndex]['recommendations'] as List
            : [];

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
                          Text(
                            widget.destination['name'] ?? 'Trip Details',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$days days • ${DateFormat('MMM dd').format(widget.startDate)} - ${DateFormat('MMM dd').format(widget.endDate)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saveItinerary,
                      icon: const Icon(Icons.save, color: Color(0xFF00DFD8)),
                    ),
                  ],
                ),
              ),

              // Day Selector with Weather
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days,
                  itemBuilder: (context, index) {
                    final date = widget.startDate.add(Duration(days: index));
                    final weather = widget.weatherPredictions.length > index
                        ? widget.weatherPredictions[index]
                        : null;
                    final isSelected = index == _currentDayIndex;
                    final isGood = weather?['isGoodForTravel'] ?? true;
                    final hasActivities =
                        (_dailyItinerary[date]?.isNotEmpty ?? false);

                    return GestureDetector(
                      onTap: () => setState(() => _currentDayIndex = index),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF007CF0),
                                    Color(0xFF00DFD8),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00DFD8)
                                : isGood
                                    ? const Color(0xFF00DFD8).withOpacity(0.3)
                                    : const Color(0xFFEF4444).withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (weather != null) ...[
                              const SizedBox(height: 2),
                              Icon(
                                weather['icon'] as IconData? ?? Icons.wb_sunny,
                                color:
                                    weather['color'] as Color? ?? Colors.yellow,
                                size: 14,
                              ),
                            ],
                            if (hasActivities)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00DFD8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Weather Summary for Current Day
              if (currentWeather != null)
                _buildWeatherSummaryCard(currentWeather, currentDate),

              const SizedBox(height: 16),

              // Tab Bar
              DefaultTabController(
                length: 3,
                child: Expanded(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TabBar(
                          labelColor: const Color(0xFF00DFD8),
                          unselectedLabelColor: Colors.white70,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          tabs: const [
                            Tab(text: 'My Itinerary'),
                            Tab(text: 'Recommended'),
                            Tab(text: 'Hotels & Food'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildItineraryTab(currentDate),
                            _buildRecommendedTab(
                                currentDate, currentRecommendations),
                            _buildHotelsAndFoodTab(currentDate),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSummaryCard(Map<String, dynamic> weather, DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: (weather['isGoodForTravel'] as bool)
              ? [const Color(0xFF1E3A8A), const Color(0xFF0D9488)]
              : [const Color(0xFF1E3A8A), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (weather['isGoodForTravel'] as bool)
              ? const Color(0xFF00DFD8)
              : const Color(0xFFEF4444),
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
                  'Day ${_currentDayIndex + 1}: ${DateFormat('EEEE, MMM dd').format(date)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weather['condition']} • ${(weather['temperature'] as num).toStringAsFixed(0)}°C',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Text(
                  weather['recommendation'] ?? 'Enjoy your day!',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (weather['isGoodForTravel'] as bool)
                  ? const Color(0xFF00DFD8).withOpacity(0.2)
                  : const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (weather['isGoodForTravel'] as bool)
                    ? const Color(0xFF00DFD8)
                    : const Color(0xFFEF4444),
              ),
            ),
            child: Text(
              (weather['isGoodForTravel'] as bool) ? 'Good' : 'Poor',
              style: TextStyle(
                color: (weather['isGoodForTravel'] as bool)
                    ? const Color(0xFF00DFD8)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryTab(DateTime currentDate) {
    final items = _dailyItinerary[currentDate] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No activities planned for ${DateFormat('MMM dd').format(currentDate)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add places from the Recommended tab',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          key: ValueKey(item['id']),
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF00DFD8).withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00DFD8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.drag_handle, color: Color(0xFF00DFD8)),
            ),
            title: Text(
              item['name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              item['address'] ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.access_time, color: Color(0xFF00DFD8)),
                  onPressed: () => _showTimePickerDialog(item, currentDate),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.remove_circle, color: Color(0xFFEF4444)),
                  onPressed: () => _removeFromItinerary(item, currentDate),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTimePickerDialog(
      Map<String, dynamic> item, DateTime date) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (selectedTime != null) {
      PopupMessage.showSuccess(
        context,
        'Time set to ${selectedTime.format(context)} for ${item['name']}',
        title: 'Time Updated',
      );
    }
  }

  Widget _buildRecommendedTab(
      DateTime currentDate, List<dynamic> recommendations) {
    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations for this day',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            Text(
              'Try another day or location',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final item = recommendations[index] as Map<String, dynamic>;
        final isAdded = (_dailyItinerary[currentDate] ?? []).any(
          (i) => i['id'] == item['id'],
        );
        final isIndoor = item['isIndoor'] as bool? ?? false;

        return _buildRecommendationCard(
          item: item,
          isAdded: isAdded,
          isIndoor: isIndoor,
          onAdd: () => _addToItinerary(item, currentDate),
          onTap: () => _showPlaceDetails(item),
        );
      },
    );
  }

  Widget _buildRecommendationCard({
    required Map<String, dynamic> item,
    required bool isAdded,
    required bool isIndoor,
    required VoidCallback onAdd,
    required VoidCallback onTap,
  }) {
    final weather = widget.weatherPredictions[_currentDayIndex];
    final isGoodWeather = weather['isGoodForTravel'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E3A8A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isIndoor == !isGoodWeather
              ? const Color(0xFF00DFD8)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIndoor
                        ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                        : [const Color(0xFF007CF0), const Color(0xFF00DFD8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIndoor ? Icons.meeting_room : Icons.place,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isIndoor)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Indoor',
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['address'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${(item['rating'] as num?)?.toStringAsFixed(1) ?? '4.0'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isGoodWeather == !isIndoor
                                ? const Color(0xFF00DFD8).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGoodWeather == !isIndoor
                                ? 'Perfect for today'
                                : '',
                            style: const TextStyle(
                              color: Color(0xFF00DFD8),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isAdded)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00DFD8).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF00DFD8)),
                  ),
                  onPressed: onAdd,
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelsAndFoodTab(DateTime currentDate) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hotels Section
        const Text(
          '🏨 Nearby Hotels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.nearbyHotels.map((hotel) => _buildHotelFoodCard(
              item: hotel,
              icon: Icons.hotel,
              date: currentDate,
            )),

        const SizedBox(height: 24),

        // Restaurants Section
        const Text(
          '🍽️ Nearby Restaurants',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.nearbyRestaurants.map((restaurant) => _buildHotelFoodCard(
              item: restaurant,
              icon: Icons.restaurant,
              date: currentDate,
            )),
      ],
    );
  }

  Widget _buildHotelFoodCard({
    required Map<String, dynamic> item,
    required IconData icon,
    required DateTime date,
  }) {
    final isAdded = (_dailyItinerary[date] ?? []).any(
      (i) => i['id'] == item['id'],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E3A8A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showPlaceDetails(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['address'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${(item['rating'] as num?)?.toStringAsFixed(1) ?? '4.0'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isAdded)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00DFD8).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF00DFD8)),
                  ),
                  onPressed: () => _addToItinerary(item, date),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaceDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationDetailSheet(destination: item),
    );
  }
}
