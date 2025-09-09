import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitspot/firestore/firestore_data_schema.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // FITNESS LOCATIONS
  
  // Get all fitness locations
  Stream<List<FitnessLocationDocument>> getFitnessLocations({bool? validated}) {
    Query query = _firestore.collection(FirestoreSchema.fitnessLocationsCollection);
    
    if (validated != null) {
      query = query.where('isValidated', isEqualTo: validated);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FitnessLocationDocument.fromFirestore(doc);
      }).toList();
    });
  }

  // Get fitness locations by type
  Stream<List<FitnessLocationDocument>> getFitnessLocationsByType(String type) {
    return _firestore
        .collection(FirestoreSchema.fitnessLocationsCollection)
        .where('type', isEqualTo: type)
        .orderBy('averageRating', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FitnessLocationDocument.fromFirestore(doc);
      }).toList();
    });
  }

  // Get single fitness location
  Future<FitnessLocationDocument?> getFitnessLocation(String locationId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .doc(locationId)
          .get();
      
      if (doc.exists) {
        return FitnessLocationDocument.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Get fitness location error: $e');
      return null;
    }
  }

  // Get approved fitness locations as FitnessLocation models (for backwards compatibility)
  Future<List<dynamic>> getApprovedFitnessLocations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .where('isValidated', isEqualTo: true)
          .get();
      
      // Convert from Firestore documents to FitnessLocation models
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Convert from Firestore format to FitnessLocation format
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'address': data['address'] ?? '',
          'latitude': data['latitude'] ?? 0.0,
          'longitude': data['longitude'] ?? 0.0,
          'equipmentTypes': List<String>.from(data['equipment'] ?? []),
          'averageRating': (data['averageRating'] ?? 0.0).toDouble(),
          'reviewCount': data['reviewCount'] ?? 0,
          'isValidated': data['isValidated'] ?? false,
          'status': data['status'] ?? 'ottimo',
          'imageUrls': List<String>.from(data['imageUrls'] ?? []),
        };
      }).toList();
    } catch (e) {
      print('Get approved fitness locations error: $e');
      return [];
    }
  }

  // Create fitness location
  Future<String?> createFitnessLocation(FitnessLocationDocument location) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      DocumentReference docRef = await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .add(location.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Create fitness location error: $e');
      throw e;
    }
  }

  // Update fitness location
  Future<void> updateFitnessLocation(String locationId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .doc(locationId)
          .update(data);
    } catch (e) {
      print('Update fitness location error: $e');
      throw e;
    }
  }

  // Validate fitness location (admin only)
  Future<void> validateFitnessLocation(String locationId) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .doc(locationId)
          .update({
        'isValidated': true,
        'validatedBy': currentUserId,
        'validatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Validate fitness location error: $e');
      throw e;
    }
  }

  // REVIEWS
  
  // Get reviews for a location
  Stream<List<ReviewDocument>> getLocationReviews(String locationId) {
    return _firestore
        .collection(FirestoreSchema.reviewsCollection)
        .where('locationId', isEqualTo: locationId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReviewDocument.fromFirestore(doc);
      }).toList();
    });
  }

  // Alias method for backward compatibility
  Stream<List<ReviewDocument>> getReviewsForLocation(String locationId) {
    return getLocationReviews(locationId);
  }

  // Get validated locations
  Stream<List<FitnessLocationDocument>> getValidatedLocations() {
    return getFitnessLocations(validated: true);
  }

  // Add location suggestion
  Future<String?> addLocationSuggestion(FitnessLocationDocument location) async {
    return await createFitnessLocation(location);
  }

  // Add review
  Future<String?> addReview(ReviewDocument review) async {
    return await createReview(review);
  }

  // Create review
  Future<String?> createReview(ReviewDocument review) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      // Add the review
      DocumentReference docRef = await _firestore
          .collection(FirestoreSchema.reviewsCollection)
          .add(review.toFirestore());
      
      // Update location's average rating and review count
      await _updateLocationRating(review.locationId);
      
      return docRef.id;
    } catch (e) {
      print('Create review error: $e');
      throw e;
    }
  }

  // Update location rating after review changes
  Future<void> _updateLocationRating(String locationId) async {
    try {
      // Get all reviews for this location
      QuerySnapshot reviews = await _firestore
          .collection(FirestoreSchema.reviewsCollection)
          .where('locationId', isEqualTo: locationId)
          .get();
      
      if (reviews.docs.isEmpty) return;
      
      // Calculate average rating
      int totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] as int;
      }
      
      double averageRating = totalRating / reviews.docs.length;
      
      // Update location document
      await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .doc(locationId)
          .update({
        'averageRating': averageRating,
        'reviewCount': reviews.docs.length,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Update location rating error: $e');
    }
  }

  // WORKOUTS
  
  // Add workout
  Future<String?> addWorkout(WorkoutDocument workout) async {
    return await createWorkout(workout);
  }

  // Create workout
  Future<String?> createWorkout(WorkoutDocument workout) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      DocumentReference docRef = await _firestore
          .collection(FirestoreSchema.workoutsCollection)
          .add(workout.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Create workout error: $e');
      throw e;
    }
  }
  
  // Get user workouts
  Stream<List<WorkoutDocument>> getUserWorkouts(String userId) {
    return _firestore
        .collection(FirestoreSchema.workoutsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WorkoutDocument.fromFirestore(doc);
      }).toList();
    });
  }

  // Get current user workouts
  Stream<List<WorkoutDocument>> getCurrentUserWorkouts() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return getUserWorkouts(currentUserId!);
  }

  // Update workout
  Future<void> updateWorkout(String workoutId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(FirestoreSchema.workoutsCollection)
          .doc(workoutId)
          .update(data);
    } catch (e) {
      print('Update workout error: $e');
      throw e;
    }
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _firestore
          .collection(FirestoreSchema.workoutsCollection)
          .doc(workoutId)
          .delete();
    } catch (e) {
      print('Delete workout error: $e');
      throw e;
    }
  }

  // LOCATION SUGGESTIONS
  
  // Get location suggestions (admin only)
  Stream<List<LocationSuggestionDocument>> getLocationSuggestions({String? status}) {
    Query query = _firestore.collection(FirestoreSchema.locationSuggestionsCollection);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LocationSuggestionDocument.fromFirestore(doc);
      }).toList();
    });
  }

  // Create location suggestion
  Future<String?> createLocationSuggestion(LocationSuggestionDocument suggestion) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      DocumentReference docRef = await _firestore
          .collection(FirestoreSchema.locationSuggestionsCollection)
          .add(suggestion.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Create location suggestion error: $e');
      throw e;
    }
  }

  // Approve location suggestion (admin only)
  Future<void> approveLocationSuggestion(String suggestionId) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      // Get the suggestion
      DocumentSnapshot suggestionDoc = await _firestore
          .collection(FirestoreSchema.locationSuggestionsCollection)
          .doc(suggestionId)
          .get();
      
      if (!suggestionDoc.exists) throw 'Suggestion not found';
      
      LocationSuggestionDocument suggestion = LocationSuggestionDocument.fromFirestore(suggestionDoc);
      
      // Create fitness location from suggestion
      // Convert equipmentStatus string to Map
      Map<String, dynamic> equipmentStatusMap = {};
      for (String equipment in suggestion.equipment) {
        equipmentStatusMap[equipment] = suggestion.equipmentStatus;
      }
      
      FitnessLocationDocument location = FitnessLocationDocument(
        id: '',
        name: suggestion.name,
        description: suggestion.description,
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
        address: suggestion.address,
        type: suggestion.type,
        equipment: suggestion.equipment,
        imageUrls: suggestion.imageUrls,
        isValidated: true,
        submittedBy: suggestion.submittedBy,
        validatedBy: currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        validatedAt: DateTime.now(),
        equipmentStatus: equipmentStatusMap,
      );
      
      await createFitnessLocation(location);
      
      // Update suggestion status
      await _firestore
          .collection(FirestoreSchema.locationSuggestionsCollection)
          .doc(suggestionId)
          .update({
        'status': 'approved',
        'reviewedBy': currentUserId,
        'reviewedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Approve location suggestion error: $e');
      throw e;
    }
  }

  // Reject location suggestion (admin only)
  Future<void> rejectLocationSuggestion(String suggestionId, String adminNotes) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      await _firestore
          .collection(FirestoreSchema.locationSuggestionsCollection)
          .doc(suggestionId)
          .update({
        'status': 'rejected',
        'reviewedBy': currentUserId,
        'reviewedAt': Timestamp.now(),
        'adminNotes': adminNotes,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Reject location suggestion error: $e');
      throw e;
    }
  }



  // Get unmoderated reviews
  Stream<List<ReviewDocument>> getUnmoderatedReviews() {
    return _firestore
        .collection(FirestoreSchema.reviewsCollection)
        .where('isModerated', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewDocument.fromFirestore(doc))
            .toList());
  }

  // Moderate review (approve)
  Future<void> moderateReview(String reviewId, bool approve, String? adminNotes) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';
      
      Map<String, dynamic> updateData = {
        'isModerated': true,
        'moderatedBy': currentUserId,
        'moderatedAt': Timestamp.now(),
        'isApproved': approve,
        'updatedAt': Timestamp.now(),
      };

      if (adminNotes != null && adminNotes.isNotEmpty) {
        updateData['adminNotes'] = adminNotes;
      }

      await _firestore
          .collection(FirestoreSchema.reviewsCollection)
          .doc(reviewId)
          .update(updateData);
    } catch (e) {
      print('Moderate review error: $e');
      throw e;
    }
  }
}