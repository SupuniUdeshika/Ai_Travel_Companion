// lib/services/trip_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's trips
  Future<List<Map<String, dynamic>>> getUserTrips() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting user trips: $e');
      return [];
    }
  }

  // Get recent trips
  Future<List<Map<String, dynamic>>> getRecentTrips({int limit = 5}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting recent trips: $e');
      return [];
    }
  }

  // Get trip by ID
  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }
      return null;
    } catch (e) {
      print('Error getting trip: $e');
      return null;
    }
  }

  // Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  // Update trip
  Future<bool> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  // Get upcoming trips
  Future<List<Map<String, dynamic>>> getUpcomingTrips() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final now = DateTime.now().toIso8601String();

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .where('startDate', isGreaterThan: now)
          .orderBy('startDate')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting upcoming trips: $e');
      return [];
    }
  }

  // Get past trips
  Future<List<Map<String, dynamic>>> getPastTrips() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final now = DateTime.now().toIso8601String();

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .where('endDate', isLessThan: now)
          .orderBy('endDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting past trips: $e');
      return [];
    }
  }

  // Get trip statistics
  Future<Map<String, dynamic>> getTripStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final allTrips = await getUserTrips();

      int totalTrips = allTrips.length;
      int totalDays = 0;
      int totalPlaces = 0;

      for (var trip in allTrips) {
        // FIXED: Safely convert to int with proper type handling
        final duration = trip['duration'];
        if (duration is int) {
          totalDays += duration;
        } else if (duration is num) {
          totalDays += duration.toInt();
        } else if (duration is String) {
          totalDays += int.tryParse(duration) ?? 0;
        }

        final places = trip['totalPlaces'];
        if (places is int) {
          totalPlaces += places;
        } else if (places is num) {
          totalPlaces += places.toInt();
        } else if (places is String) {
          totalPlaces += int.tryParse(places) ?? 0;
        }
      }

      return {
        'totalTrips': totalTrips,
        'totalDays': totalDays,
        'totalPlaces': totalPlaces,
      };
    } catch (e) {
      print('Error getting trip stats: $e');
      return {};
    }
  }

  // Helper method to safely get int value from dynamic data
  int _safeGetInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Get total trip days (alternative method using helper)
  int getTotalTripDays(List<Map<String, dynamic>> trips) {
    int total = 0;
    for (var trip in trips) {
      total += _safeGetInt(trip['duration']);
    }
    return total;
  }

  // Get total places across all trips (alternative method using helper)
  int getTotalPlaces(List<Map<String, dynamic>> trips) {
    int total = 0;
    for (var trip in trips) {
      total += _safeGetInt(trip['totalPlaces']);
    }
    return total;
  }
}
