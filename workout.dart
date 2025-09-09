class Workout {
  final String id;
  final String userId;
  final String? locationId;
  final String? locationName;
  final String title;
  final String description;
  final WorkoutType type;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> exercises;
  final String notes;
  final int caloriesBurned;
  final double? distanceKm;

  const Workout({
    required this.id,
    required this.userId,
    this.locationId,
    this.locationName,
    required this.title,
    required this.description,
    required this.type,
    required this.duration,
    required this.startTime,
    this.endTime,
    this.exercises = const [],
    this.notes = '',
    this.caloriesBurned = 0,
    this.distanceKm,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'locationId': locationId,
      'locationName': locationName,
      'title': title,
      'description': description,
      'type': type.name,
      'duration': duration.inMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises,
      'notes': notes,
      'caloriesBurned': caloriesBurned,
      'distanceKm': distanceKm,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      locationId: json['locationId'],
      locationName: json['locationName'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: WorkoutType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WorkoutType.general,
      ),
      duration: Duration(minutes: json['duration'] ?? 0),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      exercises: List<String>.from(json['exercises'] ?? []),
      notes: json['notes'] ?? '',
      caloriesBurned: json['caloriesBurned'] ?? 0,
      distanceKm: json['distanceKm']?.toDouble(),
    );
  }
}

enum WorkoutType { 
  cardio, 
  strength, 
  flexibility, 
  sports, 
  calisthenics,
  running,
  cycling,
  general 
}

extension WorkoutTypeExtension on WorkoutType {
  String get displayName {
    switch (this) {
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.strength:
        return 'Forza';
      case WorkoutType.flexibility:
        return 'Flessibilità';
      case WorkoutType.sports:
        return 'Sport';
      case WorkoutType.calisthenics:
        return 'Calisthenics';
      case WorkoutType.running:
        return 'Corsa';
      case WorkoutType.cycling:
        return 'Ciclismo';
      case WorkoutType.general:
        return 'Generale';
    }
  }
}