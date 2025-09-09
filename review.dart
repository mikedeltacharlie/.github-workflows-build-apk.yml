class Review {
  final String id;
  final String locationId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final List<String> equipmentReviewed;
  final EquipmentCondition overallCondition;
  final LocationCondition locationCondition; // Stato del posto secondo la recensione
  final DateTime createdAt;
  final bool isModerated;
  final List<String> imageUrls;

  const Review({
    required this.id,
    required this.locationId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.equipmentReviewed,
    required this.overallCondition,
    required this.locationCondition,
    required this.createdAt,
    this.isModerated = false,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'equipmentReviewed': equipmentReviewed,
      'overallCondition': overallCondition.name,
      'locationCondition': locationCondition.name,
      'createdAt': createdAt.toIso8601String(),
      'isModerated': isModerated,
      'imageUrls': imageUrls,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      locationId: json['locationId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      equipmentReviewed: List<String>.from(json['equipmentReviewed'] ?? []),
      overallCondition: json['overallCondition'] != null
          ? EquipmentCondition.values.firstWhere((e) => e.name == json['overallCondition'])
          : EquipmentCondition.good,
      locationCondition: json['locationCondition'] != null
          ? LocationCondition.values.firstWhere((e) => e.name == json['locationCondition'])
          : LocationCondition.good,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isModerated: json['isModerated'] ?? false,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

}

enum EquipmentCondition { excellent, good, fair, poor }

extension EquipmentConditionExtension on EquipmentCondition {
  String get displayName {
    switch (this) {
      case EquipmentCondition.excellent:
        return 'Eccellente';
      case EquipmentCondition.good:
        return 'Buono';
      case EquipmentCondition.fair:
        return 'Discreto';
      case EquipmentCondition.poor:
        return 'Scadente';
    }
  }
}

// Enum per lo stato del posto secondo le recensioni (allineato a LocationStatus)
enum LocationCondition { excellent, good, needsMaintenance, poor, closed }

extension LocationConditionExtension on LocationCondition {
  String get displayName {
    switch (this) {
      case LocationCondition.excellent:
        return 'Eccellente';
      case LocationCondition.good:
        return 'Buono';
      case LocationCondition.needsMaintenance:
        return 'Richiede Manutenzione';
      case LocationCondition.poor:
        return 'Pessimo';
      case LocationCondition.closed:
        return 'Chiuso';
    }
  }
  
  // Valore numerico per calcolare la media
  int get value {
    switch (this) {
      case LocationCondition.excellent:
        return 5;
      case LocationCondition.good:
        return 4;
      case LocationCondition.needsMaintenance:
        return 3;
      case LocationCondition.poor:
        return 2;
      case LocationCondition.closed:
        return 1;
    }
  }
}