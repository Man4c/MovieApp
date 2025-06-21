import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/models/comment_model.dart' show ReviewModel;
import 'package:flutter_video_app/models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.116.1:4002/api';
  static String? _token;

  static void setToken(String token) {
    print('Setting token: $token'); // Debug log
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    print('Request headers: $headers'); // Debug log
    return headers;
  }

  static Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Login Response Data: ${json.encode(data)}"); // Debug log
      _token = data['token'] as String?;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      print(
        "Parsed User Data: name=${user.name}, email=${user.email}, role=${user.role}",
      ); // Debug log
      return user;
    }
    throw _handleError(response);
  }

  static Future<VideoModel> addMovieByAdmin(VideoModel movie) async {
    final response = await http.post(
      Uri.parse('$baseUrl/movies/admin/movies'),
      headers: _headers,
      body: json.encode(movie.toJson()),
    );

    if (response.statusCode == 201) {
      // Typically 201 for created resource
      final data = json.decode(response.body);
      // Assuming the backend returns { success: true, data: createdMovie }
      return VideoModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw _handleError(response);
  }

  static dynamic _handleError(http.Response response) {
    print('Error Response Status: ${response.statusCode}'); // Debug log
    print('Error Response Body: ${response.body}'); // Debug log

    try {
      final errorData = json.decode(response.body);
      throw errorData['message'] ?? 'Unknown error occurred';
    } catch (e) {
      if (e is FormatException) {
        throw 'Invalid response format from server';
      }
      rethrow;
    }
  }

  static Future<List<String>> getMovieTypes() async {
    print('Getting movie types...'); // Debug log
    final response = await http.get(
      Uri.parse('$baseUrl/genres'),
      headers: _headers,
    );

    print('Movie types response status: ${response.statusCode}'); // Debug log
    print('Movie types response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final typesList = responseData['genres'] as List?;
      final genres = List<String>.from(typesList ?? []);
      print('Found ${genres.length} genres: $genres'); // Debug log
      return genres.where((genre) => genre.isNotEmpty).toList();
    }
    throw _handleError(response);
  }

  static Future<UserModel> register(
    // Changed return type
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _headers,
      body: json.encode({
        'username': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      _token = data['token'] as String?;
      return UserModel.fromJson(
        data['user'] as Map<String, dynamic>,
      ); // Return UserModel
    }
    throw _handleError(response);
  }

  static Future<List<VideoModel>> getVideos({
    String? category,
    String? search,
    int? page,
    String? filterType,
  }) async {
    final queryParams = {
      if (category != null && category.isNotEmpty) 'category': category.trim(),
      if (search != null && search.isNotEmpty) 'search': search.trim(),
      if (filterType != null && filterType.isNotEmpty)
        'filterType': filterType.trim(),
      if (page != null) 'page': page.toString(),
    };

    print('Getting videos with params: $queryParams'); // Debug log
    print('Using headers: ${_headers}'); // Debug log

    final url = Uri.parse(
      '$baseUrl/movies',
    ).replace(queryParameters: queryParams);
    print('Request URL: $url'); // Debug log

    final response = await http.get(url, headers: _headers);

    print('Videos response status: ${response.statusCode}'); // Debug log
    print('Videos response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['data'] == null) {
        print('No videos found in response'); // Debug log
        return [];
      }
      final List<dynamic> videosData = responseData['data'] as List;
      print('Found ${videosData.length} videos'); // Debug log
      return videosData
          .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  static Future<List<VideoModel>> getFavorites() async {
    print('Getting favorites - Token: $_token'); // Debug log
    final response = await http.get(
      Uri.parse('$baseUrl/users/favorites'),
      headers: _headers,
    );

    print('Favorites response status: ${response.statusCode}'); // Debug log
    print('Favorites response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<dynamic> videosData = responseData['data'] as List;
      return videosData
          .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  static Future<void> toggleFavorite(String videoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/favorites/$videoId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  // Comments endpoints
  static Future<List<ReviewModel>> getVideoComments(String videoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movies/$videoId/comments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  static Future<ReviewModel> addComment(
    String videoId,
    String comment,
    double rating, {
    String? parentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/movies/$videoId/comments'),
      headers: _headers,
      body: json.encode({
        'comment': comment,
        'rating': rating,
        if (parentId != null) 'parentId': parentId,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return ReviewModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw _handleError(response);
  }

  static Future<UserModel> getCurrentUser() async {
    print('Getting current user info...'); // Debug log
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    print(
      'Get current user response status: ${response.statusCode}',
    ); // Debug log
    print('Get current user response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return UserModel.fromJson(data['data']);
      }
      throw 'Invalid response format';
    }
    throw _handleError(response);
  }

  static Future<List<VideoModel>> getWatchHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/watch-history'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  static Future<void> addToWatchHistory(String videoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/watch-history/$videoId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  static Future<void> clearWatchHistory() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/watch-history'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  static Future<UserModel> updateUsername(String newUsername) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/username'), // Corrected endpoint
      headers: _headers,
      body: json.encode({'newUsername': newUsername}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Backend returns { success: true, message: "...", data: { id: ..., name: ... }}
      // The actual user object is in data['data']
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw _handleError(response);
  }

  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }
    throw _handleError(response);
  }

  static Future<Map<String, dynamic>> signInWithGoogleToken(
    String idToken,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google/token'),
      headers: _headers,
      body: json.encode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'] as String?;
      return data;
    }
    throw _handleError(response);
  }

  static Future<Map<String, dynamic>> createPaymentIntent(
    String userId,
    String priceId,
  ) async {
    print('Creating payment intent for priceId: $priceId'); // Debug log
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-subscription'),
      headers: _headers,
      body: json.encode({'userId': userId, 'priceId': priceId}),
    );

    print(
      'Payment intent response status: ${response.statusCode}',
    ); // Debug log
    print('Payment intent response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw _handleError(response);
  }

  static Future<void> confirmSubscription(String subscriptionId) async {
    print('Confirming subscription: $subscriptionId'); // Debug log
    final response = await http.post(
      Uri.parse('$baseUrl/payments/confirm-subscription'),
      headers: _headers,
      body: json.encode({'subscriptionId': subscriptionId}),
    );

    print(
      'Confirm subscription response status: ${response.statusCode}',
    ); // Debug log
    print('Confirm subscription response body: ${response.body}'); // Debug log

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    print('Getting subscription status'); // Debug log
    final response = await http.get(
      Uri.parse('$baseUrl/payments/subscription-status'),
      headers: _headers,
    );

    print(
      'Subscription status response status: ${response.statusCode}',
    ); // Debug log
    print('Subscription status response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw _handleError(response);
  }

  static Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/admin/users/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<dynamic> usersData = responseData['data'] as List;
      return usersData
          .map(
            (userData) => UserModel.fromJson(userData as Map<String, dynamic>),
          )
          .toList();
    }
    throw _handleError(response);
  }

  static Future<UserModel?> getMe() async {
    print('Getting current user info'); // Debug log
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    print('Get me response status: ${response.statusCode}'); // Debug log
    print('Get me response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    return null;
  }
}
