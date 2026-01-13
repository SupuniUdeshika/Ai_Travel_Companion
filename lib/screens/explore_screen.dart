import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../services/destination_service.dart';
import '../widgets/destination_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> _categories = [
    'All',
    'Beaches',
    'Hills',
    'Cultural',
    'Wildlife',
    'Historical',
    'Adventure',
    'Religious',
    'Cities',
    'Villages',
  ];

  final List<String> _provinces = [
    'All Provinces',
    'Western',
    'Central',
    'Southern',
    'Northern',
    'Eastern',
    'North Western',
    'North Central',
    'Uva',
    'Sabaragamuwa',
  ];

  String _selectedCategory = 'All';
  String _selectedProvince = 'All Provinces';
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _allDestinations = [];
  List<Map<String, dynamic>> _filteredDestinations = [];
  List<Map<String, dynamic>> _topDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    try {
      final destinationService = Provider.of<DestinationService>(
        context,
        listen: false,
      );

      // Fetch destinations from Firestore
      final destinations = await destinationService.getDestinations();
      final topPicks = await destinationService.getTopPicks();

      setState(() {
        _allDestinations = destinations.isNotEmpty
            ? destinations
            : _getSampleDestinations();
        _filteredDestinations = _allDestinations;
        _topDestinations = topPicks.isNotEmpty
            ? topPicks
            : _allDestinations
                  .where((d) => (d['isTopPick'] as bool?) ?? false)
                  .toList();
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading destinations: $error');
      // Fallback to sample data
      setState(() {
        _allDestinations = _getSampleDestinations();
        _filteredDestinations = _allDestinations;
        _topDestinations = _allDestinations
            .where((d) => (d['isTopPick'] as bool?) ?? false)
            .toList();
        _isLoading = false;
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
        'imageUrl': 'assets/images/sigiriya.jpg',
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
        'imageUrl': 'assets/images/mirissa.jpg',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 1},
      },
      {
        'id': '3',
        'name': 'Ella Rock',
        'province': 'Uva',
        'district': 'Badulla',
        'category': 'Hills',
        'description': 'Scenic hiking trail with breathtaking views.',
        'rating': 4.6,
        'reviewCount': 850,
        'bestTime': 'Jan-Mar',
        'entryFee': 0.0,
        'coordinates': {'lat': 6.8697, 'lng': 81.0464},
        'tags': ['Hiking', 'Waterfalls', 'Tea Plantations', 'Photography'],
        'isTopPick': true,
        'imageUrl': 'assets/images/ella.jpg',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 2},
      },
      {
        'id': '4',
        'name': 'Temple of the Sacred Tooth Relic',
        'province': 'Central',
        'district': 'Kandy',
        'category': 'Religious',
        'description': 'Most important Buddhist temple in Sri Lanka.',
        'rating': 4.5,
        'reviewCount': 1200,
        'bestTime': 'All Year',
        'entryFee': 10.0,
        'coordinates': {'lat': 7.2936, 'lng': 80.6413},
        'tags': ['UNESCO', 'Buddhist', 'Cultural', 'Historical'],
        'isTopPick': true,
        'imageUrl': 'assets/images/temple.jpg',
        'weatherSuitability': {'sunny': 4, 'cloudy': 5, 'rainy': 5},
      },
      {
        'id': '5',
        'name': 'Yala National Park',
        'province': 'Southern',
        'district': 'Hambantota',
        'category': 'Wildlife',
        'description': 'Best place to see leopards and elephants in Sri Lanka.',
        'rating': 4.7,
        'reviewCount': 1100,
        'bestTime': 'Feb-Jul',
        'entryFee': 40.0,
        'coordinates': {'lat': 6.3721, 'lng': 81.5153},
        'tags': ['Safari', 'Leopards', 'Elephants', 'Bird Watching'],
        'isTopPick': false,
        'imageUrl': 'assets/images/yala.jpg',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 2},
      },
      {
        'id': '6',
        'name': 'Galle Fort',
        'province': 'Southern',
        'district': 'Galle',
        'category': 'Historical',
        'description': 'Historic fort with Dutch colonial architecture.',
        'rating': 4.6,
        'reviewCount': 950,
        'bestTime': 'Dec-Mar',
        'entryFee': 0.0,
        'coordinates': {'lat': 6.0268, 'lng': 80.2166},
        'tags': ['UNESCO', 'Colonial', 'Shopping', 'Cafes'],
        'isTopPick': false,
        'imageUrl': 'assets/images/galle_fort.jpg',
        'weatherSuitability': {'sunny': 4, 'cloudy': 5, 'rainy': 4},
      },
      {
        'id': '7',
        'name': 'Adam\'s Peak',
        'province': 'Sabaragamuwa',
        'district': 'Ratnapura',
        'category': 'Religious',
        'description': 'Sacred mountain with a footprint-shaped depression.',
        'rating': 4.7,
        'reviewCount': 750,
        'bestTime': 'Dec-May',
        'entryFee': 0.0,
        'coordinates': {'lat': 6.8096, 'lng': 80.4993},
        'tags': ['Pilgrimage', 'Hiking', 'Sunrise', 'Sacred'],
        'isTopPick': false,
        'imageUrl': 'assets/images/adams_peak.jpg',
        'weatherSuitability': {'sunny': 5, 'cloudy': 3, 'rainy': 1},
      },
      {
        'id': '8',
        'name': 'Polonnaruwa Ancient City',
        'province': 'North Central',
        'district': 'Polonnaruwa',
        'category': 'Historical',
        'description': 'Medieval capital with well-preserved ruins.',
        'rating': 4.5,
        'reviewCount': 680,
        'bestTime': 'Dec-Apr',
        'entryFee': 25.0,
        'coordinates': {'lat': 7.9403, 'lng': 81.0189},
        'tags': ['UNESCO', 'Archaeological', 'Ruins', 'Buddhist'],
        'isTopPick': false,
        'imageUrl': 'assets/images/polonnaruwa.jpg',
        'weatherSuitability': {'sunny': 5, 'cloudy': 4, 'rainy': 3},
      },
    ];
  }

  void _filterDestinations() {
    List<Map<String, dynamic>> filtered = _allDestinations;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((dest) => (dest['category'] as String?) == _selectedCategory)
          .toList();
    }

    // Apply province filter
    if (_selectedProvince != 'All Provinces') {
      filtered = filtered
          .where((dest) => (dest['province'] as String?) == _selectedProvince)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((dest) {
        final name = (dest['name'] as String?)?.toLowerCase() ?? '';
        final description =
            (dest['description'] as String?)?.toLowerCase() ?? '';
        final province = (dest['province'] as String?)?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            description.contains(query) ||
            province.contains(query);
      }).toList();
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF00DFD8), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Filter Destinations',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Province Filter
                    Text(
                      'Province',
                      style: TextStyle(
                        color: Color(0xFF00DFD8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _provinces.map((province) {
                        return FilterChip(
                          label: Text(province),
                          selected: _selectedProvince == province,
                          onSelected: (selected) {
                            setState(() {
                              _selectedProvince = selected
                                  ? province
                                  : 'All Provinces';
                            });
                          },
                          backgroundColor: Colors.white.withOpacity(0.1),
                          selectedColor: Color(0xFF00DFD8),
                          labelStyle: TextStyle(
                            color: _selectedProvince == province
                                ? Colors.white
                                : Colors.white70,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    // Category Filter
                    Text(
                      'Category',
                      style: TextStyle(
                        color: Color(0xFF00DFD8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        return FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'All';
                            });
                          },
                          backgroundColor: Colors.white.withOpacity(0.1),
                          selectedColor: Color(0xFF00DFD8),
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.white
                                : Colors.white70,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedCategory = 'All';
                      _selectedProvince = 'All Provinces';
                      _filterDestinations();
                    });
                  },
                  child: Text('Reset', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _filterDestinations();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00DFD8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: _showFilterDialog,
                      icon: Icon(Icons.filter_list, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: SearchBarWidget(
                  onSearchChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _filterDestinations();
                  },
                ),
              ),

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
                        _filterDestinations();
                      },
                    );
                  },
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
                    : _filteredDestinations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/no_results.json',
                              height: 150,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No destinations found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Try different filters or search',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Top Picks Section
                          if (_selectedCategory == 'All' &&
                              _searchQuery.isEmpty)
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Top Picks This Week',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 220,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: _topDestinations.length,
                                      itemBuilder: (context, index) {
                                        final dest = _topDestinations[index];
                                        return Container(
                                          width: 280,
                                          margin: EdgeInsets.only(right: 16),
                                          child: DestinationCard(
                                            name: dest['name'] as String,
                                            location:
                                                dest['province'] as String,
                                            rating:
                                                (dest['rating'] as num?)
                                                    ?.toDouble() ??
                                                0.0,
                                            onTap: () =>
                                                _showDestinationDetail(dest),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),

                          // All Destinations Title
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _selectedCategory == 'All'
                                    ? 'All Destinations (${_filteredDestinations.length})'
                                    : '$_selectedCategory (${_filteredDestinations.length})',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Destinations Grid
                          SliverPadding(
                            padding: EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final destination =
                                    _filteredDestinations[index];
                                return GestureDetector(
                                  onTap: () =>
                                      _showDestinationDetail(destination),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1E3A8A),
                                          Color(0xFF3B82F6),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image Placeholder
                                        Container(
                                          height: 120,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF007CF0),
                                                Color(0xFF00DFD8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _getCategoryIcon(
                                                destination['category']
                                                    as String,
                                              ),
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                destination['name'] as String,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                destination['province']
                                                    as String,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    (destination['rating']
                                                                as num?)
                                                            ?.toStringAsFixed(
                                                              1,
                                                            ) ??
                                                        '0.0',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      destination['category']
                                                          as String,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
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
                              }, childCount: _filteredDestinations.length),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Beaches':
        return Icons.beach_access;
      case 'Hills':
        return Icons.landscape;
      case 'Cultural':
        return Icons.account_balance;
      case 'Wildlife':
        return Icons.pets;
      case 'Historical':
        return Icons.history;
      case 'Adventure':
        return Icons.directions_bike;
      case 'Religious':
        return Icons.temple_buddhist;
      case 'Cities':
        return Icons.location_city;
      case 'Villages':
        return Icons.house;
      default:
        return Icons.place;
    }
  }
}

class DestinationDetailSheet extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailSheet({Key? key, required this.destination})
    : super(key: key);

  @override
  _DestinationDetailSheetState createState() => _DestinationDetailSheetState();
}

class _DestinationDetailSheetState extends State<DestinationDetailSheet> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final destinationService = Provider.of<DestinationService>(
        context,
        listen: false,
      );
      final isFavorite = await destinationService.isInWishlist(
        widget.destination['id'] as String,
      );
      setState(() {
        _isFavorite = isFavorite;
      });
    } catch (error) {
      print('Error checking favorite status: $error');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final destinationService = Provider.of<DestinationService>(
        context,
        listen: false,
      );

      if (_isFavorite) {
        await destinationService.removeFromWishlist(
          widget.destination['id'] as String,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFF00DFD8),
            content: Text('Removed from favorites'),
          ),
        );
      } else {
        await destinationService.addToWishlist(
          widget.destination['id'] as String,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFF00DFD8),
            content: Text('Added to favorites!'),
          ),
        );
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (error) {
      print('Error toggling favorite: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: ${error.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final name = destination['name'] as String? ?? 'Destination';
    final province = destination['province'] as String? ?? '';
    final district = destination['district'] as String? ?? '';
    final description = destination['description'] as String? ?? '';
    final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
    final bestTime = destination['bestTime'] as String? ?? '';
    final entryFee = (destination['entryFee'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = destination['reviewCount'] as int? ?? 0;
    final category = destination['category'] as String? ?? '';
    final tags = (destination['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final weatherSuitability =
        (destination['weatherSuitability'] as Map<String, dynamic>?) ??
        {'sunny': 0, 'cloudy': 0, 'rainy': 0};

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001F3F), Color(0xFF0074D9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    gradient: LinearGradient(
                      colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.landscape,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 28,
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
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$province Province, $district',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Category Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...tags.map((tag) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF00DFD8).withOpacity(0.2),
                              border: Border.all(color: Color(0xFF00DFD8)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Color(0xFF00DFD8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
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

                      SizedBox(height: 24),

                      // Details Grid
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildDetailItem(
                                  Icons.calendar_today,
                                  'Best Time',
                                  bestTime,
                                ),
                                _buildDetailItem(
                                  Icons.attach_money,
                                  'Entry Fee',
                                  entryFee == 0
                                      ? 'Free'
                                      : '\$${entryFee.toStringAsFixed(0)}',
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                _buildDetailItem(
                                  Icons.reviews,
                                  'Reviews',
                                  reviewCount.toString(),
                                ),
                                _buildDetailItem(
                                  Icons
                                      .wb_sunny, // Changed from weather_sunny to wb_sunny
                                  'Weather',
                                  _getWeatherSuitability(weatherSuitability),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Weather Suitability
                      Text(
                        'Weather Suitability',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          _buildWeatherScore(
                            '☀️ Sunny',
                            (weatherSuitability['sunny'] as int?) ?? 0,
                          ),
                          SizedBox(width: 16),
                          _buildWeatherScore(
                            '☁️ Cloudy',
                            (weatherSuitability['cloudy'] as int?) ?? 0,
                          ),
                          SizedBox(width: 16),
                          _buildWeatherScore(
                            '🌧️ Rainy',
                            (weatherSuitability['rainy'] as int?) ?? 0,
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // In production: Navigate to trip planner with this destination
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
                                // In production: Open directions in maps
                                _openMaps();
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

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF00DFD8), size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherScore(String condition, int score) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              condition,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  color: index < score ? Color(0xFF00DFD8) : Colors.white30,
                  size: 16,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeatherSuitability(Map<String, dynamic> suitability) {
    final sunny = (suitability['sunny'] as int?) ?? 0;
    final cloudy = (suitability['cloudy'] as int?) ?? 0;
    final rainy = (suitability['rainy'] as int?) ?? 0;

    final values = [sunny, cloudy, rainy];
    values.sort((a, b) => b.compareTo(a));
    return values[0] >= 4 ? 'Mostly Good' : 'Weather Dependent';
  }

  void _openMaps() {
    // This is a placeholder for maps integration
    // You can use packages like: url_launcher, google_maps_flutter, mapbox_gl
    final coordinates =
        widget.destination['coordinates'] as Map<String, dynamic>?;
    if (coordinates != null) {
      final lat = coordinates['lat'];
      final lng = coordinates['lng'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF00DFD8),
          content: Text('Opening maps for coordinates: $lat, $lng'),
        ),
      );
    }
  }
}
