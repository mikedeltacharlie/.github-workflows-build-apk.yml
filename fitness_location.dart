import 'package:fitspot/models/review.dart';

class FitnessLocation {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> equipmentTypes;
  final List<String> images;
  final LocationStatus status;
  final bool isValidated;
  final String? validatedBy;
  final DateTime? validatedAt;
  final List<Review> reviews;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isFavorite;

  const FitnessLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.equipmentTypes = const [],
    this.images = const [],
    required this.status,
    this.isValidated = false,
    this.validatedBy,
    this.validatedAt,
    this.reviews = const [],
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isFavorite = false,
  });

  // Computed properties for UI
  double get averageRating {
    if (reviews.isEmpty) return rating;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }
  
  // Calcola la condizione media del posto basata sulle recensioni
  LocationCondition get averageLocationCondition {
    if (reviews.isEmpty) {
      // Se non ci sono recensioni, usa lo status del posto
      switch (status) {
        case LocationStatus.excellent:
          return LocationCondition.excellent;
        case LocationStatus.good:
          return LocationCondition.good;
        case LocationStatus.needsMaintenance:
          return LocationCondition.needsMaintenance;
        case LocationStatus.poor:
          return LocationCondition.poor;
        case LocationStatus.closed:
          return LocationCondition.closed;
        case LocationStatus.pending:
          return LocationCondition.poor; // Default per quelli in attesa
      }
    }
    
    // Calcola la media delle valutazioni del posto dalle recensioni
    final totalValue = reviews.map((r) => r.locationCondition.value).reduce((a, b) => a + b);
    final average = totalValue / reviews.length;
    
    // Mappa i valori numerici agli stati (da 1 a 5)
    if (average >= 4.5) return LocationCondition.excellent;      // 4.5-5
    if (average >= 3.5) return LocationCondition.good;           // 3.5-4.4
    if (average >= 2.5) return LocationCondition.needsMaintenance; // 2.5-3.4
    if (average >= 1.5) return LocationCondition.poor;           // 1.5-2.4
    return LocationCondition.closed;                             // 1-1.4
  }

  int get reviewCount => reviews.length;
  
  List<String> get imageUrls => images;
  
  String get addedBy => createdBy;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'equipmentTypes': equipmentTypes,
        'images': images,
        'status': status.name,
        'isValidated': isValidated,
        'validatedBy': validatedBy,
        'validatedAt': validatedAt?.toIso8601String(),
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'rating': rating,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'isFavorite': isFavorite,
      };

  factory FitnessLocation.fromJson(Map<String, dynamic> json) => FitnessLocation(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        address: json['address'] ?? '',
        latitude: (json['latitude'] ?? 0.0).toDouble(),
        longitude: (json['longitude'] ?? 0.0).toDouble(),
        equipmentTypes: List<String>.from(json['equipmentTypes'] ?? []),
        images: List<String>.from(json['images'] ?? []),
        status: LocationStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LocationStatus.good,
        ),
        isValidated: json['isValidated'] ?? false,
        validatedBy: json['validatedBy'],
        validatedAt: json['validatedAt'] != null 
            ? DateTime.parse(json['validatedAt']) 
            : null,
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map((r) => Review.fromJson(r))
            .toList(),
        rating: (json['rating'] ?? 0.0).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
        createdBy: json['createdBy'] ?? '',
        isFavorite: json['isFavorite'] ?? false,
      );

  FitnessLocation copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? equipmentTypes,
    List<String>? images,
    LocationStatus? status,
    bool? isValidated,
    String? validatedBy,
    DateTime? validatedAt,
    List<Review>? reviews,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isFavorite,
  }) {
    return FitnessLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      equipmentTypes: equipmentTypes ?? this.equipmentTypes,
      images: images ?? this.images,
      status: status ?? this.status,
      isValidated: isValidated ?? this.isValidated,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
      reviews: reviews ?? this.reviews,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

enum LocationStatus {
  excellent,
  good,
  needsMaintenance,
  poor,
  closed,
  pending
}

extension LocationStatusExtension on LocationStatus {
  String get displayName {
    switch (this) {
      case LocationStatus.excellent:
        return 'Eccellente';
      case LocationStatus.good:
        return 'Buono';
      case LocationStatus.needsMaintenance:
        return 'Richiede Manutenzione';
      case LocationStatus.poor:
        return 'Pessimo';
      case LocationStatus.closed:
        return 'Chiuso';
      case LocationStatus.pending:
        return 'In Attesa di Validazione';
    }
  }
}