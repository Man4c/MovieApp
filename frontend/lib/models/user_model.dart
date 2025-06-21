class SubscriptionDetails {
  final String? subscriptionId;
  final String? planId;
  final String? status;
  final DateTime? currentPeriodEnd;

  SubscriptionDetails({
    this.subscriptionId,
    this.planId,
    this.status,
    this.currentPeriodEnd,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SubscriptionDetails(); // Return default/empty if no subscription data
    }
    return SubscriptionDetails(
      subscriptionId: json['subscriptionId'] as String?,
      planId: json['planId'] as String?,
      status: json['status'] as String?,
      currentPeriodEnd:
          json['currentPeriodEnd'] != null
              ? DateTime.tryParse(json['currentPeriodEnd'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'planId': planId,
      'status': status,
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final List<String> favorites;
  final List<String> watchHistory; // Added watch history
  final String role;
  final String? googleId;
  final String? stripeCustomerId; // New field
  final SubscriptionDetails? subscription; // New field

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.favorites,
    required this.watchHistory, // Added to constructor
    required this.role,
    this.googleId,
    this.stripeCustomerId, // Added to constructor
    this.subscription, // Added to constructor
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name:
          json['name'] as String? ??
          json['username'] as String? ??
          '', // Try both name and username fields
      email: json['email'] as String? ?? '',
      favorites: List<String>.from(json['favorites'] as List? ?? []),
      watchHistory: List<String>.from(
        json['watchHistory'] as List? ?? [],
      ), // Added parsing
      role: json['role'] as String? ?? 'customer',
      googleId: json['googleId'] as String?,
      stripeCustomerId:
          json['stripeCustomerId'] as String?, // Parsing new field
      subscription:
          json['subscription'] != null
              ? SubscriptionDetails.fromJson(
                json['subscription'] as Map<String, dynamic>,
              )
              : null, // Parsing new field
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
    if (stripeCustomerId != null) {
      data['stripeCustomerId'] = stripeCustomerId; // Adding new field
    }
    if (subscription != null) {
      data['subscription'] = subscription!.toJson(); // Adding new field
    }
    return data;
  }
}
