import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class GooglePlacesService {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Sri Lankan cities coordinates
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
    ],
    'Hotels': ['lodging', 'hotel'],
    'Restaurants': ['restaurant', 'cafe', 'food'],
    'Beaches': ['beach'],
    'Hills': ['natural_feature', 'mountain'],
    'Cultural': [
      'place_of_worship',
      'hindu_temple',
      'mosque',
      'church',
      'synagogue',
    ],
    'Wildlife': ['zoo', 'aquarium', 'park'],
    'Historical': ['museum', 'historical_landmark'],
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

  // Search places by city and category
  static Future<List<Map<String, dynamic>>> searchPlaces({
    required String city,
    required String category,
    String keyword = '',
    int radius = 50000, // 50km radius
  }) async {
    if (_apiKey.isEmpty) {
      print('Google Maps API key not configured');
      // Return sample data for testing when API key is missing
      return _getSamplePlaces(city, category, keyword);
    }

    try {
      // Get city coordinates
      final coordinates = await getCityCoordinates(city);
      final lat = coordinates['lat']!;
      final lng = coordinates['lng']!;

      // Get place types for category
      final types = _categoryTypes[category] ?? ['point_of_interest'];

      List<Map<String, dynamic>> allPlaces = [];

      // Search for each place type
      for (final type in types) {
        final places = await _searchNearby(
          lat: lat,
          lng: lng,
          radius: radius,
          type: type,
          keyword: keyword,
        );
        allPlaces.addAll(places);

        // Small delay to avoid rate limiting
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Remove duplicates
      final uniquePlaces = _removeDuplicates(allPlaces);

      // If no results and keyword is provided, try text search
      if (uniquePlaces.isEmpty && keyword.isNotEmpty) {
        return await textSearch(keyword, city);
      }

      // Get details and photos for each place
      final detailedPlaces = await Future.wait(
        uniquePlaces
            .take(15)
            .map((place) async => await _getPlaceDetails(place)),
      );

      return detailedPlaces
          .where((place) => place.isNotEmpty)
          .map((place) => place.cast<String, dynamic>())
          .toList();
    } catch (e) {
      print('Error searching places: $e');
      return _getSamplePlaces(city, category, keyword);
    }
  }

  // Sample data for testing when API fails
  static List<Map<String, dynamic>> _getSamplePlaces(
    String city,
    String category,
    String keyword,
  ) {
    List<Map<String, dynamic>> samples = [];

    // Add some Sri Lankan tourist attractions
    final allSamples = [
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
      },
      {
        'id': 'sample_2',
        'name': 'Temple of the Tooth',
        'address': 'Kandy, Central Province',
        'rating': 4.7,
        'reviewCount': 980,
        'city': 'Kandy',
        'province': 'Central',
        'description': 'Sacred Buddhist temple housing a relic of Buddha.',
        'category': 'Religious',
        'photoUrl': null,
        'types': ['place_of_worship', 'tourist_attraction'],
      },
      {
        'id': 'sample_3',
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
      },
      {
        'id': 'sample_4',
        'name': 'Mirissa Beach',
        'address': 'Mirissa, Southern Province',
        'rating': 4.7,
        'reviewCount': 720,
        'city': 'Mirissa',
        'province': 'Southern',
        'description': 'Beautiful beach famous for whale watching and surfing.',
        'category': 'Beaches',
        'photoUrl': null,
        'types': ['beach', 'tourist_attraction'],
      },
      {
        'id': 'sample_5',
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
      },
      {
        'id': 'sample_6',
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
      },
    ];

    // Filter by city if specified
    for (var place in allSamples) {
      if (place['city'] == city || city == 'Colombo') {
        // Filter by category
        if (category == 'All' || place['category'] == category) {
          // Filter by keyword
          if (keyword.isEmpty ||
              place['name'].toString().toLowerCase().contains(
                keyword.toLowerCase(),
              ) ||
              place['description'].toString().toLowerCase().contains(
                keyword.toLowerCase(),
              )) {
            samples.add(Map.from(place));
          }
        }
      }
    }

    return samples;
  }

  // Search nearby places
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
          return results.map((result) {
            return {
              'place_id': result['place_id'] as String,
              'name': result['name'] as String,
              'vicinity': (result['vicinity'] ?? '') as String,
              'rating': (result['rating'] ?? 0.0) as double,
              'user_ratings_total': (result['user_ratings_total'] ?? 0) as int,
              'types': List<String>.from(result['types'] ?? []),
              'geometry': result['geometry'] as Map<String, dynamic>,
              'photos': result['photos'] as List<dynamic>?,
            };
          }).toList();
        } else {
          print(
            'Google Places API Error: ${data['status']} - ${data['error_message']}',
          );
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in nearby search: $e');
      return [];
    }
  }

  // Get detailed place information
  static Future<Map<String, dynamic>> _getPlaceDetails(
    Map<String, dynamic> place,
  ) async {
    final placeId = place['place_id'] as String;
    final url = Uri.parse(
      '$_baseUrl/details/json?'
      'place_id=$placeId'
      '&fields=name,formatted_address,formatted_phone_number,website,rating,'
      'user_ratings_total,opening_hours,price_level,photos,geometry,types,vicinity'
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
          final address =
              (result['formatted_address'] ?? place['vicinity'] ?? '')
                  as String;
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

          return {
            'id': placeId,
            'name': (result['name'] ?? place['name']) as String,
            'address':
                (result['formatted_address'] ?? place['vicinity']) as String,
            'phone': (result['formatted_phone_number'] ?? '') as String,
            'website': (result['website'] ?? '') as String,
            'rating': ((result['rating'] ?? place['rating'] ?? 0.0) as num)
                .toDouble(),
            'reviewCount':
                ((result['user_ratings_total'] ??
                            place['user_ratings_total'] ??
                            0)
                        as num)
                    .toInt(),
            'openingHours': openingHours,
            'priceLevel': (result['price_level'] ?? 0) as int,
            'types': types,
            'coordinates': coordinates,
            'photoUrl': photoUrl,
            'city': extractedCity,
            'province': _getProvinceFromCity(extractedCity),
            'description': _generateDescription(
              types,
              result['name'] as String?,
            ),
          };
        }
      }
      return {};
    } catch (e) {
      print('Error getting place details: $e');
      return {};
    }
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
      // Look for Sri Lankan city names in address parts
      for (final part in parts) {
        final trimmed = part.trim();
        for (final city in sriLankanCities) {
          if (trimmed.contains(city)) {
            return city;
          }
        }
      }
      // Return the second last part if no match
      return parts[parts.length - 2].trim();
    }

    return 'Colombo'; // Default
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

      final url = Uri.parse(
        '$_baseUrl/textsearch/json?'
        'query=${Uri.encodeComponent('$query in $city, Sri Lanka')}'
        '&location=$lat,$lng'
        '&radius=50000'
        '&key=$_apiKey'
        '&language=en'
        '&region=lk',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<dynamic> results = data['results'];

          // Get details for each result
          final detailedResults = await Future.wait(
            results.take(10).map((result) async {
              final placeId = result['place_id'] as String;
              return await _getPlaceDetails({
                'place_id': placeId,
                'name': result['name'] as String,
                'vicinity': result['formatted_address'] as String? ?? '',
                'rating': (result['rating'] as num?)?.toDouble() ?? 0.0,
                'user_ratings_total':
                    (result['user_ratings_total'] as num?)?.toInt() ?? 0,
                'types': result['types'] as List<dynamic>? ?? [],
                'geometry': result['geometry'] as Map<String, dynamic>? ?? {},
                'photos': result['photos'] as List<dynamic>?,
              });
            }),
          );

          return detailedResults
              .where((place) => place.isNotEmpty)
              .map((place) => place.cast<String, dynamic>())
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          // Try nationwide search if no results in specific city
          return await _nationwideSearch(query);
        }
      }
      return _getSamplePlaces(city, 'All', query);
    } catch (e) {
      print('Text search error: $e');
      return _getSamplePlaces(city, 'All', query);
    }
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

          // Get details for top results
          final detailedResults = await Future.wait(
            results.take(10).map((result) async {
              final placeId = result['place_id'] as String;
              return await _getPlaceDetails({
                'place_id': placeId,
                'name': result['name'] as String,
                'vicinity': result['formatted_address'] as String? ?? '',
                'rating': (result['rating'] as num?)?.toDouble() ?? 0.0,
                'user_ratings_total':
                    (result['user_ratings_total'] as num?)?.toInt() ?? 0,
                'types': result['types'] as List<dynamic>? ?? [],
                'geometry': result['geometry'] as Map<String, dynamic>? ?? {},
                'photos': result['photos'] as List<dynamic>?,
              });
            }),
          );

          return detailedResults
              .where((place) => place.isNotEmpty)
              .map((place) => place.cast<String, dynamic>())
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Nationwide search error: $e');
      return [];
    }
  }
}
