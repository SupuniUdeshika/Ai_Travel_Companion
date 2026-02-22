import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/destination_service.dart';
import '../services/google_places_service.dart';
import '../widgets/destination_card.dart';
import '../widgets/category_chip.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> _categories = [
    'All',
    'Tourist Attractions',
    'Hotels',
    'Restaurants',
    'Beaches',
    'Hills',
    'Cultural',
    'Wildlife',
    'Historical',
    'Religious',
  ];

  final List<String> _sriLankanCities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Jaffna',
    'Anuradhapura',
    'Polonnaruwa',
    'Trincomalee',
    'Batticaloa',
    'Matara',
    'Ratnapura',
    'Badulla',
    'Nuwara Eliya',
    'Hambantota',
    'Kurunegala',
    'Puttalam',
    'Kalutara',
    'Matale',
    'Monaragala',
    'Ampara',
    'Vavuniya',
    'Mannar',
    'Kilinochchi',
    'Mullaitivu',
    'Ella',
    'Sigiriya',
    'Mirissa',
    'Arugam Bay',
    'Dambulla',
    'Bentota',
    'Hikkaduwa',
    'Unawatuna',
    'Tangalle',
    'Negombo',
    'Chilaw',
    'Beruwala',
  ];

  String _selectedCategory = 'All';
  String _selectedCity = 'Colombo';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _searchingOnline = false;
  List<Map<String, dynamic>> _allDestinations = [];
  List<Map<String, dynamic>> _filteredDestinations = [];
  List<Map<String, dynamic>> _topDestinations = [];
  List<Map<String, dynamic>> _onlineResults = [];
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialPlaces(); // මුලින්ම Colombo places load කරන්න
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // මුල් places load කිරීම සඳහා අලුත් function එකක්
  Future<void> _loadInitialPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // මුලින්ම Colombo city එකේ tourist attractions load කරන්න හදමු
      List<Map<String, dynamic>> places =
          await GooglePlacesService.searchPlaces(
            city: 'Colombo',
            category: 'Tourist Attractions',
          );

      // Tourist attractions නැත්නම්, general search එකක් කරමු
      if (places.isEmpty) {
        places = await GooglePlacesService.textSearch(
          'tourist attractions',
          'Colombo',
        );
      }

      // තවමත් places නැත්නම්, sample data පාවිච්චි කරමු
      if (places.isEmpty) {
        places = _getSampleDestinations();
      }

      setState(() {
        _allDestinations = places;
        _filteredDestinations = places;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading initial places: $error');
      setState(() {
        _allDestinations = _getSampleDestinations();
        _filteredDestinations = _getSampleDestinations();
        _isLoading = false;
      });
    }
  }

  // Firebase වෙනුවට Google Places API එකෙන් data ගන්න අලුත් function එකක්
  Future<void> _loadDestinations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> places;

      if (_selectedCategory != 'All') {
        // Category එකක් තෝරලා තියෙනවා නම්, ඒ category එකේ places ගන්න
        places = await GooglePlacesService.searchPlaces(
          city: _selectedCity,
          category: _selectedCategory,
        );
      } else {
        // All category නම්, general tourist attractions ගන්න
        places = await GooglePlacesService.textSearch(
          'tourist attractions',
          _selectedCity,
        );
      }

      // API එකෙන් results නැත්නම් sample data පාවිච්චි කරමු
      if (places.isEmpty) {
        places = _getSampleDestinations().where((place) {
          if (_selectedCategory != 'All') {
            return place['category'] == _selectedCategory;
          }
          return true;
        }).toList();
      }

      setState(() {
        _allDestinations = places;
        _filteredDestinations = places;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading destinations: $error');
      setState(() {
        _allDestinations = _getSampleDestinations();
        _filteredDestinations = _getSampleDestinations();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchOnlinePlaces() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchingOnline = false;
        _onlineResults.clear();
        // Search එක clear කළාම, මුල් destinations පෙන්වන්න
        _filteredDestinations = _allDestinations;
      });
      return;
    }

    setState(() {
      _searchingOnline = true;
      _onlineResults.clear();
    });

    try {
      List<Map<String, dynamic>> places;

      // First try category-based search if not "All"
      if (_selectedCategory != 'All') {
        places = await GooglePlacesService.searchPlaces(
          city: _selectedCity,
          category: _selectedCategory,
          keyword: _searchQuery,
        );

        // If no results, fall back to text search
        if (places.isEmpty) {
          places = await GooglePlacesService.textSearch(
            _searchQuery,
            _selectedCity,
          );
        }
      } else {
        // For "All" category, use text search directly
        places = await GooglePlacesService.textSearch(
          _searchQuery,
          _selectedCity,
        );
      }

      // API එකෙන් results නැත්නම්, sample data filter කරලා පෙන්වමු
      if (places.isEmpty) {
        places = _getSampleDestinations().where((place) {
          final nameMatch = place['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final descMatch = place['description']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          final categoryMatch =
              _selectedCategory == 'All' ||
              place['category'] == _selectedCategory;
          return (nameMatch || descMatch) && categoryMatch;
        }).toList();
      }

      setState(() {
        _onlineResults = places.where((place) => place.isNotEmpty).toList();
        _searchingOnline = false;
      });
    } catch (error) {
      print('Error searching online places: $error');

      // Error එකක් වුණොත් sample data filter කරලා පෙන්වමු
      final sampleResults = _getSampleDestinations().where((place) {
        final nameMatch = place['name'].toString().toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final descMatch = place['description']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final categoryMatch =
            _selectedCategory == 'All' ||
            place['category'] == _selectedCategory;
        return (nameMatch || descMatch) && categoryMatch;
      }).toList();

      setState(() {
        _onlineResults = sampleResults;
        _searchingOnline = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSampleDestinations() {
    return [
      {
        'id': '1',
        'name': 'Sigiriya Rock Fortress',
        'province': 'Central',
        'district': 'Matale',
        'category': 'Historical',
        'description': 'Ancient rock fortress and palace ruins with frescoes.',
        'rating': 4.8,
        'reviewCount': 1250,
        'bestTime': 'Dec-Apr',
        'entryFee': 30.0,
        'coordinates': {'lat': 7.9570, 'lng': 80.7603},
        'tags': ['UNESCO', 'Archaeological', 'Sunrise', 'Photography'],
        'isTopPick': true,
        'imageUrl': null,
        'city': 'Sigiriya',
        'address': 'Sigiriya, Central Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 2},
      },
      {
        'id': '2',
        'name': 'Mirissa Beach',
        'province': 'Southern',
        'district': 'Matara',
        'category': 'Beaches',
        'description': 'Beautiful beach famous for whale watching and surfing.',
        'rating': 4.7,
        'reviewCount': 980,
        'bestTime': 'Nov-Apr',
        'entryFee': 0.0,
        'coordinates': {'lat': 5.9464, 'lng': 80.4583},
        'tags': ['Whale Watching', 'Surfing', 'Sunset', 'Relaxing'],
        'isTopPick': true,
        'imageUrl': null,
        'city': 'Mirissa',
        'address': 'Mirissa, Southern Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 1},
      },
      {
        'id': '3',
        'name': 'Temple of the Tooth',
        'province': 'Central',
        'district': 'Kandy',
        'category': 'Religious',
        'description': 'Sacred Buddhist temple housing a relic of Buddha.',
        'rating': 4.9,
        'reviewCount': 2100,
        'bestTime': 'Dec-Apr',
        'entryFee': 10.0,
        'coordinates': {'lat': 7.2936, 'lng': 80.6412},
        'tags': ['Temple', 'Buddhist', 'Sacred', 'Cultural'],
        'isTopPick': true,
        'imageUrl': null,
        'city': 'Kandy',
        'address': 'Kandy, Central Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 3},
      },
      {
        'id': '4',
        'name': 'Galle Fort',
        'province': 'Southern',
        'district': 'Galle',
        'category': 'Historical',
        'description':
            'Historic Portuguese-built fort with colonial architecture.',
        'rating': 4.6,
        'reviewCount': 850,
        'bestTime': 'Dec-Mar',
        'entryFee': 4.0,
        'coordinates': {'lat': 6.0269, 'lng': 80.2171},
        'tags': ['Fort', 'Colonial', 'UNESCO', 'Shopping'],
        'isTopPick': true,
        'imageUrl': null,
        'city': 'Galle',
        'address': 'Galle, Southern Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 2},
      },
      {
        'id': '5',
        'name': 'Nuwara Eliya',
        'province': 'Central',
        'district': 'Nuwara Eliya',
        'category': 'Hills',
        'description':
            'Hill station known for tea plantations and cool climate.',
        'rating': 4.5,
        'reviewCount': 1500,
        'bestTime': 'Jan-Apr',
        'entryFee': 0.0,
        'coordinates': {'lat': 6.9497, 'lng': 80.7891},
        'tags': ['Tea', 'Mountains', 'Scenic', 'Cool Climate'],
        'isTopPick': false,
        'imageUrl': null,
        'city': 'Nuwara Eliya',
        'address': 'Nuwara Eliya, Central Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 3},
      },
      {
        'id': '6',
        'name': 'Cinnamon Grand Colombo',
        'province': 'Western',
        'district': 'Colombo',
        'category': 'Hotels',
        'description': 'Luxury 5-star hotel in the heart of Colombo.',
        'rating': 4.5,
        'reviewCount': 650,
        'bestTime': 'Year-round',
        'entryFee': 0.0,
        'coordinates': {'lat': 6.9121, 'lng': 79.8502},
        'tags': ['Luxury', 'Hotel', 'Accommodation', 'Dining'],
        'isTopPick': false,
        'imageUrl': null,
        'city': 'Colombo',
        'address': 'Colombo, Western Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 4},
      },
      {
        'id': '7',
        'name': 'Ministry of Crab',
        'province': 'Western',
        'district': 'Colombo',
        'category': 'Restaurants',
        'description':
            'Award-winning restaurant serving Sri Lankan crab dishes.',
        'rating': 4.6,
        'reviewCount': 580,
        'bestTime': 'Evenings',
        'entryFee': 0.0,
        'coordinates': {'lat': 6.9221, 'lng': 79.8462},
        'tags': ['Seafood', 'Fine Dining', 'Crab', 'Award-winning'],
        'isTopPick': false,
        'imageUrl': null,
        'city': 'Colombo',
        'address': 'Colombo, Western Province',
        'weatherSuitability': {'sunny': 5, 'cloudy': 5, 'rainy': 5},
      },
    ];
  }

  void _filterDestinations() {
    List<Map<String, dynamic>> filtered = _allDestinations;

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((dest) => (dest['category'] as String?) == _selectedCategory)
          .toList();
    }

    setState(() {
      _filteredDestinations = filtered;
    });
  }

  void _showDestinationDetail(Map<String, dynamic> destination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DestinationDetailSheet(destination: destination);
      },
    );
  }

  void _showCitySelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E3A8A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select a City',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _sriLankanCities.length,
                  itemBuilder: (context, index) {
                    final city = _sriLankanCities[index];
                    return ListTile(
                      leading: Icon(
                        Icons.location_city,
                        color: Color(0xFF00DFD8),
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          color: _selectedCity == city
                              ? Color(0xFF00DFD8)
                              : Colors.white,
                          fontWeight: _selectedCity == city
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: _selectedCity == city
                          ? Icon(Icons.check, color: Color(0xFF00DFD8))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCity = city;
                        });
                        Navigator.pop(context);

                        // City එක වෙනස් කළාම, අලුත් city එකේ places load කරන්න
                        _loadDestinations();

                        if (_searchQuery.isNotEmpty) {
                          _searchOnlinePlaces();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search places in $_selectedCity...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Color(0xFF00DFD8)),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _onlineResults.clear();
                      _filteredDestinations = _allDestinations;
                    });
                  },
                ),
              IconButton(
                icon: Icon(Icons.location_city, color: Color(0xFF00DFD8)),
                onPressed: _showCitySelectionDialog,
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        style: TextStyle(color: Colors.black),
        onChanged: (value) {
          if (_debounceTimer?.isActive ?? false) {
            _debounceTimer!.cancel();
          }

          _debounceTimer = Timer(const Duration(milliseconds: 800), () {
            setState(() {
              _searchQuery = value;
            });
            if (value.isNotEmpty) {
              _searchOnlinePlaces();
            } else {
              setState(() {
                _onlineResults.clear();
                _filteredDestinations = _allDestinations;
              });
            }
          });
        },
      ),
    );
  }

  Widget _buildPlaceItem(Map<String, dynamic> place) {
    final name = place['name'] as String? ?? 'Place';
    final address = place['address'] as String? ?? '';
    final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = place['reviewCount'] as int? ?? 0;
    final photoUrl = place['photoUrl'] as String?;
    final description = place['description'] as String? ?? '';
    final actualCity = place['city'] as String? ?? _selectedCity;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Color(0xFF1E3A8A),
      child: InkWell(
        onTap: () => _showDestinationDetail(place),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Color(0xFF007CF0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Color(0xFF007CF0),
                          child: Center(
                            child: Icon(
                              Icons.place,
                              color: Colors.white,
                              size: 50,
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
                            size: 50,
                          ),
                        ),
                      ),
              ),
            ),

            // Details
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '($reviewCount reviews)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF00DFD8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xFF00DFD8)),
                        ),
                        child: Text(
                          actualCity,
                          style: TextStyle(
                            color: Color(0xFF00DFD8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
  }

  Widget _buildShimmerPlaceholder() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Color(0xFF1E3A8A),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[700]!,
        highlightColor: Colors.grey[500]!,
        child: Container(
          height: 200,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayResults = _searchQuery.isNotEmpty
        ? _onlineResults
        : _filteredDestinations;
    final hasResults = displayResults.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001F3F),
              Color(0xFF0074D9),
              Color.fromARGB(255, 22, 109, 143),
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Explore Sri Lanka',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: _showCitySelectionDialog,
                      icon: Icon(Icons.location_city, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Search Bar
              _buildSearchBar(),

              // Categories
              Container(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryChip(
                      label: category,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        if (_searchQuery.isEmpty) {
                          _loadDestinations(); // Category එක වෙනස් කළාම අලුත් data load කරන්න
                        } else {
                          _searchOnlinePlaces();
                        }
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 10),

              // Selected City
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF00DFD8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      '$_selectedCity',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.white70)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search: "$_searchQuery"',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00DFD8),
                        ),
                      )
                    : _searchingOnline
                    ? ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) =>
                            _buildShimmerPlaceholder(),
                      )
                    : !hasResults
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No places found for "$_searchQuery" in $_selectedCity'
                                  : 'No destinations found in $_selectedCity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Try a different search or city',
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (_searchQuery.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Try searching in different city
                                    if (_selectedCity != 'Colombo') {
                                      setState(() {
                                        _selectedCity = 'Colombo';
                                      });
                                    } else {
                                      setState(() {
                                        _selectedCity = 'Kandy';
                                      });
                                    }
                                    _searchOnlinePlaces();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF00DFD8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Try searching in ${_selectedCity == 'Colombo' ? 'Kandy' : 'Colombo'}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayResults.length,
                        itemBuilder: (context, index) {
                          return _buildPlaceItem(displayResults[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                                // Open in maps
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
