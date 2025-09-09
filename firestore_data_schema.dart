import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Data Schema for FitSpot App
/// 
/// This file defines the structure of all collections and documents
/// stored in Firebase Firestore for the fitness locations tracking app.

class FirestoreSchema {
  static const String usersCollection = 'users';
  static const String fitnessLocationsCollection = 'fitness_locations';
  static const String reviewsCollection = 'reviews';
  static const String workoutsCollection = 'workouts';
  static const String locationSuggestionsCollection = 'location_suggestions';
}

/// User document structure
/// Collection: users/{userId}
class UserDocument {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;
  final List<String> favoriteLocations;

  UserDocument({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
    this.favoriteLocations = const [],
  });

  // Getter aliases for backward compatibility
  String get name => displayName;
  String? get profileImageUrl => photoUrl;

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDocument(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      preferences: data['preferences'] ?? {},
      favoriteLocations: List<String>.from(data['favoriteLocations'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
      'favoriteLocations': favoriteLocations,
    };
  }
}

/// Fitness Location document structure
/// Collection: fitness_locations/{locationId}
class FitnessLocationDocument {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String type; // 'calisthenics', 'running', 'workout_area', 'park'
  final List<String> equipment;
  final List<String> imageUrls;
  final bool isValidated;
  final String submittedBy;
  final String? validatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? validatedAt;
  final double averageRating;
  final int reviewCount;
  final Map<String, dynamic> equipmentStatus; // equipment_name -> status

  FitnessLocationDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.type,
    this.equipment = const [],
    this.imageUrls = const [],
    this.isValidated = false,
    required this.submittedBy,
    this.validatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.validatedAt,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.equipmentStatus = const {},
  });

  factory FitnessLocationDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FitnessLocationDocument(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      type: data['type'] ?? '',
      equipment: List<String>.from(data['equipment'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isValidated: data['isValidated'] ?? false,
      submittedBy: data['submittedBy'] ?? '',
      validatedBy: data['validatedBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      validatedAt: data['validatedAt'] != null ? (data['validatedAt'] as Timestamp).toDate() : null,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      equipmentStatus: Map<String, dynamic>.from(data['equipmentStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'type': type,
      'equipment': equipment,
      'imageUrls': imageUrls,
      'isValidated': isValidated,
      'submittedBy': submittedBy,
      'validatedBy': validatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'equipmentStatus': equipmentStatus,
    };
  }
}

// Review document structure (AGGIORNATO)
/// Collection: reviews/{reviewId}
class ReviewDocument {
  final String id;
  final String locationId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating; // 1-5
  final String comment;
  final Map<String, String> equipmentReviews; // equipment_name -> review
  final List<String> imageUrls;
  final String? locationStatus; // NUOVO CAMPO - stato della location secondo la recensione
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewDocument({
    required this.id,
    required this.locationId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    this.equipmentReviews = const {},
    this.imageUrls = const [],
    this.locationStatus, // NUOVO CAMPO
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter aliases for backward compatibility
  Map<String, String> get equipmentReviewed => equipmentReviews;
  String get overallCondition => 'good'; // Default value
  bool get isModerated => true; // Default value

  factory ReviewDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewDocument(
      id: doc.id,
      locationId: data['locationId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      equipmentReviews: Map<String, String>.from(data['equipmentReviews'] ?? {}),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      locationStatus: data['locationStatus'], // NUOVO CAMPO
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'locationId': locationId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'equipmentReviews': equipmentReviews,
      'imageUrls': imageUrls,
      'locationStatus': locationStatus, // NUOVO CAMPO
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Workout document structure
/// Collection: workouts/{workoutId}
class WorkoutDocument {
  final String id;
  final String userId;
  final String? locationId;
  final String name;
  final String type;
  final DateTime date;
  final int duration; // in minutes
  final int calories;
  final String notes;
  final List<Map<String, dynamic>> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutDocument({
    required this.id,
    required this.userId,
    this.locationId,
    required this.name,
    required this.type,
    required this.date,
    required this.duration,
    required this.calories,
    this.notes = '',
    this.exercises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutDocument(
      id: doc.id,
      userId: data['userId'] ?? '',
      locationId: data['locationId'],
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      duration: data['duration'] ?? 0,
      calories: data['calories'] ?? 0,
      notes: data['notes'] ?? '',
      exercises: List<Map<String, dynamic>>.from(data['exercises'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'locationId': locationId,
      'name': name,
      'type': type,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'calories': calories,
      'notes': notes,
      'exercises': exercises,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Location Suggestion document structure
/// Collection: location_suggestions/{suggestionId}
class LocationSuggestionDocument {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String type;
  final List<String> equipment;
  final List<String> imageUrls;
  final String submittedBy;
  final String status; // 'pending', 'approved', 'rejected'
  final String equipmentStatus; // 'excellent', 'good', 'needsMaintenance', 'poor', 'closed'
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? adminNotes;

  LocationSuggestionDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.type,
    this.equipment = const [],
    this.imageUrls = const [],
    required this.submittedBy,
    this.status = 'pending',
    this.equipmentStatus = 'good',
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.adminNotes,
  });

  factory LocationSuggestionDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationSuggestionDocument(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      type: data['type'] ?? '',
      equipment: List<String>.from(data['equipment'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      submittedBy: data['submittedBy'] ?? '',
      status: data['status'] ?? 'pending',
      equipmentStatus: data['equipmentStatus'] ?? 'good',
      reviewedBy: data['reviewedBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null ? (data['reviewedAt'] as Timestamp).toDate() : null,
      adminNotes: data['adminNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'type': type,
      'equipment': equipment,
      'imageUrls': imageUrls,
      'submittedBy': submittedBy,
      'status': status,
      'equipmentStatus': equipmentStatus,
      'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'adminNotes': adminNotes,
    };
  }
}