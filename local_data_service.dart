import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/models/fitness_location.dart';
import 'package:fitspot/models/workout.dart';

import 'package:fitspot/models/simple_user.dart';
import 'package:fitspot/models/review.dart' as model_review;

class LocalDataService {
  static const String _locationsKey = 'fitness_locations';
  static const String _workoutsKey = 'workouts';
  static const String _reviewsKey = 'reviews';
  static const String _currentUserKey = 'current_user';
  static const String _isGuestModeKey = 'is_guest_mode';

  // Singleton
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize with sample data if first time
    if (!_prefs!.containsKey(_locationsKey)) {
      await _initializeSampleData();
    }
  }

  Future<void> _initializeSampleData() async {
    // Create sample locations
    final sampleLocations = [
      FitnessLocation(
        id: 'loc1',
        name: 'Parco delle Cascine',
        description: 'Bellissimo parco con area fitness all\'aperto',
        address: 'Viale degli Olmi, Firenze',
        latitude: 43.7711,
        longitude: 11.2311,
        equipmentTypes: ['Pull-up bar', 'Parallel bars', 'Rings'],
        images: ['https://picsum.photos/400/300?random=1'],
        status: LocationStatus.excellent,
        isValidated: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        createdBy: 'admin',
        rating: 4.5,
      ),
      FitnessLocation(
        id: 'loc2',
        name: 'Villa Strozzi',
        description: 'Parco storico con attrezzature moderne',
        address: 'Via Pisana, Firenze',
        latitude: 43.7611,
        longitude: 11.2211,
        equipmentTypes: ['Calisthenics station', 'Running track'],
        images: ['https://picsum.photos/400/300?random=2'],
        status: LocationStatus.good,
        isValidated: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
        createdBy: 'user1',
        rating: 4.2,
      ),
    ];
    
    // Create sample workouts
    final sampleWorkouts = [
      Workout(
        id: 'w1',
        userId: 'guest_user',
        locationId: 'loc1',
        locationName: 'Parco delle Cascine',
        title: 'Allenamento Calisthenics',
        description: 'Sessione completa di calisthenics',
        type: WorkoutType.calisthenics,
        duration: const Duration(minutes: 45),
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        exercises: ['Pull-ups', 'Push-ups', 'Dips'],
        notes: 'Ottima sessione!',
        caloriesBurned: 350,
      ),
    ];
    
    // Create sample reviews
    final sampleReviews = [
      model_review.Review(
        id: 'r1',
        locationId: 'loc1',
        userId: 'user1',
        userName: 'Marco',
        rating: 5,
        comment: 'Posto fantastico per allenarsi!',
        equipmentReviewed: ['Pull-up bar', 'Parallel bars'],
        overallCondition: model_review.EquipmentCondition.excellent,
        locationCondition: model_review.LocationCondition.excellent,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isModerated: true,
        imageUrls: ['https://picsum.photos/300/200?random=10'],
      ),
    ];
    
    // Save to SharedPreferences
    final locationsJson = sampleLocations.map((l) => l.toJson()).toList();
    await _prefs!.setString(_locationsKey, jsonEncode(locationsJson));
    
    final workoutsJson = sampleWorkouts.map((w) => w.toJson()).toList();
    await _prefs!.setString(_workoutsKey, jsonEncode(workoutsJson));
    
    final reviewsJson = sampleReviews.map((r) => r.toJson()).toList();
    await _prefs!.setString(_reviewsKey, jsonEncode(reviewsJson));
  }

  // Guest mode management
  Future<void> setGuestMode(bool isGuest) async {
    await _prefs!.setBool(_isGuestModeKey, isGuest);
    
    if (isGuest) {
      final guestUser = SimpleUser(
        id: 'guest_user',
        displayName: 'Ospite',
        email: 'guest@fitspot.local',
        createdAt: DateTime.now(),
        isAdmin: false,
      );
      await _prefs!.setString(_currentUserKey, jsonEncode(guestUser.toJson()));
    }
  }

  bool get isGuestMode => _prefs?.getBool(_isGuestModeKey) ?? false;

  // Current user management
  SimpleUser? getCurrentUser() {
    final userJson = _prefs?.getString(_currentUserKey);
    if (userJson != null) {
      return SimpleUser.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> setCurrentUser(SimpleUser user) async {
    await _prefs!.setString(_currentUserKey, jsonEncode(user.toJson()));
    await _prefs!.setBool(_isGuestModeKey, false);
  }

  Future<void> clearCurrentUser() async {
    await _prefs!.remove(_currentUserKey);
    await _prefs!.setBool(_isGuestModeKey, false);
  }

  // Locations
  List<FitnessLocation> getLocations() {
    final locationsJson = _prefs?.getString(_locationsKey);
    if (locationsJson != null) {
      final List<dynamic> decoded = jsonDecode(locationsJson);
      return decoded.map((json) => FitnessLocation.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> addLocation(FitnessLocation location) async {
    final locations = getLocations();
    locations.add(location);
    final locationsJson = locations.map((l) => l.toJson()).toList();
    await _prefs!.setString(_locationsKey, jsonEncode(locationsJson));
  }

  Future<void> updateLocation(FitnessLocation location) async {
    final locations = getLocations();
    final index = locations.indexWhere((l) => l.id == location.id);
    if (index != -1) {
      locations[index] = location;
      final locationsJson = locations.map((l) => l.toJson()).toList();
      await _prefs!.setString(_locationsKey, jsonEncode(locationsJson));
    }
  }

  // Workouts
  List<Workout> getWorkouts() {
    final workoutsJson = _prefs?.getString(_workoutsKey);
    if (workoutsJson != null) {
      final List<dynamic> decoded = jsonDecode(workoutsJson);
      return decoded.map((json) => Workout.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> addWorkout(Workout workout) async {
    final workouts = getWorkouts();
    workouts.add(workout);
    final workoutsJson = workouts.map((w) => w.toJson()).toList();
    await _prefs!.setString(_workoutsKey, jsonEncode(workoutsJson));
  }

  List<Workout> getUserWorkouts(String userId) {
    return getWorkouts().where((w) => w.userId == userId).toList();
  }

  // Reviews
  List<model_review.Review> getReviews() {
    final reviewsJson = _prefs?.getString(_reviewsKey);
    if (reviewsJson != null) {
      final List<dynamic> decoded = jsonDecode(reviewsJson);
      return decoded.map((json) => model_review.Review.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> addReview(model_review.Review review) async {
    final reviews = getReviews();
    reviews.add(review);
    final reviewsJson = reviews.map((r) => r.toJson()).toList();
    await _prefs!.setString(_reviewsKey, jsonEncode(reviewsJson));
  }

  List<model_review.Review> getLocationReviews(String locationId) {
    return getReviews().where((r) => r.locationId == locationId).toList();
  }
}