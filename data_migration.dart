import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitspot/firestore/firestore_data_schema.dart';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/models/fitness_location.dart' as models;
import 'package:fitspot/models/review.dart' as models;
import 'package:fitspot/models/workout.dart' as models;

class DataMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate sample data to Firebase
  Future<void> migrateSampleData() async {
    try {
      print('Starting data migration...');
      
      // Check if data already exists
      final locationsQuery = await _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .limit(1)
          .get();
      
      if (locationsQuery.docs.isNotEmpty) {
        print('Sample data already exists, skipping migration.');
        return;
      }
      
      // Migrate fitness locations
      await _migrateFitnessLocations();
      
      print('Data migration completed successfully!');
    } catch (e) {
      print('Data migration failed: $e');
      throw e;
    }
  }

  Future<void> _migrateFitnessLocations() async {
    final batch = _firestore.batch();
    final sampleLocations = SampleData.sampleLocations;
    
    for (final location in sampleLocations) {
      final firestoreLocation = _convertToFirestoreLocation(location);
      final docRef = _firestore
          .collection(FirestoreSchema.fitnessLocationsCollection)
          .doc();
      
      batch.set(docRef, firestoreLocation.toFirestore());
    }
    
    await batch.commit();
    print('Migrated ${sampleLocations.length} fitness locations');
  }

  FitnessLocationDocument _convertToFirestoreLocation(models.FitnessLocation location) {
    return FitnessLocationDocument(
      id: '',
      name: location.name,
      description: location.description,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      type: location.status.toString().split('.').last,
      equipment: location.equipmentTypes,
      imageUrls: location.images,
      isValidated: location.isValidated,
      submittedBy: 'system',
      validatedBy: location.isValidated ? 'admin' : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      validatedAt: location.isValidated ? DateTime.now() : null,
      averageRating: location.rating,
      reviewCount: location.reviews.length,
      equipmentStatus: {},
    );
  }

  // Helper method to add sample workouts for a user
  Future<void> addSampleWorkoutsForUser(String userId) async {
    try {
      final sampleWorkouts = SampleData.sampleWorkouts;
      final batch = _firestore.batch();
      
      for (final workout in sampleWorkouts) {
        final firestoreWorkout = _convertToFirestoreWorkout(workout, userId);
        final docRef = _firestore
            .collection(FirestoreSchema.workoutsCollection)
            .doc();
        
        batch.set(docRef, firestoreWorkout.toFirestore());
      }
      
      await batch.commit();
      print('Added ${sampleWorkouts.length} sample workouts for user $userId');
    } catch (e) {
      print('Failed to add sample workouts: $e');
    }
  }

  WorkoutDocument _convertToFirestoreWorkout(models.Workout workout, String userId) {
    return WorkoutDocument(
      id: '',
      userId: userId,
      locationId: null,
      name: workout.title,
      type: workout.type.toString().split('.').last,
      date: workout.startTime,
      duration: workout.duration.inMinutes,
      calories: workout.caloriesBurned,
      notes: workout.notes,
      exercises: workout.exercises.map((exercise) => {
        'name': exercise,
        'sets': 0,
        'reps': 0,
        'weight': 0,
        'duration': 0,
      }).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to add sample reviews for locations
  Future<void> addSampleReviewsForLocation(String locationId, String userId, String userName) async {
    try {
      // Get the location to find its reviews in sample data
      final sampleLocation = SampleData.sampleLocations.firstWhere(
        (loc) => loc.name.contains('Parco'),
        orElse: () => SampleData.sampleLocations.first,
      );
      
      if (sampleLocation.reviews.isEmpty) return;
      
      final batch = _firestore.batch();
      
      for (final review in sampleLocation.reviews.take(3)) {
        final firestoreReview = _convertToFirestoreReview(review, locationId, userId, userName);
        final docRef = _firestore
            .collection(FirestoreSchema.reviewsCollection)
            .doc();
        
        batch.set(docRef, firestoreReview.toFirestore());
      }
      
      await batch.commit();
      print('Added sample reviews for location $locationId');
    } catch (e) {
      print('Failed to add sample reviews: $e');
    }
  }

  ReviewDocument _convertToFirestoreReview(models.Review review, String locationId, String userId, String userName) {
    return ReviewDocument(
      id: '',
      locationId: locationId,
      userId: userId,
      userName: userName,
      userPhotoUrl: null,
      rating: review.rating,
      comment: review.comment,
      equipmentReviews: review.equipmentReviewed.asMap().map((key, value) => MapEntry(value, 'Good condition')),
      imageUrls: review.imageUrls,
      createdAt: review.createdAt,
      updatedAt: review.createdAt,
    );
  }
}