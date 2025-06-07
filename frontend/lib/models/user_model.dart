class UserModel {
  final String id;
  final String name;
  final String email;
  final List<String> favorites;
  final List<String> watchHistory; // Added watch history
  final String role;
  final String? googleId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.favorites,
    required this.watchHistory, // Added to constructor
    required this.role,
    this.googleId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      favorites: List<String>.from(json['favorites'] as List? ?? []),
      watchHistory: List<String>.from(
        json['watchHistory'] as List? ?? [],
      ), // Added parsing
      role: json['role'] as String? ?? 'customer',
      googleId: json['googleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'username': name,
      'email': email,
      'favorites': favorites,
      'watchHistory': watchHistory, // Added to JSON
      'role': role,
    };
    if (googleId != null) {
      data['googleId'] = googleId;
    }
    return data;
  }
}
