// lib/services/location_service.dart

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Get current location
  Future<Map<String, double>> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {
      'lat': position.latitude,
      'lng': position.longitude,
    };
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.name}, ${place.locality}, ${place.administrativeArea}';
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Get city name from coordinates
  Future<String> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks[0].locality ??
            placemarks[0].administrativeArea ??
            'Colombo';
      }
      return 'Colombo';
    } catch (e) {
      print('Error getting city: $e');
      return 'Colombo';
    }
  }

  // Search nearby places using Google Places API
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type,
    int radius = 5000, // 5km radius
  }) async {
    if (_apiKey.isEmpty) {
      print('Google Maps API key not configured');
      return _getSampleNearbyPlaces(type);
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=$radius'
        '&type=$type'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<dynamic> results = data['results'];
          return results.map((place) {
            return {
              'id': place['place_id'],
              'name': place['name'],
              'address': place['vicinity'],
              'rating': place['rating'] ?? 0.0,
              'userRatingsTotal': place['user_ratings_total'] ?? 0,
              'types': place['types'],
              'latitude': place['geometry']['location']['lat'],
              'longitude': place['geometry']['location']['lng'],
              'photoUrl': place['photos'] != null
                  ? 'https://maps.googleapis.com/maps/api/place/photo'
                      '?maxwidth=400'
                      '&photo_reference=${place['photos'][0]['photo_reference']}'
                      '&key=$_apiKey'
                  : null,
              'isOpen': place['opening_hours']?['open_now'] ?? false,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching nearby places: $e');
      return _getSampleNearbyPlaces(type);
    }
  }

  // Get nearby places of multiple categories
  Future<Map<String, List<Map<String, dynamic>>>> getAllNearbyPlaces({
    required double latitude,
    required double longitude,
  }) async {
    final categories = ['restaurant', 'lodging', 'tourist_attraction'];
    Map<String, List<Map<String, dynamic>>> results = {};

    for (String category in categories) {
      final places = await searchNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        type: category,
      );
      results[category] = places;
    }

    return results;
  }

  // Sample data for testing
  List<Map<String, dynamic>> _getSampleNearbyPlaces(String type) {
    switch (type) {
      case 'restaurant':
        return [
          {
            'id': 'rest_1',
            'name': 'The Gallery Cafe',
            'address': '2 Alfred House Rd, Colombo',
            'rating': 4.5,
            'userRatingsTotal': 234,
            'types': ['restaurant', 'cafe'],
            'latitude': 6.9045,
            'longitude': 79.8612,
            'isOpen': true,
          },
          {
            'id': 'rest_2',
            'name': 'Ministry of Crab',
            'address': 'Old Dutch Hospital, Colombo',
            'rating': 4.8,
            'userRatingsTotal': 567,
            'types': ['restaurant', 'seafood'],
            'latitude': 6.9345,
            'longitude': 79.8432,
            'isOpen': true,
          },
        ];
      case 'lodging':
        return [
          {
            'id': 'hotel_1',
            'name': 'Cinnamon Grand',
            'address': '77 Galle Rd, Colombo',
            'rating': 4.6,
            'userRatingsTotal': 892,
            'types': ['lodging', 'hotel'],
            'latitude': 6.9045,
            'longitude': 79.8612,
            'isOpen': true,
          },
        ];
      case 'tourist_attraction':
        return [
          {
            'id': 'attraction_1',
            'name': 'Gangaramaya Temple',
            'address': '61 Sri Jinaratana Rd, Colombo',
            'rating': 4.5,
            'userRatingsTotal': 345,
            'types': ['tourist_attraction', 'place_of_worship'],
            'latitude': 6.9145,
            'longitude': 79.8612,
            'isOpen': true,
          },
        ];
      default:
        return [];
    }
  }
}
