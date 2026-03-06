import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DayPlaceSelectionScreen extends StatefulWidget {
  final int dayIndex;
  final DateTime date;
  final Map<String, dynamic> weather;
  final String city;
  final List<Map<String, dynamic>> alreadySelectedPlaces;
  final List<Map<String, dynamic>> allPlaces;

  const DayPlaceSelectionScreen({
    Key? key,
    required this.dayIndex,
    required this.date,
    required this.weather,
    required this.city,
    required this.alreadySelectedPlaces,
    required this.allPlaces,
  }) : super(key: key);

  @override
  _DayPlaceSelectionScreenState createState() =>
      _DayPlaceSelectionScreenState();
}

class _DayPlaceSelectionScreenState extends State<DayPlaceSelectionScreen> {
  List<Map<String, dynamic>> _selectedPlaces = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  List<Map<String, dynamic>> _allPlacesWithScores = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Outdoor',
    'Indoor',
    'Beach',
    'Cultural',
    'Historical',
    'Nature',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlaces = List.from(widget.alreadySelectedPlaces);
    _preparePlacesWithScores();
  }

  void _preparePlacesWithScores() {
    // Check if we have places
    if (widget.allPlaces.isEmpty) {
      setState(() {
        _isLoading = false;
        _filteredPlaces = [];
      });
      return;
    }

    final isGoodWeather = widget.weather['isGoodForTravel'] ?? true;
    final condition = widget.weather['condition']?.toString() ?? 'Clear';

    // Add suitability scores to each place
    _allPlacesWithScores = widget.allPlaces.map((place) {
      final placeCopy = Map<String, dynamic>.from(place);

      // Calculate weather suitability score
      double suitabilityScore = 0.5; // Default

      // Try to get from weatherSuitability map if available
      if (place['weatherSuitability'] != null) {
        final weatherSuitability =
            place['weatherSuitability'] as Map<String, dynamic>?;
        if (weatherSuitability != null &&
            weatherSuitability.containsKey(condition)) {
          final score = weatherSuitability[condition];
          if (score is num) {
            suitabilityScore = score.toDouble();
          }
        }
      } else {
        // Fallback: outdoor places good for good weather, indoor for bad weather
        final isIndoor = place['isIndoor'] ?? false;
        if (isGoodWeather) {
          suitabilityScore = isIndoor ? 0.3 : 0.9;
        } else {
          suitabilityScore = isIndoor ? 0.9 : 0.2;
        }
      }

      placeCopy['suitabilityScore'] = suitabilityScore;
      return placeCopy;
    }).toList();

    // Sort by suitability score and rating
    _allPlacesWithScores.sort((a, b) {
      final scoreA = (a['suitabilityScore'] as num?)?.toDouble() ?? 0;
      final scoreB = (b['suitabilityScore'] as num?)?.toDouble() ?? 0;

      if ((scoreB - scoreA).abs() > 0.01) {
        return scoreB.compareTo(scoreA);
      }

      final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
      final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
      return ratingB.compareTo(ratingA);
    });

    _applyFilters();
  }

  void _applyFilters() {
    if (_allPlacesWithScores.isEmpty) {
      setState(() {
        _filteredPlaces = [];
        _isLoading = false;
      });
      return;
    }

    final isGoodWeather = widget.weather['isGoodForTravel'] ?? true;

    setState(() {
      _filteredPlaces = _allPlacesWithScores.where((place) {
        // Category filter
        bool categoryMatch = _selectedCategory == 'All';

        if (!categoryMatch) {
          final isIndoor = place['isIndoor'] ?? false;
          final types = place['types'] as List<dynamic>? ?? [];
          final name = place['name']?.toString().toLowerCase() ?? '';
          final description =
              place['description']?.toString().toLowerCase() ?? '';

          switch (_selectedCategory) {
            case 'Indoor':
              categoryMatch = isIndoor == true;
              break;
            case 'Outdoor':
              categoryMatch = isIndoor == false;
              break;
            case 'Beach':
              categoryMatch = types.contains('beach') ||
                  name.contains('beach') ||
                  description.contains('beach');
              break;
            case 'Cultural':
              categoryMatch = types.any((t) => [
                        'museum',
                        'art_gallery',
                        'place_of_worship',
                        'cultural'
                      ].contains(t)) ||
                  name.contains('temple') ||
                  name.contains('museum') ||
                  description.contains('cultural');
              break;
            case 'Historical':
              categoryMatch = types.contains('historical_landmark') ||
                  name.contains('fort') ||
                  name.contains('historical') ||
                  description.contains('historical');
              break;
            case 'Nature':
              categoryMatch = types.any((t) => [
                        'park',
                        'natural_feature',
                        'zoo',
                        'aquarium',
                        'garden'
                      ].contains(t)) ||
                  name.contains('garden') ||
                  name.contains('park') ||
                  name.contains('view') ||
                  description.contains('nature');
              break;
          }
        }

        // Search filter
        bool searchMatch = true;
        if (_searchQuery.isNotEmpty) {
          final name = place['name']?.toString().toLowerCase() ?? '';
          final address = place['address']?.toString().toLowerCase() ?? '';
          final description =
              place['description']?.toString().toLowerCase() ?? '';
          searchMatch = name.contains(_searchQuery.toLowerCase()) ||
              address.contains(_searchQuery.toLowerCase()) ||
              description.contains(_searchQuery.toLowerCase());
        }

        return categoryMatch && searchMatch;
      }).toList();

      _isLoading = false;
    });
  }

  void _togglePlaceSelection(Map<String, dynamic> place) {
    setState(() {
      final isSelected = _selectedPlaces.any((p) => p['id'] == place['id']);
      if (isSelected) {
        _selectedPlaces.removeWhere((p) => p['id'] == place['id']);
      } else {
        _selectedPlaces.add(place);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGoodWeather = widget.weather['isGoodForTravel'] ?? true;

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
              _buildHeader(isGoodWeather),

              // Search Bar
              _buildSearchBar(),

              // Category Filter
              _buildCategoryFilter(),

              // Selected Places Summary
              if (_selectedPlaces.isNotEmpty) _buildSelectedSummary(),

              // Places Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF00DFD8)))
                    : _filteredPlaces.isEmpty
                        ? _buildEmptyState()
                        : _buildPlacesGrid(),
              ),

              // Bottom Button
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isGoodWeather) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${widget.dayIndex + 1} - ${widget.city}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isGoodWeather
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGoodWeather ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: isGoodWeather ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(widget.weather['temperature'] as num?)?.toStringAsFixed(0)}°C',
                      style: TextStyle(
                        color: isGoodWeather ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isGoodWeather
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGoodWeather ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.weather['icon'] as IconData? ?? Icons.wb_sunny,
                  color: isGoodWeather ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.weather['condition']} • ${(widget.weather['temperature'] as num?)?.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isGoodWeather
                            ? 'Perfect weather for outdoor activities!'
                            : 'Consider indoor activities today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search places...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _applyFilters();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00DFD8) : Colors.white24,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00DFD8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Places:',
                style: TextStyle(
                  color: Color(0xFF00DFD8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedPlaces.length} places',
                style: const TextStyle(
                  color: Color(0xFF00DFD8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedPlaces.map((place) {
              return Chip(
                backgroundColor: const Color(0xFF00DFD8).withOpacity(0.2),
                label: Text(
                  place['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                deleteIcon:
                    const Icon(Icons.close, color: Colors.white, size: 16),
                onDeleted: () => _togglePlaceSelection(place),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.location_off,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No places match "$_searchQuery"'
                : widget.allPlaces.isEmpty
                    ? 'No places available for this destination'
                    : 'No places found for this category',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _applyFilters();
                });
              },
              child: const Text(
                'Clear Search',
                style: TextStyle(color: Color(0xFF00DFD8)),
              ),
            ),
          if (widget.allPlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, []);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00DFD8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Continue without places'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlacesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredPlaces.length,
      itemBuilder: (context, index) {
        final place = _filteredPlaces[index];
        final isSelected = _selectedPlaces.any((p) => p['id'] == place['id']);
        final photoUrl = place['photoUrl']?.toString();
        final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
        final isIndoor = place['isIndoor'] ?? false;
        final suitabilityScore =
            (place['suitabilityScore'] as num?)?.toDouble() ?? 0.5;

        return GestureDetector(
          onTap: () => _togglePlaceSelection(place),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isSelected
                    ? [const Color(0xFF007CF0), const Color(0xFF00DFD8)]
                    : [const Color(0xFF1E3A8A), const Color(0xFF0A1F44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00DFD8)
                    : suitabilityScore > 0.7
                        ? Colors.green.withOpacity(0.5)
                        : Colors.transparent,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00DFD8).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF1E3A8A),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00DFD8),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildPlaceholderImage(),
                              )
                            : _buildPlaceholderImage(),
                      ),
                      // Selection indicator
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      // Indoor/Outdoor badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isIndoor
                                ? const Color(0xFF8B5CF6).withOpacity(0.9)
                                : Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isIndoor ? 'Indoor' : 'Outdoor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Suitability badge
                      if (suitabilityScore > 0.7 && !isSelected)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Perfect',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name']?.toString() ?? 'Unknown Place',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place['address']?.toString().split(',').first ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFF1E3A8A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _selectedPlaces);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00DFD8),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _selectedPlaces.isEmpty
                ? 'Skip for now'
                : 'Done (${_selectedPlaces.length} selected)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
