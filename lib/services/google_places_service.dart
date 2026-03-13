import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class GooglePlacesService {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Sri Lankan cities coordinates - ADDED Haputale and more cities
  static final Map<String, Map<String, double>> _sriLankanCities = {
    'Colombo': {'lat': 6.9271, 'lng': 79.8612},
    'Kandy': {'lat': 7.2906, 'lng': 80.6337},
    'Galle': {'lat': 6.0535, 'lng': 80.2210},
    'Jaffna': {'lat': 9.6615, 'lng': 80.0255},
    'Anuradhapura': {'lat': 8.3114, 'lng': 80.4037},
    'Polonnaruwa': {'lat': 7.9403, 'lng': 81.0189},
    'Trincomalee': {'lat': 8.5874, 'lng': 81.2152},
    'Batticaloa': {'lat': 7.7167, 'lng': 81.7000},
    'Matara': {'lat': 5.9485, 'lng': 80.5353},
    'Ratnapura': {'lat': 6.6804, 'lng': 80.3996},
    'Badulla': {'lat': 6.9934, 'lng': 81.0550},
    'Nuwara Eliya': {'lat': 6.9497, 'lng': 80.7891},
    'Hambantota': {'lat': 6.1249, 'lng': 81.1188},
    'Kurunegala': {'lat': 7.4863, 'lng': 80.3623},
    'Puttalam': {'lat': 8.0362, 'lng': 79.8283},
    'Kalutara': {'lat': 6.5854, 'lng': 79.9607},
    'Matale': {'lat': 7.4675, 'lng': 80.6234},
    'Monaragala': {'lat': 6.8728, 'lng': 81.3508},
    'Ampara': {'lat': 7.2975, 'lng': 81.6820},
    'Vavuniya': {'lat': 8.7562, 'lng': 80.4981},
    'Mannar': {'lat': 8.9815, 'lng': 79.9040},
    'Kilinochchi': {'lat': 9.3968, 'lng': 80.3986},
    'Mullaitivu': {'lat': 9.2670, 'lng': 80.8142},
    'Ella': {'lat': 6.8697, 'lng': 81.0464},
    'Sigiriya': {'lat': 7.9570, 'lng': 80.7603},
    'Mirissa': {'lat': 5.9464, 'lng': 80.4583},
    'Arugam Bay': {'lat': 6.8375, 'lng': 81.8306},
    'Dambulla': {'lat': 7.8567, 'lng': 80.6492},
    'Bentota': {'lat': 6.4210, 'lng': 79.9956},
    'Hikkaduwa': {'lat': 6.1395, 'lng': 80.1037},
    'Unawatuna': {'lat': 6.0158, 'lng': 80.2517},
    'Tangalle': {'lat': 6.0259, 'lng': 80.7951},
    'Negombo': {'lat': 7.2086, 'lng': 79.8357},
    'Chilaw': {'lat': 7.5758, 'lng': 79.7953},
    'Beruwala': {'lat': 6.4738, 'lng': 79.9825},
    // ADDED: More cities including Haputale
    'Haputale': {'lat': 6.7689, 'lng': 80.9600},
    'Bandarawela': {'lat': 6.8333, 'lng': 80.9833},
    'Hatton': {'lat': 6.8833, 'lng': 80.6000},
    'Tissamaharama': {'lat': 6.2833, 'lng': 81.3000},
    'Kataragama': {'lat': 6.4167, 'lng': 81.3333},
    'Adam\'s Peak': {'lat': 6.8096, 'lng': 80.4994},
    'Sinharaja': {'lat': 6.4000, 'lng': 80.5000},
    'Horton Plains': {'lat': 6.8000, 'lng': 80.8000},
    'Yala': {'lat': 6.5000, 'lng': 81.5000},
    'Wilpattu': {'lat': 8.4000, 'lng': 80.0000},
    'Pinnawala': {'lat': 7.3000, 'lng': 80.3833},
    'Kitulgala': {'lat': 6.9833, 'lng': 80.4167},
    'Knuckles': {'lat': 7.4500, 'lng': 80.8000},
    'Meemure': {'lat': 7.5500, 'lng': 80.8333},
    'Ritigala': {'lat': 8.1167, 'lng': 80.6500},
    'Mihintale': {'lat': 8.3500, 'lng': 80.5167},
    'Avukana': {'lat': 8.0167, 'lng': 80.5167},
    'Aukana': {'lat': 8.0167, 'lng': 80.5167},
  };

  // Sri Lankan categories with Google Place types
  static final Map<String, List<String>> _categoryTypes = {
    'Tourist Attractions': [
      'tourist_attraction',
      'point_of_interest',
      'park',
      'museum',
      'art_gallery',
      'zoo',
      'aquarium',
      'amusement_park',
      'natural_feature',
    ],
    'Hotels': ['lodging', 'hotel', 'resort'],
    'Restaurants': [
      'restaurant',
      'cafe',
      'food',
      'meal_delivery',
      'meal_takeaway'
    ],
    'Beaches': ['beach', 'natural_feature'],
    'Hills': ['natural_feature', 'mountain'],
    'Cultural': [
      'place_of_worship',
      'hindu_temple',
      'mosque',
      'church',
      'synagogue',
      'museum',
    ],
    'Wildlife': ['zoo', 'aquarium', 'park', 'natural_feature'],
    'Historical': ['museum', 'historical_landmark', 'monument'],
    'Religious': [
      'place_of_worship',
      'hindu_temple',
      'mosque',
      'church',
      'synagogue',
      'temple',
    ],
  };

  // Get coordinates for a city
  static Future<Map<String, double>> getCityCoordinates(String cityName) async {
    // First check our predefined list
    if (_sriLankanCities.containsKey(cityName)) {
      return _sriLankanCities[cityName]!;
    }

    // If not found, use geocoding API
    try {
      List<Location> locations = await locationFromAddress(
        '$cityName, Sri Lanka',
      );
      if (locations.isNotEmpty) {
        return {
          'lat': locations.first.latitude,
          'lng': locations.first.longitude,
        };
      }
    } catch (e) {
      print('Geocoding error for $cityName: $e');
    }

    // Default to Colombo if not found
    return _sriLankanCities['Colombo']!;
  }

  // FIXED: Main search method - uses textsearch for better city-wide results
  static Future<List<Map<String, dynamic>>> searchPlaces({
    required String city,
    required String category,
    String keyword = '',
    int radius = 50000, // 50km radius
  }) async {
    if (_apiKey.isEmpty) {
      print('⚠️ Google Maps API key not configured');
      return _getSamplePlaces(city, category, keyword);
    }

    try {
      // Get city coordinates
      final coordinates = await getCityCoordinates(city);
      final lat = coordinates['lat']!;
      final lng = coordinates['lng']!;

      // Build search query based on category
      String searchQuery = _buildSearchQuery(city, category, keyword);

      print('🔍 Searching: "$searchQuery" in $city ($lat, $lng)');

      // Use textsearch for better city-wide coverage
      final places = await _textSearchWithLocation(
        query: searchQuery,
        lat: lat,
        lng: lng,
        radius: radius,
      );

      if (places.isNotEmpty) {
        print('✅ Found ${places.length} places for $city');

        // Get details for each place
        final detailedPlaces = await Future.wait(
          places.take(20).map((place) async => await _getPlaceDetails(place)),
        );

        return detailedPlaces
            .where((place) => place.isNotEmpty)
            .map((place) => place.cast<String, dynamic>())
            .toList();
      }

      // If textsearch returns empty, try nearbysearch as fallback
      print('⚠️ Text search empty, trying nearby search...');
      return await _searchNearbyFallback(
        city: city,
        category: category,
        keyword: keyword,
        lat: lat,
        lng: lng,
        radius: radius,
      );
    } catch (e) {
      print('❌ Error searching places: $e');
      return _getSamplePlaces(city, category, keyword);
    }
  }

  // Build optimized search query
  static String _buildSearchQuery(
      String city, String category, String keyword) {
    if (keyword.isNotEmpty) {
      return '$keyword in $city Sri Lanka';
    }

    switch (category) {
      case 'Tourist Attractions':
        return 'things to do in $city Sri Lanka tourist attractions';
      case 'Hotels':
        return 'hotels in $city Sri Lanka';
      case 'Restaurants':
        return 'restaurants in $city Sri Lanka';
      case 'Beaches':
        return 'beaches in $city Sri Lanka';
      case 'Hills':
        return 'hills mountains in $city Sri Lanka';
      case 'Cultural':
        return 'cultural places temples museums in $city Sri Lanka';
      case 'Wildlife':
        return 'wildlife parks zoos in $city Sri Lanka';
      case 'Historical':
        return 'historical places ancient sites in $city Sri Lanka';
      case 'Religious':
        return 'temples churches religious places in $city Sri Lanka';
      default:
        return 'places to visit in $city Sri Lanka';
    }
  }

  // FIXED: Text search with location bias - FIXED TYPE CASTING
  static Future<List<Map<String, dynamic>>> _textSearchWithLocation({
    required String query,
    required double lat,
    required double lng,
    int radius = 50000,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/textsearch/json?'
      'query=${Uri.encodeComponent(query)}'
      '&location=$lat,$lng'
      '&radius=$radius'
      '&key=$_apiKey'
      '&language=en'
      '&region=lk',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          List<dynamic> results = data['results'];
          return results.map((result) => _parsePlaceResult(result)).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          print(
              '⚠️ Places API Error: ${data['status']} - ${data['error_message'] ?? ''}');
          return [];
        }
      } else {
        print('⚠️ HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error in text search: $e');
      return [];
    }
  }

  // FIXED: Parse place result with safe type conversion
  static Map<String, dynamic> _parsePlaceResult(dynamic result) {
    // Safely convert rating (can be int or double)
    double rating = 0.0;
    var ratingRaw = result['rating'];
    if (ratingRaw != null) {
      if (ratingRaw is int) {
        rating = ratingRaw.toDouble();
      } else if (ratingRaw is double) {
        rating = ratingRaw;
      } else if (ratingRaw is num) {
        rating = ratingRaw.toDouble();
      }
    }

    // Safely convert user_ratings_total (can be int or double)
    int userRatingsTotal = 0;
    var userRatingsRaw = result['user_ratings_total'];
    if (userRatingsRaw != null) {
      if (userRatingsRaw is int) {
        userRatingsTotal = userRatingsRaw;
      } else if (userRatingsRaw is double) {
        userRatingsTotal = userRatingsRaw.toInt();
      } else if (userRatingsRaw is num) {
        userRatingsTotal = userRatingsRaw.toInt();
      }
    }

    return {
      'place_id': result['place_id'] as String,
      'name': result['name'] as String? ?? 'Unknown',
      'vicinity':
          (result['formatted_address'] ?? result['vicinity'] ?? '') as String,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'types': List<String>.from(result['types'] ?? []),
      'geometry': result['geometry'] as Map<String, dynamic>? ?? {},
      'photos': result['photos'] as List<dynamic>?,
      'business_status': result['business_status'] as String?,
    };
  }

  // Fallback: Nearby search when text search fails
  static Future<List<Map<String, dynamic>>> _searchNearbyFallback({
    required String city,
    required String category,
    required String keyword,
    required double lat,
    required double lng,
    required int radius,
  }) async {
    final types =
        _categoryTypes[category] ?? ['point_of_interest', 'tourist_attraction'];
    List<Map<String, dynamic>> allPlaces = [];

    for (final type in types.take(3)) {
      // Limit to 3 types to avoid rate limits
      final places = await _searchNearby(
        lat: lat,
        lng: lng,
        radius: radius,
        type: type,
        keyword: keyword,
      );
      allPlaces.addAll(places);

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Remove duplicates
    final uniquePlaces = _removeDuplicates(allPlaces);

    // Get details
    final detailedPlaces = await Future.wait(
      uniquePlaces.take(15).map((place) async => await _getPlaceDetails(place)),
    );

    return detailedPlaces
        .where((place) => place.isNotEmpty)
        .map((place) => place.cast<String, dynamic>())
        .toList();
  }

  // FIXED: Nearby search implementation with safe type casting
  static Future<List<Map<String, dynamic>>> _searchNearby({
    required double lat,
    required double lng,
    required int radius,
    required String type,
    String keyword = '',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?'
      'location=$lat,$lng'
      '&radius=$radius'
      '&type=$type'
      '${keyword.isNotEmpty ? '&keyword=${Uri.encodeComponent(keyword)}' : ''}'
      '&key=$_apiKey'
      '&language=en',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          List<dynamic> results = data['results'] ?? [];
          return results.map((result) => _parsePlaceResult(result)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error in nearby search: $e');
      return [];
    }
  }

  // Text Search (for general search)
  static Future<List<Map<String, dynamic>>> textSearch(
    String query,
    String city,
  ) async {
    if (_apiKey.isEmpty || query.isEmpty) {
      return _getSamplePlaces(city, 'All', query);
    }

    try {
      final coordinates = await getCityCoordinates(city);
      final lat = coordinates['lat']!;
      final lng = coordinates['lng']!;

      // Use the improved text search with location
      final places = await _textSearchWithLocation(
        query: '$query in $city Sri Lanka',
        lat: lat,
        lng: lng,
        radius: 50000,
      );

      if (places.isNotEmpty) {
        final detailedPlaces = await Future.wait(
          places.take(10).map((place) async => await _getPlaceDetails(place)),
        );
        return detailedPlaces
            .where((place) => place.isNotEmpty)
            .map((place) => place.cast<String, dynamic>())
            .toList();
      }

      return _getSamplePlaces(city, 'All', query);
    } catch (e) {
      print('Text search error: $e');
      return _getSamplePlaces(city, 'All', query);
    }
  }

  // FIXED: Get detailed place information with safe type conversion
  static Future<Map<String, dynamic>> _getPlaceDetails(
    Map<String, dynamic> place,
  ) async {
    final placeId = place['place_id'] as String;
    final url = Uri.parse(
      '$_baseUrl/details/json?'
      'place_id=$placeId'
      '&fields=name,formatted_address,formatted_phone_number,website,rating,'
      'user_ratings_total,opening_hours,price_level,photos,geometry,types,vicinity,editorial_summary'
      '&key=$_apiKey'
      '&language=en',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;

          // Get photo URL if available
          String? photoUrl;
          final photos = result['photos'] as List<dynamic>?;
          if (photos != null && photos.isNotEmpty) {
            final photoRef = photos.first['photo_reference'] as String;
            photoUrl =
                '$_baseUrl/photo?maxwidth=400&photo_reference=$photoRef&key=$_apiKey';
          }

          // Extract city from address
          final address = (result['formatted_address'] ??
              place['vicinity'] ??
              '') as String;
          final extractedCity = _extractCityFromAddress(address);

          // Get coordinates
          Map<String, dynamic> coordinates = {};
          if (result['geometry'] != null) {
            final geometry = result['geometry'] as Map<String, dynamic>;
            if (geometry['location'] != null) {
              coordinates = geometry['location'] as Map<String, dynamic>;
            }
          } else if (place['geometry'] != null) {
            final geometry = place['geometry'] as Map<String, dynamic>;
            coordinates = geometry['location'] as Map<String, dynamic>;
          }

          // Get types
          List<String> types = [];
          if (result['types'] != null) {
            types = List<String>.from(result['types'] as List<dynamic>);
          } else if (place['types'] != null) {
            types = List<String>.from(place['types'] as List<dynamic>);
          }

          // Determine if indoor/outdoor
          bool isIndoor = _isIndoorPlace(types);

          // Get opening hours
          List<String> openingHours = [];
          if (result['opening_hours'] != null) {
            final openingHoursData =
                result['opening_hours'] as Map<String, dynamic>;
            if (openingHoursData['weekday_text'] != null) {
              openingHours = List<String>.from(
                openingHoursData['weekday_text'] as List<dynamic>,
              );
            }
          }

          // Get description from editorial_summary or generate
          String description = '';
          if (result['editorial_summary'] != null) {
            final summary = result['editorial_summary'] as Map<String, dynamic>;
            description = summary['overview'] as String? ?? '';
          }
          if (description.isEmpty) {
            description =
                _generateDescription(types, result['name'] as String?);
          }

          // FIXED: Safely convert rating and review count
          double rating = 0.0;
          var ratingRaw = result['rating'] ?? place['rating'];
          if (ratingRaw != null) {
            if (ratingRaw is int) {
              rating = ratingRaw.toDouble();
            } else if (ratingRaw is double) {
              rating = ratingRaw;
            } else if (ratingRaw is num) {
              rating = ratingRaw.toDouble();
            }
          }

          int reviewCount = 0;
          var reviewRaw =
              result['user_ratings_total'] ?? place['user_ratings_total'];
          if (reviewRaw != null) {
            if (reviewRaw is int) {
              reviewCount = reviewRaw;
            } else if (reviewRaw is double) {
              reviewCount = reviewRaw.toInt();
            } else if (reviewRaw is num) {
              reviewCount = reviewRaw.toInt();
            }
          }

          return {
            'id': placeId,
            'name': (result['name'] ?? place['name']) as String,
            'address':
                (result['formatted_address'] ?? place['vicinity']) as String,
            'phone': (result['formatted_phone_number'] ?? '') as String,
            'website': (result['website'] ?? '') as String,
            'rating': rating,
            'reviewCount': reviewCount,
            'openingHours': openingHours,
            'priceLevel': (result['price_level'] ?? 0) as int,
            'types': types,
            'coordinates': coordinates,
            'photoUrl': photoUrl,
            'city': extractedCity,
            'province': _getProvinceFromCity(extractedCity),
            'description': description,
            'isIndoor': isIndoor,
          };
        }
      }
      return {};
    } catch (e) {
      print('Error getting place details: $e');
      return {};
    }
  }

  // Determine if place is indoor
  static bool _isIndoorPlace(List<String> types) {
    final indoorTypes = [
      'museum',
      'art_gallery',
      'aquarium',
      'shopping_mall',
      'movie_theater',
      'spa',
      'restaurant',
      'cafe',
      'lodging',
      'hotel',
    ];
    return types.any((type) => indoorTypes.contains(type));
  }

  // Generate description based on place types
  static String _generateDescription(List<String> types, String? name) {
    if (types.contains('restaurant')) {
      return 'A popular dining spot offering delicious cuisine. Perfect for food lovers.';
    } else if (types.contains('hotel') || types.contains('lodging')) {
      return 'Comfortable accommodation with excellent service and amenities.';
    } else if (types.contains('tourist_attraction')) {
      return 'A must-visit attraction for tourists. Experience the beauty and culture.';
    } else if (types.contains('beach')) {
      return 'Beautiful sandy beach perfect for relaxation, swimming, and water activities.';
    } else if (types.contains('museum')) {
      return 'Cultural museum showcasing history, art, and heritage.';
    } else if (types.contains('place_of_worship')) {
      return 'Sacred place of worship with spiritual significance and beautiful architecture.';
    } else if (types.contains('park')) {
      return 'Beautiful park perfect for outdoor activities, picnics, and nature walks.';
    } else if (types.contains('zoo')) {
      return 'Wildlife park with various animal species, perfect for family outings.';
    } else if (types.contains('aquarium')) {
      return 'Marine life exhibition with fascinating aquatic creatures.';
    } else if (types.contains('cafe')) {
      return 'Cozy café serving beverages, snacks, and light meals.';
    } else if (types.contains('shopping_mall')) {
      return 'Shopping destination with various stores, restaurants, and entertainment.';
    } else if (types.contains('historical_landmark')) {
      return 'Historical landmark with rich cultural significance and architectural beauty.';
    } else if (types.contains('natural_feature')) {
      return 'Natural attraction with scenic beauty and outdoor activities.';
    }

    return name != null
        ? 'Visit $name for a memorable experience in Sri Lanka.'
        : 'A popular destination worth visiting in Sri Lanka.';
  }

  // Extract city from address
  static String _extractCityFromAddress(String address) {
    final sriLankanCities = _sriLankanCities.keys.toList();
    for (final city in sriLankanCities) {
      if (address.toLowerCase().contains(city.toLowerCase())) {
        return city;
      }
    }

    // Try to extract city from address pattern
    final parts = address.split(',');
    if (parts.length > 1) {
      for (final part in parts) {
        final trimmed = part.trim();
        for (final city in sriLankanCities) {
          if (trimmed.toLowerCase().contains(city.toLowerCase())) {
            return city;
          }
        }
      }
      return parts[parts.length - 2].trim();
    }

    return 'Colombo';
  }

  // Get province from city
  static String _getProvinceFromCity(String city) {
    final provinceMap = {
      'Colombo': 'Western',
      'Negombo': 'Western',
      'Kalutara': 'Western',
      'Galle': 'Southern',
      'Matara': 'Southern',
      'Hambantota': 'Southern',
      'Kandy': 'Central',
      'Matale': 'Central',
      'Nuwara Eliya': 'Central',
      'Anuradhapura': 'North Central',
      'Polonnaruwa': 'North Central',
      'Jaffna': 'Northern',
      'Vavuniya': 'Northern',
      'Mannar': 'Northern',
      'Kilinochchi': 'Northern',
      'Mullaitivu': 'Northern',
      'Trincomalee': 'Eastern',
      'Batticaloa': 'Eastern',
      'Ampara': 'Eastern',
      'Kurunegala': 'North Western',
      'Puttalam': 'North Western',
      'Ratnapura': 'Sabaragamuwa',
      'Kegalle': 'Sabaragamuwa',
      'Badulla': 'Uva',
      'Monaragala': 'Uva',
      'Ella': 'Uva',
      'Sigiriya': 'Central',
      'Mirissa': 'Southern',
      'Arugam Bay': 'Eastern',
      'Dambulla': 'Central',
      'Bentota': 'Western',
      'Hikkaduwa': 'Southern',
      'Unawatuna': 'Southern',
      'Tangalle': 'Southern',
      'Chilaw': 'North Western',
      'Beruwala': 'Western',
      'Haputale': 'Uva',
      'Bandarawela': 'Uva',
      'Hatton': 'Central',
      'Tissamaharama': 'Southern',
      'Kataragama': 'Uva',
      'Adam\'s Peak': 'Sabaragamuwa',
      'Sinharaja': 'Sabaragamuwa',
      'Horton Plains': 'Central',
      'Yala': 'Southern',
      'Wilpattu': 'North Western',
      'Pinnawala': 'Sabaragamuwa',
      'Kitulgala': 'Sabaragamuwa',
      'Knuckles': 'Central',
      'Meemure': 'Central',
      'Ritigala': 'North Central',
      'Mihintale': 'North Central',
      'Avukana': 'North Central',
      'Aukana': 'North Central',
    };

    return provinceMap[city] ?? 'Western';
  }

  // Remove duplicate places
  static List<Map<String, dynamic>> _removeDuplicates(
    List<Map<String, dynamic>> places,
  ) {
    final seenIds = <String>{};
    final uniquePlaces = <Map<String, dynamic>>[];

    for (final place in places) {
      final placeId = place['place_id'] as String;
      if (!seenIds.contains(placeId)) {
        seenIds.add(placeId);
        uniquePlaces.add(place);
      }
    }

    return uniquePlaces;
  }

  // Nationwide search without city restriction
  static Future<List<Map<String, dynamic>>> _nationwideSearch(
    String query,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/textsearch/json?'
        'query=${Uri.encodeComponent('$query Sri Lanka')}'
        '&key=$_apiKey'
        '&language=en'
        '&region=lk',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<dynamic> results = data['results'];
          return results.map((result) => _parsePlaceResult(result)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Nationwide search error: $e');
      return [];
    }
  }

  // ENHANCED: Sample data for testing when API fails - includes ALL cities
  static List<Map<String, dynamic>> _getSamplePlaces(
    String city,
    String category,
    String keyword,
  ) {
    List<Map<String, dynamic>> samples = [];

    final allSamples = [
      // Haputale specific places
      {
        'id': 'haputale_1',
        'name': 'Lipton\'s Seat',
        'address': 'Haputale, Uva Province',
        'rating': 4.7,
        'reviewCount': 450,
        'city': 'Haputale',
        'province': 'Uva',
        'description':
            'Scenic viewpoint where Sir Thomas Lipton used to sit and overlook his tea estates.',
        'category': 'Hills',
        'photoUrl': null,
        'types': ['tourist_attraction', 'natural_feature', 'viewpoint'],
        'isIndoor': false,
      },
      {
        'id': 'haputale_2',
        'name': 'Dambatenne Tea Factory',
        'address': 'Dambatenne, Haputale',
        'rating': 4.5,
        'reviewCount': 380,
        'city': 'Haputale',
        'province': 'Uva',
        'description':
            'Historic tea factory built in 1890 by Sir Thomas Lipton. Tours available.',
        'category': 'Cultural',
        'photoUrl': null,
        'types': ['tourist_attraction', 'museum'],
        'isIndoor': true,
      },
      {
        'id': 'haputale_3',
        'name': 'Adisham Hall',
        'address': 'Haputale, Uva Province',
        'rating': 4.6,
        'reviewCount': 320,
        'city': 'Haputale',
        'province': 'Uva',
        'description':
            'English country house built in 1931, now a monastery with beautiful gardens.',
        'category': 'Historical',
        'photoUrl': null,
        'types': ['tourist_attraction', 'historical_landmark'],
        'isIndoor': false,
      },
      {
        'id': 'haputale_4',
        'name': 'Haputale Mountain View',
        'address': 'Haputale Town, Uva Province',
        'rating': 4.8,
        'reviewCount': 520,
        'city': 'Haputale',
        'province': 'Uva',
        'description':
            'Breathtaking panoramic views of the southern plains and coastline.',
        'category': 'Hills',
        'photoUrl': null,
        'types': ['tourist_attraction', 'natural_feature', 'viewpoint'],
        'isIndoor': false,
      },
      {
        'id': 'haputale_5',
        'name': 'St. Andrew\'s Hotel',
        'address': 'Haputale, Uva Province',
        'rating': 4.3,
        'reviewCount': 280,
        'city': 'Haputale',
        'province': 'Uva',
        'description':
            'Colonial-style hotel with stunning views and comfortable accommodation.',
        'category': 'Hotels',
        'photoUrl': null,
        'types': ['lodging', 'hotel'],
        'isIndoor': true,
      },
      {
        'id': 'haputale_6',
        'name': 'Haputale Tea Gardens',
        'address': 'Haputale, Uva Province',
        'rating': 4.4,
        'reviewCount': 190,
        'city': 'Haputale',
        'province': 'Uva',
        'description':
            'Beautiful tea plantations covering the rolling hills around Haputale.',
        'category': 'Nature',
        'photoUrl': null,
        'types': ['natural_feature', 'park'],
        'isIndoor': false,
      },
      // Existing places...
      {
        'id': 'sample_1',
        'name': 'Sigiriya Rock Fortress',
        'address': 'Sigiriya, Central Province',
        'rating': 4.8,
        'reviewCount': 1250,
        'city': 'Sigiriya',
        'province': 'Central',
        'description': 'Ancient rock fortress and palace ruins with frescoes.',
        'category': 'Historical',
        'photoUrl': null,
        'types': ['tourist_attraction', 'historical_landmark'],
        'isIndoor': false,
      },
      {
        'id': 'sample_2',
        'name': 'Mirissa Beach',
        'address': 'Mirissa, Southern Province',
        'rating': 4.7,
        'reviewCount': 980,
        'city': 'Mirissa',
        'province': 'Southern',
        'description': 'Beautiful beach famous for whale watching and surfing.',
        'category': 'Beaches',
        'photoUrl': null,
        'types': ['beach', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'sample_3',
        'name': 'Temple of the Tooth',
        'address': 'Kandy, Central Province',
        'rating': 4.9,
        'reviewCount': 2100,
        'city': 'Kandy',
        'province': 'Central',
        'description': 'Sacred Buddhist temple housing a relic of Buddha.',
        'category': 'Religious',
        'photoUrl': null,
        'types': ['place_of_worship', 'tourist_attraction'],
        'isIndoor': true,
      },
      {
        'id': 'sample_4',
        'name': 'Galle Fort',
        'address': 'Galle, Southern Province',
        'rating': 4.6,
        'reviewCount': 850,
        'city': 'Galle',
        'province': 'Southern',
        'description':
            'Historic Portuguese-built fort with colonial architecture.',
        'category': 'Historical',
        'photoUrl': null,
        'types': ['historical_landmark', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'sample_5',
        'name': 'Nuwara Eliya',
        'address': 'Nuwara Eliya, Central Province',
        'rating': 4.5,
        'reviewCount': 1500,
        'city': 'Nuwara Eliya',
        'province': 'Central',
        'description':
            'Hill station known for tea plantations and cool climate.',
        'category': 'Hills',
        'photoUrl': null,
        'types': ['natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'sample_6',
        'name': 'Cinnamon Grand Colombo',
        'address': 'Colombo, Western Province',
        'rating': 4.5,
        'reviewCount': 650,
        'city': 'Colombo',
        'province': 'Western',
        'description': 'Luxury 5-star hotel in the heart of Colombo.',
        'category': 'Hotels',
        'photoUrl': null,
        'types': ['lodging', 'hotel'],
        'isIndoor': true,
      },
      {
        'id': 'sample_7',
        'name': 'Ministry of Crab',
        'address': 'Colombo, Western Province',
        'rating': 4.6,
        'reviewCount': 580,
        'city': 'Colombo',
        'province': 'Western',
        'description':
            'Award-winning restaurant serving Sri Lankan crab dishes.',
        'category': 'Restaurants',
        'photoUrl': null,
        'types': ['restaurant', 'food'],
        'isIndoor': true,
      },
      {
        'id': 'sample_8',
        'name': 'Nilaveli Beach',
        'address': 'Nilaveli, Eastern Province',
        'rating': 4.7,
        'reviewCount': 420,
        'city': 'Trincomalee',
        'province': 'Eastern',
        'description':
            'Pristine beach with clear blue waters perfect for snorkeling.',
        'category': 'Beaches',
        'photoUrl': null,
        'types': ['beach', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'sample_9',
        'name': 'Koneswaram Temple',
        'address': 'Trincomalee, Eastern Province',
        'rating': 4.8,
        'reviewCount': 890,
        'city': 'Trincomalee',
        'province': 'Eastern',
        'description': 'Historic Hindu temple overlooking the ocean.',
        'category': 'Religious',
        'photoUrl': null,
        'types': ['place_of_worship', 'tourist_attraction', 'hindu_temple'],
        'isIndoor': true,
      },
      {
        'id': 'sample_10',
        'name': 'Fort Frederick',
        'address': 'Trincomalee, Eastern Province',
        'rating': 4.5,
        'reviewCount': 340,
        'city': 'Trincomalee',
        'province': 'Eastern',
        'description': '17th century fort with historical significance.',
        'category': 'Historical',
        'photoUrl': null,
        'types': ['historical_landmark', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'sample_11',
        'name': 'Nagapooshani Amman Temple',
        'address': 'Nainativu, Northern Province',
        'rating': 4.7,
        'reviewCount': 560,
        'city': 'Jaffna',
        'province': 'Northern',
        'description': 'Ancient Hindu temple on Nainativu island.',
        'category': 'Religious',
        'photoUrl': null,
        'types': ['place_of_worship', 'tourist_attraction', 'hindu_temple'],
        'isIndoor': true,
      },
      {
        'id': 'sample_12',
        'name': 'Jaffna Fort',
        'address': 'Jaffna, Northern Province',
        'rating': 4.6,
        'reviewCount': 780,
        'city': 'Jaffna',
        'province': 'Northern',
        'description': 'Dutch colonial fort with rich history.',
        'category': 'Historical',
        'photoUrl': null,
        'types': ['historical_landmark', 'tourist_attraction'],
        'isIndoor': false,
      },
      // Ella places
      {
        'id': 'ella_1',
        'name': 'Nine Arch Bridge',
        'address': 'Ella, Uva Province',
        'rating': 4.8,
        'reviewCount': 1200,
        'city': 'Ella',
        'province': 'Uva',
        'description': 'Iconic bridge with nine arches, beautiful train rides.',
        'category': 'Historical',
        'photoUrl': null,
        'types': ['tourist_attraction', 'historical_landmark'],
        'isIndoor': false,
      },
      {
        'id': 'ella_2',
        'name': 'Little Adam\'s Peak',
        'address': 'Ella, Uva Province',
        'rating': 4.7,
        'reviewCount': 980,
        'city': 'Ella',
        'province': 'Uva',
        'description': 'Easy hike with stunning views of Ella Gap.',
        'category': 'Hills',
        'photoUrl': null,
        'types': ['natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'ella_3',
        'name': 'Ravana Falls',
        'address': 'Ella, Uva Province',
        'rating': 4.5,
        'reviewCount': 750,
        'city': 'Ella',
        'province': 'Uva',
        'description': 'Beautiful waterfall associated with the Ramayana epic.',
        'category': 'Nature',
        'photoUrl': null,
        'types': ['natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
      // Bandarawela places
      {
        'id': 'bandarawela_1',
        'name': 'Bible Rock',
        'address': 'Bandarawela, Uva Province',
        'rating': 4.4,
        'reviewCount': 280,
        'city': 'Bandarawela',
        'province': 'Uva',
        'description':
            'Rock formation resembling an open book, great for hiking.',
        'category': 'Hills',
        'photoUrl': null,
        'types': ['natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'bandarawela_2',
        'name': 'Dowa Temple',
        'address': 'Bandarawela, Uva Province',
        'rating': 4.6,
        'reviewCount': 340,
        'city': 'Bandarawela',
        'province': 'Uva',
        'description':
            'Ancient rock temple with a large unfinished Buddha statue.',
        'category': 'Religious',
        'photoUrl': null,
        'types': ['place_of_worship', 'tourist_attraction'],
        'isIndoor': true,
      },
      // Nuwara Eliya specific
      {
        'id': 'nuwaraeliya_1',
        'name': 'Gregory Lake',
        'address': 'Nuwara Eliya, Central Province',
        'rating': 4.5,
        'reviewCount': 890,
        'city': 'Nuwara Eliya',
        'province': 'Central',
        'description': 'Scenic lake with boat rides and horse riding.',
        'category': 'Nature',
        'photoUrl': null,
        'types': ['park', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'nuwaraeliya_2',
        'name': 'Hakgala Botanical Garden',
        'address': 'Nuwara Eliya, Central Province',
        'rating': 4.6,
        'reviewCount': 650,
        'city': 'Nuwara Eliya',
        'province': 'Central',
        'description': 'Beautiful botanical garden with diverse flora.',
        'category': 'Nature',
        'photoUrl': null,
        'types': ['park', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'nuwaraeliya_3',
        'name': 'Pedro Tea Estate',
        'address': 'Nuwara Eliya, Central Province',
        'rating': 4.4,
        'reviewCount': 420,
        'city': 'Nuwara Eliya',
        'province': 'Central',
        'description': 'Tea factory tours and tastings with beautiful views.',
        'category': 'Cultural',
        'photoUrl': null,
        'types': ['tourist_attraction', 'museum'],
        'isIndoor': true,
      },
      // Yala places
      {
        'id': 'yala_1',
        'name': 'Yala National Park',
        'address': 'Yala, Southern Province',
        'rating': 4.9,
        'reviewCount': 1500,
        'city': 'Yala',
        'province': 'Southern',
        'description':
            'Famous wildlife sanctuary with leopards, elephants, and birds.',
        'category': 'Wildlife',
        'photoUrl': null,
        'types': ['zoo', 'park', 'tourist_attraction'],
        'isIndoor': false,
      },
      // Horton Plains
      {
        'id': 'horton_1',
        'name': 'World\'s End',
        'address': 'Horton Plains, Central Province',
        'rating': 4.8,
        'reviewCount': 1100,
        'city': 'Horton Plains',
        'province': 'Central',
        'description': 'Dramatic 880m cliff drop with stunning views.',
        'category': 'Nature',
        'photoUrl': null,
        'types': ['natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
      {
        'id': 'horton_2',
        'name': 'Baker\'s Falls',
        'address': 'Horton Plains, Central Province',
        'rating': 4.6,
        'reviewCount': 780,
        'city': 'Horton Plains',
        'province': 'Central',
        'description': 'Beautiful 20m waterfall in Horton Plains.',
        'category': 'Nature',
        'photoUrl': null,
        'types': ['natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
      // Adam's Peak
      {
        'id': 'adamspeak_1',
        'name': 'Adam\'s Peak (Sri Pada)',
        'address': 'Ratnapura District, Sabaragamuwa',
        'rating': 4.9,
        'reviewCount': 2000,
        'city': 'Adam\'s Peak',
        'province': 'Sabaragamuwa',
        'description':
            'Sacred mountain with footprint of Buddha/Adam, pilgrimage site.',
        'category': 'Religious',
        'photoUrl': null,
        'types': ['place_of_worship', 'natural_feature', 'tourist_attraction'],
        'isIndoor': false,
      },
    ];

    // Filter by city if specified
    for (var place in allSamples) {
      final placeCity = place['city'] as String;
      final placeCategory = place['category'] as String;

      bool cityMatch = city == 'Colombo' ||
          placeCity.toLowerCase() == city.toLowerCase() ||
          placeCity.toLowerCase().contains(city.toLowerCase());

      if (cityMatch || city == 'All') {
        if (category == 'All' || placeCategory == category) {
          if (keyword.isEmpty ||
              place['name']
                  .toString()
                  .toLowerCase()
                  .contains(keyword.toLowerCase()) ||
              place['description']
                  .toString()
                  .toLowerCase()
                  .contains(keyword.toLowerCase())) {
            samples.add(Map.from(place));
          }
        }
      }
    }

    return samples;
  }
}
