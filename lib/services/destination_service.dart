import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DestinationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all destinations from Firestore
  Future<List<Map<String, dynamic>>> getDestinations({
    String? category,
    String? province,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection('destinations');

      // Apply filters
      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      if (province != null && province != 'All Provinces') {
        query = query.where('province', isEqualTo: province);
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> destinations = [];
      for (var doc in snapshot.docs) {
        // Safe way to handle document data with explicit casting
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData != null) {
          destinations.add({'id': doc.id, ...docData});
        }
      }

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        destinations = destinations.where((dest) {
          final name = dest['name']?.toString().toLowerCase() ?? '';
          final description =
              dest['description']?.toString().toLowerCase() ?? '';
          final province = dest['province']?.toString().toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();

          return name.contains(query) ||
              description.contains(query) ||
              province.contains(query);
        }).toList();
      }

      // Sort by rating (highest first)
      destinations.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      return destinations;
    } catch (error) {
      print('Error fetching destinations: $error');
      return [];
    }
  }

  // Get top picks (destinations with highest ratings)
  Future<List<Map<String, dynamic>>> getTopPicks() async {
    try {
      final snapshot = await _firestore
          .collection('destinations')
          .where('rating', isGreaterThan: 4.5)
          .orderBy('rating', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final docData = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...docData};
      }).toList();
    } catch (error) {
      print('Error fetching top picks: $error');
      return [];
    }
  }

  // Get destination by ID
  Future<Map<String, dynamic>?> getDestination(String id) async {
    try {
      final doc = await _firestore.collection('destinations').doc(id).get();
      final docData = doc.data() as Map<String, dynamic>?;
      if (doc.exists && docData != null) {
        return {'id': doc.id, ...docData};
      }
      return null;
    } catch (error) {
      print('Error fetching destination: $error');
      return null;
    }
  }

  // Add destination to user's wishlist
  Future<void> addToWishlist(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(destinationId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      // Update destination's wishlist count
      await _firestore.collection('destinations').doc(destinationId).update({
        'wishlistCount': FieldValue.increment(1),
      });
    } catch (error) {
      print('Error adding to wishlist: $error');
      throw error;
    }
  }

  // Get user's wishlist
  Future<List<Map<String, dynamic>>> getUserWishlist() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      List<Map<String, dynamic>> wishlist = [];
      for (var doc in snapshot.docs) {
        final destination = await getDestination(doc.id);
        if (destination != null) {
          wishlist.add(destination);
        }
      }

      return wishlist;
    } catch (error) {
      print('Error fetching wishlist: $error');
      return [];
    }
  }

  // Get destinations by weather condition
  Future<List<Map<String, dynamic>>> getDestinationsByWeather(
    String weatherCondition,
  ) async {
    try {
      String field;
      switch (weatherCondition.toLowerCase()) {
        case 'sunny':
          field = 'weatherSuitability.sunny';
          break;
        case 'cloudy':
          field = 'weatherSuitability.cloudy';
          break;
        case 'rainy':
          field = 'weatherSuitability.rainy';
          break;
        default:
          field = 'weatherSuitability.sunny';
      }

      final snapshot = await _firestore
          .collection('destinations')
          .orderBy(field, descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final docData = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...docData};
      }).toList();
    } catch (error) {
      print('Error fetching destinations by weather: $error');
      return [];
    }
  }

  // Get popular categories
  Future<List<String>> getPopularCategories() async {
    try {
      final snapshot = await _firestore
          .collection('destinations')
          .orderBy('popularity', descending: true)
          .limit(20)
          .get();

      final categories = <String, int>{};
      for (var doc in snapshot.docs) {
        final docData = doc.data() as Map<String, dynamic>;
        final category = docData['category']?.toString() ?? '';
        if (category.isNotEmpty) {
          categories[category] = (categories[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.map((e) => e.key).toList();
    } catch (error) {
      print('Error fetching popular categories: $error');
      return ['All', 'Beaches', 'Hills', 'Cultural', 'Historical'];
    }
  }

  // Get destinations near a location
  Future<List<Map<String, dynamic>>> getNearbyDestinations(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    try {
      // Note: Firestore doesn't support geospatial queries natively
      // You would need to use a geohash library or Cloud Functions
      // For now, returning empty
      return [];
    } catch (error) {
      print('Error fetching nearby destinations: $error');
      return [];
    }
  }

  // Record destination view for analytics
  Future<void> recordView(String destinationId) async {
    try {
      await _firestore.collection('destinations').doc(destinationId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print('Error recording view: $error');
    }
  }

  // Check if destination is in wishlist
  Future<bool> isInWishlist(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(destinationId)
          .get();

      return doc.exists;
    } catch (error) {
      print('Error checking wishlist: $error');
      return false;
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(destinationId)
          .delete();

      // Update destination's wishlist count
      await _firestore.collection('destinations').doc(destinationId).update({
        'wishlistCount': FieldValue.increment(-1),
      });
    } catch (error) {
      print('Error removing from wishlist: $error');
      throw error;
    }
  }

  // Get recommended destinations based on user history
  Future<List<Map<String, dynamic>>> getRecommendedDestinations() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Get user's visited destinations
      final visitedSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('visited')
          .get();

      if (visitedSnapshot.docs.isEmpty) {
        // If no history, return top rated destinations
        return await getTopPicks();
      }

      // Get categories from visited destinations
      final visitedCategories = <String>{};
      for (var doc in visitedSnapshot.docs) {
        final destination = await getDestination(doc.id);
        if (destination != null) {
          final category = destination['category']?.toString();
          if (category != null) {
            visitedCategories.add(category);
          }
        }
      }

      // Get destinations in similar categories
      List<Map<String, dynamic>> recommendations = [];
      for (var category in visitedCategories) {
        final categoryDestinations = await getDestinations(category: category);
        recommendations.addAll(categoryDestinations);
      }

      // Remove duplicates and visited places
      final visitedIds = visitedSnapshot.docs.map((doc) => doc.id).toSet();
      recommendations = recommendations
          .where((dest) => !visitedIds.contains(dest['id']))
          .toList();

      // Remove duplicates by id
      final seenIds = <String>{};
      recommendations = recommendations.where((dest) {
        final id = dest['id']?.toString();
        if (id != null && !seenIds.contains(id)) {
          seenIds.add(id);
          return true;
        }
        return false;
      }).toList();

      // Sort by rating
      recommendations.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      return recommendations.take(10).toList();
    } catch (error) {
      print('Error getting recommendations: $error');
      return [];
    }
  }
}
