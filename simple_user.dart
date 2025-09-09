class SimpleUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isAdmin;
  final DateTime createdAt;

  const SimpleUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isAdmin = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SimpleUser.fromJson(Map<String, dynamic> json) {
    return SimpleUser(
      id: json['id'],
      displayName: json['displayName'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      isAdmin: json['isAdmin'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  @override
  String toString() {
    return 'SimpleUser(id: $id, displayName: $displayName, email: $email, isAdmin: $isAdmin)';
  }
}