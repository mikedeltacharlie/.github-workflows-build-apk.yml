import 'package:fitspot/models/fitness_location.dart';
import 'package:fitspot/models/workout.dart';
import 'package:fitspot/models/review.dart';
import 'package:fitspot/models/app_user.dart';

// Re-export enums so they can be used with SampleData
export 'package:fitspot/models/app_user.dart';
export 'package:fitspot/models/review.dart';

class SampleData {
  static final List<AppUser> sampleUsers = [
    AppUser(
      id: 'user_1',
      name: 'Mario Rossi',
      email: 'mario@example.com',
      profileImageUrl: null,
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      role: UserRole.user,
      stats: const UserStats(
        totalWorkouts: 12,
        totalWorkoutTime: Duration(hours: 15),
        locationsVisited: 5,
        reviewsWritten: 3,
        locationsAdded: 1,
      ),
    ),
    AppUser(
      id: 'admin_1',
      name: 'Admin',
      email: 'admin@fitspot.com',
      profileImageUrl: null,
      joinedAt: DateTime.now().subtract(const Duration(days: 500)),
      role: UserRole.admin,
      stats: const UserStats(
        totalWorkouts: 0,
        totalWorkoutTime: Duration.zero,
        locationsVisited: 0,
        reviewsWritten: 0,
        locationsAdded: 0,
      ),
    ),
  ];

  static final List<Review> sampleReviews = [
    Review(
      id: 'review_1',
      locationId: 'location_1',
      userId: 'user_1',
      userName: 'Mario Rossi',
      rating: 5,
      comment: 'Posto fantastico! Attrezzature in ottimo stato e molto pulito.',
      equipmentReviewed: ['Sbarre per trazioni', 'Parallele'],
      overallCondition: EquipmentCondition.excellent,
      locationCondition: LocationCondition.excellent,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Review(
      id: 'review_2',
      locationId: 'location_1',
      userId: 'user_2',
      userName: 'Giulia Bianchi',
      rating: 4,
      comment: 'Buon posto per allenarsi, solo un po\' affollato la sera.',
      equipmentReviewed: ['Parallele', 'Panca addominali'],
      overallCondition: EquipmentCondition.good,
      locationCondition: LocationCondition.good,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static final List<FitnessLocation> sampleLocations = [
    FitnessLocation(
      id: 'location_1',
      name: 'Parco delle Cascine',
      description: 'Area fitness attrezzata nel cuore del parco con vista sull\'Arno. Ideale per allenamenti mattutini e serali.',
      address: 'Parco delle Cascine, 50144 Firenze',
      latitude: 43.7854,
      longitude: 11.2230,
      equipmentTypes: ['Sbarre per trazioni', 'Parallele', 'Panca addominali', 'Anelli'],
      images: [
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        'https://images.unsplash.com/photo-1544216717-3bbf52512659?w=800',
      ],
      status: LocationStatus.excellent,
      isValidated: true,
      validatedBy: 'admin_1',
      validatedAt: DateTime.now().subtract(const Duration(days: 30)),
      reviews: sampleReviews.where((r) => r.locationId == 'location_1').toList(),
      rating: 4.5,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      createdBy: 'user_1',
    ),
    FitnessLocation(
      id: 'location_2',
      name: 'Giardino di Boboli - Area Fitness',
      description: 'Zona dedicata al fitness nel suggestivo Giardino di Boboli. Perfetta per chi ama allenarsi in un contesto storico.',
      address: 'Giardino di Boboli, 50125 Firenze',
      latitude: 43.7650,
      longitude: 11.2500,
      equipmentTypes: ['Parallele', 'Spalliera', 'Panca pesi'],
      images: [
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
      ],
      status: LocationStatus.good,
      isValidated: true,
      validatedBy: 'admin_1',
      validatedAt: DateTime.now().subtract(const Duration(days: 45)),
      reviews: [],
      rating: 4.0,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      createdBy: 'user_1',
    ),
    FitnessLocation(
      id: 'location_3',
      name: 'Parco Sant\'Antonio',
      description: 'Area fitness di recente installazione, perfetta per principianti e esperti.',
      address: 'Via Sant\'Antonio, 50100 Firenze',
      latitude: 43.7720,
      longitude: 11.2540,
      equipmentTypes: ['Sbarre per trazioni', 'Panca multifunzione', 'Cyclette'],
      images: [
        'https://images.unsplash.com/photo-1544216717-3bbf52512659?w=800',
      ],
      status: LocationStatus.needsMaintenance,
      isValidated: false,
      validatedBy: null,
      validatedAt: null,
      reviews: [],
      rating: 3.5,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'user_1',
    ),
  ];

  static final List<Workout> sampleWorkouts = [
    Workout(
      id: 'workout_1',
      userId: 'user_1',
      locationId: 'location_1',
      locationName: 'Parco delle Cascine',
      title: 'Allenamento Completo',
      description: 'Circuito completo con focus su forza e resistenza',
      type: WorkoutType.calisthenics,
      duration: const Duration(minutes: 45),
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: 1, minutes: 15)),
      exercises: ['Trazioni', 'Push-up', 'Dips', 'Squat'],
      notes: 'Ottimo allenamento, mi sono sentito molto bene',
      caloriesBurned: 320,
    ),
    Workout(
      id: 'workout_2',
      userId: 'user_1',
      locationId: null,
      locationName: null,
      title: 'Corsa Mattutina',
      description: 'Corsa leggera per iniziare la giornata',
      type: WorkoutType.running,
      duration: const Duration(minutes: 30),
      startTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: 7, minutes: 30)),
      exercises: ['Corsa'],
      notes: 'Bel tempo, corsa molto rilassante',
      caloriesBurned: 250,
      distanceKm: 4.2,
    ),
    Workout(
      id: 'workout_3',
      userId: 'user_1',
      locationId: 'location_2',
      locationName: 'Giardino di Boboli - Area Fitness',
      title: 'Sessione Forza',
      description: 'Sessione di forza sui parallele completata ieri',
      type: WorkoutType.strength,
      duration: const Duration(minutes: 40),
      startTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 20)),
      exercises: ['Dips', 'Handstand', 'L-sit'],
      notes: 'Buona progressione sui dips',
      caloriesBurned: 280,
    ),
  ];

  // Metodi per ottenere dati filtrati
  static List<FitnessLocation> get validatedLocations => 
      sampleLocations.where((location) => location.isValidated).toList();

  static List<FitnessLocation> get pendingLocations => 
      sampleLocations.where((location) => !location.isValidated).toList();

  static List<Workout> get completedWorkouts => 
      sampleWorkouts.where((workout) => workout.endTime != null).toList();

  static List<Workout> get activeWorkouts => 
      sampleWorkouts.where((workout) => workout.endTime == null).toList();

  // Metodi per aggiungere nuovi elementi (per test)
  static void addLocation(FitnessLocation location) {
    sampleLocations.add(location);
  }

  static void addWorkout(Workout workout) {
    sampleWorkouts.add(workout);
  }

  static void addReview(Review review) {
    sampleReviews.add(review);
  }

  // Attrezzature disponibili per i filtri
  static const List<String> availableEquipment = [
    'Sbarre per trazioni',
    'Parallele',
    'Panca addominali',
    'Panca pesi',
    'Anelli',
    'Spalliera',
    'Panca multifunzione',
    'Cyclette',
    'TRX',
    'Kettlebell',
    'Corde',
    'Balance board',
  ];

  static const List<String> commonEquipmentTypes = availableEquipment;

  static AppUser get sampleUser => sampleUsers.first;
}