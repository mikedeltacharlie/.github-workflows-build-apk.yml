class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime joinedAt;
  final UserRole role;
  final UserStats stats;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.joinedAt,
    this.role = UserRole.user,
    required this.stats,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'joinedAt': joinedAt.toIso8601String(),
        'role': role.name,
        'stats': stats.toJson(),
        'isActive': isActive,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        profileImageUrl: json['profileImageUrl'],
        joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.user,
        ),
        stats: UserStats.fromJson(json['stats'] ?? {}),
        isActive: json['isActive'] ?? true,
      );
}

class UserStats {
  final int totalWorkouts;
  final Duration totalWorkoutTime;
  final int locationsVisited;
  final int reviewsWritten;
  final int locationsAdded;

  const UserStats({
    this.totalWorkouts = 0,
    this.totalWorkoutTime = Duration.zero,
    this.locationsVisited = 0,
    this.reviewsWritten = 0,
    this.locationsAdded = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalWorkouts': totalWorkouts,
        'totalWorkoutTime': totalWorkoutTime.inMinutes,
        'locationsVisited': locationsVisited,
        'reviewsWritten': reviewsWritten,
        'locationsAdded': locationsAdded,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalWorkouts: json['totalWorkouts'] ?? 0,
        totalWorkoutTime: Duration(minutes: json['totalWorkoutTime'] ?? 0),
        locationsVisited: json['locationsVisited'] ?? 0,
        reviewsWritten: json['reviewsWritten'] ?? 0,
        locationsAdded: json['locationsAdded'] ?? 0,
      );

  UserStats copyWith({
    int? totalWorkouts,
    Duration? totalWorkoutTime,
    int? locationsVisited,
    int? reviewsWritten,
    int? locationsAdded,
  }) => UserStats(
        totalWorkouts: totalWorkouts ?? this.totalWorkouts,
        totalWorkoutTime: totalWorkoutTime ?? this.totalWorkoutTime,
        locationsVisited: locationsVisited ?? this.locationsVisited,
        reviewsWritten: reviewsWritten ?? this.reviewsWritten,
        locationsAdded: locationsAdded ?? this.locationsAdded,
      );
}

enum UserRole { user, admin }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Utente';
      case UserRole.admin:
        return 'Amministratore';
    }
  }
}