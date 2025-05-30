class UserModel {
  final String id;
  final String name;
  final String email;
  final List<String> favorites; // Added favorites
  final String role; // Added role

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.favorites, // Added to constructor
    required this.role, // Added to constructor
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Handles if 'id' or '_id' is present
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['username'] as String? ?? '', // Map 'username' from backend to 'name'
      email: json['email'] as String? ?? '',
      favorites: List<String>.from(json['favorites'] as List? ?? []),
      role: json['role'] as String? ?? 'customer', // Default to 'customer' if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Serialize as '_id'
      'username': name, // Map 'name' back to 'username'
      'email': email,
      'favorites': favorites,
      'role': role,
    };
  }
}
