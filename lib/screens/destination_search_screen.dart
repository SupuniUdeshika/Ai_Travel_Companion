import 'package:flutter/material.dart';
import '../services/google_places_service.dart';
import '../widgets/search_result_card.dart';
import '../widgets/popup_message.dart';

class DestinationSearchScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onDestinationSelected;

  const DestinationSearchScreen({
    Key? key,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  _DestinationSearchScreenState createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _selectedPlaceId;

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;

    setState(() => _isLoading = true);

    try {
      final results = await GooglePlacesService.textSearch(query, 'Sri Lanka');
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      PopupMessage.show(
        context: context,
        title: 'Search Error',
        message: 'Failed to search destinations. Please try again.',
        isSuccess: false,
      );
    }
  }

  void _selectDestination(Map<String, dynamic> place) {
    setState(() => _selectedPlaceId = place['id'] as String?);

    // FIXED: Removed the 'icon' parameter from PopupMessage.show call
    PopupMessage.show(
      context: context,
      title: 'Destination Selected',
      message: 'You selected ${place['name']}. Continue to plan your trip?',
      isSuccess: true,
      onConfirm: () {
        widget.onDestinationSelected(place);
        Navigator.pop(context);
      },
    );
  }

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
                        'Select Destination',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search destinations in Sri Lanka...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults.clear());
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      if (value.length >= 2) {
                        _performSearch(value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Results
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00DFD8),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
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
                                  'Search for destinations',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return SearchResultCard(
                                place: place,
                                isSelected: _selectedPlaceId == place['id'],
                                onTap: () => _selectDestination(place),
                              );
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
